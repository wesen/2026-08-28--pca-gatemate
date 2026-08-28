// obj_regfile.sv — the Z80 register-file object (design-doc §6.4, §8.3), 3B/3F.
//
// A held-request bus slave holding the 8-bit registers (B,C,D,E,H,L,A,F),
// indexed by the Z80 r-table (0=B,1=C,2=D,3=E,4=H,5=L,6=(HL) reserved,
// 7=A, 8=F). 3F adds 16-bit register-pair access (3F): indices 9=BC,10=DE,
// 11=HL,12=AF — z80_obj::REG_READ returns {high,low}, z80_obj::REG_WRITE takes {high,low}.
// (HL) as a memory operand is handled by the decode via the memory object
// (compose H:L -> MEM read/write), so index 6 is unused here. The alternate
// register set (B'..A', F') is added when EXX/EX are wired (later).
//
//   z80_obj::REG_READ  (we=0): rdata = index<9 ? {8'h00, reg[idx]} : pair[idx]
//   z80_obj::REG_WRITE (we=1): index<9 ? reg[idx]=wdata[7:0] : pair[idx]=wdata
// Same captured-transaction anti-double handshake as obj_pc.
`default_nettype none

import z80_obj::*;

module obj_regfile (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp,
    // debug visibility: the 8-bit registers, flat
    output logic [7:0] dbg_b, dbg_c, dbg_d, dbg_e, dbg_h, dbg_l, dbg_a, dbg_f,
    output logic [15:0] dbg_ix, dbg_iy
);
    // 9 entries: 0=B 1=C 2=D 3=E 4=H 5=L 6=(reserved) 7=A 8=F
    logic [7:0] reg_t [0:8];
    logic [15:0] idx_ix, idx_iy;   // IX/IY (3D.7, DD/FD prefix)

    assign dbg_b = reg_t[0];
    assign dbg_c = reg_t[1];
    assign dbg_d = reg_t[2];
    assign dbg_e = reg_t[3];
    assign dbg_h = reg_t[4];
    assign dbg_l = reg_t[5];
    assign dbg_a = reg_t[7];
    assign dbg_f = reg_t[8];
    assign dbg_ix = idx_ix;
    assign dbg_iy = idx_iy;

    logic        captured;
    logic [3:0]  idx_q;
    logic [15:0] rd_q;
    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_REG);

    // combinational read value (pair or 8-bit)
    function automatic logic [15:0] rd_of(input logic [3:0] idx);
        case (idx)
            4'd9:  rd_of = {reg_t[0], reg_t[1]};   // BC
            4'd10: rd_of = {reg_t[2], reg_t[3]};   // DE
            4'd11: rd_of = {reg_t[4], reg_t[5]};   // HL
            4'd12: rd_of = {reg_t[7], reg_t[8]};   // AF
            4'd13: rd_of = idx_ix;                // IX (DD/FD prefix, 3D.7)
            4'd14: rd_of = idx_iy;                // IY
            default: rd_of = {8'h00, reg_t[idx]};
        endcase
    endfunction

    initial begin
        for (int i = 0; i < 9; i++) reg_t[i] = 8'h00;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            captured <= 1'b0;
            idx_q    <= 4'd0;
            rd_q     <= 16'h0000;
            for (int i = 0; i < 9; i++) reg_t[i] <= 8'h00;
            idx_ix <= 16'h0000;
            idx_iy <= 16'h0000;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                idx_q    <= bus_req.addr[3:0];
                rd_q     <= rd_of(bus_req.addr[3:0]);
                if (bus_req.we) begin
                    case (bus_req.addr[3:0])
                        4'd9:  begin reg_t[0] <= bus_req.wdata[15:8]; reg_t[1] <= bus_req.wdata[7:0]; end  // BC
                        4'd10: begin reg_t[2] <= bus_req.wdata[15:8]; reg_t[3] <= bus_req.wdata[7:0]; end  // DE
                        4'd11: begin reg_t[4] <= bus_req.wdata[15:8]; reg_t[5] <= bus_req.wdata[7:0]; end  // HL
                        4'd12: begin reg_t[7] <= bus_req.wdata[15:8]; reg_t[8] <= bus_req.wdata[7:0]; end  // AF
                        4'd13: idx_ix <= bus_req.wdata;   // IX
                        4'd14: idx_iy <= bus_req.wdata;   // IY
                        default: reg_t[bus_req.addr[3:0]] <= bus_req.wdata[7:0];
                    endcase
                end
            end else if (!sel) begin
                captured <= 1'b0;
            end
        end
    end

    assign bus_resp.ack   = sel && captured;
    assign bus_resp.rdata = rd_q;
endmodule

`default_nettype wire
