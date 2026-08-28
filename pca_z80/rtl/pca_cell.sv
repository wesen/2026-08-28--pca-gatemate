// pca_cell.sv — a PCA cell for Phase 1 (design-doc §9.1, §6.4).
//
// Phase 1 factoring: the cell is the router (built-in part) with its Local
// port exposed for an external object/host. The plastic part (LUT-RAM) is
// added in Phase 3 when Z80 objects attach to these Local ports. This keeps
// Phase 1 focused on the routing substrate (design-doc §13 Phase 1 exit:
// "a packet routes A->B with a single ack; anti-double holds").
//
//   Local port (object <-> router):
//     l_in_req/l_in_msg : object drives a packet INTO the router (router input L)
//     l_in_ack          : router acks the object
//     l_out_req/l_out_msg: router delivers a packet TO the object (router output L)
//     l_out_ack         : object acks the delivery
//
//   Mesh ports (N/S/E/W): req/ack are `logic [4:0]` (bit d = port d); messages
//   are a flat 1D bundle `logic [MW-1:0]` (5*PW bits), Yosys-friendly.
`default_nettype none

import pca_types::*;

module pca_cell #(
    parameter logic [7:0] X = 8'd0,
    parameter logic [7:0] Y = 8'd0
) (
    input  logic           clk,
    input  logic           rst_n,
    // Mesh ports: only [3:0] used (N=0,S=1,E=2,W=3); bit 4 is Local (handled below).
    input  logic [4:0]                       m_in_req,
    input  logic [5*pca_types::PKT_W-1:0]     m_in_msg,
    output logic [4:0]                       m_in_ack,
    output logic [4:0]                       m_out_req,
    output logic [5*pca_types::PKT_W-1:0]     m_out_msg,
    input  logic [4:0]                       m_out_ack,
    // Local port (flat, TB/object-friendly).
    input  logic                             l_in_req,
    input  logic [pca_types::PKT_W-1:0]      l_in_msg,
    output logic                             l_in_ack,
    output logic                             l_out_req,
    output logic [pca_types::PKT_W-1:0]      l_out_msg,
    input  logic                             l_out_ack
);
    localparam int PW = pca_types::PKT_W;
    localparam int MW = 5*PW;

    // Router 5-port bundles: 0..3 = N/S/E/W mesh, 4 = Local.
    logic [4:0]           r_in_req, r_in_ack, r_out_req, r_out_ack;
    logic [MW-1:0]        r_in_msg, r_out_msg;

    // Mesh ports 0..3 pass straight through.
    assign r_in_req[3:0] = m_in_req[3:0];
    assign r_in_msg[4*PW-1:0] = m_in_msg[4*PW-1:0];   // ports 0..3
    assign m_in_ack[3:0]  = r_in_ack[3:0];
    assign m_out_req[3:0] = r_out_req[3:0];
    assign m_out_msg[4*PW-1:0] = r_out_msg[4*PW-1:0];
    assign r_out_ack[3:0] = m_out_ack[3:0];
    // Mesh port 4 mirrors Local (unused by the mesh, which uses the scalar port);
    // driven so the mesh bundle has no undriven bits.
    assign m_in_ack[4]    = r_in_ack[4];
    assign m_out_req[4]    = r_out_req[4];
    assign m_out_msg[4*PW +: PW] = r_out_msg[4*PW +: PW];
    // Local (port 4) <-> scalar Local IO.
    assign r_in_req[4]    = l_in_req;
    assign r_in_msg[4*PW +: PW] = l_in_msg;
    assign l_in_ack       = r_in_ack[4];
    assign l_out_req      = r_out_req[4];
    assign l_out_msg      = r_out_msg[4*PW +: PW];
    assign r_out_ack[4]   = l_out_ack;

    pca_router #(.X(X), .Y(Y)) u_router (
        .clk     (clk),
        .rst_n   (rst_n),
        .in_req  (r_in_req),
        .in_msg  (r_in_msg),
        .in_ack  (r_in_ack),
        .out_req (r_out_req),
        .out_msg (r_out_msg),
        .out_ack (r_out_ack)
    );
endmodule

`default_nettype wire
