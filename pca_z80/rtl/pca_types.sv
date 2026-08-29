// pca_types.sv — the PCA message-protocol contract (single source of truth).
//
// This package is to the PCA routing substrate what `opcodes.py` is to the
// sibling MATE-16 ISA: the one definition consumed by the router, the mesh,
// the cell, the testbench, and (in Phase 3+) every Z80 object. Change it
// here; everything else reads it.
//
// Design refs (design-doc §4.3, §9): messages are variable-length packets of
// (routing command, payload, trailer); the baseline uses single-flit
// (fixed-width) packets with deterministic XY routing (the paper's "exact,
// not adaptive" routing) and a four-cycle bundled held-request/ack handshake.
`default_nettype none

package pca_types;

  // Direction codes for the 5 router ports (N/S/E/W + Local).
  typedef enum logic [2:0] {
    DIR_N    = 3'd0,
    DIR_S    = 3'd1,
    DIR_E    = 3'd2,
    DIR_W    = 3'd3,
    DIR_L    = 3'd4,   // Local (object / plastic part)
    DIR_NONE = 3'd5
  } dir_e;

  // Payload command. The plastic part / object interprets cmd on receipt.
  typedef enum logic [2:0] {
    CMD_NOP    = 3'd0,
    CMD_CONFIG = 3'd1,   // load plastic-part configuration (Phase 3+)
    CMD_WRITE  = 3'd2,   // write data to object at (dest) [addr]
    CMD_READ   = 3'd3,   // read  object at (dest) [addr]; object sends RESP
    CMD_RESP   = 3'd4    // response packet carrying read data back to src
  } cmd_e;

  // Static hardware supports meshes through 4x4. Two-bit coordinates avoid
  // switching 24 unused coordinate bits through every physical router.
  localparam int COORD_W = 2;

  // A single-flit packet. Stable while req is held (held-request contract).
  // Width = 3 + COORD_W*4 + 16*2 = 43 bits.
  typedef struct packed {
    cmd_e      cmd;
    logic [COORD_W-1:0] dest_x;
    logic [COORD_W-1:0] dest_y;
    logic [COORD_W-1:0] src_x;
    logic [COORD_W-1:0] src_y;
    logic [15:0] addr;
    logic [15:0] data;
  } msg_t;

  // Packed width of msg_t (for packed 2D port arrays — iverilog-safe).
  localparam int PKT_W = 3 + 4*COORD_W + 2*16;  // Yosys cannot parse $bits(msg_t) here.

  // Deterministic XY routing (paper: exact, not adaptive; deadlock-free on a
  // 2D mesh). Resolve X (East/West) first, then Y (North/South), else Local.
  // Convention: X = column increasing East; Y = row increasing South.
  function automatic dir_e xy_route(input logic [COORD_W-1:0] dx,
                                    input logic [COORD_W-1:0] dy,
                                    input logic [7:0] mx, input logic [7:0] my);
    if      (dx > mx) xy_route = DIR_E;
    else if (dx < mx) xy_route = DIR_W;
    else if (dy > my) xy_route = DIR_S;
    else if (dy < my) xy_route = DIR_N;
    else              xy_route = DIR_L;
  endfunction

endpackage : pca_types

`default_nettype wire
