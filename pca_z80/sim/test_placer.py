import copy
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from placer import PlacementError, generate, place, validate_input


def valid_input():
    return {
        "schema": "pca-placement-input/v1",
        "mesh": {"cols": 3, "rows": 3},
        "objects": [
            {"id": 0, "name": "decode", "footprint": {"w": 1, "h": 1}},
            {"id": 1, "name": "pc", "footprint": {"w": 1, "h": 1}},
            {"id": 2, "name": "mem", "footprint": {"w": 1, "h": 1}},
            {"id": 3, "name": "reg", "footprint": {"w": 1, "h": 1}},
            {"id": 4, "name": "alu", "footprint": {"w": 1, "h": 1}},
            {"id": 5, "name": "flags", "footprint": {"w": 1, "h": 1}},
        ],
        "edges": [
            {"src": 0, "dst": object_id, "weight": 1}
            for object_id in range(1, 6)
        ],
    }


def rejected(raw, match):
    with pytest.raises(PlacementError, match=match):
        validate_input(raw)


def test_six_object_star_is_valid_and_deterministic():
    first = place(validate_input(valid_input()))
    second = place(validate_input(copy.deepcopy(valid_input())))
    assert first == second
    assert first["metrics"] == {
        "max_hops": 2,
        "objects": 6,
        "occupied_cells": 6,
        "weighted_hops": 8,
    }
    assert len({(p["x"], p["y"]) for p in first["placements"]}) == 6
    assert len(first["routes"]) == 5


def test_reordered_arrays_emit_identical_bytes():
    original = valid_input()
    reordered = copy.deepcopy(original)
    reordered["objects"].reverse()
    reordered["edges"].reverse()
    assert generate(original) == generate(reordered)


def test_fixed_coordinate_is_preserved():
    raw = valid_input()
    raw["objects"][3]["fixed"] = {"x": 2, "y": 2}
    result = place(validate_input(raw))
    reg = next(item for item in result["placements"] if item["name"] == "reg")
    assert (reg["x"], reg["y"], reg["cell_id"]) == (2, 2, 8)


def test_single_object_single_cell():
    raw = valid_input()
    raw["mesh"] = {"cols": 1, "rows": 1}
    raw["objects"] = raw["objects"][:1]
    raw["edges"] = []
    result = place(validate_input(raw))
    assert result["placements"] == [
        {"cell_id": 0, "id": 0, "name": "decode", "x": 0, "y": 0}
    ]
    assert result["metrics"]["max_hops"] == 0


def test_xy_route_resolves_x_then_y():
    raw = {
        "schema": "pca-placement-input/v1",
        "mesh": {"cols": 3, "rows": 3},
        "objects": [
            {"id": 0, "name": "a", "footprint": {"w": 1, "h": 1}, "fixed": {"x": 0, "y": 0}},
            {"id": 1, "name": "b", "footprint": {"w": 1, "h": 1}, "fixed": {"x": 2, "y": 2}},
        ],
        "edges": [{"src": 0, "dst": 1, "weight": 3}],
    }
    route = place(validate_input(raw))["routes"][0]
    assert route["path"] == [
        {"x": 0, "y": 0}, {"x": 1, "y": 0}, {"x": 2, "y": 0},
        {"x": 2, "y": 1}, {"x": 2, "y": 2},
    ]
    assert route["hops"] == 4


@pytest.mark.parametrize(
    "mutate,match",
    [
        (lambda r: r.update(schema="wrong"), "schema"),
        (lambda r: r.update(extra=True), "unknown field"),
        (lambda r: r["mesh"].update(cols=0), "mesh.cols"),
        (lambda r: r["objects"][1].update(id=0), "duplicate object id"),
        (lambda r: r["objects"][1].update(name="decode"), "duplicate object name"),
        (lambda r: r["objects"][0]["footprint"].update(w=2), "only 1x1"),
        (lambda r: r["objects"][0].update(fixed={"x": 9, "y": 0}), "fixed.x"),
        (lambda r: r["edges"][0].update(dst=15), "unknown object id"),
        (lambda r: r["edges"][0].update(dst=0), "self-edge"),
        (lambda r: r["edges"].append(copy.deepcopy(r["edges"][0])), "duplicate directed edge"),
        (lambda r: r["edges"][0].update(weight=0), "weight"),
    ],
)
def test_rejection_vectors(mutate, match):
    raw = valid_input()
    mutate(raw)
    rejected(raw, match)


def test_capacity_rejected():
    raw = valid_input()
    raw["mesh"] = {"cols": 2, "rows": 2}
    rejected(raw, "exceed mesh capacity")


def test_colliding_fixed_coordinates_rejected():
    raw = valid_input()
    raw["objects"][0]["fixed"] = {"x": 1, "y": 1}
    raw["objects"][1]["fixed"] = {"x": 1, "y": 1}
    rejected(raw, "already fixed")


def test_cli_atomic_generation_and_check(tmp_path):
    root = Path(__file__).resolve().parent.parent
    source = tmp_path / "objects.json"
    json_output = tmp_path / "nested" / "placement.json"
    sv_output = tmp_path / "nested" / "placement.sv"
    source.write_text(json.dumps(valid_input()), encoding="utf-8")
    command = [
        sys.executable, str(root / "tools" / "placer.py"),
        "--input", str(source), "--json", str(json_output), "--sv", str(sv_output),
    ]
    generated = subprocess.run(command, text=True, capture_output=True)
    assert generated.returncode == 0, generated.stderr
    assert "PASS: placed 6 objects" in generated.stdout
    assert json_output.exists() and sv_output.exists()

    checked = subprocess.run(command + ["--check"], text=True, capture_output=True)
    assert checked.returncode == 0, checked.stderr
    sv_output.write_text("stale\n", encoding="utf-8")
    stale = subprocess.run(command + ["--check"], text=True, capture_output=True)
    assert stale.returncode == 2
    assert "stale or missing" in stale.stderr
    assert sv_output.read_text(encoding="utf-8") == "stale\n"


def test_cli_rejection_leaves_no_outputs(tmp_path):
    root = Path(__file__).resolve().parent.parent
    raw = valid_input()
    raw["objects"][0]["footprint"]["w"] = 2
    source = tmp_path / "bad.json"
    json_output = tmp_path / "placement.json"
    sv_output = tmp_path / "placement.sv"
    source.write_text(json.dumps(raw), encoding="utf-8")
    result = subprocess.run([
        sys.executable, str(root / "tools" / "placer.py"),
        "--input", str(source), "--json", str(json_output), "--sv", str(sv_output),
    ], text=True, capture_output=True)
    assert result.returncode == 2
    assert "only 1x1" in result.stderr
    assert not json_output.exists()
    assert not sv_output.exists()


def test_generated_sv_compiles_when_iverilog_available(tmp_path):
    iverilog = shutil.which("iverilog")
    if not iverilog:
        pytest.skip("iverilog not on PATH")
    _, sv = generate(valid_input())
    package = tmp_path / "placement.sv"
    smoke = tmp_path / "smoke.sv"
    package.write_bytes(sv)
    smoke.write_text(
        "module smoke; initial begin "
        "$display(\"%0d\", pca_placement_pkg::OBJ_DECODE_CELL); end endmodule\n",
        encoding="utf-8",
    )
    result = subprocess.run(
        [iverilog, "-g2012", "-s", "smoke", "-o", str(tmp_path / "smoke.vvp"),
         str(package), str(smoke)], text=True, capture_output=True,
    )
    assert result.returncode == 0, result.stderr
