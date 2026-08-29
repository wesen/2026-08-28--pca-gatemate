# GateMate ROM/BRAM comparison repository provenance

Cloned under `/home/manuel/code/others/gatemate/` for the PCA-Z80 ROM/BRAM investigation.

| Repository | Commit | Why inspected |
|---|---|---|
| `PythonLinks/awesome-gatemate` | `bb8040678871ad8d495694d7c04d879f1678cfe4` | Curated discovery index requested by user |
| `fm4dd/gatemate-riscv` | `1cd29180eba4` | Native GateMate FemtoRV tutorial; BRAM thresholds and firmware `$readmemh` flow |
| `tarik-ibrahimovic/LUTRAM_Stress_Test` | `c2e6558da35e` | Generic distributed LUTRAM stress methodology |
| `YosysHQ/prjpeppercorn-test-cases` | `d2af90eae7c0` | Sparse: LiteX VexRiscv, SERV, FazyRV, ColecoVision GateMate cases |

## Most relevant source anchors

- `gatemate-riscv/step03/SOC.v`, `step03/readme.md`: minimum-size experiment and `CC_BRAM_20K` evidence.
- `gatemate-riscv/step20/SOC.v`, `step20/Makefile`: generated `firmware.hex` as a build dependency; synchronous initialized unified memory.
- `gatemate-riscv/step21/SOC.v`, `step21/Makefile`: 1536×32 initialized read/write memory running C firmware.
- `prjpeppercorn-test-cases/058-litex-vexriscv/olimex_gatemate_a1_evb.v`: 6049×32 synchronous ROM and 2048×32 SRAM.
- `.../061-litex-serv/olimex_gatemate_a1_evb.v`: 6093×32 synchronous initialized ROM.
- `.../089-litex-fazyrv/olimex_gatemate_a1_evb.v`: 6095×32 synchronous initialized ROM.
- `.../085-colecovision/src/rom.v`: parameterized 4096×8 `$readmemh` ROM with registered output.
- Installed OSS CAD Suite `share/yosys/gatemate/brams.txt` and `brams_map.v`: actual mapper capabilities and init mapping.
