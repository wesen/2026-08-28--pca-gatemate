---
Title: Static Placer and Mesh Transport Contract
Ticket: PCA-Z80-GATEMATE
Status: active
Topics:
    - pca
    - reconfigurable-computing
    - z80
    - rtl
    - software-tools
    - verification
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/pca_mesh.sv
      Note: Existing local endpoint arrays indexed by row-major cell id
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/pca_router.sv
      Note: Existing single-packet held-request forwarding and local priority behavior
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/pca_types.sv
      Note: Existing 67-bit packet and deterministic XY route contract
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/z80_core.sv
      Note: Proven direct-bus reference behavior and six-object topology
    - Path: /home/manuel/code/wesen/2026-08-28--pca-gatemate/pca_z80/rtl/z80_obj.sv
      Note: Existing 38-bit request and 17-bit response semantics to preserve
    - Path: repo://pca_z80/config/z80_objects.json
      Note: Canonical six-object input graph (commit 921fabc)
    - Path: repo://pca_z80/rtl/z80_mesh_adapter.sv
      Note: Implemented request/response state machines (commit 0bb600b)
    - Path: repo://pca_z80/rtl/z80_mesh_core.sv
      Note: Generated endpoint and PCA mesh integration (commit 0bb600b)
    - Path: repo://pca_z80/sim/run_mesh_integ.py
      Note: Mesh differential and transaction conservation harness
    - Path: repo://pca_z80/sim/test_placer.py
      Note: Executable valid and rejection vectors (commit 921fabc)
    - Path: repo://pca_z80/tools/placer.py
      Note: Deterministic contract implementation (commit 921fabc)
ExternalSources: []
Summary: Normative contract for deterministic static object placement, generated artifacts, request/response packet encoding, endpoint handshakes, and pre-implementation acceptance tests.
LastUpdated: 2026-08-28T21:15:00-04:00
WhatFor: Freeze all observable placer and mesh-adapter behavior before implementing continuation phases P3 and P4.
WhenToUse: Use when writing placer.py, placement tests, generated placement packages, endpoint adapters, or mesh-backed integration tests.
---







# Static Placer and Mesh Transport Contract

## 1. Status and normative language

This document is the continuation P2 contract. `MUST`, `MUST NOT`, `SHOULD`,
and `MAY` are normative. P3 implements placement tooling; P4 implements RTL
transport. Contract changes after P2 require a separate reviewed commit and a
diary entry explaining the violated assumption.

This is **logical endpoint placement** on the tested PCA packet mesh. It does
not claim that an object's LUTs are physically relocated at runtime. The direct
object modules remain ordinary synthesized RTL connected to selected local mesh
ports. Runtime pressure-based configuration is original Phase 7 and outside
this contract.

## 2. Evidence from current RTL

The contract follows five existing constraints:

1. `pca_types::msg_t` is 67 bits: command, destination coordinate, source
   coordinate, 16-bit address, and 16-bit data.
2. `pca_router` allows one packet per router, uses fixed local-first input
   priority, and holds each forwarded request until acknowledgement.
3. `pca_mesh` exposes one bidirectional local endpoint per cell, with cell id
   `y * cols + x`.
4. `z80_obj::bus_req_t` has one master request containing `we`, target object,
   address, and write data. `bus_resp_t` contains acknowledgement and read data.
5. `z80_core` permits only one decode transaction in flight. Only the selected
   slave acknowledges; response arbitration therefore has no transaction id.

These constraints favor a conservative request/response adapter rather than a
new multi-request protocol.

## 3. Decisions

### D1 — One logical object endpoint per cell

Each of the six objects occupies one logical mesh endpoint in the first static
integration. Footprints are fixed to 1×1. The input schema carries footprint
fields so later designs can reject rather than silently truncate larger
objects, but P3 MUST reject any footprint other than `{w: 1, h: 1}`.

### D2 — Every object operation returns a response packet

Reads and writes both produce `CMD_RESP`. Router acknowledgement is a link and
delivery handshake, not the architectural `bus_resp.ack`. The decode adapter
asserts architectural acknowledgement only after receiving and validating the
response packet. Uniform responses avoid different completion semantics for
reads and writes and leave room for later status encoding.

### D3 — One end-to-end transaction in flight

The decode adapter MUST NOT inject a second request until the response to the
first has been accepted and the architectural requester has deasserted `req`.
No transaction id is required in the baseline. This follows the current decode
FSM and prevents response ambiguity.

### D4 — Coordinates route packets; route paths are review metadata

Runtime routers continue to compute exact X-then-Y routing from packet
coordinates. The placer emits Manhattan paths for validation and review, but
RTL MUST NOT depend on a programmed next-hop table in this phase.

