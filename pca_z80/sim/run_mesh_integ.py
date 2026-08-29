#!/usr/bin/env python3
"""Differentially run an assembled program through the mesh-backed Z80."""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from run_integ import run_model
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from zasm import assemble

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RTL = os.path.join(ROOT, "rtl")
SIM = os.path.join(ROOT, "sim")
BUILD = os.path.join(ROOT, "build")
FILES = [
    os.path.join(BUILD, "pca_placement_pkg.sv"),
    *[os.path.join(RTL, name) for name in (
        "pca_types.sv", "z80_obj.sv", "pca_router.sv", "pca_cell.sv", "pca_mesh.sv",
        "z80_mesh_adapter.sv", "obj_pc.sv", "obj_memio.sv", "obj_regfile.sv",
        "obj_alu.sv", "obj_flags.sv", "obj_decode.sv", "z80_mesh_core.sv")],
    os.path.join(SIM, "tb_z80_mesh_integ.sv"),
]


def main():
    if len(sys.argv) != 2:
        print("usage: run_mesh_integ.py <program.asm>", file=sys.stderr)
        return 2
    with open(sys.argv[1], encoding="utf-8") as stream:
        image, _, _ = assemble(stream.read())
    os.makedirs(BUILD, exist_ok=True)
    hex_path = os.path.join(BUILD, "mesh_integ.hex")
    with open(hex_path, "w", encoding="utf-8") as stream:
        stream.writelines(f"{byte:02X}\n" for byte in image)
    subprocess.run(["make", "placement"], cwd=ROOT, check=True, capture_output=True, text=True)
    vvp = os.path.join(BUILD, "z80_mesh_integ.vvp")
    trace_args = ["-DMESH_TRACE"] if os.environ.get("MESH_TRACE") else []
    compiled = subprocess.run([
        "iverilog", "-g2012", *trace_args, "-s", "tb_z80_mesh_integ",
        f'-Ptb_z80_mesh_integ.ROM_FILE="{hex_path}"', "-o", vvp, *FILES,
    ], cwd=ROOT, capture_output=True, text=True)
    if compiled.returncode:
        print("iverilog failed:\n" + compiled.stderr)
        return 2
    simulated = subprocess.run(["vvp", vvp], cwd=ROOT, capture_output=True, text=True)
    if os.environ.get("MESH_TRACE"):
        print(simulated.stdout)
    state = {}
    with open(os.path.join(BUILD, "mesh_integ_state.txt"), encoding="utf-8") as stream:
        for line in stream:
            key, value = line.split()
            state[key] = int(value)
    model = run_model(bytes(image))
    keys = ["PC", "R", "SP", "COUNT", "HALTED", "FAULTED", "A", "B", "C", "D", "E", "F"]
    differences = [(key, model[key], state.get(key)) for key in keys if model[key] != state.get(key)]
    if differences:
        print("FAIL: model divergence")
        for key, expected, actual in differences:
            print(f"  {key}: model={expected} mesh={actual}")
        return 1
    if state["PROTOCOL"] or not (state["REQUESTS"] == state["RESPONSES"] == state["ACCEPTS"]):
        print("FAIL: mesh protocol/count invariant", state)
        return 1
    print(f"PASS: mesh-backed object graph matches model on {sys.argv[1]}; "
          f"transactions={state['REQUESTS']}")
    return simulated.returncode


if __name__ == "__main__":
    raise SystemExit(main())
