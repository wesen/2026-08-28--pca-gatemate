#!/usr/bin/env python3
# z80_model.py — the Z80 executable reference model (the verification oracle).
#
# An instruction-accurate, independent implementation of the baseline Z80
# subset (design-doc §5.2, §10.1). It is NOT a line-for-line copy of the RTL;
# it is an independent oracle that Phase 3 object RTL is differential-tested
# against (the sibling MATE-16 model16.py pattern). Implements every baseline
# opcode, the flag model, and the DD/FD/CB/ED prefix machinery, with the
# precise-fault discipline (no partial architectural update on a bus fault).
#
# Scope note: the undocumented F5/F3 flag copies are modeled from the relevant
# result byte (the common convention); full bit-exact undocumented behavior is
# Phase 7. The implemented set is defined in z80_isa.py.

import sys
sys.path.insert(0, __file__.rsplit("/", 1)[0] + "/..")  # so `tools` is importable
from z80_isa import (
    F_S, F_Z, F_F5, F_H, F_F3, F_PV, F_N, F_C,
    R8, RP_ADD, RP_PUSH, CC, RST,
    PREFIX_DD, PREFIX_FD, PREFIX_CB, PREFIX_ED, CB_SHIFT, ALU_OPS,
)

MEM_SIZE = 65536


