#!/usr/bin/env python3
# z80_isa.py — the Z80 ISA contract (single source of truth).
#
# Consumed by the reference model (z80_model.py), the assembler (Phase 4), the
# decoder/disassembler, and the tests — exactly as opcodes.py is the single
# contract for the sibling MATE-16 project. Change it here; everything else
# reads it.
#
# Scope: a focused BASELINE subset of the Z80 (design-doc §5.2), enough to run
# real programs and to drive the Phase 3 object graph and Phase 5 differential
# tests. Undocumented opcodes and the full ED set are Phase 7. The set is
# deliberately explicit (an IMPLEMENTED set) so the model and assembler agree
# on what is legal.

# ---- Flag bits in the F register ----
F_S  = 0x80  # sign
F_Z  = 0x40  # zero
F_F5 = 0x20  # undocumented copy of bit 5
F_H  = 0x10  # half-carry
F_F3 = 0x08  # undocumented copy of bit 3
F_PV = 0x04  # parity/overflow
F_N  = 0x02  # add/subtract
F_C  = 0x01  # carry

# ---- 8-bit register r-table (the 000..111 encoding) ----
# index 6 is the (HL) memory operand, as in the real Z80.
R8 = ["B", "C", "D", "E", "H", "L", "(HL)", "A"]

# ---- 16-bit register-pair rp-table (the 00..11 encoding for ADD HL,rr) ----
RP_ADD = ["BC", "DE", "HL", "SP"]

# ---- rp-table for PUSH/POP (00..11) ----
RP_PUSH = ["BC", "DE", "HL", "AF"]

# ---- condition codes cc (000..111) ----
CC = ["NZ", "Z", "NC", "C", "PO", "PE", "P", "M"]

# ---- restart vectors p (000..111) -> address ----
RST = {"00": 0x00, "08": 0x08, "10": 0x10, "18": 0x18,
       "20": 0x20, "28": 0x28, "30": 0x30, "38": 0x38}

# ---- Prefix bytes ----
PREFIX_DD = 0xDD
PREFIX_FD = 0xFD
PREFIX_CB = 0xCB
PREFIX_ED = 0xED

# ---- Single-operand rotate/shift ops (CB-prefixed) ----
# (mnemonic, modifies-carry)
CB_SHIFT = ["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"]

# ---- ALU operations (the 000..111 secondary opcode for ALU r) ----
ALU_OPS = ["ADD A", "ADC A", "SUB", "SBC A", "AND", "XOR", "OR", "CP"]

# ---- The implemented baseline instruction set (authoritative) ----
# Each entry: mnemonic -> (length_template, operands, flag_class)
#   length_template: base byte length excluding prefixes and (IX+d) displacement
#   operands:        list describing operand kinds, for the assembler
#   flag_class:      which flags are affected (string tag the model interprets)
IMPLEMENTED = {
    "NOP":  (1, [], "none"),
    "HALT": (1, [], "none"),
    "LD":   (1, ["r,r", "r,n", "r,(HL)", "(HL),r", "A,(BC)", "A,(DE)",
                 "A,(nn)", "(nn),A", "r,(IX+d)", "(IX+d),r",
                 "rr,nn", "HL,(nn)", "(nn),HL", "SP,HL", "rr,(nn)", "(nn),rr"],
             "none"),
    # 8-bit ALU
    "ADD A":  (1, ["r", "(HL)", "n", "(IX+d)"], "arith8"),
    "ADC A":  (1, ["r", "(HL)", "n", "(IX+d)"], "arith8_c"),
    "SUB":    (1, ["r", "(HL)", "n", "(IX+d)"], "sub8"),
    "SBC A":  (1, ["r", "(HL)", "n", "(IX+d)"], "sub8_c"),
    "AND":    (1, ["r", "(HL)", "n", "(IX+d)"], "logic8"),
    "OR":     (1, ["r", "(HL)", "n", "(IX+d)"], "logic8"),
    "XOR":    (1, ["r", "(HL)", "n", "(IX+d)"], "logic8"),
    "CP":     (1, ["r", "(HL)", "n", "(IX+d)"], "cp8"),
    "INC":    (1, ["r", "(HL)", "(IX+d)", "rr", "IX", "IY"], "inc8"),
    "DEC":    (1, ["r", "(HL)", "(IX+d)", "rr", "IX", "IY"], "dec8"),
    # 16-bit
    "ADD HL": (1, ["rr"], "arith16_none"),      # does not affect S/Z/PV
    "ADD IX": (1, ["rr"], "arith16_none"),
    "ADD IY": (1, ["rr"], "arith16_none"),
    # control
    "JP":     (1, ["nn", "cc,nn", "(HL)", "(IX)"], "none"),
    "JR":     (1, ["e", "cc,e"], "none"),         # cc limited to NZ/Z/NC/C
    "DJNZ":   (1, ["e"], "none"),
    "CALL":   (1, ["nn", "cc,nn"], "none"),
    "RET":    (1, ["", "cc"], "none"),
    "RST":    (1, ["p"], "none"),
    # stack
    "PUSH":   (1, ["rr"], "none"),
    "POP":    (1, ["rr"], "none"),
    # exchange
    "EX":     (1, ["DE,HL", "AF,AF'", "(SP),HL", "(SP),IX", "(SP),IY"], "none"),
    "EXX":    (1, [], "none"),
    # rotates/shifts (unprefixed 4)
    "RLCA":   (1, [], "rot_a"),
    "RRCA":   (1, [], "rot_a"),
    "RLA":    (1, [], "rot_a"),
    "RRA":    (1, [], "rot_a"),
    # misc
    "DI":     (1, [], "none"),
    "EI":     (1, [], "none"),
    "LD SP":  (1, ["HL"], "none"),
}

# CB-prefixed: rotate/shift r and BIT/SET/RES (design-doc §5.2).
CB_IMPLEMENTED = {op: (2, ["r", "(HL)"], "cb_rot") for op in CB_SHIFT}
CB_BIT = {  # (mnemonic, operand pattern)
    "BIT": (2, ["b,r", "b,(HL)"], "bit"),
    "RES": (2, ["b,r", "b,(HL)"], "res_set"),
    "SET": (2, ["b,r", "b,(HL)"], "res_set"),
}

# ED-prefixed baseline subset (block + 16-bit loads).
ED_IMPLEMENTED = {
    "LDI":  (2, [], "none"),
    "LDD":  (2, [], "none"),
    "LD (nn),rr": (2, ["rr"], "none"),   # rr in {BC,DE,HL,SP}? actually HL only for ED; keep generic
    "LD rr,(nn)": (2, ["rr"], "none"),
    "NEG":  (2, [], "neg"),
    "CPL":  (2, [], "cpl"),
}

def is_implemented(mnemonic: str) -> bool:
    return mnemonic in IMPLEMENTED or mnemonic in CB_IMPLEMENTED or mnemonic in ED_IMPLEMENTED

def all_mnemonics() -> list[str]:
    return sorted(list(IMPLEMENTED) + list(CB_IMPLEMENTED) + list(ED_IMPLEMENTED))
