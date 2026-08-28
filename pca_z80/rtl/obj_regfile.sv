// obj_regfile.sv — the Z80 register-file object (design-doc §6.4, §8.3), 3B.
//
// A held-request bus slave holding the 8-bit registers (B,C,D,E,H,L,A) plus
// F, indexed by the Z80 r-table (0=B,1=C,2=D,3=E,4=H,5=L,6=(HL) reserved,
// 7=A, 8=F). (HL) as a memory operand is handled by the decode via the memory
// object (compose H:L -> MEM read/write), so index 6 is unused here. The
// alternate register set (B'..A', F') is added when EXX/EX are wired (3F).
//
//   z80_obj::REG_READ  (we=0): rdata = {8'h00, reg[addr[3:0]]}
//   z80_obj::REG_WRITE (we=1): reg[addr[3:0]] = wdata[7:0]
// Same captured-transaction anti-double handshake as obj_pc.
`default_nettype none

import z80_obj::*;

module obj_regfile (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp,
    // debug visibility: the 8-bit registers, flat
    output logic [7:0] dbg_b, dbg_c, dbg_d, dbg_e, dbg_h, dbg_l, dbg_a, dbg_f
);
    // 9 entries: 0=B 1=C 2=D 3=E 4=H 5=L 6=(reserved) 7=A 8=F
    logic [7:0] reg_t [0:8];

    assign dbg_b = reg_t[0];
    assign dbg_c = reg_t[1];
    assign dbg_d = reg_t[2];
    assign dbg_e = reg_t[3];
    assign dbg_h = reg_t[4];
    assign dbg_l = reg_t[5];
    assign dbg_a = reg_t[7];
    assign dbg_f = reg_t[8];

    logic        captured;
    logic [3:0]  idx_q;
    logic [7:0]  rd_q;
    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_REG);

    initial begin
        for (int i = 0; i < 9; i++) reg_t[i] = 8'h00;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            captured <= 1'b0;
            idx_q    <= 4'd0;
            rd_q     <= 8'h00;
            for (int i = 0; i < 9; i++) reg_t[i] <= 8'h00;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                idx_q    <= bus_req.addr[3:0];
                rd_q     <= reg_t[bus_req.addr[3:0]];
                if (bus_req.we) begin
                    reg_t[bus_req.addr[3:0]] <= bus_req.wdata[7:0];
                end
            end else if (!sel) begin
                captured <= 1'b0;
            end
        end
    end

    assign bus_resp.ack   = sel && captured;
    assign bus_resp.rdata = {8'h00, rd_q};
endmodule

`default_nettype wire
