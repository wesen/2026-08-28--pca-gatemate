# Sources — Plastic Cell Architecture (PCA)

Primary literature and reference material collected to design a **Z80 built on
Plastic Cell Architecture (PCA)** and deployed on the Olimex GateMateA1-EVB
(Cologne Chip CCGM1A1) FPGA. Downloaded and studied in this session.

## The founding idea (why PCA matters for this project)

PCA is a *dynamically reconfigurable hardware-based computer* proposed at NTT
(1998–1999) and later continued at Nagasaki University (Oguri Lab). Its central
claim, from the founding paper, is the direct justification for building a Z80
this way:

> "A von Neumann architecture is obtained if only one cell part is extracted.
> The memory corresponds to the plastic part and the built-in part can be
> compared with a mini CPU engine."
> — Nakada et al., *Plastic Cell Architecture: A Dynamically Reconfigurable
> Hardware-based Computer*, IPPS/SPDP'99 Workshops (Springer LNCS 1586),
> DOI 10.1007/BFb0097953.

In other words: a single PCA cell, isolated from the mesh, is already a tiny
CPU+memory pair. A Z80 is a von-Neumann-style CPU; mapping it onto PCA cells is
the canonical "implement a processor as wired logic on PCA" exercise.

## The "twice double structure" of general-purpose computing (Oguri Lab)

From the Oguri Lab PCA page (Nagasaki University), the conceptual frame:

- **von Neumann:** hardware = CPU+MEM, software = program logic. Changeable
  part of hardware = *content of MEM*. Fixed part of hardware = *CPU + MEM
  access scheme*.
- **PCA:** hardware = PCA, software = **wired logic**. Changeable part of PCA =
  *contents of many small memories (LUTs)*. Fixed part of PCA = *message routing
  network + connections of memories that form LUT-based logic*.

So "running a program on PCA" = **dynamically generating/deleting hardware
objects (wired-logic circuits) on a sea of LUT cells, glued together by a
message-routing cellular automaton.** A Z80 on PCA is a fixed (or slowly
reconfiguring) cluster of such objects.

## Files

