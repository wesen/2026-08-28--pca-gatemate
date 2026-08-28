# Changelog

## 2026-08-28

- Initial workspace created


## 2026-08-28

Step 1: researched PCA (downloaded founding paper 01, pressure paper 02b, space-allocation paper 05, Oguri lab deck); wrote sources/SOURCES.md with evidence-anchored concept extraction; added 11 PCA vocab topics; created ticket PCA-Z80-GATEMATE with design-doc + diary (commit ddf251f)

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/SOURCES.md — Evidence-anchored index of collected PCA primary sources


## 2026-08-28

Step 2: wrote the PCA-Z80 System Intern Onboarding Guide (design-doc 01, ~50KB) — PCA twice-double structure, cell dual structure, objects/messages/async handshake, Z80 ISA recap, object-graph mapping, bit-serial datapath, decode FSM as PLA, verification pyramid vs z80_model.py, GateMate toolchain/pins reused from MATE-16, 7-phase plan, 7 decision records, file/API map; populated tasks.md and index.md; related the guide to all sources + sibling MATE-16 files

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/design-doc/01-pca-z80-system-intern-onboarding-guide.md — The intern onboarding guide (main deliverable)


## 2026-08-28

Step 3: fixed source-file placement (real PDFs 01/02b/05 + deck 06 moved root->sources/, stale HTML removed); docmgr doctor now clean; committed (929a738); bundle-uploaded the guide + SOURCES.md + diary to reMarkable at /ai/2026/08/28/PCA-Z80-GATEMATE (dry-run first); verified on device.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/reference/01-investigation-diary.md — Diary Step 3 records the placement fix, commit, and reMarkable upload


## 2026-08-28

Step 4 / Phase 0: built pca_z80/ skeleton + verified the OSS CAD flow end-to-end. Makefile (versions/test/sim/synth/pnr/bit/load), constraints (verified pins reused from MATE-16), reset_sync + placeholder counter-LED top, sim CC_USR_RSTN model + tb_top. make versions recorded toolchain (Yosys 0.68, nextpnr 0.11.1, iverilog 14, verilator 5.051, openFPGALoader 1.1.1, py3.11.6); make sim PASS; make bit -> build/top.bit (181 bytes). Printed brutalist PLAN slip (7 phases) + P0 START slip.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/Makefile — Phase 0 build flow (versions/test/sim/synth/pnr/bit/load)


## 2026-08-28

Step 5 / Phase 1: built the PCA routing substrate. pca_types.sv (msg_t/dir_e/cmd_e + xy_route), pca_router.sv (5-port XY, held-request/ack, one-in-flight, anti-double), pca_cell.sv (router + scalar Local), pca_mesh.sv (COLS×ROWS neighbor-wired, flat packed-1D links). tb_pca_mesh T1/T2/T3 PASS (A->B single ack; A->C XY via B-path, B untouched; anti-double under random stalls). 3×3 mesh synthesizes clean (Yosys, 0 errors, ~12.5k cells). Portable subset locked: packed 1D + +: + pca_types:: scoping + bare enum constants (works in iverilog AND Yosys). Phase 0 top sim still passes (regression). Printed P1 START slip.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/pca_router.sv — 5-port XY router, held-request handshake, anti-double


## 2026-08-28

Step 6 / Phase 2: built the Z80 reference model (oracle). z80_isa.py (single ISA contract: flag bits, r/rp/cc tables, IMPLEMENTED baseline subset), z80_model.py (~600 lines: full arch state, 8-bit ALU with correct S/Z/H/PV/N/C flags, loads, 16-bit, control, stack, exchange, rotates, CB, ED, DD/FD/CB/ED prefixes, precise bus-fault), test_model.py (49 hand-computed tests, all pass). Fixed: 3-bit register fields (not 4-bit hi/lo), CP flag store, DD/FD 16-bit IX/IY substitution, _step_indexed IX clobber. make test now runs mesh sim + 49 model tests (full software pyramid, <0.2s). Model-first invariant held: no obj_*.sv RTL written. Printed P2 START slip.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/tools/z80_model.py — Z80 executable reference model (the differential oracle for Phase 3)

