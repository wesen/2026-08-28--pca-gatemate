---
Title: GateMate Firmware ROM BRAM and UART Bring-Up Intern Guide
Ticket: PCA-Z80-GATEMATE
Status: active
Topics:
    - fpga
    - rtl
    - toolchain
    - verification
    - hardware
    - z80
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/Makefile
      Note: Firmware generation, synthesis, post-synth verification, PnR, pack, and load flow
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/obj_memio.sv
      Note: |-
        Production registered ROM, RAM, GPIO, and UART memory object
        Production registered initialized GateMate BRAM ROM implementation
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/sim/tb_post_synth.sv
      Note: GateMate primitive netlist firmware-execution smoke test
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/tools/check_gatemate_rom.py
      Note: |-
        Synthesized BRAM allocation and non-zero INIT checker
        Synthesized primitive allocation and INIT checker
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/tools/zasm.py
      Note: Assembler and full-size hardware image generation API
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/gatemate/repository-provenance.md
      Note: Exact comparison repositories, commits, and source anchors
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/sources/gatemate/rom-inference-matrix-results.txt
      Note: Measured Yosys GateMate ROM inference boundary
    - Path: repo://ttmp/2026/08/28/PCA-Z80-GATEMATE--build-a-z80-on-plastic-cell-architecture-pca-and-deploy-on-the-olimex-gatematea1-evb-fpga/scripts/15-gatemate-rom-inference-matrix.py
      Note: Reproducible read-style and capacity synthesis experiment
ExternalSources:
    - https://github.com/PythonLinks/awesome-gatemate
Summary: A research-backed intern guide to initialized firmware ROM inference, synthesis verification, post-synthesis testing, and physical UART bring-up on GateMate, derived from PCA-Z80 and representative GateMate projects.
LastUpdated: 2026-08-28T20:45:00-04:00
WhatFor: Understand, implement, validate, and debug firmware-bearing GateMate block RAM and the full FPGA-to-RP2040 UART path.
WhenToUse: Read before changing PCA-Z80 memory geometry, firmware image generation, synthesis, board UART constraints, or hardware bring-up tests.
---




# GateMate Firmware ROM, BRAM, and UART Bring-Up

## 0. Purpose and required outcome

A processor bitstream is useful only when the FPGA contains the intended firmware and the processor can communicate with external hardware. RTL simulation is not sufficient evidence for either condition. A testbench can initialize internal arrays directly, while the synthesized netlist can contain an uninitialized or zero-initialized memory. A UART testbench can decode a correct serial waveform while the package pin, RP2040 UART input, or USB CDC interface remains incorrect.

This guide explains how PCA-Z80 now handles these concerns on the Olimex GateMateA1-EVB. It develops the design from the actual GateMate memory template through synthesis, primitive initialization, post-synthesis execution, package-pin direction, RP2040 firmware, and USB capture. The final acceptance evidence is concrete:

- Yosys maps the firmware ROM to one `CC_BRAM_20K` (`RAM_HALF: 1`).
- The generated `CC_BRAM_20K.INIT_*` parameters contain non-zero Z80 firmware.
- GateMate primitive netlist simulation executes that firmware and drives the LED after 51 clocks.
- The physical board loads successfully through DirtyJTAG.
- `/dev/ttyACM0` receives bytes `0x48 0x69`, the string `Hi`, from Z80 code executing on the FPGA.

> [!summary]
> A correct GateMate firmware ROM requires a registered read, sufficient logical capacity to trigger block-RAM mapping, a complete padded initialization file, and a build graph that generates the file before synthesis. Resource allocation, content initialization, execution, and external transport must each be verified separately.

## 1. The failure that motivated the investigation

The PCA-Z80 RTL and UART simulations passed, but the first hardware bitstream did not produce a visible Z80-driven blink and neither USB CDC port produced UART bytes. A hardware-counter test bitstream did blink the same LED. These observations constrained the problem:

1. FPGA configuration succeeded.
2. The 10 MHz board clock reached fabric logic.
3. `IO_SB_B6` was the correct LED pin.
4. The failure was inside the processor firmware path or UART path, not the board load path.

The original tests had a blind spot. `tb_z80_core.sv`, integration tests, and `tb_hello.sv` directly loaded an internal array:

```systemverilog
$readmemh("build/hello.hex", dut.u_core.u_memio.rom);
```