### D5 — JSON is canonical; SystemVerilog package is generated

A canonical, stable JSON artifact supports tests and human inspection. P3 also
emits a generated SystemVerilog package containing object coordinates and mesh
constants. Both files MUST derive from the same in-memory validated placement.
The JSON is the source artifact; generated SV MUST include the JSON content
SHA-256 in a comment.

### D6 — Deterministic weighted greedy placement

Objects are ordered by descending weighted degree, then ascending numeric id,
then name. Fixed objects are reserved first. Each unplaced object chooses the
free cell minimizing weighted Manhattan distance to already placed neighbors;
ties resolve by row-major `(y, x)`. If it has no placed neighbor, choose the
first row-major free cell.

The algorithm is intentionally simple and testable. Global optimization and
pressure-based movement are not P3 requirements.

## 4. Canonical input schema

The file name SHOULD be `config/z80_objects.json`.

```json
{
  "schema": "pca-placement-input/v1",
  "mesh": {"cols": 3, "rows": 3},
  "objects": [
    {"id": 0, "name": "decode", "footprint": {"w": 1, "h": 1}},
    {"id": 1, "name": "pc",     "footprint": {"w": 1, "h": 1}},
    {"id": 2, "name": "mem",    "footprint": {"w": 1, "h": 1}},
    {"id": 3, "name": "reg",    "footprint": {"w": 1, "h": 1}},
    {"id": 4, "name": "alu",    "footprint": {"w": 1, "h": 1}},
    {"id": 5, "name": "flags",  "footprint": {"w": 1, "h": 1}}
  ],
  "edges": [
    {"src": 0, "dst": 1, "weight": 1},
    {"src": 0, "dst": 2, "weight": 1},
    {"src": 0, "dst": 3, "weight": 1},
    {"src": 0, "dst": 4, "weight": 1},
    {"src": 0, "dst": 5, "weight": 1}
  ]
}
```

### Input field rules

| Field | Rule |
|---|---|
| `schema` | MUST equal `pca-placement-input/v1` |
| `mesh.cols`, `mesh.rows` | integers 1–255; product MUST cover all objects |
| `objects[].id` | unique integer 0–15; MUST match `z80_obj` id |
| `objects[].name` | unique non-empty lowercase identifier |
| `footprint` | required and exactly 1×1 in v1 |
| `fixed` | optional `{x,y}`; coordinate must fit and be unique |
| `edges[].src/dst` | must reference distinct defined object ids |
| `edges[].weight` | positive integer; duplicate directed pairs forbidden |

Edges describe expected communication cost. P3 treats cost as undirected for
placement by summing both directions between a pair. Output retains input edge
direction for review.

Unknown fields MUST be rejected. Silent schema evolution is forbidden.

## 5. Canonical output schema

Default JSON output SHOULD be `build/placement.json`; tests MAY write a temp
path. Stable JSON uses UTF-8, two-space indentation, sorted keys, and exactly
one trailing newline.

```json
{
  "schema": "pca-placement/v1",
  "input_sha256": "<64 lowercase hex characters>",
  "mesh": {"cols": 3, "rows": 3},
  "placements": [
    {"id": 0, "name": "decode", "x": 1, "y": 0, "cell_id": 1}
  ],
  "routes": [
    {
      "src": 0,
      "dst": 1,
      "weight": 1,
      "hops": 1,
      "path": [{"x": 1, "y": 0}, {"x": 0, "y": 0}]
    }
  ],
  "metrics": {
    "objects": 6,
    "occupied_cells": 6,
    "weighted_hops": 7,
    "max_hops": 2
  }
}
```

### Output invariants

- `placements` sorted by numeric object id.
- `cell_id == y * cols + x`.
- All coordinates are in bounds and unique.
- Each route begins at the source placement and ends at the destination.
- Every path resolves X fully before Y and contains `hops + 1` coordinates.
- `hops` equals Manhattan distance.
- `weighted_hops` equals `sum(route.weight * route.hops)`.
- Repeated execution on byte-identical input emits byte-identical JSON and SV.

## 6. Generated SystemVerilog package

Default output is `build/pca_placement_pkg.sv`. P3 tested unpacked parameter
arrays against OSS CAD Suite Icarus 14, which reports:

```text
/tmp/test_pkg.sv:2: sorry: unpacked array parameters are not supported yet.
```

The implemented fallback is therefore one scalar coordinate and cell constant
per object:

