---
Title: PCA-Z80 Engineering Report
Ticket: PCA-Z80-GATEMATE
Status: active
Topics:
    - pca
    - z80
    - rtl
    - fpga
    - verification
    - hardware
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_decode.sv
      Note: The decode master FSM (the control unit; ~70 states, all implemented opcodes)
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/z80_core.sv
      Note: The Z80 object graph (master + 5 slaves on the held-request bus)
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/sim/run_integ.py
      Note: The integration differential harness (assemble -> model + object graph)
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/tools/z80_model.py
      Note: |-
        The differential oracle (the reference model)
        The differential oracle (reference model)
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/tools/zasm.py
      Note: The two-pass assembler
    - Path: repo://pca_z80/rtl/obj_memio.sv
      Note: Final registered 512-byte GateMate BRAM firmware memory
    - Path: repo://pca_z80/tools/check_gatemate_rom.py
      Note: Final synthesized BRAM INIT validation
    - Path: repo://ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/design-doc/03-gatemate-firmware-rom-bram-and-uart-bring-up-intern-guide.md
      Note: Detailed evidence behind updated hardware results
ExternalSources: []
Summary: 'Engineering report for the PCA-Z80 build: architecture, software, verification, FPGA implementation, hardware results, and limitations. The Z80 object graph is differential-tested against a Python oracle, executes padded firmware from inferred GateMate block RAM, visibly blinks the board LED, and physically emits Hi through DirtyJTAG CDC0.'
LastUpdated: 2026-08-28T21:10:00-04:00
WhatFor: Summarize the PCA-Z80 build for review and handoff.
WhenToUse: Read for the project status, results, and known limitations.
---





# PCA-Z80 Engineering Report

## 1. Summary

The PCA-Z80 project built a **Z80 8-bit microprocessor as a graph of wired-logic
"objects" communicating over a held-request bus** — the Plastic Cell
Architecture (PCA) object/message model (design-doc DR-7) — and deployed it on
the **Olimex GateMateA1-EVB** (Cologne Chip CCGM1A1) FPGA as a bitstream whose
on-board LED is **driven by Z80 instructions**. The Z80 is not a conventional
soft core (one clocked netlist); it is decomposed into six objects (decode/pc/
regfile/alu/flags/memio) on a shared bus, differential-tested against an
independent Python reference model (the "oracle"), and assembled from real
`.asm` programs by a two-pass assembler. The full system is green: PCA mesh
substrate, Z80 object graph, 49 model tests, 22 assembler tests, 6 integration
tests, UART simulation, synthesized GateMate primitive execution, and a
256,096-byte bitstream that uses one `RAM_HALF` and meets 10 MHz with more than
5× margin. The physical board visibly blinks from Z80 firmware and emits bytes
`48 69` (`Hi`) through `/dev/ttyACM0`.

## 2. Architecture

### 2.1 The PCA substrate (Phase 1)

