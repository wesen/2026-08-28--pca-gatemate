// obj_decode.sv — the Z80 fetch/decode/execute control object (design-doc §6.4, §7).
//
// Phase 3B: the bus master that fetches bytes and executes NOP / HALT / LD r,n
// / LD r,r' (register operands only; (HL) memory operands arrive in a 3B.5
// follow-on). It issues held-request transactions on the object bus (PC.read,
// MEM.read, PC.inc, REG.read, REG.write) and retires instructions.
//
// The FSM mirrors the Z80 fetch-decode-execute loop (design-doc §7.1):
//   FETCH_PC -> FETCH_OP -> INC_OP -> DECODE -> (per-instruction execute) -> retire
// Multi-byte instructions sequence further bytes through FETCH_IMM/INC_IMM,
// advancing a local pc_cur that shadows the PC object. Retirement increments
// the count only on success (the MATE-16 / oracle discipline).
//
// Portable subset (locked in Phases 1-3A): field-by-field struct assigns
// (iverilog has no named struct literals), explicit z80_obj:: scoping for
// typedefs/localparams (Yosys wildcard import omits them).
`default_nettype none

import z80_obj::*;

module obj_decode (
    input  logic      clk,
    input  logic      rst_n,
    output z80_obj::bus_req_t  bus_req,
    input  z80_obj::bus_resp_t bus_resp,
    // debug visibility
    output logic [7:0]  dbg_ir,
    output logic [15:0] dbg_pc_val,
    output logic [31:0] dbg_count,
    output logic        dbg_halted,
    output logic        dbg_faulted
);
    typedef enum logic [5:0] {
        S_FETCH_PC, S_FETCH_OP, S_INC_OP, S_DECODE,
        S_FETCH_IMM, S_INC_IMM,
        S_REG_READ_SRC, S_REG_WRITE_DST,
        S_ALU_READ_A, S_ALU_READ_B, S_ALU_FETCH_IMM, S_ALU_INC_IMM,
        S_ALU_OP, S_ALU_WRITE_A, S_ALU_WRITE_FLAGS,
        S_JP_LO, S_JP_INC1, S_JP_HI, S_JP_INC2, S_PC_SET,
        S_JR_READ_F, S_JR_FETCH, S_JR_INC, S_JR_DO,
        S_CALL_LO, S_CALL_INC1, S_CALL_HI, S_CALL_INC2, S_CALL_DECSP2,
        S_CALL_SPHI, S_CALL_PUSHLO, S_CALL_PUSHHI, S_CALL_SET,
        S_RET_POPLO, S_RET_INC1, S_RET_POPHI, S_RET_POPLO2, S_RET_SET,
        S_PUSH_READ, S_PUSH_DECSP2, S_PUSH_SPHI, S_PUSH_SPLO, S_PUSH_SPLO2,
        S_POP_SPLO, S_POP_INC1, S_POP_SPHI, S_POP_SPLO2, S_POP_WRITE,
        S_LDNA_LO, S_LDNA_INC, S_LDNA_HI, S_LDNA_INC2, S_LDNA_WRITE, S_LDNA_COMMIT,
        S_HALT, S_FAULT
    } state_e;
    state_e state;

    logic [7:0]  ir;
    logic [15:0] pc_val;      // PC read at instruction start (debug)
    logic [15:0] pc_cur;      // local fetch cursor (shadows PC as we fetch bytes)
    logic [31:0] count;
    logic        halted, faulted;

    // decoded operands for the current instruction
    logic [3:0]  r_dst, r_src;
    logic [7:0]  imm_val;
    logic [7:0]  src_val;
    // ALU execute path (3C)
    logic [3:0]  alu_op;     // ALU_ADD/SUB/AND/XOR/OR/CP
    logic [7:0]  alu_a, alu_b, alu_result, alu_flags;
    logic        alu_is_cp;  // CP: don't write A
    // control-flow execute path (3E)
    logic [15:0] jp_addr;    // assembled JP/CALL address
    logic [7:0]  jr_e;       // JR displacement (signed)
    logic [2:0]  jr_cc;      // condition code for JR cc
    logic        jr_taken;   // resolved condition
    logic [7:0]  flag_q;     // latched F for JR cc
    // stack execute path (3F)
    logic [15:0] call_addr;   // CALL target
    logic [15:0] sp_val;      // latched SP
    logic [15:0] ret_addr;    // RET target
    logic [15:0] push_val;    // PUSH value
    logic [15:0] pop_val;     // POP value
    logic [1:0]  pp;         // push/pop pair index

    assign dbg_ir     = ir;
    assign dbg_pc_val = pc_val;
    assign dbg_count  = count;
    assign dbg_halted = halted;
    assign dbg_faulted= faulted;

    // helper: is this opcode LD r,r' (0x40-0x7F except 0x76)?
    function automatic logic is_ld_r_r(input logic [7:0] o);
        is_ld_r_r = ((o >= 8'h40) & (o <= 8'h7F)) & (o != 8'h76);
    endfunction
    // helper: is this opcode LD r,n? (0x06,0x0E,0x16,0x1E,0x26,0x2E,0x36,0x3E)
    function automatic logic is_ld_r_n(input logic [7:0] o);
        is_ld_r_n = (o & 8'hC7) == 8'h06;
    endfunction
    // helper: is this opcode ALU A,r (0x80-0xBF, excluding ADC 0x88-8F and SBC
    // 0x98-9F which need carry-in; and excluding (HL) src 6)?
    function automatic logic is_alu_r(input logic [7:0] o);
        is_alu_r = (o >= 8'h80) & (o <= 8'hBF)
                 & ~((o >= 8'h88) & (o <= 8'h8F))
                 & ~((o >= 8'h98) & (o <= 8'h9F))
                 & ((o & 8'h07) != 8'h06);
    endfunction
    // helper: is this opcode ALU A,n (ADD/SUB/AND/XOR/OR/CP n; not ADC/SBC)?
    function automatic logic is_alu_n(input logic [7:0] o);
        is_alu_n = (o == 8'hC6) | (o == 8'hD6) | (o == 8'hE6)
                 | (o == 8'hEE) | (o == 8'hF6) | (o == 8'hFE);
    endfunction
    // helper: map an ALU opcode (r-form 0x80-0xBF or n-form) to the ALU op index
    // (0=ADD,2=SUB,4=AND,5=XOR,6=OR,7=CP — matches ALU_OPS / obj_alu).
    function automatic logic [3:0] alu_op_of(input logic [7:0] o);
        if (o >= 8'h80 && o <= 8'hBF) alu_op_of = (o >> 3) & 8'h07;
        else case (o)
            8'hC6: alu_op_of = 4'd0;  // ADD
            8'hD6: alu_op_of = 4'd2;  // SUB
            8'hE6: alu_op_of = 4'd4;  // AND
            8'hEE: alu_op_of = 4'd5;  // XOR
            8'hF6: alu_op_of = 4'd6;  // OR
            8'hFE: alu_op_of = 4'd7;  // CP
            default: alu_op_of = 4'd0;
        endcase
    endfunction
    // control-flow helpers (3E)
    function automatic logic is_jp(input logic [7:0] o);
        is_jp = (o == 8'hC3);
    endfunction
    function automatic logic is_jr(input logic [7:0] o);
        is_jr = (o == 8'h18);
    endfunction
    function automatic logic is_jr_cc(input logic [7:0] o);
        is_jr_cc = (o == 8'h20) | (o == 8'h28) | (o == 8'h30) | (o == 8'h38);
    endfunction
    function automatic logic is_call(input logic [7:0] o);
        is_call = (o == 8'hCD);
    endfunction
    function automatic logic is_ret(input logic [7:0] o);
        is_ret = (o == 8'hC9);
    endfunction
    function automatic logic is_push(input logic [7:0] o);
        // C5=BC D5=DE E5=HL F5=AF
        is_push = (o == 8'hC5) | (o == 8'hD5) | (o == 8'hE5) | (o == 8'hF5);
    endfunction
    function automatic logic is_pop(input logic [7:0] o);
        // C1=BC D1=DE E1=HL F1=AF
        is_pop = (o == 8'hC1) | (o == 8'hD1) | (o == 8'hE1) | (o == 8'hF1);
    endfunction
    function automatic logic is_ld_a_nn(input logic [7:0] o);
        is_ld_a_nn = (o == 8'h32);  // LD (nn),A
    endfunction
    // push/pop reg-pair index: 0=BC,1=DE,2=HL,3=AF (matches RP_PUSH table)
    function automatic logic [1:0] pp_idx(input logic [7:0] o);
        pp_idx = (o >> 4) & 8'h03;
    endfunction
    // JR cc code: 0x20=NZ,0x28=Z,0x30=NC,0x38=C -> cc index 0,1,2,3
    function automatic logic [2:0] jr_cc_of(input logic [7:0] o);
        case (o)
            8'h20: jr_cc_of = 3'd0;  // NZ
            8'h28: jr_cc_of = 3'd1;  // Z
            8'h30: jr_cc_of = 3'd2;  // NC
            8'h38: jr_cc_of = 3'd3;  // C
            default: jr_cc_of = 3'd0;
        endcase
    endfunction
    // evaluate a JR cc against F (S=0x80 Z=0x40 C=0x01)
    function automatic logic cc_taken(input logic [2:0] cc, input logic [7:0] f);
        case (cc)
            3'd0: cc_taken = (f & 8'h40) == 8'h00;  // NZ
            3'd1: cc_taken = (f & 8'h40) != 8'h00;  // Z
            3'd2: cc_taken = (f & 8'h01) == 8'h00;  // NC
            3'd3: cc_taken = (f & 8'h01) != 8'h00;  // C
            default: cc_taken = 1'b0;
        endcase
    endfunction
    // sign-extend an 8-bit JR displacement to 16-bit
    function automatic logic [15:0] sext8(input logic [7:0] e);
        if (e & 8'h80) sext8 = {8'hFF, e};
        else sext8 = {8'h00, e};
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_FETCH_PC;
            ir       <= 8'h00;
            pc_val   <= 16'h0000;
            pc_cur   <= 16'h0000;
            count    <= 32'd0;
            halted   <= 1'b0;
            faulted  <= 1'b0;
            r_dst    <= 4'd0;
            r_src    <= 4'd0;
            imm_val  <= 8'h00;
            src_val  <= 8'h00;
            alu_op    <= 4'd0;
            alu_a     <= 8'h00;
            alu_b     <= 8'h00;
            alu_result<= 8'h00;
            alu_flags <= 8'h00;
            alu_is_cp <= 1'b0;
            jp_addr   <= 16'h0000;
            jr_e      <= 8'h00;
            jr_cc     <= 3'd0;
            jr_taken  <= 1'b0;
            flag_q    <= 8'h00;
            call_addr <= 16'h0000;
            sp_val    <= 16'h0000;
            ret_addr  <= 16'h0000;
            push_val  <= 16'h0000;
            pop_val   <= 16'h0000;
            pp        <= 2'd0;
            bus_req  <= '0;
        end else begin
            case (state)
                // ---- fetch PC (start of instruction) ----
                S_FETCH_PC: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_READ; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        pc_val      <= bus_resp.rdata;
                        pc_cur      <= bus_resp.rdata;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_OP;
                    end
                end
                // ---- fetch opcode byte at pc_cur ----
                S_FETCH_OP: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        ir          <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_INC_OP;
                    end
                end
                // ---- increment PC past the opcode ----
                S_INC_OP: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;
                        bus_req.req <= 1'b0;
                        state       <= S_DECODE;
                    end
                end
                // ---- decode ----
                S_DECODE: begin
                    if (ir == 8'h00) begin                       // NOP
                        count <= count + 32'd1;
                        state <= S_FETCH_PC;
                    end else if (ir == 8'h76) begin                // HALT
                        count  <= count + 32'd1;
                        halted <= 1'b1;
                        state  <= S_HALT;
                    end else if (is_ld_r_n(ir) && ((ir>>3)&7) != 3'd6) begin
                        // LD r,n  (r != (HL))
                        r_dst <= (ir >> 3) & 7;
                        state <= S_FETCH_IMM;
                    end else if (is_ld_r_r(ir) && ((ir>>3)&7) != 3'd6 && (ir&7) != 3'd6) begin
                        // LD r,r'  (neither is (HL))
                        r_dst <= (ir >> 3) & 7;
                        r_src <= ir & 7;
                        state <= S_REG_READ_SRC;
                    end else if (is_alu_r(ir)) begin
                        // ALU A,r  (ADD/SUB/AND/XOR/OR/CP A,r)
                        alu_op    <= alu_op_of(ir);
                        r_src     <= ir & 7;
                        alu_is_cp <= (alu_op_of(ir) == 4'd7);
                        state     <= S_ALU_READ_A;
                    end else if (is_alu_n(ir)) begin
                        // ALU A,n  (ADD/SUB/AND/XOR/OR/CP A,n)
                        alu_op    <= alu_op_of(ir);
                        alu_is_cp <= (alu_op_of(ir) == 4'd7);
                        state     <= S_ALU_FETCH_IMM;
                    end else if (is_jp(ir)) begin
                        // JP nn
                        state <= S_JP_LO;
                    end else if (is_jr(ir)) begin
                        // JR e
                        jr_taken <= 1'b1;
                        state    <= S_JR_FETCH;
                    end else if (is_jr_cc(ir)) begin
                        // JR cc,e
                        jr_cc <= jr_cc_of(ir);
                        state <= S_JR_READ_F;
                    end else if (is_call(ir)) begin
                        // CALL nn
                        state <= S_CALL_LO;
                    end else if (is_ret(ir)) begin
                        // RET
                        state <= S_RET_POPLO;
                    end else if (is_push(ir)) begin
                        // PUSH rr (BC/DE/HL/AF)
                        state <= S_PUSH_READ;
                    end else if (is_pop(ir)) begin
                        // POP rr
                        state <= S_POP_SPLO;
                    end else if (is_ld_a_nn(ir)) begin
                        // LD (nn),A  (Phase 6: write A to memory[nn], e.g. GPIO)
                        state <= S_LDNA_LO;
                    end else begin
                        faulted <= 1'b1;
                        state   <= S_FAULT;
                    end
                end
                // ---- LD r,n: fetch the immediate byte ----
                S_FETCH_IMM: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        imm_val     <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_INC_IMM;
                    end
                end
                // ---- LD r,n: increment PC past the immediate ----
                S_INC_IMM: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;
                        bus_req.req <= 1'b0;
                        state       <= S_REG_WRITE_DST;
                    end
                end
                // ---- LD r,r': read the source register ----
                S_REG_READ_SRC: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= {12'h000, r_src}; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        src_val     <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_REG_WRITE_DST;
                    end
                end
                // ---- write the destination register (LD r,n or LD r,r') ----
                S_REG_WRITE_DST: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= {12'h000, r_dst};
                        // LD r,n writes imm_val; LD r,r' writes src_val. Distinguish
                        // by whether we came from S_FETCH_IMM (imm) or S_REG_READ_SRC (src):
                        // track with a flag.
                        bus_req.wdata <= {8'h00, write_val_sel()};
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                // ---- ALU A,r / A,n: read the accumulator ----
                S_ALU_READ_A: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= 16'h0007; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        alu_a      <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        if (state == S_ALU_READ_A && (ir >= 8'h80) && (ir <= 8'hBF))
                            state <= S_ALU_READ_B;   // ALU A,r: read operand reg
                        else
                            state <= S_ALU_OP;        // ALU A,n: operand is the immediate
                    end
                end
                // ---- ALU A,r: read the operand register ----
                S_ALU_READ_B: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= {12'h000, r_src}; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        alu_b      <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_ALU_OP;
                    end
                end
                // ---- ALU A,n: fetch the immediate operand ----
                S_ALU_FETCH_IMM: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        alu_b      <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_ALU_INC_IMM;
                    end
                end
                // ---- ALU A,n: increment PC past the immediate ----
                S_ALU_INC_IMM: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;
                        bus_req.req <= 1'b0;
                        state       <= S_ALU_READ_A;
                    end
                end
                // ---- issue the ALU op ----
                S_ALU_OP: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_ALU; bus_req.addr <= {12'h000, alu_op};
                        bus_req.wdata <= {alu_a, alu_b};
                    end else if (bus_resp.ack) begin
                        alu_result <= bus_resp.rdata[7:0];
                        alu_flags  <= bus_resp.rdata[15:8];
                        bus_req.req <= 1'b0;
                        if (alu_is_cp)
                            state <= S_ALU_WRITE_FLAGS;
                        else
                            state <= S_ALU_WRITE_A;
                    end
                end
                // ---- write the result to A (skip for CP) ----
                S_ALU_WRITE_A: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= 16'h0007; bus_req.wdata <= {8'h00, alu_result};
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_ALU_WRITE_FLAGS;
                    end
                end
                // ---- write the flags ----
                S_ALU_WRITE_FLAGS: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_FLAGS; bus_req.addr <= z80_obj::FLAGS_WRITE; bus_req.wdata <= {8'h00, alu_flags};
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                // ---- JP nn: fetch low, inc PC, fetch high, inc PC, set PC ----
                S_JP_LO: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        jp_addr[7:0] <= bus_resp.rdata[7:0];
                        bus_req.req  <= 1'b0;
                        state       <= S_JP_INC1;
                    end
                end
                S_JP_INC1: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;
                        bus_req.req <= 1'b0;
                        state       <= S_JP_HI;
                    end
                end
                S_JP_HI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        jp_addr[15:8] <= bus_resp.rdata[7:0];
                        bus_req.req  <= 1'b0;
                        state       <= S_JP_INC2;
                    end
                end
                S_JP_INC2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_PC_SET;
                    end
                end
                S_PC_SET: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_SET; bus_req.wdata <= jp_addr;
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                // ---- JR cc: read flags, resolve condition ----
                S_JR_READ_F: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_FLAGS; bus_req.addr <= z80_obj::FLAGS_READ; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        flag_q      <= bus_resp.rdata[7:0];
                        jr_taken    <= cc_taken(jr_cc, bus_resp.rdata[7:0]);
                        bus_req.req <= 1'b0;
                        state       <= S_JR_FETCH;
                    end
                end
                // ---- JR e / JR cc,e: fetch the displacement byte ----
                S_JR_FETCH: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        jr_e       <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_JR_INC;
                    end
                end
                // ---- JR: inc PC past the displacement ----
                S_JR_INC: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;
                        bus_req.req <= 1'b0;
                        state       <= S_JR_DO;
                    end
                end
                // ---- JR do: set PC if taken, else retire ----
                S_JR_DO: begin
                    if (jr_taken) begin
                        if (!bus_req.req) begin
                            bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                            bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_SET;
                            bus_req.wdata <= pc_cur + sext8(jr_e);
                        end else if (bus_resp.ack) begin
                            count       <= count + 32'd1;
                            bus_req.req <= 1'b0;
                            state       <= S_FETCH_PC;
                        end
                    end else begin
                        count <= count + 32'd1;
                        state <= S_FETCH_PC;   // not taken: PC already past displacement
                    end
                end
                // ===================== 3F: stack (CALL/RET/PUSH/POP) =====================
                // ---- PUSH rr: read the pair, dec SP by 2, write high at SP, write low at SP-1 ----
                S_PUSH_READ: begin
                    if (!bus_req.req) begin
                        pp <= pp_idx(ir);
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= {12'h000, 4'd9 + pp_idx(ir)}; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        push_val   <= bus_resp.rdata;
                        bus_req.req <= 1'b0;
                        state       <= S_PUSH_DECSP2;
                    end
                end
                S_PUSH_DECSP2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_DEC; bus_req.wdata <= 16'h0002;
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_PUSH_SPHI;
                    end
                end
                S_PUSH_SPHI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_READ; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        sp_val      <= bus_resp.rdata;
                        bus_req.req <= 1'b0;
                        state       <= S_PUSH_SPLO;
                    end
                end
                S_PUSH_SPLO: begin
                    // SP already decremented by 2; write HIGH byte at SP+1, then LOW at SP.
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val + 16'h0001; bus_req.wdata <= {8'h00, push_val[15:8]};
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_PUSH_SPLO2;  // write the low byte at SP next
                    end
                end
                S_PUSH_SPLO2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val; bus_req.wdata <= {8'h00, push_val[7:0]};
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                // ---- POP rr: read low at SP, read high at SP+1, inc SP by 2, write pair ----
                S_POP_SPLO: begin
                    pp <= pp_idx(ir);
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_READ; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        sp_val      <= bus_resp.rdata;
                        bus_req.req <= 1'b0;
                        state       <= S_POP_INC1;
                    end
                end
                S_POP_INC1: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_INC; bus_req.wdata <= 16'h0002;
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_POP_SPHI;
                    end
                end
                S_POP_SPHI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val + 16'h0001; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        pop_val[15:8] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_POP_SPLO2;
                    end
                end
                S_POP_SPLO2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        pop_val[7:0] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_POP_WRITE;
                    end
                end
                S_POP_WRITE: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= {12'h000, 4'd9 + pp}; bus_req.wdata <= pop_val;
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                // ---- CALL nn: fetch target, inc PC past the 3 bytes, push return addr (PC after CALL), set PC ----
                S_CALL_LO: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        call_addr[7:0] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_INC1;
                    end
                end
                S_CALL_INC1: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_HI;
                    end
                end
                S_CALL_HI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        call_addr[15:8] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_INC2;
                    end
                end
                S_CALL_INC2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;  // pc_cur now = return addr (after CALL)
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_DECSP2;
                    end
                end
                // ---- CALL: dec SP by 2, push high then low of return addr, set PC ----
                S_CALL_DECSP2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_DEC; bus_req.wdata <= 16'h0002;
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_SPHI;
                    end
                end
                S_CALL_SPHI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_READ; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        sp_val      <= bus_resp.rdata;
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_PUSHLO;
                    end
                end
                S_CALL_PUSHLO: begin
                    // SP already dec by 2; push HIGH byte of return addr at SP+1, then LOW at SP.
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val + 16'h0001; bus_req.wdata <= {8'h00, pc_cur[15:8]};
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_PUSHHI;
                    end
                end
                S_CALL_PUSHHI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val; bus_req.wdata <= {8'h00, pc_cur[7:0]};
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_CALL_SET;
                    end
                end
                S_CALL_SET: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_SET; bus_req.wdata <= call_addr;
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                // ---- RET: read low at SP, read high at SP+1, inc SP by 2, set PC ----
                S_RET_POPLO: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_READ; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        sp_val      <= bus_resp.rdata;
                        bus_req.req <= 1'b0;
                        state       <= S_RET_INC1;
                    end
                end
                S_RET_INC1: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::SP_INC; bus_req.wdata <= 16'h0002;
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_RET_POPHI;
                    end
                end
                S_RET_POPHI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val + 16'h0001; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        ret_addr[15:8] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_RET_POPLO2;
                    end
                end
                S_RET_POPLO2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= sp_val; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        ret_addr[7:0] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_RET_SET;
                    end
                end
                S_RET_SET: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_SET; bus_req.wdata <= ret_addr;
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                // ---- LD (nn),A: fetch addr lo/hi, inc PC past them, read A, write A to mem[addr] ----
                S_LDNA_LO: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        call_addr[7:0] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_LDNA_INC;
                    end
                end
                S_LDNA_INC: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        pc_cur      <= pc_cur + 16'h0001;
                        bus_req.req <= 1'b0;
                        state       <= S_LDNA_HI;
                    end
                end
                S_LDNA_HI: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_cur; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        call_addr[15:8] <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_LDNA_INC2;
                    end
                end
                S_LDNA_INC2: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_LDNA_WRITE;
                    end
                end
                S_LDNA_WRITE: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_REG; bus_req.addr <= 16'h0007; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        alu_a       <= bus_resp.rdata[7:0];  // reuse alu_a to hold A
                        bus_req.req <= 1'b0;
                        state       <= S_LDNA_COMMIT;
                    end
                end
                S_LDNA_COMMIT: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= call_addr; bus_req.wdata <= {8'h00, alu_a};
                    end else if (bus_resp.ack) begin
                        count       <= count + 32'd1;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_PC;
                    end
                end
                S_HALT, S_FAULT: begin
                    bus_req.req <= 1'b0;                // quiescent
                end
                default: state <= S_FETCH_PC;
            endcase
        end
    end

    // Selects imm_val for LD r,n or src_val for LD r,r'. The opcode in `ir`
    // still holds the instruction at S_REG_WRITE_DST: LD r,n matches
    // (ir & 0xC7)==0x06; LD r,r' is 0x40-0x7F.
    function automatic logic [7:0] write_val_sel();
        if ((ir & 8'hC7) == 8'h06)
            write_val_sel = imm_val;
        else
            write_val_sel = src_val;
    endfunction
endmodule

`default_nettype wire
