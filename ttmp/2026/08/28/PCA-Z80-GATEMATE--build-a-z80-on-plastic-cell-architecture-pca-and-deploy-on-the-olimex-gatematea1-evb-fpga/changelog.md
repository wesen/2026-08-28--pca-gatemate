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


## 2026-08-28

Step 7 / Phase 3A: built the first Z80 object-RTL milestone. z80_obj.sv (object-bus contract: bus_req_t/bus_resp_t, object ids, PC sub-ops), obj_pc.sv (PC+R held-request slave), obj_memio.sv (byte ROM+RAM slave), obj_decode.sv (master FSM FETCH_PC/FETCH_OP/INC/DECODE; NOP retires, HALT halts), z80_core.sv (master-to-slaves wiring). tb_z80_core.sv directed differential vs oracle: NOP,NOP,HALT -> PC=3,R=3,count=3,halted (PASS). Synth clean (~995 cells). make test = mesh + 3A + 49 model tests. Scope: 3A delivered; 3B-3F follow same pattern (budget). Printed P3 START slip.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_decode.sv — Z80 decode master FSM (3A: fetch/NOP/HALT)


## 2026-08-28

Step 8 / Phase 3B: added obj_regfile + extended decode to LD r,n and LD r,r' (register operands). obj_regfile.sv (9-entry 8-bit register array, held-request slave), obj_decode.sv rewritten as a general fetch-decode-execute sequencer with local pc_cur for multi-byte instructions (S_FETCH_PC->FETCH_OP->INC_OP->DECODE->FETCH_IMM/REG_READ_SRC->REG_WRITE_DST). tb_z80_core.sv 3 differential tests vs oracle: NOP/HALT, LD A,0x42;LD B,A, LD A,0x11;LD C,0x22;LD D,A all PASS. Synth clean (~4443 cells). make test = mesh + 3A/3B + 49 model tests. Portability rules added: V2K function style (no return), &/| not &&/|| in functions.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_regfile.sv — Z80 register-file object (8-bit regs, held-request bus slave)


## 2026-08-28

Step 9 / Phase 3C: added obj_alu + obj_flags + 8-bit ALU A,r/A,n (ADD/SUB/AND/XOR/OR/CP) with full flag model ported from z80_model.py. obj_alu.sv (combinational result+flags, parity/H/carry/overflow), obj_flags.sv (F register), decode +6-state ALU path (READ_A/READ_B|FETCH_IMM/OP/WRITE_A/WRITE_FLAGS). 5 differential tests vs oracle all PASS (ADD half-carry, SUB N, AND Z+H+PV, ADD A,B sign, ADD FF+01 carry+zero+H). Synth clean (~4760 cells). make test = mesh + 3A/3B/3C + 49 model tests. Fixed enum overflow (17 states -> 5 bits), enum ternary -> if/else.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_alu.sv — Z80 8-bit ALU object (ADD/SUB/AND/XOR/OR/CP + flags, ported from z80_model.py)


## 2026-08-28

Step 10 / Phase 3E: added control flow JP nn / JR e / JR cc,e (NZ/Z/NC/C). decode +9 control states (JP_LO/INC1/HI/INC2/PC_SET; JR_READ_F/FETCH/INC/DO) reading flags for conditions, sign-extending the JR displacement. 3 differential tests vs oracle all PASS (JP taken, JR taken, JR NZ not-taken). Synth clean (~4960 cells). Skipped ahead from 3C to 3E (control unblocks loops/programs; 3D 16-bit and 3F stack/CALL-RET follow). make test = mesh + 3A/3B/3C/3E + 49 model tests.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_decode.sv — Z80 decode master (3A/3B/3C/3E: NOP/HALT/LD/ALU/JP/JR)


## 2026-08-28

Step 11 / Phase 3F: added the stack (SP in obj_pc) + CALL/RET/PUSH/POP. obj_pc rewritten (PC+SP+R, 7 sub-ops), obj_regfile rewritten (+16-bit pair access idx 9-12 = BC/DE/HL/AF), obj_decode +~24 stack states (PUSH read-pair/dec-SP2/write-hi@SP+1/write-lo@SP; POP read-SP/inc-SP2/read-hi/read-lo/write-pair; CALL fetch-target/dec-SP2/push-retaddr/set-PC; RET read-SP/inc-SP2/pop-retaddr/set-PC). 2 differential tests vs oracle PASS (CALL/RET A=0x42 SP=FFFF; PUSH BC/POP DE D=0x12 E=0x34 SP=FFFF). Fixed little-endian stack byte order (high@SP+1, low@SP), enum overflow (->6 bits), obj_pc output assign. Synth clean (~5450 cells). Object graph now executes NOP/HALT/LD/ALU/JP/JR/CALL/RET/PUSH/POP.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_pc.sv — Z80 PC + SP + R object (held-request bus slave, 7 sub-ops)