```systemverilog
package pca_placement_pkg;
  localparam int PCA_COLS = 3;
  localparam int PCA_ROWS = 3;
  localparam int PCA_OBJECTS = 6;
  localparam logic [7:0] OBJ_DECODE_X = 8'd0;
  localparam logic [7:0] OBJ_DECODE_Y = 8'd0;
  localparam int OBJ_DECODE_CELL = 0;
  // OBJ_PC_*, OBJ_MEM_*, OBJ_REG_*, OBJ_ALU_*, OBJ_FLAGS_*
endpackage
```

A compile smoke test guards this package in `sim/test_placer.py`. Generated
code MUST NOT be hand-edited.

## 7. Packet encoding

### 7.1 Request packet

| `msg_t` field | Encoding |
|---|---|
| `cmd` | `CMD_WRITE` when `bus_req.we=1`, otherwise `CMD_READ` |
| `dest_x/y` | placement coordinate for `bus_req.obj` |
| `src_x/y` | decode endpoint coordinate |
| `addr` | `bus_req.addr`, unchanged |
| `data` | `bus_req.wdata`, unchanged; ignored by read target |

The decode adapter MUST reject an object id with no placement. In synthesizable
RTL this is a fault/assertion path, not coordinate zero fallback.

### 7.2 Response packet

| `msg_t` field | Encoding |
|---|---|
| `cmd` | `CMD_RESP` |
| `dest_x/y` | request `src_x/y` |
| `src_x/y` | target endpoint coordinate |
| `addr` | request `addr`, echoed |
| `data` | slave `bus_resp.rdata` for every operation |

`we` describes how the request presents operands or mutation intent; it does
not guarantee response data is irrelevant. In particular, ALU operations use
write-like requests carrying operands and return `{flags,result}`. Ordinary
memory/register writes naturally return zero under their existing object
contracts.

The decode adapter accepts a response only when command, destination, source,
and echoed address match the outstanding request. Unexpected packets MUST NOT
assert `bus_resp.ack`; simulation MUST report them as protocol errors.

### 7.3 Commands not used in baseline transport

- `CMD_CONFIG` remains reserved for original Phase 7 runtime configuration.
- `CMD_NOP` is not a valid object transaction.
- A target receiving `CMD_RESP` as a request or an unsupported command MUST
  report a protocol error and MUST NOT mutate object state.

## 8. Endpoint handshake state machines

### 8.1 Decode/master adapter

```text
IDLE:
  when bus_req.req:
    latch the complete request and placement coordinates
    present one stable READ/WRITE packet to decode local input
    -> INJECT

INJECT:
  hold local input request and packet stable
  when mesh acknowledges delivery:
    deassert local request
    -> WAIT_RESP

WAIT_RESP:
  when a matching local output RESP arrives:
    latch data; acknowledge that packet exactly once
    -> ACK_BUS

ACK_BUS:
  hold bus_resp.ack and rdata stable
  when bus_req.req deasserts:
    clear response
    -> IDLE
```

The adapter MUST tolerate arbitrary mesh backpressure in `INJECT` and
`WAIT_RESP`. It MUST NOT infer architectural completion from injection ack.

### 8.2 Slave endpoint adapter

```text
WAIT_REQ:
  when local output READ/WRITE request arrives:
    latch packet
    present held bus_req to local object
    -> WAIT_OBJECT

WAIT_OBJECT:
  hold bus_req stable
  when object bus_resp.ack:
    latch read data (or zero for write)
    deassert object request
    acknowledge mesh request once
    -> DRAIN_REQUEST

DRAIN_REQUEST:
  wait until local output request deasserts
  deassert local output ack
  -> INJECT_RESP

INJECT_RESP:
  hold stable RESP packet on local input
  when mesh acknowledges delivery:
    deassert response request
    -> WAIT_OBJECT_ACK_LOW

WAIT_OBJECT_ACK_LOW:
  wait for object bus_resp.ack to deassert if necessary
  -> WAIT_REQ
```

An implementation MAY merge states only if tests retain the exact held-request
and anti-double properties.

## 9. Architectural acknowledgement and side effects

The target object's existing held-request contract remains authoritative. The
slave adapter acknowledges the incoming network packet only after the object
has acknowledged and its side effect has occurred. The source adapter
acknowledges decode only after the response returns. Therefore:

- one decode request causes one target acceptance;
- a stalled packet cannot duplicate a register, memory, GPIO, or UART write;
- a response cannot precede the target side effect;
- source-visible read data is stable for the full architectural ack interval.

The increased latency is acceptable because decode already waits on ack and
there is one transaction in flight.

## 10. Reset contract

On reset, adapters MUST deassert all mesh and object request/ack outputs and
clear outstanding transaction state. Objects and mesh receive the same
synchronized active-low reset. Reset during any state cancels the transaction;
no completion is reported after reset release. Tests MUST cover reset during
injection, target wait, response injection, and source ack.

