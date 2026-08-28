#!/usr/bin/env python3
# run_integ.py — Phase 5 integration differential harness.
#
# Assembles a Z80 program with zasm.py, runs it on (a) the z80_model.py oracle
# and (b) the object-graph testbench tb_z80_integ.sv (iverilog), then compares
# the retired state. Any divergence is a Phase 5 failure: the integrated
# object graph disagrees with the model on the same assembled bytes.
#
# Usage: python3 sim/run_integ.py <program.asm>
import sys, os, subprocess, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from zasm import assemble
from z80_model import Z80

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIM = os.path.join(ROOT, "sim")
RTL = os.path.join(ROOT, "rtl")
BUILD = os.path.join(ROOT, "build")

RTL_FILES = ["z80_obj.sv", "obj_pc.sv", "obj_memio.sv", "obj_regfile.sv",
             "obj_alu.sv", "obj_flags.sv", "obj_decode.sv", "z80_core.sv"]

def run_model(img: bytes, sp: int = 0xFFFF, max_steps: int = 100000):
    m = Z80(); m.SP = sp; m.load(img); m.run(max_steps=max_steps)
    return {
        "PC": m.PC, "R": m.R, "SP": m.SP, "COUNT": m.instruction_count,
        "HALTED": 1 if m.halted else 0, "FAULTED": 1 if m.faulted else 0,
        "A": m.A, "B": m.B, "C": m.C, "D": m.D, "E": m.E, "F": m.F,
    }

def run_rtl(hex_path: str):
    os.makedirs(BUILD, exist_ok=True)
    srcs = [os.path.join(RTL, f) for f in RTL_FILES] + [os.path.join(SIM, "tb_z80_integ.sv")]
    vvp = os.path.join(BUILD, "z80_integ.vvp")
    # compile
    r = subprocess.run(["iverilog", "-g2012", "-s", "tb_z80_integ",
                        "-pvalue=ROM_FILE=\"%s\"" % hex_path,
                        "-o", vvp] + srcs,
                       capture_output=True, text=True)
    if r.returncode != 0:
        print("iverilog failed:\n" + r.stderr); sys.exit(2)
    # run (drop the VCD noise)
    r = subprocess.run(["vvp", vvp], capture_output=True, text=True, cwd=ROOT)
    state_path = os.path.join(BUILD, "integ_state.txt")
    state = {}
    with open(state_path) as f:
        for line in f:
            k, v = line.split()
            state[k] = int(v)
    return state, r.stdout

def main():
    if len(sys.argv) < 2:
        print("usage: run_integ.py <program.asm>"); sys.exit(2)
    with open(sys.argv[1]) as f: text = f.read()
    img, sym, lst = assemble(text)
    os.makedirs(BUILD, exist_ok=True)
    hex_path = os.path.join(BUILD, "integ.hex")
    with open(hex_path, "w") as f:
        for b in img: f.write("%02X\n" % b)
    print("assembled %d bytes" % len(img))
    mstate = run_model(img)
    rstate, out = run_rtl(hex_path)
    print("model:    ", mstate)
    print("rtl:      ", rstate)
    # compare the fields the RTL exposes
    keys = ["PC", "R", "SP", "COUNT", "HALTED", "FAULTED", "A", "B", "C", "D", "E", "F"]
    diffs = [(k, mstate[k], rstate.get(k)) for k in keys if mstate[k] != rstate.get(k)]
    if diffs:
        print("FAIL: %d divergence(s):" % len(diffs))
        for k, mv, rv in diffs:
            print("  %s: model=%s rtl=%s" % (k, mv, rv))
        sys.exit(1)
    print("PASS: integrated object graph matches the model on %s" % sys.argv[1])

if __name__ == "__main__":
    main()