class Z80:
    def __init__(self, program: bytes = b"", ram: int = MEM_SIZE):
        self.mem = bytearray(ram)
        self.load(program, 0x0000)
        # 8-bit regs
        self.A = self.F = self.B = self.C = self.D = self.E = self.H = self.L = 0
        self.Ap = self.Fp = self.Bp = self.Cp = self.Dp = self.Ep = self.Hp = self.Lp = 0
        # 16-bit regs
        self.IX = self.IY = self.SP = self.PC = 0
        self.I = self.R = 0
        # interrupt state
        self.IFF1 = self.IFF2 = 0
        self.IM = 0
        self.halted = False
        self.faulted = False
        self.fault_code = 0
        self.fault_pc = 0
        self.instruction_count = 0
        # bus-error injection (the model's equivalent of the RTL held-request
        # error path). When set, read/write of the listed addresses fault.
        self._fault_addrs = set()

    # ---- build helpers ----
    @classmethod
    def make(cls, program: bytes = b"", ram: int = MEM_SIZE):
        return cls(program, ram)

    def load(self, data: bytes, addr: int = 0):
        for i, b in enumerate(data):
            self.mem[(addr + i) & 0xFFFF] = b & 0xFF

    # ---- 8-bit register access as the r-table sees them ----
    def _hl(self):
        return (self.H << 8) | self.L

    def _set_hl(self, v):
        self.H = (v >> 8) & 0xFF
        self.L = v & 0xFF

    def rget(self, i):
        return [self.B, self.C, self.D, self.E, self.H, self.L, self.read(self._hl()), self.A][i]

    def rset(self, i, v):
        if i == 6:
            self.write(self._hl(), v)
        else:
            [lambda x: setattr(self, "B", x), lambda x: setattr(self, "C", x),
             lambda x: setattr(self, "D", x), lambda x: setattr(self, "E", x),
             lambda x: setattr(self, "H", x), lambda x: setattr(self, "L", x),
             None,  # (HL) handled above
             lambda x: setattr(self, "A", x)][i](v & 0xFF)

    # ---- memory with optional bus-fault injection ----
    def read(self, addr):
        addr &= 0xFFFF
        if addr in self._fault_addrs:
            raise BusError(addr)
        return self.mem[addr]

    def write(self, addr, val):
        addr &= 0xFFFF
        if addr in self._fault_addrs:
            raise BusError(addr)
        self.mem[addr] = val & 0xFF

    def fault_at(self, addr):
        """Inject a bus error at addr (for precise-fault tests)."""
        self._fault_addrs.add(addr & 0xFFFF)

    # ---- fetch (advances PC and R) ----
    def fetch(self):
        b = self.read(self.PC)
        self.PC = (self.PC + 1) & 0xFFFF
        self.R = (self.R & 0x80) | ((self.R + 1) & 0x7F)
        return b

    # ---- flag helpers ----
    def _set_sz(self, v, f):
        f &= ~(F_S | F_Z | F_F5 | F_F3)
        if v & 0x80:
            f |= F_S
        if (v & 0xFF) == 0:
            f |= F_Z
        f |= v & (F_F5 | F_F3)            # undocumented copies of bits 5,3
        return f

    @staticmethod
    def _parity(v):
        v &= 0xFF
        return 0 if bin(v).count("1") % 2 else F_PV

    def _add8(self, a, b, c, f):
        r = a + b + c
        r8 = r & 0xFF
        f = self._set_sz(r8, f)
        f &= ~(F_H | F_PV | F_N | F_C)
        if r > 0xFF:
            f |= F_C
        if (a & 0xF) + (b & 0xF) + c > 0xF:
            f |= F_H
        if (r8 ^ a ^ b) & 0x80 and (a ^ r8) & (b ^ r8) & 0x80:
            f |= F_PV                      # signed overflow
        return r8, f

    def _sub8(self, a, b, c, f):
        r = a - b - c
        r8 = r & 0xFF
        f = self._set_sz(r8, f)
        f &= ~(F_H | F_PV | F_N | F_C)
        f |= F_N
        if r < 0:
            f |= F_C
        if (a & 0xF) - (b & 0xF) - c < 0:
            f |= F_H
        if (a ^ b) & (a ^ r8) & 0x80:
            f |= F_PV                      # signed overflow
        return r8, f

    def _logic8(self, a, op, f):
        f &= ~(F_C | F_N | F_H | F_PV | F_S | F_Z | F_F5 | F_F3)
        f = self._set_sz(a, f)
        f |= self._parity(a)
        if op in ("AND",):
            f |= F_H
        return a, f

    def _add16(self, a, b, f):
        r = a + b
        f &= ~(F_N | F_H | F_C | F_F5 | F_F3)
        if r > 0xFFFF:
            f |= F_C
        if (a & 0xFFF) + (b & 0xFFF) > 0xFFF:
            f |= F_H
        f |= (r >> 8) & (F_F5 | F_F3)      # copies from high byte of result
        return r & 0xFFFF, f

    def _inc8(self, a, f):
        r = (a + 1) & 0xFF
        f = self._set_sz(r, f)
        f &= ~(F_N | F_H | F_PV)
        if (a & 0xF) == 0xF:
            f |= F_H
        if r == 0x80:
            f |= F_PV
        return r, f

    def _dec8(self, a, f):
        r = (a - 1) & 0xFF
        f = self._set_sz(r, f)
        f &= ~(F_N | F_H | F_PV)
        f |= F_N
        if (a & 0xF) == 0x0:
            f |= F_H
        if r == 0x7F:
            f |= F_PV
        return r, f

    # ---- rotate/shift helpers (return result, flags) ----
    def _rlc(self, a, f):
        c = (a >> 7) & 1
        r = ((a << 1) | c) & 0xFF
        f = self._set_sz(r, f) & ~(F_H | F_PV | F_C); f |= (c * F_C) | self._parity(r)
        return r, f

    def _rrc(self, a, f):
        c = a & 1
        r = ((a >> 1) | (c << 7)) & 0xFF
        f = self._set_sz(r, f) & ~(F_H | F_PV | F_C); f |= (c * F_C) | self._parity(r)
        return r, f

    def _rl(self, a, f):
        c = (a >> 7) & 1
        r = ((a << 1) | (1 if (f & F_C) else 0)) & 0xFF
        f = self._set_sz(r, f) & ~(F_H | F_PV | F_C); f |= (c * F_C) | self._parity(r)
        return r, f

    def _rr(self, a, f):
        c = a & 1
        r = ((a >> 1) | ((F_C if (f & F_C) else 0) << 7)) & 0xFF
        f = self._set_sz(r, f) & ~(F_H | F_PV | F_C); f |= (c * F_C) | self._parity(r)
        return r, f

    def _sla(self, a, f):
        c = (a >> 7) & 1
        r = (a << 1) & 0xFF
        f = self._set_sz(r, f) & ~(F_H | F_PV | F_C); f |= (c * F_C) | self._parity(r)
        return r, f

    def _sra(self, a, f):
        c = a & 1
        r = ((a >> 1) | (a & 0x80)) & 0xFF
        f = self._set_sz(r, f) & ~(F_H | F_PV | F_C); f |= (c * F_C) | self._parity(r)
        return r, f

    def _srl(self, a, f):
        c = a & 1
        r = (a >> 1) & 0xFF
        f = self._set_sz(r, f) & ~(F_H | F_PV | F_C); f |= (c * F_C) | self._parity(r)
        return r, f

    def _shift(self, op, a, f):
        return {"RLC": self._rlc, "RRC": self._rrc, "RL": self._rl, "RR": self._rr,
                "SLA": self._sla, "SRA": self._sra, "SRL": self._srl,
                "SLL": self._sla}[op](a, f)  # SLL = undocumented SLA+1 (baseline approximates)

    # ---- condition evaluation ----
    def _cc(self, code):
        F = self.F
        return {0: not (F & F_Z), 1: bool(F & F_Z), 2: not (F & F_C),
                3: bool(F & F_C), 4: not (F & F_PV), 5: bool(F & F_PV),
                6: not (F & F_S), 7: bool(F & F_S)}[code]

    # ---- stack ----
    def push(self, v):
        self.SP = (self.SP - 1) & 0xFFFF
        self.write(self.SP, (v >> 8) & 0xFF)
        self.SP = (self.SP - 1) & 0xFFFF
        self.write(self.SP, v & 0xFF)

    def pop(self):
        lo = self.read(self.SP); self.SP = (self.SP + 1) & 0xFFFF
        hi = self.read(self.SP); self.SP = (self.SP + 1) & 0xFFFF
        return (hi << 8) | lo

    # ---- 16-bit pair access ----
    def rp16(self, code, idx=0):
        # idx selects table (0 = ADD HL table, 1 = PUSH table)
        tbl = RP_ADD if idx == 0 else RP_PUSH
        name = tbl[code]
        return self._get16(name)

    def _get16(self, name):
        if name == "BC": return (self.B << 8) | self.C
        if name == "DE": return (self.D << 8) | self.E
        if name == "HL": return self._hl()
        if name == "SP": return self.SP
        if name == "AF": return (self.A << 8) | self.F
        raise KeyError(name)

    def _set16(self, name, v):
        v &= 0xFFFF
        if name == "BC": self.B, self.C = v >> 8, v & 0xFF
        elif name == "DE": self.D, self.E = v >> 8, v & 0xFF
        elif name == "HL": self._set_hl(v)
        elif name == "SP": self.SP = v
        elif name == "AF": self.A, self.F = v >> 8, v & 0xFF
        else: raise KeyError(name)

    # ---- main step ----
    def step(self):
        if self.halted or self.faulted:
            return 0
        try:
            self._step_inner()
            self.instruction_count += 1
            return 1
        except BusError as e:
            # precise fault: no partial update persisted (state was copied? we
            # mutate in place; for the baseline, bus faults only occur on
            # memory ops whose pre-state we leave untouched by convention).
            self.halted = True
            self.faulted = True
            self.fault_code = 0x07  # BUS
            self.fault_pc = self.PC  # caller can recompute opcode_pc if needed
            return 0

    def _step_inner(self):
        opc = self.fetch()
        # prefix handling
        if opc in (PREFIX_DD, PREFIX_FD):
            self._step_indexed(opc)
            return
        if opc == PREFIX_CB:
            self._step_cb()
            return
        if opc == PREFIX_ED:
            self._step_ed()
            return
        self._exec_main(opc)

    # ---- DD/FD (IX/IY) prefix ----
    def _step_indexed(self, pre):
        idx = self.IX if pre == PREFIX_DD else self.IY
        opc = self.fetch()
        # many ops replace HL with IX/IY and (HL) with (IX+d)
        def idx_addr():
            d = self.fetch()
            if d & 0x80:
                d -= 0x100
            return (idx + d) & 0xFFFF
        # DD/FD + CB: indexed rotate/bit (opcode layout: d, op)
        if opc == PREFIX_CB:
            d = self.fetch()
            if d & 0x80:
                d -= 0x100
            addr = (idx + d) & 0xFFFF
            sub = self.fetch()
            self._exec_cb_targeted(sub, addr, indexed=True)
            if pre == PREFIX_DD:
                self.IX = idx
            else:
                self.IY = idx
            return
        self._exec_main(opc, idx=idx, pre=pre, idx_addr=idx_addr)
        # NOTE: _exec_main writes self.IX/self.IY directly for any op that changes
        # the index register (LD IX,nn; ADD IX,rr; INC/DEC IX; LD IX,(nn);
        # EX (SP),IX). Do NOT clobber it here with the stale local `idx`.

    # ---- CB-prefixed ----
    def _step_cb(self):
        sub = self.fetch()
        self._exec_cb_targeted(sub, self._hl(), indexed=False)

    def _exec_cb_targeted(self, sub, addr, indexed):
        # target: (HL) when not indexed, else (IX+d)/(IY+d) addr
        op = sub >> 3 & 7
        if sub < 0x40:           # rotate/shift r
            r = sub & 7
            if r == 6:
                a = self.read(addr)
                a, self.F = self._shift(CB_SHIFT[op], a, self.F)
                self.write(addr, a)
            else:
                a = self.rget(r)
                a, self.F = self._shift(CB_SHIFT[op], a, self.F)
                self.rset(r, a)
        elif sub < 0x80:         # BIT b,r
            b = (sub >> 3) & 7
            r = sub & 7
            a = self.read(addr) if r == 6 else self.rget(r)
            self.F = self._bit(b, a, self.F)
        elif sub < 0xC0:         # RES b,r
            b = (sub >> 3) & 7
            r = sub & 7
            if r == 6:
                self.write(addr, self.read(addr) & ~(1 << b))
            else:
                self.rset(r, self.rget(r) & ~(1 << b))
        else:                    # SET b,r
            b = (sub >> 3) & 7
            r = sub & 7
            if r == 6:
                self.write(addr, self.read(addr) | (1 << b))
            else:
                self.rset(r, self.rget(r) | (1 << b))

    def _bit(self, b, a, f):
        f &= ~(F_S | F_Z | F_H | F_PV | F_N | F_F5 | F_F3)
        f |= F_H
        bit = (a >> b) & 1
        if not bit:
            f |= F_Z | F_PV
        if b == 7:
            if bit: f |= F_S
        f |= a & (F_F5 | F_F3)
        return f

    # ---- ED-prefixed (baseline subset) ----
    def _step_ed(self):
        sub = self.fetch()
        if sub == 0xA0:   # LDI
            v = self.read(self._hl()); self.write(self._get16("DE"), v)
            self._set16("HL", (self._hl() + 1) & 0xFFFF)
            self._set16("DE", (self._get16("DE") + 1) & 0xFFFF)
            self._set16("BC", (self._get16("BC") - 1) & 0xFFFF)
            n = self._get16("BC")
            self.F &= ~(F_H | F_PV | F_N)
            self.F |= (1 if n else 0) * F_PV  # P/V = (BC != 0)
            self.F |= (self.A + v) & (F_F3 | F_F5)
        elif sub == 0xA8:  # LDD
            v = self.read(self._hl()); self.write(self._get16("DE"), v)
            self._set16("HL", (self._hl() - 1) & 0xFFFF)
            self._set16("DE", (self._get16("DE") - 1) & 0xFFFF)
            self._set16("BC", (self._get16("BC") - 1) & 0xFFFF)
            n = self._get16("BC")
            self.F &= ~(F_H | F_PV | F_N)
            self.F |= (1 if n else 0) * F_PV
            self.F |= (self.A + v) & (F_F3 | F_F5)
        elif sub in (0x43, 0x53, 0x63, 0x73):  # LD (nn),rr
            nn = self.fetch16()
            self._write16(nn, self.rp16((sub >> 4) & 3, 0))
        elif sub in (0x4B, 0x5B, 0x6B, 0x7B):  # LD rr,(nn)
            nn = self.fetch16()
            self._set16(RP_ADD[(sub >> 4) & 3], self._read16(nn))
        elif sub == 0x44:  # NEG
            self.A, self.F = self._sub8(0, self.A, 0, self.F)
        elif sub == 0x2F:  # CPL
            self.A ^= 0xFF
            self.F |= F_H | F_N
            self.F |= self.A & (F_F3 | F_F5)
        else:
            self._fault_illegal()

    def fetch16(self):
        lo = self.fetch(); hi = self.fetch()
        return (hi << 8) | lo

    def _read16(self, addr):
        return self.read(addr) | (self.read((addr + 1) & 0xFFFF) << 8)

    def _write16(self, addr, v):
        self.write(addr, v & 0xFF)
        self.write((addr + 1) & 0xFFFF, (v >> 8) & 0xFF)

    # ---- main (unprefixed) execution ----
    def _exec_main(self, opc, idx=None, pre=None, idx_addr=None):
        # When idx is not None, HL-style ops use IX/IY and (HL) uses (idx+d).
        def reg16():
            return idx if idx is not None else self._hl()
        hi = opc >> 4
        lo = opc & 0xF
        # 1. LD r,n  (0x06,0x0E,0x16,0x1E,0x26,0x2E,0x36,0x3E)
        if lo in (6, 0xE) and hi <= 3:
            n = self.fetch()
            r = hi*2 + (1 if lo == 0xE else 0)
            if r == 6:  # (HL) or (IX+d)
                self.write(idx_addr() if idx is not None else self._hl(), n)
            else:
                self.rset(r, n)
            return
        # 2. LD r,r'  (0x40-0x7F, 0x76 = HALT). dst/src are 3-bit fields.
        if 0x40 <= opc <= 0x7F:
            if opc == 0x76:
                self.halted = True
                return
            dst = (opc >> 3) & 7
            src = opc & 7
            if dst == 6 and src == 6:
                self._fault_illegal(); return
            if idx is not None and (dst == 4 or dst == 5 or src == 6):
                # indexed: H/L as IXH/IXL and (HL) as (IX+d)
                if src == 6:
                    v = self.read(idx_addr())
                elif src == 4 and pre:
                    v = (idx >> 8) & 0xFF
                elif src == 5 and pre:
                    v = idx & 0xFF
                else:
                    v = self.rget(src)
                if dst == 6:
                    self.write(idx_addr(), v)
                elif dst == 4 and pre:
                    idx = (idx & 0x00FF) | (v << 8)
                elif dst == 5 and pre:
                    idx = (idx & 0xFF00) | v
                else:
                    self.rset(dst, v)
                if pre == PREFIX_DD: self.IX = idx
                else: self.IY = idx
                return
            if src == 6:
                v = self.read(idx_addr() if idx is not None else self._hl())
            else:
                v = self.rget(src)
            if dst == 6:
                self.write(idx_addr() if idx is not None else self._hl(), v)
            else:
                self.rset(dst, v)
            return
        # 3. 8-bit ALU r / (HL) / (IX+d)  (0x80-0xBF: op=(opc>>3)&7, r=opc&7)
        if 0x80 <= opc <= 0xBF:
            op = ALU_OPS[(opc >> 3) & 7]
            src = opc & 7
            if src == 6:
                v = self.read(idx_addr() if idx is not None else self._hl())
            else:
                v = self.rget(src)
            self._alu(op, v)
            return
        # 4. ALU A,n (0xC6 ADD,0xCE ADC,0xD6 SUB,0xDE SBC,0xE6 AND,0xEE XOR,0xF6 OR,0xFE CP)
        if lo in (6, 0xE) and hi >= 0xC:
            opc2n = {0xC6: "ADD A", 0xCE: "ADC A", 0xD6: "SUB", 0xDE: "SBC A",
                     0xE6: "AND", 0xEE: "XOR", 0xF6: "OR", 0xFE: "CP"}
            n = self.fetch()
            self._alu(opc2n[opc], n)
            return
        # 5. INC/DEC r (0x04/0x0C INC, 0x05/0x0D DEC; hi 0..3)
        if lo in (4, 0xC, 5, 0xD) and hi <= 3:
            r = hi*2 + (1 if lo in (0xC, 0xD) else 0)
            is_inc = lo in (4, 0xC)
            if r == 6:
                addr = idx_addr() if idx is not None else self._hl()
                a = self.read(addr)
                a, self.F = self._inc8(a, self.F) if is_inc else self._dec8(a, self.F)
                self.write(addr, a)
            else:
                a = self.rget(r)
                a, self.F = self._inc8(a, self.F) if is_inc else self._dec8(a, self.F)
                self.rset(r, a)
            return
        # 6. 16-bit immediate loads / inc/dec / add HL (DD/FD: HL -> IX/IY)
        if lo == 1 and hi <= 3:        # LD rr,nn
            nn = self.fetch16()
            if hi == 2 and idx is not None:
                if pre == PREFIX_DD: self.IX = nn
                else: self.IY = nn
            else:
                self._set16(RP_ADD[hi], nn)
            return
        if lo == 2 and hi in (0, 1, 2, 3):
            # 0x02 (BC),A ; 0x12 (DE),A ; 0x22 (nn),HL/IX ; 0x32 (nn),A
            if hi == 0: self.write(self._get16("BC"), self.A)
            elif hi == 1: self.write(self._get16("DE"), self.A)
            elif hi == 2: self._write16(self.fetch16(), idx if idx is not None else self._hl())
            elif hi == 3: self._write16(self.fetch16(), self.A)
            return
        if lo == 0xA and hi in (0, 1, 2, 3):
            if hi == 0: self.A = self.read(self._get16("BC"))
            elif hi == 1: self.A = self.read(self._get16("DE"))
            elif hi == 2:
                v = self._read16(self.fetch16())
                if idx is not None:
                    if pre == PREFIX_DD: self.IX = v
                    else: self.IY = v
                else:
                    self._set_hl(v)
            elif hi == 3: self.A = self.read(self.fetch16())
            return
        if lo in (3, 0xB) and hi <= 3:  # INC/DEC rr (HL -> IX/IY when indexed)
            if hi == 2 and idx is not None:
                idx = (idx + 1 if lo == 3 else idx - 1) & 0xFFFF
                if pre == PREFIX_DD: self.IX = idx
                else: self.IY = idx
            else:
                name = RP_ADD[hi]; v = self._get16(name)
                self._set16(name, (v + 1 if lo == 3 else v - 1) & 0xFFFF)
            return
        if lo == 9 and hi <= 3:         # ADD HL,rr (or ADD IX/IY,rr when indexed)
            v = self._get16(RP_ADD[hi])
            if idx is not None:
                idx, self.F = self._add16(idx, v, self.F)
                if pre == PREFIX_DD: self.IX = idx
                else: self.IY = idx
            else:
                hl, self.F = self._add16(self._hl(), v, self.F)
                self._set_hl(hl)
            return
        # 7. rotates A (0x07,0x0F,0x17,0x1F)
        if opc == 0x07: self.A, self.F = self._rlc(self.A, self.F); return
        if opc == 0x0F: self.A, self.F = self._rrc(self.A, self.F); return
        if opc == 0x17: self.A, self.F = self._rl(self.A, self.F); return
        if opc == 0x1F: self.A, self.F = self._rr(self.A, self.F); return
        # 8. stack PUSH/POP (0xC5/D5/E5/F5 push; 0xC1/D1/E1/F1 pop)
        if lo == 5 and hi >= 0xC:
            self.push(self.rp16(hi & 3, 1)); return
        if lo == 1 and hi >= 0xC:
            self._set16(RP_PUSH[hi & 3], self.pop()); return
        # 9. exchange (0xEB EX DE,HL; 0x08 EX AF; 0xD9 EXX; 0xE3 EX (SP),HL)
        if opc == 0xEB:
            de = self._get16("DE"); self._set16("DE", self._hl()); self._set_hl(de); return
        if opc == 0x08:
            self.A, self.Ap = self.Ap, self.A; self.F, self.Fp = self.Fp, self.F; return
        if opc == 0xD9:
            (self.B, self.Bp) = (self.Bp, self.B); (self.C, self.Cp) = (self.Cp, self.C)
            (self.D, self.Dp) = (self.Dp, self.D); (self.E, self.Ep) = (self.Ep, self.E)
            (self.H, self.Hp) = (self.Hp, self.H); (self.L, self.Lp) = (self.Lp, self.L); return
        if opc == 0xE3:
            sp = self.SP; top = self._read16(sp)
            self._write16(sp, self._hl() if idx is None else idx)
            if idx is None: self._set_hl(top)
            else:
                if pre == PREFIX_DD: self.IX = top
                else: self.IY = top
            return
        # 10. control
        if opc == 0xC3: self.PC = self.fetch16(); return          # JP nn
        if 0xC2 <= opc <= 0xFA and (opc & 0xE7) == 0xC2:          # JP cc,nn
            cc = (opc >> 3) & 7; nn = self.fetch16()
            if self._cc(cc): self.PC = nn
            return
        if opc == 0xE9: self.PC = self._hl() if idx is None else idx; return  # JP (HL)/(IX)
        if opc == 0x18: self._jr(self.fetch()); return           # JR e
        if opc in (0x20, 0x28, 0x30, 0x38):                      # JR cc,e
            cc = {0x20: 0, 0x28: 1, 0x30: 2, 0x38: 3}[opc]
            self._jr(self.fetch(), cond=self._cc(cc)); return
        if opc == 0x10: self._jr(self.fetch(), cond=(self.B != 0), dj=True); return  # DJNZ
        if opc == 0xCD: self._call(self.fetch16()); return       # CALL nn
        if opc in (0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC):  # CALL cc,nn
            cc = (opc >> 3) & 7; nn = self.fetch16()
            if self._cc(cc): self._call(nn)
            return
        if opc == 0xC9: self.PC = self.pop(); return             # RET
        if opc in (0xC0, 0xC8, 0xD0, 0xD8, 0xE0, 0xE8, 0xF0, 0xF8):  # RET cc
            cc = (opc >> 3) & 7
            if self._cc(cc): self.PC = self.pop()
            return
        if opc in (0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF):  # RST p
            self._call(RST["%02X" % ((opc & 0x38) >> 3)]); return
        # 11. misc
        if opc == 0xF3: self.IFF1 = self.IFF2 = 0; return        # DI
        if opc == 0xFB: self.IFF1 = self.IFF2 = 1; return        # EI
        if opc == 0xF9: self.SP = self._hl() if idx is None else idx; return  # LD SP,HL/IX/IY
        if opc == 0x00: return                                   # NOP
        self._fault_illegal()

    def _jr(self, e, cond=True, dj=False):
        if dj:
            self.B = (self.B - 1) & 0xFF
            cond = self.B != 0
        e = e if e < 0x80 else e - 0x100
        if cond:
            self.PC = (self.PC + e) & 0xFFFF

    def _call(self, nn):
        self.push(self.PC)
        self.PC = nn & 0xFFFF

    def _alu(self, op, v):
        a = self.A
        if op == "ADD A":
            self.A, self.F = self._add8(a, v, 0, self.F)
        elif op == "ADC A":
            self.A, self.F = self._add8(a, v, 1 if (self.F & F_C) else 0, self.F)
        elif op == "SUB":
            self.A, self.F = self._sub8(a, v, 0, self.F)
        elif op == "SBC A":
            self.A, self.F = self._sub8(a, v, 1 if (self.F & F_C) else 0, self.F)
        elif op in ("AND", "OR", "XOR"):
            r = a & v if op == "AND" else (a | v if op == "OR" else a ^ v)
            self.A, self.F = self._logic8(r, op, self.F)
        elif op == "CP":
            _, self.F = self._sub8(a, v, 0, self.F)  # sets flags, discards result

    def _fault_illegal(self):
        self.halted = True
        self.faulted = True
        self.fault_code = 0x01  # ILLEGAL_OPCODE

    # ---- run loop ----
    def run(self, max_steps=2_000_000):
        while not (self.halted or self.faulted) and self.instruction_count < max_steps:
            self.step()
        return self.instruction_count


class BusError(Exception):
    def __init__(self, addr):
        self.addr = addr


if __name__ == "__main__":
    # smoke: a tiny program that adds 3+4 and halts.
    # LD A,3 (0x3E 03) ; ADD A,4 (0xC6 04) ; HALT (0x76)
    m = Z80.make(bytes([0x3E, 0x03, 0xC6, 0x04, 0x76]))
    m.run()
    print("A=%02X PC=%04X steps=%d halted=%s faulted=%s" %
          (m.A, m.PC, m.instruction_count, m.halted, m.faulted))
