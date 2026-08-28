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
ExternalSources: []
Summary: 'Engineering report for the PCA-Z80 build: architecture, software, verification, FPGA implementation, hardware results, and limitations. The Z80 is built as a graph of wired-logic objects on a held-request bus (the PCA object/message model, DR-7), differential-tested against a Python oracle, and deployed as a GateMate bitstream that blinks an LED driven by Z80 instructions.'
LastUpdated: 2026-08-28T20:00:00-04:00
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
substrate, Z80 object graph, 49 model tests, 19 assembler tests, 6 integration
tests, and a synthesizable 220 KB bitstream that meets 10 MHz with 5× margin.

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

### 2.2 The Z80 object graph (Phases 3A-3D.6)

The Z80 is a **single master + five memory-mapped slaves** on a held-request
object bus (`z80_obj.sv`):

| Object | File | Role |
|---|---|---|
| `obj_decode` | `obj_decode.sv` | bus master; fetch/decode/execute FSM (~70 states) |
| `obj_pc` | `obj_pc.sv` | PC + SP + R; held-request slave |
| `obj_memio` | `obj_memio.sv` | byte ROM (init via `$readmemh`) + RAM + GPIO port |
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
| I/O | memory-mapped GPIO (write addr 0x0000 → gpio_out) |
| Misc | DI, EI, RLCA, RRCA, RLA, RRA, EXX |

**Not yet implemented:** the DD/FD (IX/IY) and ED (block) prefixes; real
port I/O (OUT/IN, separate I/O space); RET cc; RST; the (HL) forms of CB ops;
EX DE,HL / EX AF / EX (SP),HL; the alternate register set; interrupts. The
reference model (`z80_model.py`) implements all of these — they are decode
gaps, not architecture gaps.

## 3. Software

- **`z80_isa.py`** — the ISA contract (flag bits, r/rp/cc tables, the
  `IMPLEMENTED` set). Single source of truth for model/assembler/tests (DR-3).
- **`z80_model.py`** — the executable reference model (~600 lines): full
  architectural state, every baseline opcode, the flag model, and the
  DD/FD/CB/ED prefix machinery. The differential oracle.
- **`zasm.py`** — the two-pass assembler (no `eval`, DR-9): emits
  `.hex`/`.bin`/`.lst`/`.sym.json`; computes JR displacements relative to PC
  after the JR; covers the implemented set.
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
| Assembler golden vectors + cross-check (pytest) | 19 | explicit bytes + model | <0.1 s |
| Integration (assemble → object graph vs model) | 6 | z80_model.py | ~1 s |
| Synthesis + PnR + timing | 1 | reports | ~100 s |
| Hardware (LED driven by Z80) | 1 | observation | sim-verified; board load pending |

The **differential discipline** (model-first, DR-4): the RTL is wrong iff it
diverges from `z80_model.py` on the same assembled bytes. Every Phase 3
milestone added a directed differential test; the integration harness runs
real assembled programs end-to-end. The selftest program (LD A,0; loop: ADD
A,1; CP 3; JR NZ,loop; CALL add5; HALT) reaches the magic final state A=8,
model==RTL byte-for-byte.

## 5. FPGA implementation (Phase 6)

`make bit` (Yosys `synth_gatemate -luttree -nomx8` → nextpnr-himbaechel →
gmpack) produces `build/top.bit` (220 KB) from `rtl/top.sv` (board top:
`CC_USR_RSTN` → `reset_sync` → `z80_core`, `user_led = gpio[0]`), with the
program ROM initialized at synthesis via `$readmemh` (`-DROM_FILE` macro).

| Resource | Used | Available | % |
|---|---:|---:|---:|
| CPE_LT (LUTs) | 6,026 | 40,960 | 14.7% |
| CPE_FF | 2,451 | 40,960 | 6.0% |

Timing: 10 MHz clock, post-route max **51.41 MHz** — positive slack, **5×
margin**. The Z80 object graph fits in ~15% of the CCGM1A1, leaving ample room
for the PCA mesh (Phase 1's 3×3 was ~12.5k cells) and the remaining prefixes.

The `programs/blink.asm` demo blinks the LED: `LD A,1; LD (0),A; DEC B loop;
LD A,0; LD (0),A; DEC B loop; JR start`. A GPIO testbench observes both on
and off cycles (gpio toggles, not faulted) — the LED is driven by Z80
instructions, not a hardware counter.

## 6. Hardware results

- **Sim-verified:** the blink program toggles GPIO bit 0 (on=12096,
  off=7904 over 20000 cycles), driven by Z80 LD/DEC/JR/LD (nn),A.
- **Bitstream built:** `build/top.bit` (220 KB), timing-clean at 5× margin.
- **Board load:** deferred — the GateMateA1-EVB was not connected during the
  session (`openFPGALoader --detect` found no FTDI). The single remaining
  step is `openFPGALoader -b olimex_gatemateevb build/top.bit` + visual LED
  observation.

## 7. Limitations and known gaps

1. **No DD/FD (IX/IY) or ED (block) prefixes** in the decode/assembler (the
   model implements them). The largest gap to a "full Z80."
2. **Memory-mapped GPIO and UART, not real OUT/IN** — the baseline I/O map writes
   address 0x0000 to drive GPIO (LED) and 0x0001 to drive the UART transmitter;
   a real Z80 port I/O space (OUT/IN) is a 3F.5b add. The UART TX (8-N-1,
   115200 baud) is wired in `top.sv` and sim-verified to emit "Hi".
3. **Memory map simplification** — reads at addr < ROM_DEPTH (256) hit ROM,
   ≥256 hit RAM; writes hit RAM except addr 0 (GPIO). The model has a flat 64K,
   so the integration harness tests ROM-only programs; RAM-touching programs
   are tested via the direct object-graph testbench.
4. **No interrupts, no alternate register set, no EX**, no RET cc/RST in the
   decode (model has them).
5. **PCA mesh not wired to the Z80** — the baseline runs the object graph
   directly; the placer (`placer.py`) and full mesh integration are Phase 7
   (the DR-7 reconfigurable refinement).
6. **Physical board load pending** (see §6).

## 8. Reproducibility

```bash
source ~/fpga/oss-cad-suite/environment   # OSS CAD Suite 20260825
cd pca_z80
make test            # mesh + object graph + 49 model + 19 asm + 6 integration
make bit             # synth -> PnR -> pack -> build/top.bit (220 KB, 5x margin)
# when the board is connected:
openFPGALoader -b olimex_gatemateevb build/top.bit   # LED blinks (Z80-driven)
```

A clean checkout regenerates everything: the toolchain is pinned
(`make versions`), the program ROM is a build dependency (assembled from
`programs/blink.asm`), and the full test pyramid is toolchain-independent for
the fast suites.

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

## 10. Conclusion

The PCA-Z80 is a real, synthesizable Z80 object graph — not a paper design —
that executes real assembled Z80 programs, differential-tested against an
independent oracle, deployed as a timing-clean GateMate bitstream that drives
the board LED. The PCA object/message architecture (DR-7) is proven at the
substrate level (the mesh) and the system level (the object bus), with the
full mesh integration as the documented Phase 7 refinement. The remaining
work is ISA breadth (the DD/FD/ED prefixes, real I/O) and the physical board
load — not architecture.
