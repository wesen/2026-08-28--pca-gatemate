// pca_mesh.sv — a COLS×ROWS array of PCA cells, neighbor-wired (design-doc §9.3).
//
// Coordinates: X = column (increases East), Y = row (increases South). XY
// routing resolves X then Y. Each cell's Local port is exposed to the host
// (testbench in Phase 1; Z80 objects in Phase 3) as flat packed arrays
// indexed by cell id = Y*COLS + X.
//
// All multi-bit bundles (messages) are flat 1D packed vectors sliced with
// `[i*PW +: PW]` — Yosys does not support packed 2D array ports/nets, so we
// avoid them. Per-link 1-bit signals are packed 1D `logic [N-1:0]`.
//
// Link convention (a link carries two directed channels):
//   Vertical link v(x,y) between cell(x,y) [north] and cell(x,y+1) [south]:
//     vs_* south-going (north cell S_out -> south cell N_in)
//     vn_* north-going (south cell N_out -> north cell S_in)
//   Horizontal link h(x,y) between cell(x,y) [west] and cell(x+1,y) [east]:
//     he_* east-going  (west cell E_out -> east cell W_in)
//     hw_* west-going  (east cell W_out -> west cell E_in)
// Boundary in-ports are tied to 0; boundary out-ports are left unconnected.
`default_nettype none

import pca_types::*;

module pca_mesh #(
    parameter int COLS = 3,
    parameter int ROWS = 3
) (
    input  logic           clk,
    input  logic           rst_n,
    // Local ports, flat over all cells (id = Y*COLS + X).
    input  logic [COLS*ROWS-1:0]                  l_in_req,
    input  logic [COLS*ROWS*pca_types::PKT_W-1:0]  l_in_msg,
    output logic [COLS*ROWS-1:0]                  l_in_ack,
    output logic [COLS*ROWS-1:0]                  l_out_req,
    output logic [COLS*ROWS*pca_types::PKT_W-1:0]  l_out_msg,
    input  logic [COLS*ROWS-1:0]                  l_out_ack
);
    localparam int PW = pca_types::PKT_W;
    localparam int N  = COLS*ROWS;
    localparam int NV = (ROWS>1) ? COLS*(ROWS-1) : 1;  // vertical links
    localparam int NH = (COLS>1) ? (COLS-1)*ROWS : 1;  // horizontal links
    localparam int MW = 5*PW;

    // Link wires (packed 1D; flat index: vidx = x*(ROWS-1) + y, hidx = x*ROWS + y).
    logic [NV-1:0]     vs_req, vs_ack, vn_req, vn_ack;
    logic [NV*PW-1:0]  vs_msg, vn_msg;
    logic [NH-1:0]     he_req, he_ack, hw_req, hw_ack;
    logic [NH*PW-1:0]  he_msg, hw_msg;

    genvar gx, gy;
    generate
      for (gy=0; gy<ROWS; gy=gy+1) begin : prow
        for (gx=0; gx<COLS; gx=gx+1) begin : pcol
          localparam int ID = gy*COLS + gx;
          logic [4:0]     cin_req, cin_ack, cout_req, cout_ack;
          logic [MW-1:0]  cin_msg, cout_msg;
          assign cin_msg[4*PW +: PW] = '0;   // mesh port 4 (Local) unused on mesh side
          assign cin_req[4] = 1'b0;        // (Local uses the scalar l_in_req)
          assign cout_ack[4] = 1'b0;

          // --- North port (idx 0) ---
          if (gy > 0) begin : n_link
            localparam int VI = gx*(ROWS-1) + (gy-1);
            assign cin_req[0]      = vs_req[VI];
            assign cin_msg[0*PW +: PW] = vs_msg[VI*PW +: PW];
            assign vs_ack[VI]      = cin_ack[0];
            assign vn_req[VI]      = cout_req[0];
            assign vn_msg[VI*PW +: PW] = cout_msg[0*PW +: PW];
            assign cout_ack[0]     = vn_ack[VI];
          end else begin : n_edge
            assign cin_req[0] = 1'b0; assign cin_msg[0*PW +: PW] = '0; assign cout_ack[0] = 1'b0;
          end

          // --- South port (idx 1) ---
          if (gy < ROWS-1) begin : s_link
            localparam int VI = gx*(ROWS-1) + gy;
            assign vs_req[VI]      = cout_req[1];
            assign vs_msg[VI*PW +: PW] = cout_msg[1*PW +: PW];
            assign cout_ack[1]     = vs_ack[VI];
            assign cin_req[1]      = vn_req[VI];
            assign cin_msg[1*PW +: PW] = vn_msg[VI*PW +: PW];
            assign vn_ack[VI]      = cin_ack[1];
          end else begin : s_edge
            assign cin_req[1] = 1'b0; assign cin_msg[1*PW +: PW] = '0; assign cout_ack[1] = 1'b0;
          end

          // --- East port (idx 2) ---
          if (gx < COLS-1) begin : e_link
            localparam int HI = gx*ROWS + gy;
            assign he_req[HI]      = cout_req[2];
            assign he_msg[HI*PW +: PW] = cout_msg[2*PW +: PW];
            assign cout_ack[2]     = he_ack[HI];
            assign cin_req[2]      = hw_req[HI];
            assign cin_msg[2*PW +: PW] = hw_msg[HI*PW +: PW];
            assign hw_ack[HI]      = cin_ack[2];
          end else begin : e_edge
            assign cin_req[2] = 1'b0; assign cin_msg[2*PW +: PW] = '0; assign cout_ack[2] = 1'b0;
          end

          // --- West port (idx 3) ---
          if (gx > 0) begin : w_link
            localparam int HI = (gx-1)*ROWS + gy;
            assign cin_req[3]      = he_req[HI];
            assign cin_msg[3*PW +: PW] = he_msg[HI*PW +: PW];
            assign he_ack[HI]      = cin_ack[3];
            assign hw_req[HI]      = cout_req[3];
            assign hw_msg[HI*PW +: PW] = cout_msg[3*PW +: PW];
            assign cout_ack[3]     = hw_ack[HI];
          end else begin : w_edge
            assign cin_req[3] = 1'b0; assign cin_msg[3*PW +: PW] = '0; assign cout_ack[3] = 1'b0;
          end

          pca_cell #(.X(gx[7:0]), .Y(gy[7:0])) u_cell (
            .clk        (clk),
            .rst_n      (rst_n),
            .m_in_req   (cin_req),
            .m_in_msg   (cin_msg),
            .m_in_ack   (cin_ack),
            .m_out_req  (cout_req),
            .m_out_msg  (cout_msg),
            .m_out_ack  (cout_ack),
            .l_in_req   (l_in_req[ID]),
            .l_in_msg   (l_in_msg[ID*PW +: PW]),
            .l_in_ack   (l_in_ack[ID]),
            .l_out_req  (l_out_req[ID]),
            .l_out_msg  (l_out_msg[ID*PW +: PW]),
            .l_out_ack  (l_out_ack[ID])
          );
        end
      end
    endgenerate
endmodule

`default_nettype wire
