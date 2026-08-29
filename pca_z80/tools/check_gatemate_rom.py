#!/usr/bin/env python3
"""Fail a hardware build if the synthesized GateMate firmware ROM is absent/zero."""
from __future__ import annotations

import argparse
import re
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("netlist", type=Path)
    ap.add_argument("--expected-bram20", type=int, default=1)
    args = ap.parse_args()
    text = args.netlist.read_text()
    brams = len(re.findall(r"\bCC_BRAM_20K\s*#\(", text))
    if brams != args.expected_bram20:
        raise SystemExit(f"FAIL: expected {args.expected_bram20} CC_BRAM_20K, found {brams}")
    init_values = re.findall(r"\.INIT_[0-9A-F]+\(\d+'h([0-9a-fA-Fx]+)\)", text)
    if not init_values:
        raise SystemExit("FAIL: no GateMate BRAM INIT parameters found")
    if all(set(value.lower()) <= {"0"} for value in init_values):
        raise SystemExit("FAIL: all GateMate BRAM INIT parameters are zero")
    first_nonzero = next(v for v in init_values if set(v.lower()) - {"0"})
    print(f"PASS: {brams} CC_BRAM_20K; non-zero firmware INIT (sample ...{first_nonzero[-16:]})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
