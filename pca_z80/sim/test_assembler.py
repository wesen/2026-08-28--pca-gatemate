# test_assembler.py — zasm.py golden-vector + cross-check tests (Phase 4).
#
# Golden vectors: hand-computed byte sequences for each implemented instruction
# form. Cross-check: assemble a program, run it on the z80_model.py oracle, and
# verify the retired state matches — i.e. the assembler's output is executable
# Z80 that the model agrees with. (The object graph is differential-tested
# separately in tb_z80_core.sv; here we prove the assembler produces correct
# bytes the model can run.)
import sys, os, tempfile
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from zasm import assemble
from z80_model import Z80

def asm_bytes(text):
    img, sym, lst = assemble(text)
    return bytes(img)

# ---- golden vectors (hand-computed) ----
def test_nop_halt():
    assert asm_bytes("NOP\nHALT") == bytes([0x00, 0x76])

def test_ld_r_n():
    assert asm_bytes("LD A,0x42") == bytes([0x3E, 0x42])
    assert asm_bytes("LD B,0x10") == bytes([0x06, 0x10])
    assert asm_bytes("LD C,0x22") == bytes([0x0E, 0x22])

def test_ld_r_r():
    assert asm_bytes("LD B,A") == bytes([0x47])
    assert asm_bytes("LD D,A") == bytes([0x57])

def test_ld_rr_nn():
    assert asm_bytes("LD BC,0x1234") == bytes([0x01, 0x34, 0x12])
    assert asm_bytes("LD HL,0xABCD") == bytes([0x21, 0xCD, 0xAB])

def test_alu_a_n():
    assert asm_bytes("ADD A,0x01") == bytes([0xC6, 0x01])
    assert asm_bytes("SUB 0x03") == bytes([0xD6, 0x03])
    assert asm_bytes("AND 0x0F") == bytes([0xE6, 0x0F])
    assert asm_bytes("CP 0x05") == bytes([0xFE, 0x05])

def test_alu_a_r():
    assert asm_bytes("ADD A,B") == bytes([0x80])
    assert asm_bytes("SUB C") == bytes([0x91])
    assert asm_bytes("AND D") == bytes([0xA2])

def test_jp():
    assert asm_bytes("JP 0x1234") == bytes([0xC3, 0x34, 0x12])
    assert asm_bytes("JP NZ,0x5678") == bytes([0xC2, 0x78, 0x56])

def test_jr_label():
    # JR to a forward label; disp is relative to PC after the JR (addr+2).
    # JR loop (2B@0) ; NOP (1B@2) ; loop: HALT (1B@3). disp = 3 - 2 = 1
    img = asm_bytes("    JR loop\n    NOP\nloop: HALT")
    assert img == bytes([0x18, 0x01, 0x00, 0x76]), img.hex()

def test_jr_forward_skip():
    # JR skip(2B@0); NOP(1B@2); skip: LD A,0x01(2B@3); HALT(1B@5). disp = 3-2 = 1
    img = asm_bytes("    JR skip\n    NOP\nskip: LD A,0x01\n    HALT")
    assert img == bytes([0x18, 0x01, 0x00, 0x3E, 0x01, 0x76]), img.hex()

def test_call_ret():
    assert asm_bytes("CALL 0x0123") == bytes([0xCD, 0x23, 0x01])
    assert asm_bytes("RET") == bytes([0xC9])

def test_push_pop():
    assert asm_bytes("PUSH BC") == bytes([0xC5])
    assert asm_bytes("PUSH AF") == bytes([0xF5])
    assert asm_bytes("POP DE") == bytes([0xD1])
    assert asm_bytes("POP HL") == bytes([0xE1])

def test_misc():
    assert asm_bytes("DI") == bytes([0xF3])
    assert asm_bytes("EI") == bytes([0xFB])
    assert asm_bytes("RLCA") == bytes([0x07])
    assert asm_bytes("EXX") == bytes([0xD9])

def test_mem_ld():
    assert asm_bytes("LD A,(HL)") == bytes([0x7E])
    assert asm_bytes("LD (HL),B") == bytes([0x70])
    assert asm_bytes("LD A,(BC)") == bytes([0x0A])
    assert asm_bytes("LD A,(DE)") == bytes([0x1A])
    assert asm_bytes("LD A,(0x1234)") == bytes([0x3A, 0x34, 0x12])
    assert asm_bytes("LD (0x1234),A") == bytes([0x32, 0x34, 0x12])

def test_inc_dec():
    assert asm_bytes("INC B") == bytes([0x04])
    assert asm_bytes("DEC A") == bytes([0x3D])
    assert asm_bytes("INC BC") == bytes([0x03])
    assert asm_bytes("DEC HL") == bytes([0x2B])
    assert asm_bytes("ADD HL,BC") == bytes([0x09])

def test_cb():
    CB_SHIFT = ["RLC","RRC","RL","RR","SLA","SRA","SLL","SRL"]
    R8N = ["B","C","D","E","H","L","(HL)","A"]
    for op_i, mn in enumerate(CB_SHIFT):
        for r_i, r in enumerate(R8N):
            if r == "(HL)":
                continue  # baseline defers (HL) CB ops
            b = 0x00 | (op_i << 3) | r_i
            assert asm_bytes(mn + " " + r) == bytes([0xCB, b]), (mn, r, asm_bytes(mn + " " + r).hex())
    # BIT/SET/RES b,r
    for b in range(8):
        for r_i, r in enumerate(R8N):
            if r == "(HL)":
                continue
            assert asm_bytes("BIT %d,%s" % (b, r)) == bytes([0xCB, 0x40 | (b << 3) | r_i])
            assert asm_bytes("RES %d,%s" % (b, r)) == bytes([0xCB, 0x80 | (b << 3) | r_i])
            assert asm_bytes("SET %d,%s" % (b, r)) == bytes([0xCB, 0xC0 | (b << 3) | r_i])

# ---- cross-check: assemble -> model run -> state matches ----
def test_cross_check_alu_loop():
    prog = """
    LD A, 0x0F
    ADD A, 0x01
    LD B, A
    JR loop
    NOP
loop:
    LD C, 0x22
    PUSH BC
    POP DE
    HALT
    """
    img = asm_bytes(prog)
    m = Z80(); m.SP = 0xFFFF; m.load(img); m.run()
    assert m.A == 0x10 and m.B == 0x10 and m.C == 0x22 and m.D == 0x10 and m.E == 0x22
    assert m.halted and m.instruction_count == 8

def test_cross_check_call_ret():
    prog = """
    CALL sub
    HALT
    NOP
    NOP
sub:
    LD A, 0x42
    RET
    """
    img = asm_bytes(prog)
    m = Z80(); m.SP = 0xFFFF; m.load(img); m.run()
    assert m.A == 0x42 and m.halted

def test_cross_check_jr_back_loop():
    # LD B,3; loop: DEC? (no DEC yet) -> use a countdown via CP. Simple backward JR.
    prog = """
    LD B, 0x03
loop:
    SUB B
    JR loop
    HALT
    """
    # This loops forever (JR loop with no exit) — cap with max_steps; just check
    # it assembles and the model runs without faulting past a few steps.
    img = asm_bytes(prog)
    m = Z80(); m.SP = 0xFFFF; m.load(img)
    m.run(max_steps=10)
    assert m.instruction_count == 10  # ran 10 instructions then hit the cap

def test_determinism():
    text = "LD A,0x42\nLD B,A\nHALT"
    a = asm_bytes(text)
    b = asm_bytes(text)
    assert a == b == bytes([0x3E, 0x42, 0x47, 0x76])
