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
  // SP sub-ops (addr field when obj==OBJ_PC, we treat SP as part of the PC object).
  localparam logic [15:0] SP_READ = 16'h0003;  // read  -> rdata = SP
  localparam logic [15:0] SP_DEC  = 16'h0004;  // write -> SP -= wdata (pre-decrement for push)
  localparam logic [15:0] SP_INC  = 16'h0005;  // write -> SP += wdata (post-increment for pop)
  localparam logic [15:0] SP_SET  = 16'h0006;  // write -> SP = wdata (LD SP,nn / LD SP,HL)

  // Register-file object sub-ops (addr field when obj==OBJ_REG).
  // The addr field is the Z80 r-table index: 0=B,1=C,2=D,3=E,4=H,5=L,
  // 6=(HL) [handled by the decode via MEM, not the regfile], 7=A.
  // Index 8 = F (flags mirror).
  // Indices 9-12 = 16-bit register PAIRS (3F): 9=BC,10=DE,11=HL,12=AF.
  //   REG_READ  pair -> rdata = {high, low} of the pair
  //   REG_WRITE pair -> wdata written as {high, low} of the pair
  localparam logic [15:0] REG_READ  = 16'h0000;  // read  -> rdata[7:0] = reg[addr[3:0]]
  localparam logic [15:0] REG_WRITE = 16'h0001;  // write -> reg[addr[3:0]] = wdata[7:0]

  // ALU object sub-ops (addr field when obj==OBJ_ALU). Matches ALU_OPS index
  // in z80_isa.py: 0=ADD,1=ADC,2=SUB,3=SBC,4=AND,5=XOR,6=OR,7=CP.
  // wdata = {a[7:0], b[7:0]} (a=high byte, b=low byte).
  // rdata = {new_flags[7:0], result[7:0]} (flags=high, result=low).
  // 3C implements ADD/SUB/AND/OR/XOR/CP (no carry-in); ADC/SBC in 3C.5.
  localparam logic [15:0] ALU_ADD = 16'h0000;
  localparam logic [15:0] ALU_SUB = 16'h0002;
  localparam logic [15:0] ALU_AND = 16'h0004;
  localparam logic [15:0] ALU_XOR = 16'h0005;
  localparam logic [15:0] ALU_OR  = 16'h0006;
  localparam logic [15:0] ALU_CP  = 16'h0007;

  // Flags object sub-ops (addr field when obj==OBJ_FLAGS).
  localparam logic [15:0] FLAGS_READ  = 16'h0000;  // read  -> rdata[7:0] = F
  localparam logic [15:0] FLAGS_WRITE = 16'h0001;  // write -> F = wdata[7:0]
endpackage : z80_obj

`default_nettype wire
