// pca_router.sv — the PCA built-in-part router node (design-doc §9.2).
//
// A 5-port router (N/S/E/W + Local) using deterministic XY routing (exact, not
// adaptive; deadlock-free on a 2D mesh) and a four-cycle bundled held-request
// handshake (design-doc §4.3): req held stable until ack; requester deasserts
// req one cycle after ack; target deasserts ack after req deasserts.
//
// Baseline: one packet in flight at a time (single-flit, no parallel
// arbitration). This makes the anti-double property (design-doc §4.3, the
// MATE-16 "doubled side effect" rule) straightforward: a held req is accepted
// exactly once, and an output req is driven exactly once per transaction.
//
// Ports: req/ack are 1D packed `logic [4:0]` (bit d = port d). Messages are a
// FLAT 1D bundle `logic [MW-1:0]` (5 packets of PW bits concatenated) accessed
// with `[d*PW +: PW]` — Yosys does not support packed 2D array ports, so we
// avoid them. Port order N=0,S=1,E=2,W=3,L=4 (matches dir_e).
//
// FSM:
//   IDLE    -> pick an input with req (priority L,N,S,E,W), compute XY route,
//              latch packet, drive out_req[out_idx], go FORWARD.
//   FORWARD -> hold out_req[out_idx] + out_msg; on out_ack[out_idx], go ACK_IN.
//   ACK_IN  -> deassert out_req, hold in_ack[sel]; when in_req[sel] deasserts,
//              deassert in_ack[sel], go IDLE.
`default_nettype none

import pca_types::*;

module pca_router #(
    parameter logic [7:0] X = 8'd0,
    parameter logic [7:0] Y = 8'd0
) (
    input  logic           clk,
    input  logic           rst_n,
    input  logic [4:0]     in_req,
    input  logic [5*pca_types::PKT_W-1:0] in_msg,
    output logic [4:0]     in_ack,
    output logic [4:0]     out_req,
    output logic [5*pca_types::PKT_W-1:0] out_msg,
    input  logic [4:0]     out_ack
);
    localparam int PW = pca_types::PKT_W;
    localparam int MW = 5*PW;
    // Port indices (match dir_e order N,S,E,W,L).
    localparam int N = 0, S = 1, E = 2, W = 3, L = 4;

    typedef enum logic [1:0] { IDLE, FORWARD, ACK_IN } state_e;
    state_e state;

    logic [2:0] sel;        // selected input port index
    logic [2:0] out_idx;    // computed output port index
    pca_types::msg_t pkt_q; // latched packet (held stable while out_req)

    // Combinational: choose an input when IDLE (fixed priority L,N,S,E,W).
    logic [2:0] sel_next;
    logic       any_req;
    pca_types::msg_t sel_pkt;
    always_comb begin
        sel_next = 3'd5;        // 5 = none
        any_req  = 1'b0;
        sel_pkt  = '0;
        if      (in_req[L]) begin sel_next = L; any_req = 1'b1; sel_pkt = pca_types::msg_t'(in_msg[L*PW +: PW]); end
        else if (in_req[N]) begin sel_next = N; any_req = 1'b1; sel_pkt = pca_types::msg_t'(in_msg[N*PW +: PW]); end
        else if (in_req[S]) begin sel_next = S; any_req = 1'b1; sel_pkt = pca_types::msg_t'(in_msg[S*PW +: PW]); end
        else if (in_req[E]) begin sel_next = E; any_req = 1'b1; sel_pkt = pca_types::msg_t'(in_msg[E*PW +: PW]); end
        else if (in_req[W]) begin sel_next = W; any_req = 1'b1; sel_pkt = pca_types::msg_t'(in_msg[W*PW +: PW]); end
    end

    // Combinational output drives.
    always_comb begin
        out_req = 5'b00000;
        out_msg = '0;
        in_ack  = 5'b00000;
        if (state == FORWARD) begin
            out_req[out_idx] = 1'b1;
            out_msg[out_idx*PW +: PW] = pkt_q;
        end
        if (state == ACK_IN) begin
            in_ack[sel] = 1'b1;     // held until in_req[sel] deasserts
        end
    end

    // Sequential state.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            sel     <= 3'd0;
            out_idx <= 3'd0;
            pkt_q   <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (any_req) begin
                        sel     <= sel_next;
                        out_idx <= dir_to_idx(pca_types::xy_route(
                                       sel_pkt.dest_x, sel_pkt.dest_y, X, Y));
                        pkt_q   <= sel_pkt;
                        state   <= FORWARD;
                    end
                end
                FORWARD: begin
                    if (out_ack[out_idx]) begin
                        state <= ACK_IN;
                    end
                end
                ACK_IN: begin
                    if (!in_req[sel]) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // dir_e -> port index (N=0,S=1,E=2,W=3,L=4) matching dir_e enum order.
    function automatic logic [2:0] dir_to_idx(input pca_types::dir_e d);
        case (d)
            DIR_N: dir_to_idx = N;
            DIR_S: dir_to_idx = S;
            DIR_E: dir_to_idx = E;
            DIR_W: dir_to_idx = W;
            DIR_L: dir_to_idx = L;
            default: dir_to_idx = L;
        endcase
    endfunction

endmodule

`default_nettype wire
