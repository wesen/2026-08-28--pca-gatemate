# test_integ.py — Phase 5 integration pytest wrapper.
#
# Assembles each program, runs it on both z80_model.py and the object-graph
# testbench (sim/run_integ.py), and asserts the retired state matches. This
# is the Phase 5 differential gate: the integrated object graph must agree
# with the model on the same assembled bytes.
import os, subprocess, sys, tempfile
import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROG_DIR = os.path.join(ROOT, "programs")

# programs/ ships selftest.asm; additional inline programs cover more paths.
INLINE = {
    "smoke.asm": "LD A,0x42\nLD B,A\nHALT\n",
    "alu.asm": "LD A,0x0F\nADD A,1\nSUB 0\nHALT\n",
    "loop.asm": "LD A,0\nloop:\nADD A,1\nCP 3\nJR NZ,loop\nHALT\n",
    "call.asm": "CALL sub\nHALT\nNOP\nNOP\nsub:\nLD A,0x42\nRET\n",
    "stack.asm": "LD B,0x12\nLD C,0x34\nPUSH BC\nPOP DE\nHALT\n",
}


@pytest.mark.parametrize("name,text", list(INLINE.items()))
def test_inline_programs(name, text, tmp_path):
    src = tmp_path / name
    src.write_text(text)
    r = subprocess.run([sys.executable, os.path.join(ROOT, "sim", "run_integ.py"), str(src)],
                       capture_output=True, text=True, cwd=ROOT)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "PASS" in r.stdout


def test_selftest_program(tmp_path):
    # the shipped selftest.asm reaches the magic final state A=8
    src = os.path.join(PROG_DIR, "selftest.asm")
    assert os.path.exists(src), "programs/selftest.asm missing"
    r = subprocess.run([sys.executable, os.path.join(ROOT, "sim", "run_integ.py"), src],
                       capture_output=True, text=True, cwd=ROOT)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "PASS" in r.stdout
    # the harness already asserts model==rtl state; confirm A=8 reached
    assert "'A': 8" in r.stdout