## 2026-08-28

Step 12 / Phase 4: built the two-pass Z80 assembler zasm.py (no eval, DR-9). Targets the implemented ISA (NOP/HALT/LD r,n/r,r'/rr,nn/8-bit ALU A,r/A,n/JP nn/JP cc,nn/JR e/JR cc,e/CALL nn/CALL cc,nn/RET/PUSH rr/POP rr/DI/EI/RLCA/EXX). Two-pass (size->addr->resolve->emit), tiny hand-written expr evaluator (no eval). Outputs program.hex/.bin/.lst/.sym.json. sim/test_assembler.py: 16 tests (golden vectors + 3 assemble->model cross-checks + determinism) all pass. A real 13-byte program (LD A,0x0F;ADD A,1;LD B,A;JR loop;NOP;loop:LD C,0x22;PUSH BC;POP DE;HALT) assembles and runs on the model with expected state. Fixed operand comma-split, LD rr,nn sizing, .ORG parse, JP/JR/CALL cc form, JR displacement off-by-one. make test = mesh + object graph + 49 model + 16 assembler tests.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/tools/zasm.py — Two-pass Z80 assembler (no eval) targeting the implemented ISA


## 2026-08-28

Step 13 / Phase 5: integration — object graph runs assembled Z80, differential vs model. tb_z80_integ.sv loads .hex via $readmemh into the memory object; run_integ.py assembles a program, runs z80_model.py + the object-graph testbench, compares 12 state fields. programs/selftest.asm (LD A,0; loop: ADD A,1; CP 3; JR NZ,loop; CALL add5; HALT; add5: ADD A,5; RET) reaches magic A=8, model==RTL byte-for-byte (PC=12 count=14 F=0x08). test_integ.py 6 tests (smoke/alu/loop/call/stack/selftest) pass. make test = mesh + object graph + 49 model + 16 assembler + 6 integration. placer.py deferred (baseline demo synthesizes z80_core directly in P6).

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/sim/tb_z80_integ.sv — Integration testbench (loads assembled .hex via $readmemh, dumps state)


## 2026-08-28

Step 14 / Phase 6: Z80 object graph -> GateMate bitstream. Added GPIO output port to obj_memio (write addr 0x0000 -> gpio_out), LD (nn),A (0x32) to decode + assembler, programs/blink.asm (LD A,1; LD (0),A; HALT -> LED on), rtl/top.sv board top (CC_USR_RSTN named connection + reset_sync + z80_core + LED=gpio[0]). ROM init via ROM_FILE macro + $readmemh (Yosys -DROM_FILE). make bit: Yosys synth_gatemate -> nextpnr -> gmpack -> build/top.bit (220KB). Resources 6026 CPE_LT (14%), 2451 CPE_FF (5%), 184 CC_ADDF; timing 51.41 MHz PASS at 10 MHz (5x margin). Fixed: CC_USR_RSTN constant-fold (named connection), string param -> macro. Sim blink: gpio=01 count=3 (LED driven by Z80). Board not connected (no FTDI) -> physical load + LED observation deferred. make test = mesh + object graph + 49 model + 16 assembler + 6 integration tests.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/top.sv — Phase 6 board-facing top (Z80 core + LED=gpio[0], ROM init via ROM_FILE macro)


## 2026-08-28

Step 15 / Phase 3F.5: added INC/DEC r (porting _inc8/_dec8, C preserved). ALU +ALU_INC/ALU_DEC cases (wdata={value,cur_flags}, rdata preserves C). decode +5 states (read r, read flags, ALU op, write r, write flags). zasm +INC/DEC. 3 differential tests PASS (INC B 7F->80 S+PV; DEC A 0->FF N+H+S; DEC B countdown loop B->0). programs/blink.asm now a real blink loop (LD/DEC/JR/LD (nn),A) — GPIO sim observes on=12096 off=7904 over 20000 cycles (LED toggles, driven by Z80). Synth clean. Fixed: cur_f wire, DJNZ-vs-DEC-B test opcode. make test = mesh + object graph (with INC/DEC) + 49 model + 16 assembler + 6 integration.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/programs/blink.asm — Real blinking-LED demo (LD/DEC/JR/LD (nn),A loop drives GPIO bit 0)


## 2026-08-28

Step 16 / Phase 3D: added 16-bit register-pair ops (LD rr,nn/INC rr/DEC rr/ADD HL,rr), reusing 3F's 16-bit pair access. decode +~16 states (LDRR/INCRR/DECRR/ADDHL), SP split (rp3->obj_pc SP_SET/INC/DEC/READ, rp0-2->regfile pairs idx 9-11). ADD HL,rr sets only H/C/N preserving S/Z/PV + F5/F3 from result hi (model _add16). zasm +INC/DEC rr + ADD HL,rr. 3 differential tests PASS (ADD HL,BC->0x1001 H; INC BC FFFF->0; DEC HL 0->FFFF). Integration harness cross-check PASS. Synth clean. Enum ->7 bits. make test green.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_decode.sv — Z80 decode master (3A-3F/3F5/3D: +16-bit LD/INC/DEC/ADD HL)


## 2026-08-28

Step 17 / Phase 3D.5: added memory-operand LDs (LD r,(HL)/(HL),r/LD A,(BC)/(DE)/(nn)). decode +~18 states (compose HL/BC/DE/nn -> addr, MEM read/write, 8-bit reg access). zasm +mem-LD encodings + size_of fixes (ADD HL,rr 1 byte; (HL)/(BC)/(DE) 1 byte vs (nn) 3 byte). 3 differential tests PASS (LD A,(HL) A=0x99; LD (HL),B ram[0]=0x55; LD A,(nn) A=0x88; addr>=256 hits RAM). +9 assembler golden vectors (18 total). Synth clean. make test = mesh + object graph (mem-LD) + 49 model + 18 asm + 6 integ. Memory map: ROM<256/RAM>=256/GPIO=0 (baseline simplification; integ harness stays ROM-only).

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/tools/zasm.py — Two-pass assembler (now with memory-operand LDs, INC/DEC, ADD HL, 18 golden vectors)


## 2026-08-28

Step 18 / Phase 3D.6: added CB-prefixed shifts/bits (RLC/RRC/RL/RR/SLA/SRA/SRL + BIT/SET/RES). ALU +7 shift sub-ops (ALU_RLC..SRL, idx 10-16) porting model shift flag model (H=0/N=0/PV=parity/C=shifted-out). decode +CB states (fetch sub-op, dispatch shift/BIT/SET-RES, r=6->FAULT) + helpers cb_shift_op/cb_bit_flags/cb_sr_result. alu_op widened to 5 bits. zasm +CB mnemonics. 5 diff tests PASS (RLC 0x81->0x03 C; SRL 0x0F->0x07 C; BIT 4,A Z; SET/RES). ~64-sub-test CB golden sweep (19 assembler tests). Synth clean. make test = mesh + object graph (CB) + 49 model + 19 asm + 6 integ. DD/FD + ED prefixes remain as the largest ISA gap.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_alu.sv — Z80 ALU (8-bit ALU + INC/DEC + CB shifts, flag model ported from z80_model.py)


## 2026-08-28

Step 19: wrote the engineering report (design-doc 02, design-doc §4.20) summarizing architecture/ISA/software/verification/FPGA implementation (6026 LUT 15%, 51.4 MHz 5x margin, 220KB bitstream)/hardware/limitations/reproducibility/bug diary. Bundle-uploaded the report + intern guide + diary to reMarkable at /ai/2026/08/28/PCA-Z80-GATEMATE (verified on device, 2 docs). doctor clean.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/design-doc/02-pca-z80-engineering-report.md — Engineering report (Phase 6 §4.20 deliverable)


## 2026-08-28

Step 20 / Phase 3D.7: added DD/FD (IX/IY) prefix subset (LD IX,nn / INC-DEC IX / LD A,(IX+d)). regfile +IX/IY pair idx 13/14 (+dbg_ix/dbg_iy). decode +idx_sel + idx_pair_idx (HL->IX/IY redirect) + prefix-accumulator (PREFIX_FETCH/INC/DECODE) + LD A,(IX+d) path (fetch d, IX+d, MEM read). 16-bit states reuse idx_pair_idx (no new states for LD/INC-DEC IX). zasm +DD/FD + size_of INC IX=2. 4 diff tests PASS (LD IX,1234; INC IX; LD A,(IX+2) A=0xAB; LD IY,ABCD) + 7 golden vectors. Synth clean. make test = mesh + object graph (IX/IY) + 49 model + 20 asm + 6 integ. Last listed Phase 3 item done (full DD/FD substitution + ED prefix deferred).

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_regfile.sv — Z80 register file (8-bit + 16-bit pairs BC/DE/HL/AF + IX/IY)


## 2026-08-28

Step 21 / Phase 6: added UART TX (Z80 emits 'Hi' over UART, completing LED+UART bring-up in sim). Reused MATE-16 uart_tx.sv (8-N-1 115200 baud). obj_memio +UART write port (addr 0x0001 -> byte + 1-cycle start). z80_core +top wire uart_tx -> uart_tx_pin. programs/hello.asm (LD A,0x48; LD (1),A; delay; LD A,0x69; LD (1),A; LED on; HALT). tb_hello.sv UART RX monitor decoded 0x48 0x69 = 'Hi' (PASS Phase 6 LED+UART). Fixed iverilog string crash (byte array), multiple-driver on uart_tx_pin. make sim_hello target. Full regression green; UART-top synth clean. make test = mesh + object graph + 49 model + 20 asm + 6 integ. Board load remains the one environmental step.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/uart_tx.sv — 8-N-1 UART transmitter (reused from MATE-16, Z80-driven via memory-mapped port)


## 2026-08-28

Step 23: decomposed GateMate ROM/UART bring-up into eight independently observable stages; archived awesome-gatemate and mapper sources; cloned and studied FemtoRV, LiteX VexRiscv/SERV/FazyRV, ColecoVision, LUTRAM stress, and pico-dirtyJtag; measured sync-ROM BRAM threshold (272x8); fixed 512-byte registered/padded firmware ROM; added BRAM INIT checker + post-synth GateMate simulation + debug LED modes + deterministic PnR seed; physically captured Z80 UART bytes 48 69 ('Hi') on /dev/ttyACM0.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_memio.sv — Corrected ROM implementation
- /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/gatemate/rom-inference-matrix-results.txt — Measured inference evidence


## 2026-08-28

Step 24: wrote design-doc 03, GateMate Firmware ROM BRAM and UART Bring-Up Intern Guide (research comparison, inference matrix, corrected 512-byte padded synchronous ROM, primitive INIT validation, post-synth execution, debug LED modes, DirtyJTAG UART/CDC mapping, failure matrix, APIs, commands, decisions).

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/design-doc/03-gatemate-firmware-rom-bram-and-uart-bring-up-intern-guide.md — New intern guide


## 2026-08-28

Step 24 publication: validated design-doc 03; dry-ran and bundle-uploaded guide + repository provenance + diary to reMarkable at /ai/2026/08/28/PCA-Z80-GATEMATE. Fixed a XeLaTeX failure caused by literal escaped newlines in a verbatim diary prompt.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/design-doc/03-gatemate-firmware-rom-bram-and-uart-bring-up-intern-guide.md — Published intern guide


## 2026-08-28

Step 25: wrote textbook-style Obsidian deep-dive article (603 lines) covering PCA-Z80 architecture and GateMate firmware BRAM/UART verification; committed and pushed go-go-parc vault as 44e1caf; restored physical board to BRAM-backed blink image (DEBUG_LED_MODE=0, PNR seed 1).

### Related Files

- /home/manuel/code/wesen/go-go-golems/go-go-parc/Projects/2026/08/28/ARTICLE - PCA-Z80 - Firmware BRAM and Physical UART on GateMate.md — Published vault deep-dive report


## 2026-08-28

Step 26: audited and updated engineering report design-doc 02 from pre-hardware status to final measured evidence (512-byte BRAM firmware, 22 assembler tests, IX/IY subset, post-synth proof, physical blink and ACM0 Hi, current resources/timing/limitations); validated and uploaded versioned reMarkable bundle 'PCA-Z80 Engineering Report Final Hardware'.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/design-doc/02-pca-z80-engineering-report.md — Updated final hardware report


## 2026-08-28

Step 27: user visually confirmed the final BRAM-backed production image blinks the physical GateMateA1-EVB user LED, closing end-to-end blink acceptance.

### Related Files

- /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/programs/blink.asm — Physically observed production firmware