That proves the processor and UART work **when a testbench supplies firmware**. It does not prove the synthesis command embeds the same bytes into GateMate configuration memory. The distinction is the foundation of the debugging method in this guide.

## 2. Decompose the system before debugging

The bring-up path is a sequence of independent transformations. Each stage needs its own observable and acceptance rule.

```mermaid
flowchart LR
    ASM[Z80 assembly] --> HEX[512-byte padded hex]
    HEX --> RTL[RTL memory declaration]
    RTL --> YOSYS[Yosys synth_gatemate]
    YOSYS --> BRAM[CC_BRAM_20K plus INIT parameters]
    BRAM --> PNR[nextpnr placement and routing]
    PNR --> BIT[gmpack bitstream]
    BIT --> FPGA[GateMate SRAM configuration]
    FPGA --> CPU[Z80 fetch and retirement]
    CPU --> UART[FPGA UART TX waveform]
    UART --> RP[RP2040 UART0 RX]
    RP --> CDC[USB CDC0]
    CDC --> HOST[/dev/ttyACM0]
```

A single end-to-end failure does not identify which arrow is broken. The PCA-Z80 diagnostic ladder uses these stages:

| Stage | Claim | Independent observable |
|---|---|---|
| 1 | Board config, clock, and LED pin work | Hardware counter blinks LED |
| 2 | CPU reset releases and instructions retire | `DEBUG_LED_MODE=1`, LED from `dbg_count[17]` |
| 3 | Firmware artifact contains expected bytes | Inspect `build/top_prog.hex`, exact 512 lines |
| 4 | Firmware ROM maps to block RAM | `CC_BRAM_20K` / `RAM_HALF: 1` |
| 5 | BRAM contains firmware | Non-zero `INIT_*`; `check_gatemate_rom.py` |
| 6 | Synthesized CPU executes firmware | `make post_synth`, LED after 51 clocks |
| 7 | CPU issues UART transaction | `DEBUG_LED_MODE=2`, sticky `uart_seen` |
| 8 | Physical bridge transports bytes | ACM0 capture equals `48 69` |

Debug these stages in order. Do not infer a later stage from an earlier pass.

## 3. What representative GateMate projects do

The investigation began from the requested `PythonLinks/awesome-gatemate` index. The page and raw README are archived under `sources/gatemate/`. Representative projects were cloned under `/home/manuel/code/others/gatemate/`; exact commits are recorded in `sources/gatemate/repository-provenance.md`.

### 3.1 FemtoRV GateMate tutorial

`fm4dd/gatemate-riscv` gives the clearest progressive evidence. Step 3 explicitly studies block-RAM inference. It declares a memory large enough to cross the GateMate mapper's cost threshold and reports one `RAM_HALF`:

```verilog
reg [4:0] MEM [0:435];

always @(posedge clk) begin
    leds <= MEM[PC];
end
```

Later steps use a unified 1536×32 firmware RAM:

```verilog
reg [31:0] MEM [0:1535];

initial begin
    $readmemh("firmware.hex", MEM);
end

always @(posedge clk) begin
    if (mem_rstrb)
        mem_rdata <= MEM[word_addr];
    if (mem_wmask[0]) MEM[word_addr][7:0] <= mem_wdata[7:0];
    // other byte lanes omitted
end
```

The associated Makefile generates `firmware.hex` before synthesis and makes it a prerequisite of synthesis, implementation, and simulation. The firmware converter writes a complete image sized for the declared memory.

### 3.2 LiteX VexRiscv, SERV, and FazyRV

The Project Peppercorn GateMate cases contain generated LiteX RTL. Their processor size differs, but the ROM template is consistent:

```verilog
reg [31:0] rom[0:6092];
initial begin
    $readmemh("olimex_gatemate_a1_evb_rom.init", rom);
end
reg [31:0] rom_dat0;
always @(posedge sys_clk) begin
    rom_dat0 <= rom[main_basesoc_basesoc_adr];
end
```

The important properties are:

- The array is large enough to be an obvious block-RAM candidate.
- The read data is registered on the clock edge.
- The initialization file is a generated build artifact.
- ROM and writable SRAM are distinct arrays with distinct port behavior.

### 3.3 ColecoVision

The ColecoVision GateMate case packages the same pattern as a reusable module:

