// obj_alu.sv — the Z80 8-bit ALU object (design-doc §6.4, §8.2), 3C.
//
// A held-request bus slave that computes an 8-bit ALU op + the new flags in
// one transaction, mirroring z80_model.py's _add8/_sub8/_logic8 flag model.
//   addr  = op (z80_obj::ALU_ADD/SUB/AND/XOR/OR/CP; matches ALU_OPS index)
//   wdata = {a[7:0], b[7:0]}  (a = high byte = accumulator, b = low = operand)
//   rdata = {new_flags[7:0], result[7:0]}  (CP: result is 0/don't-care, flags set)
// 3C: ADD/SUB/AND/OR/XOR/CP (no carry-in). ADC/SBC (carry-in from flags) in 3C.5.
//
// Flag bits (z80_isa.py): S=0x80 Z=0x40 F5=0x20 H=0x10 F3=0x08 PV=0x04 N=0x02 C=0x01.
`default_nettype none

import z80_obj::*;

module obj_alu (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp
);
    localparam logic [7:0] F_S=8'h80, F_Z=8'h40, F_F5=8'h20, F_H=8'h10,
                           F_F3=8'h08, F_PV=8'h04, F_N=8'h02, F_C=8'h01;

    logic        captured;
    logic [7:0]  a_q, b_q;
    logic [7:0]  result_q, flags_q;

    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_ALU);

    // combinational ALU + flags (computed on capture)
    logic [8:0]  add_res;       // 9-bit for carry
    logic [8:0]  sub_res;
    logic [7:0]  r8;
    logic [7:0]  fl;
    logic [7:0]  cur_f;       // current flags (for INC/DEC C preservation)
    always_comb begin
        a_q = bus_req.wdata[15:8];
        b_q = bus_req.wdata[7:0];
        cur_f = bus_req.wdata[7:0];   // for INC/DEC: low byte carries current F
        add_res = a_q + b_q;
        sub_res = a_q - b_q;
        fl = 8'h00;
        r8 = 8'h00;
        case (bus_req.addr)
            z80_obj::ALU_ADD: begin
                r8 = add_res[7:0];
                fl = (r8 & F_S) | ((r8==0) ? F_Z : 0) | (r8 & (F_F5|F_F3))
                     | (((a_q&8'h0F)+(b_q&8'h0F))>8'h0F ? F_H : 0)
                     | (((a_q^r8)&(b_q^r8)&8'h80) ? F_PV : 0)
                     | (add_res[8] ? F_C : 0);
            end
            z80_obj::ALU_SUB, z80_obj::ALU_CP: begin
                r8 = sub_res[7:0];
                fl = F_N | (r8 & F_S) | ((r8==0) ? F_Z : 0) | (r8 & (F_F5|F_F3))
                     | ((a_q&8'h0F)<(b_q&8'h0F) ? F_H : 0)
                     | (((a_q^b_q)&(a_q^r8)&8'h80) ? F_PV : 0)
                     | (sub_res[8] ? F_C : 0);
            end
            z80_obj::ALU_AND: begin
                r8 = a_q & b_q;
                fl = (r8 & F_S) | ((r8==0) ? F_Z : 0) | (r8 & (F_F5|F_F3))
                     | F_H | (parity(r8) ? F_PV : 0);
            end
            z80_obj::ALU_XOR: begin
                r8 = a_q ^ b_q;
                fl = (r8 & F_S) | ((r8==0) ? F_Z : 0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0);
            end
            z80_obj::ALU_OR: begin
                r8 = a_q | b_q;
                fl = (r8 & F_S) | ((r8==0) ? F_Z : 0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0);
            end
            z80_obj::ALU_INC: begin
                // r = a + 1; flags S/Z/H/PV/N (C preserved from cur_f). Matches _inc8.
                r8 = (a_q + 8'd1) & 8'hFF;
                fl = (r8 & F_S) | ((r8==0) ? F_Z : 0) | (r8 & (F_F5|F_F3))
                     | ((a_q & 8'h0F)==8'h0F ? F_H : 0)
                     | (r8==8'h80 ? F_PV : 0);
                fl = fl | (cur_f & F_C);   // preserve C
            end
            z80_obj::ALU_DEC: begin
                // r = a - 1; flags S/Z/H/PV/N (C preserved). Matches _dec8.
                r8 = (a_q - 8'd1) & 8'hFF;
                fl = F_N | (r8 & F_S) | ((r8==0) ? F_Z : 0) | (r8 & (F_F5|F_F3))
                     | ((a_q & 8'h0F)==8'h00 ? F_H : 0)
                     | (r8==8'h7F ? F_PV : 0);
                fl = fl | (cur_f & F_C);   // preserve C
            end
            // CB shifts (3D.6): port _rlc/_rrc/_rl/_rr/_sla/_sra/_srl.
            // H=0, N=0, PV=parity, C=shifted-out bit, S/Z + F5/F3 from result.
            z80_obj::ALU_RLC: begin
                r8 = ((a_q << 1) | (a_q >> 7)) & 8'hFF;   // C = old bit 7
                fl = (r8 & F_S) | ((r8==0)?F_Z:0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0) | ((a_q >> 7) & 1 ? F_C : 0);
            end
            z80_obj::ALU_RRC: begin
                r8 = ((a_q >> 1) | (a_q << 7)) & 8'hFF;   // C = old bit 0
                fl = (r8 & F_S) | ((r8==0)?F_Z:0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0) | (a_q & 1 ? F_C : 0);
            end
            z80_obj::ALU_RL: begin
                r8 = ((a_q << 1) | (cur_f & F_C ? 1 : 0)) & 8'hFF;   // C = old bit 7
                fl = (r8 & F_S) | ((r8==0)?F_Z:0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0) | ((a_q >> 7) & 1 ? F_C : 0);
            end
            z80_obj::ALU_RR: begin
                r8 = ((a_q >> 1) | (cur_f & F_C ? 8'h80 : 0)) & 8'hFF;  // C = old bit 0
                fl = (r8 & F_S) | ((r8==0)?F_Z:0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0) | (a_q & 1 ? F_C : 0);
            end
            z80_obj::ALU_SLA: begin
                r8 = (a_q << 1) & 8'hFF;   // C = old bit 7
                fl = (r8 & F_S) | ((r8==0)?F_Z:0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0) | ((a_q >> 7) & 1 ? F_C : 0);
            end
            z80_obj::ALU_SRA: begin
                r8 = ((a_q >> 1) | (a_q & 8'h80)) & 8'hFF;  // C = old bit 0
                fl = (r8 & F_S) | ((r8==0)?F_Z:0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0) | (a_q & 1 ? F_C : 0);
            end
            z80_obj::ALU_SRL: begin
                r8 = (a_q >> 1) & 8'hFF;   // C = old bit 0
                fl = (r8 & F_S) | ((r8==0)?F_Z:0) | (r8 & (F_F5|F_F3))
                     | (parity(r8) ? F_PV : 0) | (a_q & 1 ? F_C : 0);
            end
            default: begin
                r8 = 8'h00; fl = 8'h00;
            end
        endcase
    end

    function automatic logic parity(input logic [7:0] v);
        logic [7:0] x;
        begin
            x = v;
            x = x ^ (x >> 4);
            x = x ^ (x >> 2);
            x = x ^ (x >> 1);
            parity = ~x[0];   // even parity -> 1
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            captured <= 1'b0;
            result_q <= 8'h00;
            flags_q  <= 8'h00;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                result_q <= r8;
                flags_q  <= fl;
            end else if (!sel) begin
                captured <= 1'b0;
            end
        end
    end

    assign bus_resp.ack   = sel && captured;
    assign bus_resp.rdata = {flags_q, result_q};
endmodule

`default_nettype wire