The substrate is a COLS×ROWS mesh of PCA cells (`pca_mesh.sv`), each a 5-port
XY-routing router (`pca_router.sv`) with a four-cycle held-request/ack
handshake and a single-flit, one-in-flight anti-double guarantee (the MATE-16
"doubled side effect" rule). The message protocol is one contract
(`pca_types.sv`: `msg_t` 67-bit packet + `xy_route`). Directed tests prove
A→B routing with a single accept, diagonal A→C XY routing without
mis-delivering the on-path cell, and anti-double under random stalls. The 3×3
mesh synthesizes clean (~12.5k cells). The Z80 objects are *not yet* placed on
the mesh — the baseline hardware demo runs the object graph directly (DR-7:
the bus becomes the mesh's static message channels at Phase 7).

### 2.2 The Z80 object graph (Phases 3A-3D.7)

The Z80 is a **single master + five memory-mapped slaves** on a held-request
object bus (`z80_obj.sv`):

| Object | File | Role |
|---|---|---|
| `obj_decode` | `obj_decode.sv` | bus master; fetch/decode/execute FSM (~70 states) |
| `obj_pc` | `obj_pc.sv` | PC + SP + R; held-request slave |
| `obj_memio` | `obj_memio.sv` | registered 512×8 firmware ROM (`CC_BRAM_20K`) + RAM + GPIO + UART |
| `obj_regfile` | `obj_regfile.sv` | 8-bit regs (r-table) + 16-bit pairs (BC/DE/HL/AF) |
| `obj_alu` | `obj_alu.sv` | 8-bit ALU (ADD/SUB/AND/OR/XOR/CP/INC/DEC/CB shifts) |
| `obj_flags` | `obj_flags.sv` | the F register |

Every instruction is a sequence of held-request bus transactions
(`if(!req) setup; else if(ack) latch+advance`). The decode FSM is the control
unit; the bus is the object-to-object message channel.

### 2.3 Implemented instruction set

| Group | Opcodes |
|---|---|
| Stack/control | NOP, HALT, JP nn, JP cc,nn, JR e, JR cc,e, CALL nn, RET, PUSH rr, POP rr |
| 8-bit load | LD r,n, LD r,r', LD r,(HL), LD (HL),r, LD A,(BC)/(DE)/(nn), LD (nn),A |
| 16-bit load | LD rr,nn |
| 8-bit ALU | ADD A,r/n, SUB, AND, OR, XOR, CP |
| INC/DEC | INC r, DEC r, INC rr, DEC rr |
| 16-bit ALU | ADD HL,rr |
| CB shifts/bits | RLC, RRC, RL, RR, SLA, SRA, SRL (SLL→SLA), BIT b,r, SET b,r, RES b,r |
| I/O | memory-mapped GPIO (write 0x0000), UART TX (write 0x0001) |
| DD/FD subset | LD IX/IY,nn; INC/DEC IX/IY; LD A,(IX/IY+d) |

**Not yet implemented:** full DD/FD substitution, ED block instructions, real
port I/O (`OUT`/`IN` in a separate I/O space), RET cc, RST, (HL) CB forms,
full exchange/alternate-register behavior, and interrupts. The reference model
contains broader semantics; these are decode and integration gaps.

## 3. Software

- **`z80_isa.py`** — the ISA contract (flag bits, r/rp/cc tables, the
  `IMPLEMENTED` set). Single source of truth for model/assembler/tests (DR-3).
- **`z80_model.py`** — the executable reference model (~600 lines): full
  architectural state, every baseline opcode, the flag model, and the
  DD/FD/CB/ED prefix machinery. The differential oracle.
- **`zasm.py`** — the two-pass assembler (no `eval`, DR-9): emits
  `.hex`/`.bin`/`.lst`/`.sym.json`; computes JR displacements relative to PC
  after the JR; covers the implemented set. `--size 512` emits a complete,
  padded physical ROM image and rejects overflow.
- **`run_integ.py`** — the integration differential harness: assembles a
  program, runs it on both the model and the object-graph testbench, and
  compares 12 state fields.

## 4. Verification

A pyramid, fastest to slowest, all green (`make test` in <3 s):

| Layer | Count | Oracle | Speed |
|---|---:|---|---|
| PCA mesh substrate (iverilog) | 3 | directed invariants | <0.1 s |
| Z80 object graph (iverilog, directed differential) | ~20 | z80_model.py | <1 s |
| Pure-software model unit tests (pytest) | 49 | hand-computed | <0.1 s |
| Assembler golden vectors + cross-check (pytest) | 22 | explicit bytes + model | <0.2 s |
| Integration (assemble → object graph vs model) | 6 | z80_model.py | ~3 s |
| UART RTL | 1 | decoded bytes `48 69` | seconds |
| GateMate post-synthesis firmware execution | 1 | primitive INIT + LED assertion | seconds |
| Synthesis + PnR + timing | 1 | reports | minutes |
| Physical hardware | LED + UART | visible blink + ACM0 byte capture | observed |

The **differential discipline** (model-first, DR-4): the RTL is wrong iff it
diverges from `z80_model.py` on the same assembled bytes. Every Phase 3
milestone added a directed differential test; the integration harness runs
real assembled programs end-to-end. The selftest program (LD A,0; loop: ADD
A,1; CP 3; JR NZ,loop; CALL add5; HALT) reaches the magic final state A=8,
model==RTL byte-for-byte.

## 5. FPGA implementation (Phase 6)

`make bit` (Yosys `synth_gatemate -luttree -nomx8` → nextpnr-himbaechel →
gmpack) produces `build/top.bit` (256,096 bytes for the final blink build) from
`rtl/top.sv`. Firmware is assembled and padded to a complete 512-byte image,
then loaded through a registered inferred ROM. Yosys maps it to one
`CC_BRAM_20K`; `make post_synth` verifies non-zero primitive `INIT_*` data and
executes the GateMate primitive netlist.

| Resource | Used | Available | % |
|---|---:|---:|---:|
| CPE_LT (LUTs) | 7,168 | 40,960 | 17.5% |
| CPE_FF | 2,558 | 40,960 | 6.2% |
| RAM_HALF | 1 | 64 | 1.6% |

Timing: 10 MHz clock, post-route max **51.19 MHz** on the main reported clock
(another reported constrained path reaches 29.54 MHz) — both pass with ample
margin. Router2 uses deterministic `PNR_SEED=1`; the prior default seed could
remain one wire overused after thousands of iterations.

The `programs/blink.asm` demo blinks the LED with nested B×C countdown loops,
producing about 310 ms per transition (human-visible). A GPIO testbench and the
post-synthesis primitive test confirm execution; the same BRAM-backed image was
loaded on the board. The LED is driven by Z80 instructions, not a hardware
counter.

## 6. Hardware results

- **Firmware ROM:** registered 512×8 inferred ROM, one `CC_BRAM_20K`; generated
  primitive initialization is non-zero and begins with the assembled program.
- **Post-synthesis execution:** GateMate cell-model simulation executes blink
  firmware and drives LED high after 51 clocks.
- **Visible LED:** BRAM-backed `blink.asm` is loaded over DirtyJTAG and visibly
  toggles the board user LED; the power LED remains continuously on.
- **Physical UART:** BRAM-backed `hello.asm` emits `48 69` (`Hi`) through FPGA
  TX `IO_SA_B6` → RP2040 GPIO13/UART0_RX → DirtyJTAG CDC0 → `/dev/ttyACM0`.
  A simultaneous `/dev/ttyACM1` capture receives zero bytes, as expected.
- **Bitstream:** final blink artifact is 256,096 bytes and timing-clean.

The full ROM/BRAM/UART evidence and staged debugging method are documented in
design-doc 03.

## 7. Limitations and known gaps

1. **Partial DD/FD and no ED block prefix** — IX/IY load, INC/DEC, and indexed
   `LD A,(IX/IY+d)` work; complete substitution rules and ED instructions do
   not. This remains the largest gap to a full Z80.
2. **Memory-mapped GPIO and UART, not real OUT/IN** — the baseline I/O map writes
   address 0x0000 to drive GPIO (LED) and 0x0001 to drive the UART transmitter;
   a real Z80 port I/O space (OUT/IN) is a future add. The UART TX (8-N-1,
   115200 baud) is verified in RTL and physically through DirtyJTAG CDC0.
3. **Memory map simplification** — reads below `ROM_DEPTH=512` hit ROM; higher
   addresses hit the small RAM. Writes are RAM except address 0 (GPIO) and 1
   (UART TX). The model has a flat 64K, so integration focuses on ROM programs;
   direct object tests cover RAM operations.
4. **Incomplete architectural breadth** — no interrupts, complete alternate
   register/exchange behavior, RET cc, or RST in decode.
5. **PCA mesh not wired to the Z80** — hardware execution and UART are
   complete, but the baseline object graph still uses the direct held-request
   bus. The placer (`placer.py`) and generated mesh integration remain Phase 7.

## 8. Reproducibility

```bash
source ~/fpga/oss-cad-suite/environment   # OSS CAD Suite 20260825
cd pca_z80
make test            # mesh + object graph + 49 model + 22 asm + 6 integration
make sim_hello       # decode UART bytes 48 69 in RTL simulation
make post_synth PROG=blink  # BRAM allocation/init + primitive execution proof
make bit PROG=blink DEBUG_LED_MODE=0 PNR_SEED=1
openFPGALoader -b olimex_gatemateevb build/top.bit   # visible Z80-driven blink
```

A clean checkout regenerates everything: the toolchain is pinned
(`make versions`), the program ROM is assembled and padded as a hard build
dependency, `make post_synth` validates the generated GateMate primitive, and
the fast suites remain toolchain-independent.

## 9. Bug diary (selected)

- **Yosys constant-folded the whole core to a static LED** (Phase 6): the
  `CC_USR_RSTN` primitive was instantiated with no port connection, leaving
  reset undriven, so the FSM's constant program optimized to LED=1 (0 CPE
  cells). Fixed with the sibling's named-connection form
  `CC_USR_RSTN u_cfg_reset (.USR_RSTN(cfg_rst_n))`.
