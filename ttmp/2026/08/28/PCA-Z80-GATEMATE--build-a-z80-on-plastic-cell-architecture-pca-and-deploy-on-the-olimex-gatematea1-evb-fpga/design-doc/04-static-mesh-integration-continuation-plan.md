---
Title: Static Mesh Integration Continuation Plan
Ticket: PCA-Z80-GATEMATE
Status: active
Topics:
    - pca
    - reconfigurable-computing
    - z80
    - asynchronous
    - fpga
    - rtl
    - cpu-design
    - toolchain
    - verification
    - hardware
    - software-tools
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/pca_mesh.sv
      Note: Existing tested packet-routing substrate targeted by continuation integration
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/z80_core.sv
      Note: Proven direct-bus object graph retained as the differential reference
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/z80_obj.sv
      Note: Existing held-request object transaction contract to adapt to mesh packets
ExternalSources: []
Summary: "Six-phase continuation plan that closes the skipped static placer and mesh-integration work before attempting pressure-based dynamic placement."
LastUpdated: 2026-08-28T20:55:00-04:00
WhatFor: "Define phase boundaries, acceptance gates, commits, diary updates, and thermal work-slip checkpoints for the next PCA-Z80 implementation sequence."
WhenToUse: "Read before starting any continuation phase after the proven direct-bus hardware baseline."
---

# Static Mesh Integration Continuation Plan

## Executive summary

The direct-bus PCA-Z80 baseline is complete: assembled firmware executes from
initialized GateMate block RAM, the user LED visibly blinks, and physical UART
emits `Hi`. The major omitted baseline deliverable is **static placement and
transport of object transactions over `pca_mesh`**. This is Phase 5 in the
original onboarding plan. Runtime pressure-based placement remains an original
Phase 7 extension and must not be started until static integration passes.

The continuation uses six independently reviewable phases. Every phase begins
with a printed thermal start slip, ends only after its acceptance commands pass,
updates the strict-format diary, receives a focused commit, and then prints a
completion slip containing the commit QR.

## Scope correction and phase mapping

The printed continuation phases P1–P6 are operational checkpoints, not a
renumbering of the original architecture plan:

| Continuation | Original plan | Purpose |
|---|---|---|
| P1 | Baseline audit | Reconcile stale tasks and freeze the proven entry state |
| P2 | Phase 5 design | Define placer, packet adapter, and generated-artifact contracts |
| P3 | Phase 5 tooling | Implement deterministic static placement and routing artifacts |
| P4 | Phase 5 RTL | Carry object transactions over the mesh in simulation |
| P5 | Phase 5 exit + Phase 6 regression | Differential, synthesis, timing, and physical validation |
| P6 | Handoff | Final reports, diary, task closure, vault, and reMarkable publication |

Original Phase 7 pressure-based placement is a separate follow-on decision. It
is not implicitly included in P1–P6.

## Preserved baseline

The following evidence is the non-regression floor:

- 49 model tests, 22 assembler tests, and 6 integration tests pass.
- `make sim_hello` decodes UART bytes `48 69`.
- `make post_synth` proves one initialized `CC_BRAM_20K` and firmware execution.
- The direct-bus `z80_core` physically blinks and emits `Hi` through CDC0.
- `DEBUG_LED_MODE=0`, `ROM_DEPTH=512`, and `PNR_SEED=1` remain the production
  hardware settings.

The direct-bus core remains buildable as the reference path until P5 proves the
mesh-backed path. No phase may delete its tests merely to make integration
simpler.

## Phase P1 — Reconcile the baseline

### Deliverables

- Close stale task 27 and physical/report tasks 49–51.
- Correct stale task annotations for IX/IY scope, test counts, resources, BRAM,
  board load, UART, and report state.
- Add explicit P1–P6 continuation tasks.
- Publish this mapping document.

### Exit gate

- `docmgr task list --ticket PCA-Z80-GATEMATE` accurately distinguishes done,
  deferred ISA work, static mesh work, and Phase 7 extensions.
- `docmgr doctor --ticket PCA-Z80-GATEMATE --stale-after 30` passes.

## Phase P2 — Define placer and transport contracts

### Deliverables

- Input schema for object identity, footprint, mesh dimensions, and communication
  edges.
- Deterministic output schema for coordinates, route metadata, and a versioned
  generated artifact.
- Packet encoding that maps held-request operations to `msg_t` without losing
  object id, sub-operation, address, data, acknowledgement, or fault semantics.
