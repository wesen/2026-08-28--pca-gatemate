#!/usr/bin/env python3
"""Deterministic static logical placer for PCA-Z80 mesh endpoints."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

INPUT_SCHEMA = "pca-placement-input/v1"
OUTPUT_SCHEMA = "pca-placement/v1"


class PlacementError(ValueError):
    """Invalid input or generated placement."""


def _fail(path: str, message: str) -> None:
    raise PlacementError(f"{path}: {message}")


def _keys(value: Any, allowed: set[str], required: set[str], path: str) -> None:
    if not isinstance(value, dict):
        _fail(path, "expected object")
    unknown = set(value) - allowed
    missing = required - set(value)
    if unknown:
        _fail(path, f"unknown field(s): {', '.join(sorted(unknown))}")
    if missing:
        _fail(path, f"missing field(s): {', '.join(sorted(missing))}")


def _integer(value: Any, path: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        _fail(path, "expected integer")
    if not minimum <= value <= maximum:
        _fail(path, f"must be in range {minimum}..{maximum}")
    return value


def _identifier(value: Any, path: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", value):
        _fail(path, "expected lowercase identifier")
    return value


def validate_input(raw: Any) -> dict[str, Any]:
    """Validate and canonicalize a v1 placement input."""
    _keys(raw, {"schema", "mesh", "objects", "edges"},
          {"schema", "mesh", "objects", "edges"}, "input")
    if raw["schema"] != INPUT_SCHEMA:
        _fail("schema", f"expected {INPUT_SCHEMA!r}")

    mesh = raw["mesh"]
    _keys(mesh, {"cols", "rows"}, {"cols", "rows"}, "mesh")
    cols = _integer(mesh["cols"], "mesh.cols", 1, 255)
    rows = _integer(mesh["rows"], "mesh.rows", 1, 255)

    if not isinstance(raw["objects"], list) or not raw["objects"]:
        _fail("objects", "expected non-empty array")
    objects: list[dict[str, Any]] = []
    ids: set[int] = set()
    names: set[str] = set()
    fixed_cells: set[tuple[int, int]] = set()
    for index, item in enumerate(raw["objects"]):
        path = f"objects[{index}]"
        _keys(item, {"id", "name", "footprint", "fixed"},
              {"id", "name", "footprint"}, path)
        object_id = _integer(item["id"], f"{path}.id", 0, 15)
        name = _identifier(item["name"], f"{path}.name")
        if object_id in ids:
            _fail(f"{path}.id", f"duplicate object id {object_id}")
        if name in names:
            _fail(f"{path}.name", f"duplicate object name {name!r}")
        ids.add(object_id)
        names.add(name)

        footprint = item["footprint"]
        _keys(footprint, {"w", "h"}, {"w", "h"}, f"{path}.footprint")
        w = _integer(footprint["w"], f"{path}.footprint.w", 1, 255)
        h = _integer(footprint["h"], f"{path}.footprint.h", 1, 255)
        if (w, h) != (1, 1):
            _fail(f"{path}.footprint", "v1 supports only 1x1 footprints")

        obj: dict[str, Any] = {
            "id": object_id,
            "name": name,
            "footprint": {"h": h, "w": w},
        }
        if "fixed" in item:
            fixed = item["fixed"]
            _keys(fixed, {"x", "y"}, {"x", "y"}, f"{path}.fixed")
            x = _integer(fixed["x"], f"{path}.fixed.x", 0, cols - 1)
            y = _integer(fixed["y"], f"{path}.fixed.y", 0, rows - 1)
            if (x, y) in fixed_cells:
                _fail(f"{path}.fixed", f"cell ({x},{y}) already fixed")
            fixed_cells.add((x, y))
            obj["fixed"] = {"x": x, "y": y}
        objects.append(obj)

    if len(objects) > cols * rows:
        _fail("objects", f"{len(objects)} objects exceed mesh capacity {cols * rows}")

    if not isinstance(raw["edges"], list):
        _fail("edges", "expected array")
    edges: list[dict[str, int]] = []
    pairs: set[tuple[int, int]] = set()
    for index, item in enumerate(raw["edges"]):
        path = f"edges[{index}]"
        _keys(item, {"src", "dst", "weight"}, {"src", "dst", "weight"}, path)
        src = _integer(item["src"], f"{path}.src", 0, 15)
        dst = _integer(item["dst"], f"{path}.dst", 0, 15)
        weight = _integer(item["weight"], f"{path}.weight", 1, 2**31 - 1)
        if src not in ids:
            _fail(f"{path}.src", f"unknown object id {src}")
        if dst not in ids:
            _fail(f"{path}.dst", f"unknown object id {dst}")
        if src == dst:
            _fail(path, "self-edge is not allowed")
        if (src, dst) in pairs:
            _fail(path, f"duplicate directed edge {src}->{dst}")
        pairs.add((src, dst))
        edges.append({"src": src, "dst": dst, "weight": weight})

    objects.sort(key=lambda obj: (obj["id"], obj["name"]))
    edges.sort(key=lambda edge: (edge["src"], edge["dst"], edge["weight"]))
    return {
        "schema": INPUT_SCHEMA,
        "mesh": {"cols": cols, "rows": rows},
        "objects": objects,
        "edges": edges,
    }


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def _degrees(objects: list[dict[str, Any]], edges: list[dict[str, int]]) -> dict[int, int]:
    degree = {obj["id"]: 0 for obj in objects}
    for edge in edges:
        degree[edge["src"]] += edge["weight"]
        degree[edge["dst"]] += edge["weight"]
    return degree


def _pair_weight(a: int, b: int, edges: list[dict[str, int]]) -> int:
    return sum(edge["weight"] for edge in edges
               if {edge["src"], edge["dst"]} == {a, b})


def _xy_path(src: tuple[int, int], dst: tuple[int, int]) -> list[dict[str, int]]:
    x, y = src
    dx, dy = dst
    path = [{"x": x, "y": y}]
    while x != dx:
        x += 1 if dx > x else -1
        path.append({"x": x, "y": y})
    while y != dy:
        y += 1 if dy > y else -1
        path.append({"x": x, "y": y})
    return path


def place(normalized: dict[str, Any]) -> dict[str, Any]:
    """Place validated objects and return a canonical output model."""
    cols = normalized["mesh"]["cols"]
    rows = normalized["mesh"]["rows"]
    objects = normalized["objects"]
    edges = normalized["edges"]
    degree = _degrees(objects, edges)
    by_id = {obj["id"]: obj for obj in objects}

    placed: dict[int, tuple[int, int]] = {}
    occupied: set[tuple[int, int]] = set()
    for obj in objects:
        if "fixed" in obj:
            cell = (obj["fixed"]["x"], obj["fixed"]["y"])
            placed[obj["id"]] = cell
            occupied.add(cell)

    order = sorted((obj for obj in objects if obj["id"] not in placed),
                   key=lambda obj: (-degree[obj["id"]], obj["id"], obj["name"]))
    all_cells = [(x, y) for y in range(rows) for x in range(cols)]
    for obj in order:
        candidates = [cell for cell in all_cells if cell not in occupied]
        if not candidates:
            _fail("placement", f"no free cell for object {obj['name']!r}")

        def cost(cell: tuple[int, int]) -> tuple[int, int, int]:
            total = 0
            for other_id, other_cell in placed.items():
                weight = _pair_weight(obj["id"], other_id, edges)
                total += weight * (abs(cell[0] - other_cell[0]) + abs(cell[1] - other_cell[1]))
            return total, cell[1], cell[0]

        chosen = min(candidates, key=cost)
        placed[obj["id"]] = chosen
        occupied.add(chosen)

    placements = []
    for object_id in sorted(placed):
        x, y = placed[object_id]
        placements.append({
            "cell_id": y * cols + x,
            "id": object_id,
            "name": by_id[object_id]["name"],
            "x": x,
            "y": y,
        })

    routes = []
    weighted_hops = 0
    max_hops = 0
    for edge in edges:
        path = _xy_path(placed[edge["src"]], placed[edge["dst"]])
        hops = len(path) - 1
        routes.append({
            "dst": edge["dst"],
            "hops": hops,
            "path": path,
            "src": edge["src"],
            "weight": edge["weight"],
        })
        weighted_hops += edge["weight"] * hops
        max_hops = max(max_hops, hops)

    input_bytes = canonical_json(normalized)
    result = {
        "input_sha256": hashlib.sha256(input_bytes).hexdigest(),
        "mesh": {"cols": cols, "rows": rows},
        "metrics": {
            "max_hops": max_hops,
            "objects": len(objects),
            "occupied_cells": len(occupied),
            "weighted_hops": weighted_hops,
        },
        "placements": placements,
        "routes": routes,
        "schema": OUTPUT_SCHEMA,
    }
    validate_output(result)
    return result


def validate_output(result: dict[str, Any]) -> None:
    cols = result["mesh"]["cols"]
    rows = result["mesh"]["rows"]
    coordinates: set[tuple[int, int]] = set()
    positions: dict[int, tuple[int, int]] = {}
    last_id = -1
    for item in result["placements"]:
        object_id, x, y = item["id"], item["x"], item["y"]
        if object_id <= last_id:
            _fail("placements", "not sorted by object id")
        last_id = object_id
        if not (0 <= x < cols and 0 <= y < rows):
            _fail("placements", f"object {object_id} out of bounds")
        if (x, y) in coordinates:
            _fail("placements", f"duplicate coordinate ({x},{y})")
        if item["cell_id"] != y * cols + x:
            _fail("placements", f"object {object_id} has invalid cell_id")
        coordinates.add((x, y))
        positions[object_id] = (x, y)
    for route in result["routes"]:
        expected = _xy_path(positions[route["src"]], positions[route["dst"]])
        if route["path"] != expected or route["hops"] != len(expected) - 1:
            _fail("routes", f"invalid XY path {route['src']}->{route['dst']}")


def render_sv(result: dict[str, Any]) -> bytes:
    """Render scalar constants; Icarus 14 rejects unpacked array parameters."""
    lines = [
        "// Generated by tools/placer.py; DO NOT EDIT.",
        f"// input_sha256: {result['input_sha256']}",
        "package pca_placement_pkg;",
        f"  localparam int PCA_COLS = {result['mesh']['cols']};",
        f"  localparam int PCA_ROWS = {result['mesh']['rows']};",
        f"  localparam int PCA_OBJECTS = {len(result['placements'])};",
    ]
    for item in result["placements"]:
        name = re.sub(r"[^A-Za-z0-9_]", "_", item["name"]).upper()
        lines.extend([
            f"  localparam logic [7:0] OBJ_{name}_X = 8'd{item['x']};",
            f"  localparam logic [7:0] OBJ_{name}_Y = 8'd{item['y']};",
            f"  localparam int OBJ_{name}_CELL = {item['cell_id']};",
        ])
    lines.extend(["endpackage : pca_placement_pkg", ""])
    return "\n".join(lines).encode("utf-8")


def generate(raw: Any) -> tuple[bytes, bytes]:
    normalized = validate_input(raw)
    result = place(normalized)
    return canonical_json(result), render_sv(result)


def _atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def _read_json(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as stream:
            return json.load(stream)
    except (OSError, json.JSONDecodeError) as error:
        raise PlacementError(f"{path}: {error}") from error


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--json", required=True, type=Path, dest="json_output")
    parser.add_argument("--sv", required=True, type=Path, dest="sv_output")
    parser.add_argument("--check", action="store_true",
                        help="compare exact generated bytes without writing")
    args = parser.parse_args(argv)
    try:
        json_bytes, sv_bytes = generate(_read_json(args.input))
        outputs = ((args.json_output, json_bytes), (args.sv_output, sv_bytes))
        if args.check:
            stale = []
            for path, expected in outputs:
                try:
                    actual = path.read_bytes()
                except OSError:
                    actual = None
                if actual != expected:
                    stale.append(str(path))
            if stale:
                raise PlacementError("stale or missing generated file(s): " + ", ".join(stale))
            print(f"PASS: placement artifacts current ({len(json_bytes)} JSON bytes, {len(sv_bytes)} SV bytes)")
        else:
            for path, data in outputs:
                _atomic_write(path, data)
            result = json.loads(json_bytes)
            metrics = result["metrics"]
            print(f"PASS: placed {metrics['objects']} objects; weighted_hops={metrics['weighted_hops']}; max_hops={metrics['max_hops']}")
        return 0
    except PlacementError as error:
        print(f"placer: error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
