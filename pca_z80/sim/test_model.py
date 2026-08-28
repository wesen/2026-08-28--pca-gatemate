# test_model.py — Z80 reference-model unit tests (Phase 2 oracle, design-doc §10).
#
# Hand-computed expectations for the baseline subset: 8-bit ALU + flags, loads,
# INC/DEC, 16-bit, control, stack, exchange, rotates, and the DD/FD/CB/ED
# prefixes. These are the fast, toolchain-independent tests run constantly; the
# model is the oracle Phase 3 RTL is differential-tested against.
import sys, os, struct
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from z80_model import Z80
from z80_isa import F_S, F_Z, F_H, F_PV, F_N, F_C

def run(prog, regs=None, mem=None, max_steps=10000):
    m = Z80.make(bytes(prog))
    if regs:
        for k, v in regs.items():
            setattr(m, k, v)
    if mem:
        for a, v in mem.items():
            m.mem[a & 0xFFFF] = v & 0xFF
    m.run(max_steps)
    return m

# ---- helpers ----
def prog_add_a(v): return [0xC6, v]            # ADD A,n
def prog_sub(v):   return [0xD6, v]            # SUB n

# ---- 8-bit ALU flag tests (hand-computed) ----
def test_add_no_carry():
    m = run([0x3E, 0x10, 0xC6, 0x01, 0x76])   # LD A,0x10 ; ADD A,1 -> 0x11, no H, no C
    assert m.A == 0x11
    assert not (m.F & F_C) and not (m.F & F_H) and not (m.F & F_N)
    assert not (m.F & F_S) and not (m.F & F_Z) and not (m.F & F_PV)

def test_add_half_carry():
    m = run([0x3E, 0x0F, 0xC6, 0x01, 0x76])    # 0x0F + 0x01 -> H set (bit3->4)
    assert m.A == 0x10
    assert m.F & F_H

def test_add_carry_out():
    m = run([0x3E, 0xFF, 0xC6, 0x01, 0x76])   # 0xFF + 0x01 -> 0x00, C set, Z set, no PV
    assert m.A == 0x00
    assert m.F & F_C and m.F & F_Z and not (m.F & F_S)
    assert not (m.F & F_PV)  # -1 + 1 = 0: signed result fits, no overflow

def test_add_signed_overflow_no_carry():
    m = run([0x3E, 0x7F, 0xC6, 0x01, 0x76])   # 0x7F + 0x01 -> 0x80, PV set (overflow), C clear
    assert m.A == 0x80
    assert m.F & F_PV and m.F & F_S and not (m.F & F_C)

def test_sub_borrow():
    m = run([0x3E, 0x00, 0xD6, 0x01, 0x76])   # 0 - 1 -> 0xFF, C set, N set, S set
    assert m.A == 0xFF
    assert m.F & F_C and m.F & F_N and m.F & F_S and not (m.F & F_Z)

def test_sub_zero():
    m = run([0x3E, 0x05, 0xD6, 0x05, 0x76])   # 5 - 5 -> 0, Z set, N set, C clear
    assert m.A == 0x00
    assert m.F & F_Z and m.F & F_N and not (m.F & F_C)

def test_adc_uses_carry():
    # 0 - 1 sets C; LD A,1 (flags unchanged); ADC A,1 -> 1+1+1 = 3, C clear
    m = run([0x3E, 0x00, 0xD6, 0x01, 0x3E, 0x01, 0xCE, 0x01, 0x76])
    assert m.A == 3 and not (m.F & F_C)

def test_sbc_uses_carry():
    m = run([0x3E, 0x00, 0xD6, 0x01, 0x3E, 0x05, 0xDE, 0x02, 0x76])
    # 0-1 sets C; LD A,5; SBC A,2 -> 5 - 2 - 1 = 2
    assert m.A == 2

def test_and_flags():
    m = run([0x3E, 0xF0, 0xE6, 0x0F, 0x76])   # 0xF0 AND 0x0F -> 0x00, Z, H set, C clear
    assert m.A == 0x00
    assert m.F & F_Z and m.F & F_H and not (m.F & F_C) and not (m.F & F_N)

