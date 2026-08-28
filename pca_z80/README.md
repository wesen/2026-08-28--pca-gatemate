# PCA-Z80 — a Z80 microprocessor built on Plastic Cell Architecture (PCA)

A Z80 8-bit CPU mapped onto **Plastic Cell Architecture** (NTT/Nagasaki-U,
1998–2005): a 2-D mesh of cells each pairing a fixed cellular-automaton
**built-in part** with a reconfigurable **sea-of-LUTs plastic part**, where
the Z80 is expressed as a graph of wired-logic **objects** that communicate
by message passing. Deployed on the **Olimex GateMateA1-EVB** (Cologne Chip
CCGM1A1) using only open-source tools.

See the ticket for the full design:
`ttmp/2026/08/28/PCA-Z80-GATEMATE--.../design-doc/01-pca-z80-system-intern-onboarding-guide.md`

## Repository layout (Phase 0)

```
pca_z80/
├── Makefile              # versions, sim, synth, pnr, bit, load, clean
├── constraints/          # CCF pins (verified), SDC timing, openFPGALoader udev rule
├── rtl/                  # synthesizable SystemVerilog
│   ├── reset_sync.sv     # async-assert/sync-release reset (reused from MATE-16)
│   └── top.sv            # Phase 0 placeholder: counter-driven LED (PCA cells come in Phase 1)
├── sim/                  # testbenches + sim-only CC_USR_RSTN model
│   ├── CC_USR_RSTN.sv
│   └── tb_top.sv
├── tools/                # (Phase 2+) z80_isa.py, z80_model.py, zasm.py, placer.py
├── programs/             # (Phase 4+) Z80 assembly programs
├── scripts/              # synth_sys.ys (Yosys script)
└── build/                # generated (gitignored)
```

## Toolchain

Install the OSS CAD Suite once (sibling project):
```bash
mkdir -p ~/fpga && cd ~/fpga
curl -L -o oss-cad-suite.tgz \
  https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-08-25/oss-cad-suite-linux-x64-20260825.tgz
tar -xvf oss-cad-suite.tgz
source ~/fpga/oss-cad-suite/environment   # in every working shell
```

## Quick start (Phase 0)

```bash
source ~/fpga/oss-cad-suite/environment
cd pca_z80
make versions     # record tool versions to build/tool-versions.txt
make sim          # simulate the placeholder top
make bit          # synth -> PnR -> pack -> top.bit
make load         # load the bitstream to the board (LED blinks)
```

## Phases (see the design doc §13)

- **P0** repo + toolchain bootstrap (this phase)
- **P1** PCA cell / router / mesh RTL
- **P2** Z80 reference model (the oracle, model-first)
- **P3** object RTL, milestone per Z80 subsystem
- **P4** assembler + decoder round-trip
- **P5** placer + integration on the mesh
- **P6** verification, FPGA implementation, hardware
- **P7** (optional) extensions: pressure placement, bit-parallel, interrupts