```verilog
module rom(
    input clk,
    input [11:0] addr,
    output reg [7:0] dout
);
    parameter MEM_INIT_FILE = "";
    reg [7:0] rom [0:4095];

    initial
        if (MEM_INIT_FILE != "")
            $readmemh(MEM_INIT_FILE, rom);

    always @(posedge clk)
        dout <= rom[addr];
endmodule
```

This is close to the required PCA-Z80 interface: byte-wide firmware, parameterized file, synchronous read.

### 3.4 LUTRAM stress test

`LUTRAM_Stress_Test` deliberately generates many small 16×10 distributed memories. Its purpose differs from firmware ROM: it measures distributed LUT memory capacity and deliberately avoids vendor-specific primitives. It is useful because it separates **small distributed memory** from **large block memory**. A small array can synthesize correctly without consuming BRAM, but that does not establish a safe firmware initialization path on this target.

## 4. GateMate and Yosys memory capabilities

The installed OSS CAD Suite contains the actual mapping specification:

- `/home/manuel/fpga/oss-cad-suite/share/yosys/gatemate/brams.txt`
- `/home/manuel/fpga/oss-cad-suite/share/yosys/gatemate/brams_map.v`

Copies are archived under `sources/gatemate/` for this ticket.

`brams.txt` describes `CC_BRAM_20K` and `CC_BRAM_40K` mapping options. Relevant facts:

- A 20K block supports port widths 1, 2, 5, 10, and 20 bits.
- A byte-wide logical ROM is mapped through a 10-bit physical width.
- Ports are synchronous (`clock anyedge`) and support clock enable.
- Initial contents are supported (`init no_undef`).
- Mapping is cost-based. A syntactically valid memory may remain LUT/register logic when too small.

The mapper's primitive capability is necessary but not sufficient. Yosys must recognize the RTL as a compatible synchronous memory, and the candidate must be large enough to beat logic implementation cost.

## 5. The controlled inference experiment

Ticket script `scripts/15-gatemate-rom-inference-matrix.py` synthesizes isolated initialized 8-bit ROMs across two read styles and seven depths. The experiment controls everything except read style and depth.

### 5.1 Probe template

```verilog
module romprobe #(parameter integer DEPTH = 256) (
    input wire clk,
    input wire [15:0] addr,
    output reg [7:0] q
);
    reg [7:0] mem [0:DEPTH-1];
    initial $readmemh("rom.hex", mem);

    // Synchronous case:
    always @(posedge clk)
        q <= mem[addr[$clog2(DEPTH)-1:0]];
endmodule
```

The asynchronous variant replaces the clocked block with `always @*`.

### 5.2 Measured results

| Read style | Depth | Logical bits | `CC_BRAM_20K` |
|---|---:|---:|---:|
| sync | 128×8 | 1024 | 0 |
| sync | 256×8 | 2048 | 0 |
| sync | **272×8** | **2176** | **1** |
| sync | 436×8 | 3488 | 1 |
| sync | 512×8 | 4096 | 1 |
| sync | 1024×8 | 8192 | 1 |
| sync | 2048×8 | 16384 | 1 |
| async | 128×8 through 2048×8 | 1024–16384 | 0 |

The measured transition for this toolchain and byte width is between 256 and 272 words. The PCA-Z80 baseline chooses **512×8**, not the minimum, so future firmware can grow without crossing the boundary accidentally.

> [!warning]
> The threshold is an observed Yosys cost decision for this toolchain, memory width, port shape, and synthesis options. It is not a universal GateMate silicon limit. Preserve the automated assertion rather than relying on the numeric threshold alone.

## 6. Memory shape and memory contents are different claims

The investigation exposed two independent failures.

### 6.1 Shape failure

The original 256×8 ROM was only 2048 logical bits and did not map to BRAM. Increasing to 512×8 with a synchronous read produced one `CC_BRAM_20K`.

This proved allocation, but not contents.

### 6.2 Content failure

The first 512×8 implementation combined a procedural zero-fill loop with a partial `$readmemh` file containing only 32 program bytes. Yosys produced a BRAM, but generated primitive parameters were all zero:

```verilog
CC_BRAM_20K #(
    .INIT_00(320'h0000...0000),
    // INIT_01 through INIT_3F also zero
) firmware_rom (...);
```

A resource report showing `RAM_HALF: 1` therefore coexisted with an empty firmware ROM.

