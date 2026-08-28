---
Title: Tasks
Ticket: PCA-Z80-GATEMATE
Status: active
Topics:
    - pca
    - z80
DocType: reference
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: "Phase checklist for the PCA-Z80 build. Each task maps to a phase exit criterion in the intern onboarding guide (§13)."
LastUpdated: 2026-08-28T14:35:00-04:00
WhatFor: "Track phase completion against the implementation plan."
WhenToUse: "Check off tasks as each phase exit criterion is met."
---

# Tasks

## TODO

### Phase 0 — Ticket, repo, and tooling bootstrap
- [x] Create docmgr ticket `PCA-Z80-GATEMATE` with design doc + diary  *(done this session)*
- [x] Gather + study PCA literature; write `sources/SOURCES.md`  *(done this session)*
- [x] Install OSS CAD Suite toolchain (reuse `~/fpga/oss-cad-suite/` from sibling project; source `environment`, verify 7 tools)  *(verified: Yosys 0.68, nextpnr 0.11.1, iverilog 14, verilator 5.051, gmpack, openFPGALoader 1.1.1, py3.11.6)*
- [x] `pca_z80/` project skeleton (rtl/tools/programs/sim/constraints/scripts/build)  *(done)*
- [x] `.gitignore` (build/*, *.vcd, *.fst, *.log, __pycache__/, .pytest_cache/)  *(done)*
- [x] `Makefile` stub incl. `versions` target  *(done; full targets versions/test/sim/synth/pnr/bit/load/clean)*
- [x] `make versions` → `build/tool-versions.txt`  *(done)*
- [x] Exit: toolchain verified; skeleton synthesizes an empty top  *(PASS: sim self-test + synth/pnr/bit produces build/top.bit)*

### Phase 1 — PCA cell substrate (paper 01 §2, paper 05)
- [x] `pca_z80/rtl/pca_types.sv` — msg_t/dir_e/cmd_e contract + xy_route (§9.1)
- [x] `pca_z80/rtl/pca_router.sv` — 5-port XY router, held-request/ack, one-in-flight (§9.2)
- [x] `pca_z80/rtl/pca_cell.sv` — router wrapper + scalar Local port (§9.1)
- [x] `pca_z80/rtl/pca_mesh.sv` — COLS×ROWS neighbor-wired array (§9.3)
- [x] `sim/tb_pca_mesh.sv` directed tests; held-request anti-double under random stalls
- [x] Exit: a packet routes A->B with a single ack; anti-double holds (T1/T2/T3 PASS); 3×3 mesh synthesizes clean

### Phase 2 — Z80 reference model (the oracle)
- [x] No object RTL yet (Phase-2 model-first invariant)  *(enforced; no obj_*.sv written)*
- [x] `pca_z80/tools/z80_isa.py` — single ISA contract (DR-3)  *(done)*
- [x] `pca_z80/tools/z80_model.py` — all baseline opcodes, flags, prefixes (§10.1)  *(done; ~600 lines)*
- [x] `sim/test_model.py` — 49 unit tests with hand-computed state  *(done; 49 passed)*
- [x] Exit: model passes the unit suite; no object RTL written  *(49 passed in 0.11s)*

### Phase 3 — Object RTL, milestone per object (§6.4)
- [x] `z80_obj.sv` object-bus contract (req/resp structs, object ids, PC sub-ops)
- [x] `obj_pc.sv` — PC + R refresh counter (held-request slave)
- [x] `obj_memio.sv` — byte ROM + RAM (3A: reads)
- [x] `obj_decode.sv` — master FSM (3A: fetch/NOP/HALT) (§7)
- [x] `z80_core.sv` — wires master to slaves (OR-ack + rdata mux)
- [x] 3A fetch/NOP/HALT — directed differential vs oracle (PASS; synth clean ~995 cells)
- [x] 3B LD immediate/register — add obj_regfile, extend decode (PASS; synth clean ~4443 cells)
- [ ] 3B.5 LD r,(HL)/(HL),r + LD A,(BC)/(DE)/(nn) (memory-operand LDs)
- [x] 3C 8-bit ALU + flags — add obj_alu, obj_flags (PASS; synth clean ~4760 cells)
- [x] 3D 16-bit + IX/IY — LD rr,nn/INC-DEC rr/ADD HL,rr done (PASS); IX/IY (DD/FD) deferred
- [x] 3D.5 memory-operand LDs — LD r,(HL)/(HL),r/LD A,(BC)/(DE)/(nn) done (PASS)
- [x] 3E JP/JR/CALL/RET — JP/JR/JR cc done (PASS; synth clean ~4960 cells); CALL/RET done in 3F
- [x] 3F stack + I/O + faults — CALL/RET/PUSH/POP done (PASS; synth clean ~5450 cells); I/O (IN/OUT) + RET cc/RST pending
- [x] 3F.5 INC/DEC r + LD (nn),A (GPIO) — done (PASS; enables blinking-LED demo)
- [ ] 3F.5b OUT/IN (real port I/O) + RET cc/RST
- [ ] Exit: each object passes directed tests vs model slices; decode handles all 4 prefix families

### Phase 4 — Assembler + decoder round-trip
- [x] `pca_z80/tools/zasm.py` — two-pass, no eval, prefix + displacement encoding (§11.1)  *(done; LD/ALU/JP/JR/CALL/PUSH-POP/etc.)*
- [x] Outputs: program.hex/.bin/.lst/.sym.json §3.4.5  *(done)*
- [x] `sim/test_assembler.py` — golden vectors, symbols, negatives (16 tests pass)  *(done)*
- [ ] `pca_z80/tools/zdis.py` — disassembler / message trace (§11.2)  *(deferred)*
- [x] Exit: golden vectors byte-exact; deterministic; clear diagnostics (16 tests pass + 3 cross-checks vs model)

### Phase 5 — Placer + integration on the mesh
- [x] integration testbench `tb_z80_integ.sv` (asm->ROM via $readmemh)  *(done)*
- [x] `sim/run_integ.py` differential harness (model vs object graph on same bytes)  *(done)*
- [x] `programs/selftest.asm` reaches magic final state A=8 (PASS)  *(done)*
- [x] `sim/test_integ.py` 6 integration tests (smoke/alu/loop/call/stack/selftest) pass  *(done)*
- [ ] `tools/placer.py` static object placement (deferred to Phase 6 hardware; baseline demo synthesizes z80_core directly)
- [x] Exit: assembled Z80 runs on object graph in sim; differential zero divergence; selftest reaches A=8

### Phase 6 — Verification, FPGA implementation, hardware
- [x] Synthesis/PnR/timing clean; 10 MHz positive slack; resource ledger  *(6026 LUT 14%, 2451 FF 5%, 51.41 MHz PASS at 10 MHz, 5x margin)*
- [x] Hardware bring-up: Z80 LD (0),A drives GPIO bit 0 -> LED (proven in sim; board top + 220KB bitstream built)  *(done in sim; physical load pending board access)*
- [ ] `openFPGALoader -b olimex_gatemateevb build/top.bit` + observe LED  *(deferred: board not connected)*
- [ ] Engineering report + bug diary (design-doc §4.20)  *(deferred)*
- [x] Exit (partial): synth/PnR/timing clean; LED driven by Z80 in sim; bitstream built. Physical board load + report pending.

### Phase 7 — Extensions (only after baseline passes)
- [ ] Runtime pressure-based object placement (papers 02b, 05)
- [ ] Full bit-parallel datapath (§8.1)
- [ ] Interrupts (IM 0/1/2), RETI/RETN
- [ ] Undocumented-opcode bit-exactness
- [ ] Multi-context / partial reconfiguration; VGA / PS2 / PSRAM (sibling §4.22)
