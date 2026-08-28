// z80_core.sv — the Z80 object graph (design-doc §6), Phase 3A baseline.
//
// Wires the decode master to the pc and memio slaves on the shared held-request
// object bus. Only the addressed slave drives ack; the core ORs the acks and
// muxes the read data. The decode master sees a single bus_resp. (Phase 5
// places these objects on PCA mesh cells; the bus becomes the mesh's static
// message channels — DR-7.)
`default_nettype none

import z80_obj::*;

module z80_core #(
    parameter int ROM_DEPTH = 256,
    parameter int RAM_WORDS = 256
) (
    input  logic      clk,
    input  logic      rst_n,
    // debug visibility (hierarchical in sim; here for the testbench)
    output logic [7:0]  dbg_ir,
    output logic [15:0] dbg_pc,
    output logic [7:0]  dbg_r,
    output logic [15:0] dbg_sp,
    output logic [7:0]  gpio_out,
    output logic [31:0] dbg_count,
    output logic        dbg_halted,
    output logic        dbg_faulted
);
    z80_obj::bus_req_t  bus_req;
    z80_obj::bus_resp_t bus_resp;

    z80_obj::bus_resp_t pc_resp, mem_resp, reg_resp, alu_resp, flags_resp;

    // Master drives the bus; slaves share it.
    obj_decode u_decode (
        .clk(clk), .rst_n(rst_n),
        .bus_req(bus_req), .bus_resp(bus_resp),
        .dbg_ir(dbg_ir), .dbg_pc_val(), .dbg_count(dbg_count),
        .dbg_halted(dbg_halted), .dbg_faulted(dbg_faulted)
    );

    obj_pc u_pc (
        .clk(clk), .rst_n(rst_n),
        .bus_req(bus_req), .bus_resp(pc_resp),
        .dbg_pc(dbg_pc), .dbg_r(dbg_r), .dbg_sp(dbg_sp)
    );

    obj_memio #(.ROM_DEPTH(ROM_DEPTH), .RAM_WORDS(RAM_WORDS)) u_memio (
        .clk(clk), .rst_n(rst_n),
        .bus_req(bus_req), .bus_resp(mem_resp),
        .gpio_out(gpio_out)
    );

    obj_regfile u_regfile (
        .clk(clk), .rst_n(rst_n),
        .bus_req(bus_req), .bus_resp(reg_resp),
        .dbg_b(), .dbg_c(), .dbg_d(), .dbg_e(),
        .dbg_h(), .dbg_l(), .dbg_a(), .dbg_f(),
        .dbg_ix(), .dbg_iy()
    );

    obj_alu u_alu (
        .clk(clk), .rst_n(rst_n),
        .bus_req(bus_req), .bus_resp(alu_resp)
    );

    obj_flags u_flags (
        .clk(clk), .rst_n(rst_n),
        .bus_req(bus_req), .bus_resp(flags_resp),
        .dbg_f()
    );

    // Bus response aggregation: only the addressed slave acks.
    assign bus_resp.ack   = pc_resp.ack | mem_resp.ack | reg_resp.ack
                             | alu_resp.ack | flags_resp.ack;
    assign bus_resp.rdata = pc_resp.ack   ? pc_resp.rdata   :
                             mem_resp.ack  ? mem_resp.rdata  :
                             reg_resp.ack  ? reg_resp.rdata  :
                             alu_resp.ack  ? alu_resp.rdata  : flags_resp.rdata;
endmodule

`default_nettype wire
