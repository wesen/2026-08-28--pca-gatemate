// obj_pc.sv — the Z80 program-counter object (design-doc §6.4).
//
// A held-request bus slave holding PC[15:0] and the refresh counter R[6:0].
//   z80_obj::PC_READ: read  -> rdata = PC
//   z80_obj::PC_INC : write -> PC = (PC + wdata) & 0xFFFF; R = (R + 1) & 0x7F
//   z80_obj::PC_SET : write -> PC = wdata
// One transaction at a time; the held-request anti-double rule: accept on the
// first req&&ready edge, hold ack until req deasserts, never re-accept a held
// req (the MATE-16 captured-transaction pattern).
`default_nettype none

import z80_obj::*;

module obj_pc (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp,
    // debug visibility
    output logic [15:0] dbg_pc,
    output logic [7:0]  dbg_r
);
    logic [15:0] pc;
    logic [7:0]  r;
    logic        captured;   // accepted this transaction; hold ack until req drops

    assign dbg_pc = pc;
    assign dbg_r  = r;

    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_PC);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h0000;
            r  <= 8'h00;
            captured <= 1'b0;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                if (bus_req.we) begin
                    if (bus_req.addr == z80_obj::PC_INC)
                        pc <= (pc + bus_req.wdata) & 16'hFFFF;
                    else if (bus_req.addr == z80_obj::PC_SET)
                        pc <= bus_req.wdata;
                    r <= (r + 8'd1) & 8'h7F;   // R bumps per fetch/inc (Z80 refresh)
                end
            end else if (!sel) begin
                captured <= 1'b0;
            end
        end
    end

    // ack held while the captured transaction's req is still asserted.
    assign bus_resp.ack  = sel && captured;
    assign bus_resp.rdata = pc;
endmodule

`default_nettype wire