| # | File | Paper | Year | Status |
|---|------|-------|------|--------|
| 01 | `01-PCA-dynamically-reconfigurable-IPPS-SPDP-1999-Nakada-BFb0097953.pdf` | Nakada, Oguri, Imlig, Inamori, Konishi, Ito, Nagami, Shiozawa — *Plastic Cell Architecture: A Dynamically Reconfigurable Hardware-based Computer* (IPPS/SPDP'99 WS, Springer LNCS 1586) | 1999 | ✅ full text |
| 02b | `02b-PCA-new-area-management-pressure-EUC-2005-Nagamoto-lab.pdf` | Nagamoto, Yano, Uchida, Shibata, Oguri — *New Area Management Method Based on "Pressure" for Plastic Cell Architecture* (IFIP EUC 2005, LNCS 3824) | 2005 | ✅ full text (lab copy) |
| 05 | `05-PCA-space-allocation-circuits-EUC-2005-Kyusaka.pdf` | Kyusaka, Higuchi, Nagamoto, Shibata, Oguri — *Evaluation of Space Allocation Circuits* (IFIP EUC 2005) | 2005 | ✅ full text |
| 06 | `06-PCA-Oguri-lab-activity.ppt` | Oguri Lab — *Recent Activity* slides (Japanese) | 2006 | ✅ deck |

**Open-but-paywalled (abstracts studied, not downloaded):**

- Nagami, Oguri, Shiozawa, Ito, Konishi — *Plastic cell architecture: A scalable
  device architecture for general-purpose reconfigurable computing*, IEICE Trans.
  Electron. **E81-C**(9):1431, 1998 (10.1587/e81-c_9_1431). IEEE version: FCCM'98
  (10.1109/FCCM.1998.707883).
- Ito, Oguri, Nagami, Konishi, Shiozawa — *The plastic cell architecture for
  dynamic reconfigurable computing*, IEEE RAW'98 (10.1109/RSP.1998.676666).
- Ito, Konishi, Nakada, Oguri, Inamori, Nagoya — *Dynamically Reconfigurable
  Logic LSI—PCA-1: The First Realization of the Plastic Cell Architecture*, IEICE
  Trans. Inf. **E86-D**(5):859, 2003 (10.1587/e86-d_5_859). Async-chip version:
  Konishi et al., *PCA-1: a fully asynchronous, self-reconfigurable LSI*, IEEE
  (10.1109/ASYNC.2000.914069).
- Amano — *A survey on dynamically reconfigurable processors*, IEICE Trans.
  Commun. **E89-B**(12):3179, 2006 (10.1093/ietcom/e89-b.12.3179).

## Key technical facts extracted (evidence-anchored)

### PCA cell = dual structure (paper 01, §2.1)

A **plastic cell** has two parts, both on one LSI, tiled in a 2D orthogonal mesh:

- **Plastic part (PP-plane)** — the *variable/changeable* part. A "sea of LUTs":
  an array of **basic cells**, each basic cell = **four 4-input LUTs + wires**.
  Only LUTs and wire — **no dedicated flip-flops, no global clock**. LUTs realize
  any logic, data branch, transfer, and storage (a flip-flop is a LUT looped back
  on itself). Per the EUC papers, the plastic part is an **8×8 array of basic
  cells**, each LUT is a 4-bit-address / 1-bit-output truth table (16-entry), i.e.
  a "16-bit LUT".
- **Built-in part (BP-plane)** — the *fixed* part. Forms a network of **cellular
  automata**. Its fixed functions are exactly three: (1) **reconfigure the plastic
  part**, (2) **data I/O to/from the plastic part**, (3) **mutual communication
  with adjacent plastic parts** (N/S/E/W routing).

### Objects, generation, communication (paper 01, §2.2)

- An **object** = a processing module made of several plastic parts, realized as
  **wired logic**. Objects are arranged to correspond to a **Data Flow Diagram**
  (paper 02b).
- Objects are **dynamically generated and deleted** by message passing through
  built-in parts. Allocation steps: (1) search & reserve free area, (2) inject
  behavior into the plastic part, (3) enable the new object, (4) open the
  built-in↔plastic message path, (5) operate, (6) on a release message, free the
  area.
- **Mother–child relationship:** only the mother object can release a child's
  resources.
- **Messages** are variable-length packets with three frame types: **routing
  command** (N/S/E/W, exact/static routing, *not* adaptive), **payload**
  (configuration command + data), **trailer** (clear). Built-in parts process the
  routing frames.
- **Async:** PCA uses **asynchronous circuits** with a **bundled protocol,
  four-cycle signaling** (paper 02b §2.1). No global clock → easy to splice in a
  new object without retiming.

### Design flow / mapping logic to plastic parts (paper 01, §3)

The plastic part is a **"relocatable PLA"**. Three mapping routes:

- **(a) Conventional FPGA flow:** technology mapping → placement → routing →
  (back-track on unrouted wires).
- **(b) ASIC-style for PCA:** technology mapping → primary placement → routing →
  channel insertion → load. Simpler than (a) because PCA is homogeneous; **grid
  model + Dijkstra routing** apply directly.
- **(c) PLA design scheme (preferred):** HDL → **SOP (sum-of-products) synthesis**
  → graph embedding → placement & routing → load. No separate place/route stage;
  ideal for compact FSMs (e.g. a CPU control unit).

### Area management = "pressure" (papers 02b, 05) — malloc/new for wired logic

- PCA needs a hardware analog of `malloc`/`new` so objects can grow at runtime,
  but a central "domain administrator" serializes parallel objects and risks
  deadlock.
- **Pressure method:** when object B needs a new object B', B broadcasts a
  **pressure command** to neighbors; neighbors **slide to vacant cells**, then B
  materializes B' in the freed space. Performed independently in many places
  simultaneously — no administrator.
- Built-in part cell for pressure: **5 ports (N/S/E/W + feedback)**, a state
  machine (vacant/circuit/receiving-pressure), a switch to limit accepted input
  directions; **wormhole routing, no-wait (non-blocking) issue** to avoid
  deadlock (commands may be overwritten rather than stall).
- **Measured cell cost (paper 05):** **200 gates per PCA cell**, **3.55 ns** max
  delay per cell; a 3×3 PCA cell block running six space-allocation commands
  consumes **306.3 µW**.

### VLSI density argument (paper 01, §4.1)

PCA's plastic part is *pure memory structure*, so it rides the DRAM density curve
(memory quadruples / 3 yr vs MPU doubles / 3 yr). A 32-bit array multiplier: ASIC
≈ 51k transistors; PCA ≈ 2000 basic cells ≈ 1.3M transistors — **25× more
transistors but only ~2.5× area** if PCA is 10× denser; converges as the density
gap widens. Lesson for the GateMate port: PCA is area-hungry vs hand-rolled RTL,
but the CCGM1A1 (~40k LUTs) is large enough for a small Z80 object graph.

### PCA-1 / PCA-2 chips (from abstracts + paper 02b §2.3)

- **PCA-1** (IEICE E86-D, 2003): first VLSI realization of PCA; **fully
  asynchronous**, homogeneous, dual-structured cell array enabling dynamic,
  autonomous reconfiguration. (Async version: IEEE ASYNC 2000.)
- **PCA-2** (paper 02b §2.3): higher integration + speed; can **partially change
  its composition based on data the objects themselves generate**.
- **Bit Serial PCA** (paper 02b §2.2): each plastic part = a **state machine +
  shift register**; bit-serial suits PCA because reconfiguration switches live in
  the wiring (parallel adds skew/overhead), and PCA lays operation circuits along
  the data flow. Compact + high speed; a strong fit for a bit-serial Z80
  datapath.

## How these sources drive the Z80-on-PCA design

1. **Cell as CPU+MEM** (paper 01 §5) → map Z80 registers/ALU/control as a cluster
   of PCA objects (PP-plane wired logic) with BP-plane message routing between
   them.
2. **Object = DFG node** (paper 02b) → decompose the Z80 into a data-flow graph of
   objects: register file, ALU, flags, instruction decode/FSM, memory interface,
   each a small cluster of plastic parts.
3. **PLA/SOP mapping** (paper 01 §3, route c) → synthesize the Z80 control FSM as
   sum-of-products and embed it as a relocatable PLA — exactly the "compact FSM"
   case the paper calls out.
4. **Async + four-cycle bundled protocol** (paper 02b) → no global clock across
   objects; use request/ack handshakes between Z80 objects (mirrors the held-
   request discipline from the sibling MATE-16 project).
5. **Pressure/area management** (papers 02b, 05) → for the baseline (fixed Z80),
   we place objects statically; pressure is reserved as an extension to
   dynamically grow an object (e.g. instantiate an extra register bank on an
   `EXX`).
6. **Bit-serial datapath option** (paper 02b §2.2) → a bit-serial Z80 ALU/plastic
   part keeps the cell graph small enough to fit the CCGM1A1; document the
   bit-parallel vs bit-serial tradeoff.
7. **Cell cost budget** (paper 05) → 200 gates/cell, 3.55 ns/cell; use to estimate
   the Z80 object-graph footprint and the achievable clock on GateMate.

## Related prior project (sibling workspace)

`../2026-08-25--vm-cpu-gatemate/` — the **MATE-16** bytecode VM CPU on the same
GateMate board, built with the same OSS CAD Suite toolchain and the same
held-request bus / precise-fault discipline. The PCA-Z80 ticket reuses that
project's toolchain, board pin reference, and verification-pyramid methodology.
The MATE-16 intern guide (`.../design-doc/02-mate-16-system-intern-onboarding-guide.md`)
is the structural template for this ticket's intern guide.
