// obj_decode.sv — the Z80 fetch/decode/execute control object (design-doc §6.4, §7).
//
// Phase 3A baseline: the bus master that fetches one byte at a time and
// executes NOP / HALT. It issues held-request transactions on the object bus
// (PC.read, MEM.read, PC.inc) and retires instructions. The FSM is the seed of
// the full Z80 decoder; 3B-3F add register/ALU/flags/control objects and the
// prefix machinery on the same bus, milestone by milestone.
//
// FSM: FETCH_PC -> FETCH_OP -> INC -> DECODE -> (NOP: retire, FETCH_PC | HALT)
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
    typedef enum logic [2:0] { S_FETCH_PC, S_FETCH_OP, S_INC, S_DECODE, S_HALT, S_FAULT } state_e;
    state_e state;

    logic [7:0]  ir;
    logic [15:0] pc_val;
    logic [31:0] count;
    logic        halted, faulted;

    assign dbg_ir     = ir;
    assign dbg_pc_val = pc_val;
    assign dbg_count  = count;
    assign dbg_halted = halted;
    assign dbg_faulted= faulted;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_FETCH_PC;
            ir       <= 8'h00;
            pc_val   <= 16'h0000;
            count    <= 32'd0;
            halted   <= 1'b0;
            faulted  <= 1'b0;
            bus_req  <= '0;
        end else begin
            case (state)
                S_FETCH_PC: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_READ; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        pc_val      <= bus_resp.rdata;
                        bus_req.req <= 1'b0;
                        state       <= S_FETCH_OP;
                    end
                end
                S_FETCH_OP: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b0;
                        bus_req.obj <= z80_obj::OBJ_MEM; bus_req.addr <= pc_val; bus_req.wdata <= 16'h0000;
                    end else if (bus_resp.ack) begin
                        ir          <= bus_resp.rdata[7:0];
                        bus_req.req <= 1'b0;
                        state       <= S_INC;
                    end
                end
                S_INC: begin
                    if (!bus_req.req) begin
                        bus_req.req <= 1'b1; bus_req.we <= 1'b1;
                        bus_req.obj <= z80_obj::OBJ_PC; bus_req.addr <= z80_obj::PC_INC; bus_req.wdata <= 16'h0001;
                    end else if (bus_resp.ack) begin
                        bus_req.req <= 1'b0;
                        state       <= S_DECODE;
                    end
                end
                S_DECODE: begin
                    if (ir == 8'h00) begin              // NOP
                        count <= count + 32'd1;
                        state <= S_FETCH_PC;
                    end else if (ir == 8'h76) begin      // HALT
                        count  <= count + 32'd1;        // HALT retires (matches model)
                        halted <= 1'b1;
                        state  <= S_HALT;
                    end else begin
                        faulted <= 1'b1;                 // 3A: only NOP/HALT legal
                        state   <= S_FAULT;
                    end
                end
                S_HALT, S_FAULT: begin
                    bus_req.req <= 1'b0;                // quiescent; no bus requests
                end
                default: state <= S_FETCH_PC;
            endcase
        end
    end
endmodule

`default_nettype wire