The corrected flow generates a complete 512-byte image, removes the ROM zero-fill loop, and lets `$readmemh` provide the only ROM initialization. The generated primitive then contains non-zero initialization:

```text
INIT_00 = ...003800000320043e
```

The low-order sequence contains the opening blink bytes `3E 01 32 00 00 ...` in the GateMate mapper's packed format.

## 7. The production PCA-Z80 ROM design

### 7.1 RTL interface

The memory object is `pca_z80/rtl/obj_memio.sv`. It serves the held-request object bus and combines four responsibilities:

- read-only firmware ROM below `ROM_DEPTH`;
- small writable byte RAM outside the ROM region;
- memory-mapped GPIO write at address `0x0000`;
- memory-mapped UART transmit write at address `0x0001`.

Writes at addresses 0 and 1 are side effects even though reads at those addresses fetch ROM. This is intentional for the baseline's minimal I/O map.

### 7.2 Registered read

```systemverilog
logic [7:0] rom [0:ROM_DEPTH-1];
logic [7:0] rom_q;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rom_q <= 8'h00;
    end else if (sel && !captured) begin
        addr_q <= bus_req.addr;
        rom_q  <= rom[bus_req.addr[$clog2(ROM_DEPTH)-1:0]];
    end
end
```

The bus handshake naturally accommodates the registered latency:

```mermaid
sequenceDiagram
    participant D as Decode object
    participant M as obj_memio
    participant B as CC_BRAM_20K
    D->>M: req=1, address stable
    M->>B: register address on clock edge
    B-->>M: registered ROM byte
    M-->>D: ack=1, rdata valid
    D->>M: req=0
    M-->>D: ack=0; transaction released
```

The requester holds `req` and address stable until `ack`, so one synchronous memory cycle fits without changing the architectural bus contract.

### 7.3 Conditional synthesis initialization