- Arbitration and backpressure invariants.
- Test vectors and rejection cases before implementation.

### Exit gate

A design review can answer exactly what `placer.py` consumes and emits, how an
object request crosses the mesh and returns an acknowledgement, and which
invariants tests must enforce. No RTL or placer implementation starts before
this contract is committed.

## Phase P3 — Implement deterministic static placement

### Deliverables

- `pca_z80/tools/placer.py` with no random default behavior.
- Unit tests for valid placement, stable output, capacity failure, duplicate
  identity, unreachable route, and malformed schema.
- A checked or reproducibly generated placement artifact for the six Z80
  objects.
- Makefile dependency wiring and a stale-artifact check.

### Exit gate

Two runs on the same input produce byte-identical output; invalid graphs fail
with actionable diagnostics; all existing fast regressions remain green.

## Phase P4 — Integrate mesh transport in simulation

### Deliverables

- Request and response adapters between `z80_obj` transactions and `msg_t`.
- Placed object endpoints connected through `pca_mesh`.
- Tests for held request, backpressure, single acceptance, response correlation,
  reset, and fault propagation.
- Mesh-backed integration mode alongside the direct-bus reference mode.

### Exit gate

The assembled self-test and integration programs run through mesh transport
with zero model divergence. Transaction counts prove no doubled side effects.

## Phase P5 — Verify, synthesize, and validate hardware

### Deliverables

- Full direct-bus and mesh-backed regression matrix.
- Deterministic synthesis/PnR resource and timing ledger.
- Preserved BRAM initialization and post-synthesis execution checks.
- Physical blink and UART acceptance for the mesh-backed image if it fits and
  meets timing.

### Exit gate

All tests pass from a clean checkout; timing passes at 10 MHz; physical blink
and UART are observed; any resource/performance delta is documented against the
proven direct-bus baseline.

## Phase P6 — Final handoff

### Deliverables

- Updated engineering report, intern guide, diary, task ledger, and changelog.
- Versioned reMarkable bundle.
- Append-only Obsidian follow-up note if the architecture materially changes.
- Final focused documentation commit and clean working trees.

### Exit gate

`docmgr doctor` passes, publication targets are verified, all explicit tasks map
to evidence, and no required continuation work remains.

## Commit, diary, and printing protocol

For every phase:

1. Print a phase-start slip stating scope and immediate acceptance gate.
2. Add a diary step with exact prompt context and the intended phase contract.
3. Implement in small independently observable increments.
4. Record failed commands and exact errors immediately.
5. Run the phase gate and the existing non-regression suite.
6. Update tasks, relations, and changelog.
7. Commit only the coherent phase change.
8. Print a phase-complete status slip with commit QR, tests, tricky points, and
   the next phase.

Intermediate commits are allowed when a phase contains a stable contract,
tooling, or RTL boundary that is independently reviewable.

## Risks and controls

- **Protocol mismatch:** keep direct-bus tests and define packet semantics first.
- **Double side effects:** preserve held-request and one-accept invariants in
  adapter and mesh tests.
- **Generated artifact drift:** make generation deterministic and add a check.
- **Resource expansion:** measure after each RTL integration increment.
- **Hardware regression:** retain BRAM INIT, primitive execution, LED, and UART
  acceptance rather than relying on synthesis success.
- **Scope inflation:** static placement precedes pressure-based runtime placement.

## Open questions for P2

- Should one PCA cell represent one object endpoint, or may an object reserve a
  rectangular footprint?
- Does the first mesh integration carry one request and response packet per
  transaction, or model request/ack as held levels at endpoint adapters?
- Is return routing encoded explicitly, computed by XY routing from source
  coordinates, or stored in the generated artifact?
- Which response correlation field is required when the initial implementation
  permits only one transaction in flight?
- Should generated placement be SystemVerilog include data, memory hex, JSON, or
  a pair of machine and review formats?

These questions must be resolved by evidence from the current RTL and PCA
literature during P2.

## References

- `design-doc/01-pca-z80-system-intern-onboarding-guide.md`, §§11.3 and 13.
- `design-doc/02-pca-z80-engineering-report.md`, current limitations.
- `design-doc/03-gatemate-firmware-rom-bram-and-uart-bring-up-intern-guide.md`.
- `pca_z80/rtl/pca_types.sv`, `pca_router.sv`, `pca_mesh.sv`.
- `pca_z80/rtl/z80_obj.sv`, `z80_core.sv`.