## 11. Static topology for first integration

The graph contains decode and five slaves. P3 computes the exact placement;
P4 MUST consume generated coordinates rather than repeat numeric literals.
A 3×3 mesh is the baseline because it already passes router tests and leaves
three spare endpoints for probes or future adapters.

Only decode initiates object operations in this phase. Slave-to-slave edges are
not required. The transport design nevertheless uses request source fields and
return packets so later initiators do not require packet-format replacement.

## 12. P3 placer acceptance vectors

### Valid vectors

1. Six-object 3×3 star graph produces six unique placements and five routes.
2. Same input run twice produces byte-identical JSON and SV.
3. Reordered input arrays produce identical semantic and byte output after
   canonical sorting.
4. Fixed legal coordinate is preserved.
5. 1×1 mesh with one object succeeds.
6. Route path resolves X before Y and metrics match hand calculation.

### Rejection vectors

1. Unknown schema or unknown field.
2. Zero, negative, non-integer, or greater-than-255 mesh dimension.
3. Capacity smaller than object count.
4. Duplicate object id or name.
5. Object id outside 0–15.
6. Footprint other than 1×1.
7. Fixed coordinate out of bounds or colliding.
8. Edge references unknown id, self-edge, duplicate directed pair, or
   non-positive weight.
9. Output path parent does not exist and cannot be created.
10. Generated artifacts disagree with internal validation.

Diagnostics MUST identify the JSON field or object/edge involved. The CLI MUST
exit non-zero and MUST NOT leave a partial output file.

## 13. P4 transport acceptance vectors

1. Decode READ to PC returns the exact PC value after arbitrary injected stalls.
2. Decode WRITE to PC performs exactly one increment while request is held.
3. Register write and read round-trip across at least two hops.
4. ALU request returns exact result and flags.
5. Memory fetch crosses mesh and instruction execution advances.
6. GPIO write toggles exactly once under source, router, and target stalls.
7. UART start pulses once under held request.
8. Unexpected command/source/address response does not acknowledge decode.
9. Reset in each adapter state clears the transaction without delayed mutation.
10. Full assembled self-test and six integration programs match the model.

Tests SHOULD expose counters for injected requests, target accepts, responses,
and architectural acks; all four counts must agree after draining.

## 14. Build dependency contract

P3 adds commands equivalent to:

```bash
python3 tools/placer.py \
  --input config/z80_objects.json \
  --json build/placement.json \
  --sv build/pca_placement_pkg.sv

python3 tools/placer.py ... --check
```

The Makefile MUST make both generated outputs depend on the input and placer
source. `--check` MUST generate in memory and compare exact bytes without
modifying files. Simulation and synthesis for mesh mode MUST depend on the SV
artifact. The direct-bus build remains independent.

## 15. Alternatives rejected

### Use delivery acknowledgement as write completion

Rejected for the baseline because read and write would have different
architectural completion mechanisms, and network acceptance can be confused
with object acceptance during adapter evolution.

### Add a transaction id immediately

Rejected because decode permits one request in flight and `msg_t` has no spare
field without changing the proven 67-bit router contract. Source coordinate,
command, and echoed address are sufficient for this scope.

### Emit only a SystemVerilog include

Rejected because tests and review need a language-neutral canonical artifact.
JSON plus generated SV provides both while retaining one generation path.

### Program route tables

Rejected because existing exact XY routing already consumes destination
coordinates and has directed tests. Route paths remain validation metadata.

### Start pressure-based runtime placement

Rejected until the deterministic static path executes the full object graph.
Dynamic movement would combine placement, configuration, state transfer, and
transport failures before the transport boundary is independently proven.

## 16. Phase P2 exit checklist

- [x] Input and output schemas defined.
- [x] Deterministic placement algorithm and tie-breakers defined.
- [x] Generated JSON/SV consistency rule defined.
- [x] Request and response packet fields defined.
- [x] Architectural ack separated from router delivery ack.
- [x] Source and target state machines specified.
- [x] Reset, backpressure, and anti-double invariants specified.
- [x] P3 valid/rejection vectors defined.
- [x] P4 transport/integration vectors defined.
- [x] Direct-bus non-regression and scope boundary retained.

## 17. References

- `pca_z80/rtl/pca_types.sv`
- `pca_z80/rtl/pca_router.sv`
- `pca_z80/rtl/pca_mesh.sv`
- `pca_z80/rtl/z80_obj.sv`
- `pca_z80/rtl/z80_core.sv`
- design-doc 01, §§6.4, 9, 11.3, and 13
- design-doc 04, continuation phase plan