```systemverilog
`ifdef ROM_FILE
    initial $readmemh(`ROM_FILE, rom);
`endif
```

Ordinary RTL tests leave `ROM_FILE` undefined and load the desired fixture explicitly. Hardware synthesis defines it on the Yosys command line. This prevents simulation from silently loading a stale default path.

RAM initialization is separate because RAM has different semantics and does not use the firmware file.

## 8. Firmware image generation API

The assembler API now supports exact output-image size without changing the default unpadded behavior.

### 8.1 CLI

```bash
python3 tools/zasm.py programs/blink.asm \
  -o build -n top_prog --size 512
```

Outputs:

- `build/top_prog.hex`: exactly 512 lines, one byte per line;
- `build/top_prog.bin`: exactly 512 bytes;
- `build/top_prog.lst`: listing for actual source instructions;
- `build/top_prog.sym.json`: symbols.

Unused bytes are `00` (`NOP`). The assembler rejects overflow:

```text
program is N bytes, exceeds requested image size 512
```

### 8.2 Python API

```python
image, symbols, listing = assemble(source)
write_outputs(
    image,
    symbols,
    listing,
    out_dir="build",
    name="top_prog",
    size=512,
)
```

The default `size=None` preserves compact output for unit and integration tests.

### 8.3 Build dependency

The synthesis target runs assembly before Yosys:

```make
ROM_DEPTH ?= 512

synth:
	python3 tools/zasm.py programs/$(PROG).asm \
	  -o $(BUILD) -n top_prog --size $(ROM_DEPTH)
	yosys ... -DROM_FILE="$(BUILD)/top_prog.hex" ...
```

A clean build cannot synthesize a prior firmware image accidentally because generation and synthesis are in one target dependency chain.

## 9. Three levels of firmware verification

### 9.1 Artifact verification

Check exact size and opening bytes:

```bash
wc -l build/top_prog.hex       # 512
head -8 build/top_prog.hex     # 3E, 01, 32, 00, ... for blink
```

This proves assembler output only.

### 9.2 Primitive allocation and initialization verification

`make post_synth` converts Yosys JSON back into a primitive netlist and runs:

```bash
python3 tools/check_gatemate_rom.py build/top_synth.v
```

The checker requires:

1. exactly one `CC_BRAM_20K` for the baseline ROM;
2. at least one BRAM `INIT_*` parameter;
3. at least one non-zero initialization parameter.

Expected output:

```text
PASS: 1 CC_BRAM_20K; non-zero firmware INIT (sample ...003800000320043e)
```

This proves allocation and encoded contents, but not execution.

### 9.3 Post-synthesis execution verification

`sim/tb_post_synth.sv` compiles:

- the generated `build/top_synth.v`;
- Yosys GateMate primitive models (`cells_sim.v`);
- the local `CC_USR_RSTN` simulation model.

It clocks the synthesized netlist and requires blink firmware to drive the LED within 3000 clocks. Current evidence:

```text
PASS: post-synth initialized ROM executed; LED=1 after 51 cycles
```

This proves the synthesized primitive netlist contains executable firmware and the CPU reaches memory-mapped GPIO.

## 10. Debug LED modes

`top.sv` provides a synthesis parameter for stage-specific hardware observations:

| `DEBUG_LED_MODE` | LED source | Question answered |
|---:|---|---|
| 0 | `gpio[0]` | Did the program execute its GPIO write? |
| 1 | `dbg_count[17]` | Is the CPU retiring instructions? |
| 2 | sticky `uart_seen` | Did the CPU issue at least one UART transaction? |

Build examples:

```bash
make bit PROG=blink DEBUG_LED_MODE=0   # production GPIO blink
make bit PROG=blink DEBUG_LED_MODE=1   # CPU retirement heartbeat
make bit PROG=hello DEBUG_LED_MODE=2   # UART-start proof
```

The UART mode latches the event:

```systemverilog
always_ff @(posedge clk_10m or negedge rst_n) begin
    if (!rst_n) uart_seen <= 1'b0;
    else if (uart_start) uart_seen <= 1'b1;
end
```

A pulse at 115200 baud is too short for visual inspection. A sticky latch converts the event into a stable board-level observable without changing UART behavior.

## 11. Physical UART direction

The board schematic and DirtyJTAG firmware define direction. `pico-dirtyJtag` configures:

```c
#define PIN_UART0_TX 12
#define PIN_UART0_RX 13
```

The Olimex schematic connects:

| RP2040 function | RP GPIO | FPGA pin | FPGA direction |
|---|---:|---|---|
| UART0 TX | GPIO12 | `IO_SA_A6` | FPGA RX input |
| UART0 RX | GPIO13 | `IO_SA_B6` | FPGA TX output |

Therefore PCA-Z80 constraints are:

```text
Pin_out "uart_tx_pin" Loc = "IO_SA_B6";
Pin_in  "uart_rx_pin" Loc = "IO_SA_A6";
```

Do not infer direction from `DBG-UART_TX` alone. That net name describes RP2040 UART direction; the FPGA side is opposite.

## 12. USB CDC interface selection

The connected DirtyJTAG device exposes five USB interfaces and two ACM devices:

| Linux device | USB interface | DirtyJTAG bridge | RP pins |
|---|---:|---|---|
| `/dev/ttyACM0` | 01, “DirtyJTAG CDC 0” | UART0 | GPIO12/13 |
| `/dev/ttyACM1` | 03, “DirtyJTAG CDC 1” | UART1 | GPIO4/5 |

The Olimex FPGA debug UART is wired to UART0, so read `/dev/ttyACM0`.

Configure it as 115200 8N1 raw:

```bash
stty -F /dev/ttyACM0 115200 cs8 -cstopb -parenb -ixon raw
```

For a one-shot startup message, open the reader **before** FPGA configuration:

```bash
rm -f /tmp/acm0.bin
(timeout 8 cat /dev/ttyACM0 > /tmp/acm0.bin) & reader=$!
sleep 1
openFPGALoader -b olimex_gatemateevb build/top.bit
wait "$reader" || true
xxd /tmp/acm0.bin
```

Expected physical evidence for `hello.asm`:

```text
00000000: 4869  Hi
```

This procedure prevents missing bytes emitted immediately after configuration reset releases.

## 13. Place-and-route reproducibility

The BRAM-backed design exposed seed sensitivity in router2. Seed 0 remained at one overused wire after more than 3000 rip-up iterations. Seed 1 routed successfully.

The Makefile now declares:

```make
PNR_SEED ?= 1

nextpnr-himbaechel ... --router router2 --seed $(PNR_SEED)
```

The seed is overridable for experiments, but a default makes CI and intern work reproducible. Current final hello build uses one `RAM_HALF` and meets all 10 MHz constraints; reported maximum frequencies exceed 26 MHz.

## 14. Recommended implementation sequence

When adding or modifying firmware memory, follow this order.

```pseudo
1. Define architectural behavior:
   address width, data width, read latency, write behavior, I/O aliases.

2. Write a target-compatible memory template:
   array declaration;
   conditional readmemh;
   clocked output register.

3. Generate a complete image:
   assemble source;
   reject overflow;
   pad to declared depth;
   make it a synthesis dependency.

4. Run RTL tests:
   model tests;
   object-graph differential tests;
   integration programs;
   UART waveform decoder.

5. Run isolated inference test if geometry changed:
   synthesize memory alone;
   inspect CC_BRAM count.

6. Inspect synthesized primitive contents:
   write primitive netlist;
   require non-zero INIT parameters.

7. Run post-synthesis execution test:
   compile GateMate cells_sim + netlist;
   require firmware-visible output.

8. Place and route with recorded seed:
   require RAM_HALF count;
   require timing pass.

9. Load board and test observables in order:
   hardware counter;
   CPU heartbeat;
   program GPIO;
   sticky UART event;
   CDC byte capture.
```

This sequence localizes failures. It also produces durable evidence at each transformation boundary.

## 15. Failure-mode reference

| Symptom | Likely stage | Test | Resolution |
|---|---|---|---|
| Hardware counter does not blink | config/clock/pin | counter-only bitstream | fix board, CCF, load path |
| Counter blinks; CPU heartbeat does not | reset/core | `DEBUG_LED_MODE=1` | inspect reset and fetch |
| RTL passes; `RAM_HALF=0` | memory shape/size | inference matrix | registered read; increase depth |
| `RAM_HALF=1`; `INIT_*` all zero | image/init | `check_gatemate_rom.py` | full padded file; one ROM initializer |
| `INIT_*` non-zero; post-synth LED fails | mapper/latency/core | `make post_synth` | inspect primitive ports and handshake |
| Post-synth passes; GPIO board fails | PnR/pin/build selection | load exact artifact; debug LED modes | verify seed, CCF, loaded filename |
| UART sim passes; sticky UART LED off | program/core UART request | `DEBUG_LED_MODE=2` | inspect memory-mapped write path |
| Sticky UART LED on; ACM0 empty | physical UART/bridge | scope/pin table/CDC descriptors | verify IO_SA_B6 and DirtyJTAG UART0 |
| ACM1 empty | expected | interface table | use ACM0 |
| One-shot bytes missing intermittently | reader starts too late | pre-open reader | open CDC before loading FPGA |
| Router2 never finishes | seed congestion | alternate seed | use deterministic seed 1 |

## 16. APIs and file map

### Memory and top-level RTL

- `pca_z80/rtl/obj_memio.sv`
  - Parameters: `ROM_DEPTH=512`, `RAM_WORDS=256`.
  - Inputs/outputs: held-request `bus_req`/`bus_resp`, GPIO byte, UART byte/start/ready.
  - Firmware compile macro: `ROM_FILE`.
- `pca_z80/rtl/top.sv`
  - Parameters: `ROM_DEPTH`, `DEBUG_LED_MODE`.
  - Instantiates reset synchronizer, Z80 core, and UART transmitter.
- `pca_z80/rtl/uart_tx.sv`
  - Parameters: `CLK_HZ=10_000_000`, `BAUD=115_200`.
  - Interface: `start`, `data`, `ready`, `tx`.

### Tooling

- `pca_z80/tools/zasm.py`
  - CLI `--size` pads `.hex` and `.bin`.
  - `write_outputs(..., size=N)` Python API.
- `pca_z80/tools/check_gatemate_rom.py`
  - Input: synthesized Verilog primitive netlist.
  - Checks BRAM count and non-zero init.
- `pca_z80/Makefile`
  - Variables: `PROG`, `ROM_DEPTH`, `DEBUG_LED_MODE`, `PNR_SEED`.
  - Targets: `test`, `sim_hello`, `synth`, `post_synth`, `pnr`, `bit`, `load`.

### Evidence and research

- `sources/gatemate/awesome-gatemate.md`: archived requested webpage.
- `sources/gatemate/repository-provenance.md`: commits and file anchors.
- `sources/gatemate/rom-inference-matrix-results.txt`: measured matrix.
- Ticket `scripts/15-gatemate-rom-inference-matrix.py`: reproducible experiment.
- Diary Step 23: full chronological debugging record, including failed hypotheses.

## 17. Commands for an intern

### Fast regression

```bash
cd /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80
source ~/fpga/oss-cad-suite/environment
make test
make sim_hello
```

### Prove hardware firmware survives synthesis

```bash
make post_synth PROG=blink
```

Expected:

```text
PASS: 1 CC_BRAM_20K; non-zero firmware INIT (...)
PASS: post-synth initialized ROM executed; LED=1 after 51 cycles
```

### Build and load visible blink

```bash
make bit PROG=blink DEBUG_LED_MODE=0 PNR_SEED=1
openFPGALoader -b olimex_gatemateevb build/top.bit
```

### Build and capture physical UART

```bash
make bit PROG=hello DEBUG_LED_MODE=2 PNR_SEED=1
stty -F /dev/ttyACM0 115200 cs8 -cstopb -parenb -ixon raw
(timeout 8 cat /dev/ttyACM0 > /tmp/acm0.bin) & reader=$!
sleep 1
openFPGALoader -b olimex_gatemateevb build/top.bit
wait "$reader" || true
xxd /tmp/acm0.bin
```

Expected: `4869`.

## 18. Design decisions

### DR-ROM-1 — Registered-read inferred ROM

- **Decision:** Use a clocked output register and inferred memory, not an asynchronous array or hand-instantiated primitive.
- **Evidence:** All representative GateMate projects use registered reads; inference matrix maps async cases to no BRAM.
- **Consequence:** Object bus accounts for one-cycle latency through held request/ack.
- **Status:** accepted.

### DR-ROM-2 — 512-byte baseline depth

- **Decision:** Declare 512×8 although current programs are smaller than 64 bytes.
- **Evidence:** 256×8 does not map BRAM; 272×8 does; 512 provides headroom and maps one 20K half.
- **Consequence:** Hardware images are padded to 512 bytes.
- **Status:** accepted.

### DR-ROM-3 — Complete generated image is authoritative

- **Decision:** The assembler emits the entire physical ROM image for synthesis; RTL does not mix a ROM zero-fill loop with partial `$readmemh`.
- **Evidence:** Mixed initialization yielded all-zero primitive `INIT_*`; full image yielded non-zero init and passed gate simulation.
- **Status:** accepted.

### DR-ROM-4 — Verify content after synthesis

- **Decision:** `make post_synth` is a required firmware-memory gate.
- **Evidence:** RTL and resource checks both passed while synthesized contents were wrong.
- **Status:** accepted.

### DR-UART-1 — Electrical direction controls pin naming

- **Decision:** FPGA TX is `IO_SA_B6`, connected to RP2040 GPIO13/UART0_RX. FPGA RX is `IO_SA_A6`.
- **Evidence:** Board schematic, RP2040 pin functions, pico-dirtyJtag definitions, and physical `Hi` capture.
- **Status:** accepted.

## 19. Working rules

- Do not call a memory "working" because RTL simulation loaded it.
- Do not call a memory "initialized" because a BRAM resource appears.
- Do not call a UART "working on hardware" because a testbench decoded it.
- Use one observable per layer and keep observables selectable at build time.
- Preserve exact external repository commits and toolchain versions for inference research.
- Keep firmware generation in the Make dependency graph.
- Run `make post_synth` whenever ROM width, depth, read style, init flow, or synthesis command changes.
- Open the USB reader before loading one-shot UART firmware.
- Use `/dev/ttyACM0` for the Olimex debug UART under the current DirtyJTAG firmware.
- Treat `PNR_SEED=1` as part of this build's reproducibility contract until router behavior is requalified.

## 20. Closing result

The PCA-Z80 firmware path is now verified at four levels: source assembly, synthesized primitive content, synthesized-netlist execution, and physical UART output. The final design uses an inferred 512×8 synchronous ROM mapped to one `CC_BRAM_20K`, with a complete padded initialization file generated immediately before synthesis. The physical board receives the bitstream over DirtyJTAG and emits `Hi` through the RP2040 UART0-to-CDC0 bridge.

The broader engineering result is the validation method. Each stage has an explicit artifact, command, and expected result. Future changes to firmware size, memory geometry, toolchain version, pin constraints, or UART behavior can be tested at the stage they affect instead of being diagnosed from a silent LED or empty terminal.