- **The Z80 little-endian stack** (Phase 3F): the first PUSH/CALL cut wrote
  low@SP+1, high@SP — swapped. The oracle pushes high@SP+1, low@SP; fixed
  both PUSH and CALL.
- **PV vs carry** (Phase 3C): a test expected PV for 0xFF+0x01; the oracle
  correctly omits it (−1+1=0 is not signed overflow). The RTL was right; the
  test was wrong (the model-first payoff).
- **ADD HL,rr sizing** (Phase 3D.5): `size_of` returned 2 for the 1-byte
  `ADD HL,BC`, breaking the address layout; the golden vector caught it.
- **Firmware BRAM contained zeros despite `RAM_HALF: 1`:** the original
  256×8 ROM was below the measured inference threshold; after growing it, a
  partial `$readmemh` combined with procedural zero-fill produced all-zero
  `INIT_*`. Fixed with a registered 512×8 ROM and complete padded image. A
  primitive checker and post-synthesis execution test now guard the boundary.
- **UART documentation direction conflict:** resolved from the schematic and
  pico-dirtyJtag definitions. FPGA TX is `IO_SA_B6` into RP2040 UART0 RX;
  physical CDC0 capture returned `Hi`.

## 10. Conclusion

The PCA-Z80 is a synthesizable, physically demonstrated Z80 object graph. It
executes real assembled programs, is differential-tested against an independent
oracle, fetches firmware from initialized GateMate block RAM, visibly drives
the board LED, and physically emits `Hi` through DirtyJTAG CDC0. The PCA
object/message architecture is proven at the mesh-substrate and direct-object-
bus levels; generated placement of the processor onto the mesh remains the
Phase 7 refinement. Remaining work concerns ISA breadth and dynamic PCA
integration, not basic firmware, synthesis, board loading, or UART transport.
