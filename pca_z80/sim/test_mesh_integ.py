import os
import subprocess
import sys

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROGRAMS = {
    "smoke.asm": "LD A,0x42\nLD B,A\nHALT\n",
    "alu.asm": "LD A,0x0F\nADD A,1\nSUB 0\nHALT\n",
    "loop.asm": "LD A,0\nloop:\nADD A,1\nCP 3\nJR NZ,loop\nHALT\n",
    "call.asm": "CALL sub\nHALT\nNOP\nNOP\nsub:\nLD A,0x42\nRET\n",
    "stack.asm": "LD B,0x12\nLD C,0x34\nPUSH BC\nPOP DE\nHALT\n",
}


def run(source):
    return subprocess.run(
        [sys.executable, os.path.join(ROOT, "sim", "run_mesh_integ.py"), str(source)],
        cwd=ROOT, capture_output=True, text=True,
    )


@pytest.mark.parametrize("name,text", PROGRAMS.items())
def test_inline_mesh_programs(name, text, tmp_path):
    source = tmp_path / name
    source.write_text(text, encoding="utf-8")
    result = run(source)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "PASS: mesh-backed object graph matches model" in result.stdout


def test_mesh_selftest():
    result = run(os.path.join(ROOT, "programs", "selftest.asm"))
    assert result.returncode == 0, result.stdout + result.stderr
    assert "PASS: mesh-backed object graph matches model" in result.stdout
