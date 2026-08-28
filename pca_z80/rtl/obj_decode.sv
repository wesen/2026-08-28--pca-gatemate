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
    typedef enum logic [4:0] {
        S_FETCH_PC, S_FETCH_OP, S_INC_OP, S_DECODE,
        S_FETCH_IMM, S_INC_IMM,
        S_REG_READ_SRC, S_REG_WRITE_DST,
        S_ALU_READ_A, S_ALU_READ_B, S_ALU_FETCH_IMM, S_ALU_INC_IMM,
        S_ALU_OP, S_ALU_WRITE_A, S_ALU_WRITE_FLAGS,
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