def test_or_flags():
    m = run([0x3E, 0xF0, 0xF6, 0x0F, 0x76])   # 0xF0 OR 0x0F -> 0xFF, S set, H clear
    assert m.A == 0xFF
    assert m.F & F_S and not (m.F & F_H) and not (m.F & F_C)

def test_xor_flags():
    m = run([0x3E, 0xFF, 0xEE, 0x0F, 0x76])   # 0xFF XOR 0x0F -> 0xF0, S set, Z clear
    assert m.A == 0xF0 and m.F & F_S and not (m.F & F_Z)

def test_cp_sets_flags_keeps_a():
    m = run([0x3E, 0x05, 0xFE, 0x05, 0x76])   # CP 5: Z set, A unchanged
    assert m.A == 0x05 and m.F & F_Z
    m = run([0x3E, 0x05, 0xFE, 0x0A, 0x76])   # CP 10: 5<10 -> C set, A unchanged
    assert m.A == 0x05 and m.F & F_C

# ---- INC/DEC ----
def test_inc_zero_to_one():
    m = run([0x3E, 0x00, 0x3C, 0x76])         # LD A,0; INC A -> 1, Z clear, no C
    assert m.A == 1 and not (m.F & F_Z) and not (m.F & F_C)

def test_inc_overflow_7f():
    m = run([0x3E, 0x7F, 0x3C, 0x76])         # INC 0x7F -> 0x80, PV set, S set
    assert m.A == 0x80 and m.F & F_PV and m.F & F_S

def test_inc_wraps_preserves_carry():
    m = run([0x3E, 0x00, 0xD6, 0x01, 0x3E, 0xFF, 0x3C, 0x76])
    # set C via 0-1; LD A,0xFF; INC A -> 0x00 (Z), C preserved (still set)
    assert m.A == 0x00 and m.F & F_Z and m.F & F_C

def test_dec_zero():
    m = run([0x3E, 0x00, 0x3D, 0x76])         # DEC 0 -> 0xFF, S set, N set, H set
    assert m.A == 0xFF and m.F & F_S and m.F & F_N and m.F & F_H

# ---- loads ----
def test_ld_r_n_all():
    for r, op in [("B", 0x06), ("C", 0x0E), ("D", 0x16), ("E", 0x1E),
                  ("H", 0x26), ("L", 0x2E), ("A", 0x3E)]:
        m = run([op, 0xAA, 0x76])
        assert getattr(m, r) == 0xAA, (r, getattr(m, r))

def test_ld_r_rprime():
    m = run([0x3E, 0x42, 0x47, 0x76])         # LD A,0x42; LD B,A
    assert m.B == 0x42 and m.A == 0x42

def test_ld_hl_mem():
    m = run([0x21, 0x00, 0x10, 0x7E, 0x76])   # LD HL,0x1000; LD A,(HL)
    assert m.A == 0
    m = run([0x21, 0x00, 0x10, 0x7E, 0x76], mem={0x1000: 0x99})
    assert m.A == 0x99

def test_ld_rr_nn():
    m = run([0x01, 0x34, 0x12, 0x76])         # LD BC,0x1234
    assert m.B == 0x12 and m.C == 0x34

def test_ld_a_nn_and_store():
    prog = [0x3E, 0x55, 0x32, 0x00, 0x20, 0x3A, 0x00, 0x20, 0x76]  # LD A,0x55;(2000),A;A,(2000)
    m = run(prog)
    assert m.A == 0x55 and m.mem[0x2000] == 0x55

# ---- 16-bit ----
def test_add_hl():
    m = run([0x21, 0xFF, 0x0F, 0x09, 0x76], regs={"B": 0x00, "C": 0x02})
    # LD HL,0x0FFF; ADD HL,BC(=0x0002) -> 0x1001, C from 0xFFF+0x002 no carry? 0x0FFF+2=0x1001 no carry-out of 16-bit. H from bit11.
    assert m._hl() == 0x1001
    # carry: 0x0FFF+0x0002 = 0x1001, no 16-bit carry. H: 0xFFF+0x002 bit11..15: 0xF+0x2=0x11>0xF -> H set
    assert m.F & F_H and not (m.F & F_C) and not (m.F & F_N)

