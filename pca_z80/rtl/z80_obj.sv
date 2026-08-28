// z80_obj.sv — the Z80 object-bus contract (design-doc §4.3, §6.4, DR-7).
//
// The Z80 objects (decode/pc/regfile/alu/flags/memio) communicate over a
// shared held-request bus — the object-to-object message channel. This is the
// faithful baseline: DR-7 keeps the PCA four-cycle request/ack *protocol*
// between objects; the Phase 5 placer maps these objects onto PCA mesh cells
// (the bus becomes the mesh's static-routed message channels). A single
// master (decode) and several memory-mapped slaves (pc/memio/...) keep 3A
// simple and the anti-double discipline identical to MATE-16.
`default_nettype none

package z80_obj;
  // Object (slave) ids on the bus — addr[15:12] convention for the full core.
  localparam logic [3:0] OBJ_DECODE = 4'd0;
  localparam logic [3:0] OBJ_PC     = 4'd1;
  localparam logic [3:0] OBJ_MEM    = 4'd2;
  localparam logic [3:0] OBJ_REG    = 4'd3;
  localparam logic [3:0] OBJ_ALU    = 4'd4;
  localparam logic [3:0] OBJ_FLAGS  = 4'd5;

  // Master -> slaves: a single held-request transaction.
  typedef struct packed {
    logic        req;
    logic        we;       // 1=write, 0=read
    logic [3:0]  obj;      // target object id
    logic [15:0] addr;     // object-specific sub-op / address
    logic [15:0] wdata;   // write data
  } bus_req_t;             // 1+1+4+16+16 = 38 bits

  // Slaves -> master: held ack + read data.
  typedef struct packed {
    logic        ack;
    logic [15:0] rdata;
  } bus_resp_t;            // 17 bits

  // PC object sub-ops (addr field when obj==OBJ_PC).
  localparam logic [15:0] PC_READ = 16'h0000;  // read  -> rdata = PC
  localparam logic [15:0] PC_INC  = 16'h0001;  // write -> PC += wdata, R++
  localparam logic [15:0] PC_SET  = 16'h0002;  // write -> PC = wdata
endpackage : z80_obj

`default_nettype wire
