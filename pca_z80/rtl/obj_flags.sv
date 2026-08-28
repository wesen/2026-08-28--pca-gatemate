// obj_flags.sv — the Z80 flags register object (design-doc §6.4, §5.1), 3C.
//
// A held-request bus slave holding the 8-bit F register (S Z F5 H F3 PV N C).
//   z80_obj::FLAGS_READ  (we=0): rdata = {8'h00, F}
//   z80_obj::FLAGS_WRITE (we=1): F = wdata[7:0]
// Same captured-transaction anti-double handshake. (Phase 5: the ALU object
// could write flags directly, but keeping flags as a separate bus object
// matches the object/message model and lets CP set flags without a reg write.)
`default_nettype none

import z80_obj::*;

module obj_flags (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp,
    output logic [7:0] dbg_f
);
    logic [7:0] f;
    logic        captured;

    assign dbg_f = f;
    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_FLAGS);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            f        <= 8'h00;
            captured <= 1'b0;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                if (bus_req.we) f <= bus_req.wdata[7:0];
            end else if (!sel) begin
                captured <= 1'b0;
            end
        end
    end

    assign bus_resp.ack   = sel && captured;
    assign bus_resp.rdata = {8'h00, f};
endmodule

`default_nettype wire