def test_inc_dec_rr():
    m = run([0x01, 0xFF, 0xFF, 0x03, 0x76])   # LD BC,0xFFFF; INC BC -> 0x0000
    assert (m.B << 8 | m.C) == 0x0000
    m = run([0x01, 0x00, 0x00, 0x0B, 0x76])   # DEC BC -> 0xFFFF
    assert (m.B << 8 | m.C) == 0xFFFF

# ---- control ----
def test_jp():
    prog = [0xC3, 0x04, 0x00, 0x76, 0x3E, 0x07, 0x76]  # JP 0x04; (0x03 HALT skipped); LD A,7; HALT
    m = run(prog)
    assert m.A == 0x07 and m.halted

def test_jr_taken():
    # LD A,1; JR -2 (loops on JR forever -> watchdog by max_steps). Use JR forward.
    prog = [0x18, 0x02, 0x76, 0x76, 0x3E, 0x07, 0x76]  # JR +2 (skip two HALT/NOP) to LD A,7
    m = run(prog)
    assert m.A == 0x07

def test_jr_cc_not_taken():
    # LD A,1 (Z clear); JR NZ,+1 -> taken to LD A,2; else JR Z not taken
    prog = [0x3E, 0x01, 0x20, 0x02, 0x76, 0x76, 0x3E, 0x02, 0x76]
    # JR NZ +2: from PC=3, +2 = skip to addr 0x07 (LD A,2)
    m = run(prog)
    assert m.A == 0x02

def test_djnz_loop():
    # LD B,3; loop: DEC B (in DJNZ); DJNZ loop; HALT. After 3 iterations B=0.
    prog = [0x06, 0x03, 0x10, 0xFD, 0x76]   # LD B,3; DJNZ -3; HALT
    m = run(prog)
    assert m.B == 0
    assert m.instruction_count >= 4

def test_call_ret():
    # CALL 0x06; HALT; (at 0x06) LD A,0x42; RET
    prog = [0xCD, 0x06, 0x00, 0x76, 0x00, 0x00, 0x3E, 0x42, 0xC9, 0x76]
    m = run(prog, regs={"SP": 0xFFFE})
    assert m.A == 0x42 and m.PC == 0x04  # returns to after CALL (addr 4 = HALT)

def test_call_cc_not_taken():
    # LD A,0; CP 0 (Z set); CALL NZ,0x0A (not taken); LD A,1; HALT; [0x0A] LD A,0x42; RET
    prog = [0x3E, 0x00, 0xFE, 0x00, 0xC4, 0x0A, 0x00, 0x3E, 0x01, 0x76,
           0x3E, 0x42, 0xC9]
    m = run(prog, regs={"SP": 0xFFFE})
    assert m.A == 0x01  # CP 0 sets Z; CALL NZ not taken; falls to LD A,1

# ---- stack ----
def test_push_pop():
    m = run([0x01, 0x34, 0x12, 0xC5, 0xD1, 0x76], regs={"SP": 0xFFFE})  # LD BC,1234;PUSH BC;POP DE
    assert m.D == 0x12 and m.E == 0x34
    assert m.SP == 0xFFFE

# ---- exchange ----
def test_ex_de_hl():
    # LD DE,0x55AA (D=0x55,E=0xAA); LD HL,0x66BB (H=0x66,L=0xBB); EX DE,HL
    m = run([0x11, 0xAA, 0x55, 0x21, 0xBB, 0x66, 0xEB, 0x76])
    assert m.D == 0x66 and m.E == 0xBB and m.H == 0x55 and m.L == 0xAA

def test_exx():
    m = run([0x06, 0x11, 0xD9, 0x76])  # LD B,0x11; EXX (0xD9) (B<->B')
    assert m.B == 0x00 and m.Bp == 0x11

def test_ex_af():
    m = run([0x3E, 0x42, 0x08, 0x76])  # LD A,0x42; EX AF,AF'
    assert m.A == 0x00 and m.Ap == 0x42

# ---- rotates ----
def test_rlca():
    m = run([0x3E, 0x81, 0x07, 0x76])  # LD A,0x81; RLCA -> 0x03, C set
    assert m.A == 0x03 and m.F & F_C

def test_rrca():
    m = run([0x3E, 0x01, 0x0F, 0x76])  # LD A,0x01; RRCA -> 0x80, C set, S set
    assert m.A == 0x80 and m.F & F_C and m.F & F_S

