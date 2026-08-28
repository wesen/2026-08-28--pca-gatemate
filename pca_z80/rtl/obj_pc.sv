// obj_pc.sv — the Z80 program-counter + stack-pointer object (design-doc §6.4), 3F.
//
// A held-request bus slave holding PC[15:0], the refresh counter R[6:0], and
// SP[15:0] (added in 3F for CALL/RET/PUSH/POP). One transaction at a time; the
// held-request anti-double rule: accept on the first req&&ready edge, hold
// ack until req deasserts, never re-accept a held req.
//   z80_obj::PC_READ: read  -> rdata = PC
//   z80_obj::PC_INC : write -> PC = (PC + wdata) & 0xFFFF; R = (R + 1) & 0x7F
//   z80_obj::PC_SET : write -> PC = wdata
//   z80_obj::SP_READ: read  -> rdata = SP
//   z80_obj::SP_DEC : write -> SP = (SP - wdata) & 0xFFFF  (pre-decrement for push)
//   z80_obj::SP_INC : write -> SP = (SP + wdata) & 0xFFFF  (post-increment for pop)
//   z80_obj::SP_SET : write -> SP = wdata
`default_nettype none

import z80_obj::*;

module obj_pc (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp,
    output logic [15:0] dbg_pc,
    output logic [7:0]  dbg_r,
    output logic [15:0] dbg_sp
);
    logic [15:0] pc;
    logic [15:0] sp;
    logic [7:0]  r;
    logic        captured;

    assign dbg_pc = pc;
    assign dbg_r  = r;
    assign dbg_sp = sp;

    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_PC);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h0000;
            sp <= 16'hFFFF;      // reset default; TB may z80_obj::SP_SET it
            r  <= 8'h00;
            captured <= 1'b0;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                if (bus_req.we) begin
                    case (bus_req.addr)
                        z80_obj::PC_INC: begin pc <= (pc + bus_req.wdata) & 16'hFFFF; r <= (r + 8'd1) & 8'h7F; end
                        z80_obj::PC_SET: pc <= bus_req.wdata;
                        z80_obj::SP_DEC: sp <= (sp - bus_req.wdata) & 16'hFFFF;
                        z80_obj::SP_INC: sp <= (sp + bus_req.wdata) & 16'hFFFF;
                        z80_obj::SP_SET: sp <= bus_req.wdata;
                        default: ;
                    endcase
                end
            end else if (!sel) begin
                captured <= 1'b0;
            end
        end
    end

    // rdata: z80_obj::PC_READ -> PC, z80_obj::SP_READ -> SP, else PC (writes return PC harmlessly).
    assign bus_resp.ack   = sel && captured;
    assign bus_resp.rdata  = (bus_req.addr == z80_obj::SP_READ) ? sp : pc;
endmodule

`default_nettype wire
