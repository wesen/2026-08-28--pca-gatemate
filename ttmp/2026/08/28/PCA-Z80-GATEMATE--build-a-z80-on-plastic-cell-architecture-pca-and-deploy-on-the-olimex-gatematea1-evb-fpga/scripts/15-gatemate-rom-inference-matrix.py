#!/usr/bin/env python3
"""Probe GateMate/Yosys ROM inference by read style and depth.

Creates isolated initialized 8-bit ROMs, runs synth_gatemate, and reports
CC_BRAM and register-cell counts. Run from anywhere; artifacts stay under the
ticket scripts/_rom_probe directory.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "_rom_probe"
DEPTHS = (128, 256, 272, 436, 512, 1024, 2048)
STYLES = ("sync", "async")

SV = r'''module romprobe #(
    parameter integer DEPTH = 256
) (
    input wire clk,
    input wire [15:0] addr,
    output reg [7:0] q
);
    reg [7:0] mem [0:DEPTH-1];
    initial $readmemh("INIT_FILE", mem);
STYLE_BODY
endmodule
'''


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, check=False)


def main() -> int:
    yosys = shutil.which("yosys")
    if not yosys:
        raise SystemExit("yosys not found; source OSS CAD Suite environment")
    OUT.mkdir(exist_ok=True)
    rows: list[tuple[str, int, str, str, str]] = []
    for style in STYLES:
        for depth in DEPTHS:
            case = OUT / f"{style}-{depth}"
            case.mkdir(exist_ok=True)
            init = case / "rom.hex"
            init.write_text("\n".join(f"{(i * 37 + 0x3e) & 0xff:02X}" for i in range(depth)) + "\n")
            body = ("    always @(posedge clk) q <= mem[addr[$clog2(DEPTH)-1:0]];"
                    if style == "sync" else
                    "    always @* q = mem[addr[$clog2(DEPTH)-1:0]];")
            sv = SV.replace("INIT_FILE", str(init)).replace("STYLE_BODY", body)
            (case / "romprobe.v").write_text(sv)
            script = (f"read_verilog romprobe.v; chparam -set DEPTH {depth} romprobe; "
                      "synth_gatemate -top romprobe -luttree -nomx8; stat")
            cp = run([yosys, "-p", script], case)
            (case / "yosys.log").write_text(cp.stdout)
            if cp.returncode:
                rows.append((style, depth, "ERROR", "-", "-"))
                continue
            def count(name: str) -> str:
                matches = re.findall(rf"^\s*(\d+)\s+{re.escape(name)}\s*$", cp.stdout, re.M)
                return matches[-1] if matches else "0"
            bram20 = count("CC_BRAM_20K")
            bram40 = count("CC_BRAM_40K")
            ff = count("CC_DFF")
            rows.append((style, depth, bram20, bram40, ff))

    print("style depth bits  BRAM20 BRAM40 DFF")
    for style, depth, b20, b40, ff in rows:
        print(f"{style:5} {depth:5} {depth*8:5} {b20:>6} {b40:>6} {ff:>5}")
    (OUT / "results.txt").write_text(
        "style depth bits BRAM20 BRAM40 DFF\n" +
        "\n".join(f"{s} {d} {d*8} {a} {b} {f}" for s, d, a, b, f in rows) + "\n"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