def test_rla():
    m = run([0x3E, 0x80, 0x17, 0x76])  # LD A,0x80; RLA (0x17) -> A=0x00, C=1 (no prior carry)
    assert m.A == 0x00 and m.F & F_C

# ---- CB-prefixed ----
def test_cb_rlc_r():
    m = run([0x3E, 0x81, 0xCB, 0x07, 0x76])  # LD A,0x81; RLC A -> 0x03, C set
    assert m.A == 0x03 and m.F & F_C

def test_cb_bit():
    m = run([0x3E, 0x04, 0xCB, 0x60, 0x76])  # LD A,4; BIT 4,A -> Z set (bit4=0)
    assert m.F & F_Z

def test_cb_res_set():
    m = run([0x3E, 0xFF, 0xCB, 0x87, 0x76])  # LD A,0xFF; RES 0,A -> 0xFE
    assert m.A == 0xFE
    m = run([0x3E, 0x00, 0xCB, 0xC7, 0x76])  # LD A,0; SET 0,A -> 0x01
    assert m.A == 0x01

# ---- DD/FD (IX/IY) ----
def test_ld_ix_nn():
    m = run([0xDD, 0x21, 0x34, 0x12, 0x76])  # LD IX,0x1234
    assert m.IX == 0x1234

def test_ld_a_ix_plus_d():
    # LD IX,0x1000; LD A,(IX+2) -> mem[0x1002]
    m = run([0xDD, 0x21, 0x00, 0x10, 0xDD, 0x7E, 0x02, 0x76], mem={0x1002: 0x77})
    assert m.A == 0x77

def test_inc_ix():
    m = run([0xDD, 0x21, 0xFF, 0xFF, 0xDD, 0x23, 0x76])  # LD IX,0xFFFF; INC IX -> 0
    assert m.IX == 0x0000

def test_add_ix():
    m = run([0xDD, 0x21, 0xFF, 0x0F, 0xDD, 0x09, 0x76], regs={"B": 0, "C": 2})  # ADD IX,BC
    assert m.IX == 0x1001

def test_iy():
    m = run([0xFD, 0x21, 0x00, 0x20, 0xFD, 0x7E, 0x05, 0x76], mem={0x2005: 0x33})
    assert m.A == 0x33

# ---- ED-prefixed ----
def test_ed_neg():
    m = run([0x3E, 0x05, 0xED, 0x44, 0x76])  # LD A,5; NEG -> -5 = 0xFB, S set, C set
    assert m.A == 0xFB and m.F & F_S and m.F & F_C and m.F & F_N

def test_ed_ldi():
    # LD HL,0x1000; LD DE,0x2000; LD BC,1; LDI -> copies 1 byte, BC->0
    m = run([0x21, 0x00, 0x10, 0x11, 0x00, 0x20, 0x01, 0x01, 0x00, 0xED, 0xA0, 0x76],
            mem={0x1000: 0xAB})
    assert m.mem[0x2000] == 0xAB and (m.B << 8 | m.C) == 0

def test_ed_ld_nn_rr():
    # LD BC,0x1234; LD (0x3000),BC
    m = run([0x01, 0x34, 0x12, 0xED, 0x43, 0x00, 0x30, 0x76])
    assert m.mem[0x3000] == 0x34 and m.mem[0x3001] == 0x12

# ---- precise fault (bus error) ----
def test_bus_fault_halts():
    m = Z80.make(bytes([0x3A, 0x00, 0x10, 0x76]))  # LD A,(0x1000)
    m.fault_at(0x1000)   # set the fault BEFORE running
    m.run()
    assert m.faulted and m.halted
    assert m.instruction_count == 0  # the faulting LD did not retire

def test_illegal_opcode_faults():
    m = run([0xDD, 0xDD, 0x76])  # DD DD is not a valid sequence in baseline
    # (model may treat second DD as a prefix again -> DD DD 76 = LD (IX+0x76)? no, 0x76 after DD is HALT)
    # Use a clearly illegal byte: 0xD3 (OUT (n),A) is not in baseline.
    m2 = run([0xD3, 0x00, 0x76])
    assert m2.faulted
