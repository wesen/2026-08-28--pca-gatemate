#!/usr/bin/env python3
# zasm.py — a two-pass Z80 assembler (no eval) for the PCA-Z80 baseline.
#
# Targets the implemented instruction set (design-doc §13 Phase 4): the core
# that the object graph executes (NOP/HALT/LD r,n/LD r,r'/8-bit ALU A,r/A,n/
# JP nn/JR e/JR cc,e/CALL nn/RET/PUSH rr/POP rr). Two passes: pass 1 parses to
# an IR + sizes instructions + assigns addresses; pass 2 resolves symbols and
# emits bytes little-endian. The expression evaluator is tiny and hand-written
# (literal/label ± offset) — never eval — mirroring the sibling MATE-16
# asm16.py safety rule (DR-9).
#
# Outputs: program.hex (one 2-digit byte per line for $readmemh), program.bin,
# program.lst (listing), program.sym.json (symbol table).
import sys, re, json, argparse

# ---- instruction metadata (matches z80_isa.py / the object graph) ----
R8 = {"B":0,"C":1,"D":2,"E":3,"H":4,"L":5,"(HL)":6,"A":7}   # r-table index
RP_PUSH = {"BC":0,"DE":1,"HL":2,"AF":3}                    # PUSH/POP pair index
ALU_OPS = {"ADD":0,"ADC":1,"SUB":2,"SBC":3,"AND":4,"XOR":5,"OR":6,"CP":7}
JR_CC = {"NZ":0x20,"Z":0x28,"NC":0x30,"C":0x38}

class AsmError(Exception): pass

def parse_reg(tok):
    t = tok.strip().upper()
    if t in R8: return R8[t]
    raise AsmError("bad register: %s" % tok)

def parse_imm(tok, symtab, pass2):
    # tiny expression evaluator: label, number, label±offset
    tok = tok.strip()
    if not pass2:
        return 0
    # hex 0x.. / $.. / decimal
    neg = False
    expr = tok
    if expr.startswith("-"):
        neg = True; expr = expr[1:].strip()
    if expr.lower().startswith("0x"):
        v = int(expr, 16)
    elif expr.startswith("$"):
        v = int(expr[1:], 16)
    elif expr in symtab:
        v = symtab[expr]
    else:
        try:
            v = int(expr, 0)
        except ValueError:
            raise AsmError("undefined symbol or bad number: %s" % tok)
    return -v if neg else v

def split_operands(operands_list):
    """Split the single operand string on the first comma into a list."""
    if not operands_list:
        return []
    s = operands_list[0]
    return [p.strip() for p in s.split(",", 1)]

def size_of(op, operands_list):
    """Return byte length of one instruction (excluding any prefix)."""
    operands = split_operands(operands_list)
    o = op.upper()
    if o in ("NOP","HALT","RET","EXX","DI","EI","RLCA","RRCA","RLA","RRA"): return 1
    CB_SHIFT = {"RLC","RRC","RL","RR","SLA","SRA","SLL","SRL"}
    if o in CB_SHIFT or o in ("BIT","RES","SET"): return 2   # 0xCB + sub-op
    if o in ("INC","DEC"):
        # INC r / DEC r = 1 byte (r in R8); INC rr / INC IX = handled below if not a single reg
        return 1
    if o == "LD":
        a, b = operands
        au, bu = a.strip().upper(), b.strip().upper()
        # (HL)/(BC)/(DE) operands are 1 byte; (nn) operands are 3 bytes
        if (a.startswith("(") and au in ("(HL)","(BC)","(DE)")) or (b.startswith("(") and bu in ("(HL)","(BC)","(DE)")):
            return 1
        if b.startswith("(") or a.startswith("("):
            return 3
        if a.upper() in R8 and b.upper() in R8:
            return 1
        if a.upper() in ("BC","DE","HL","SP"):
            return 3
        return 2
    if o in ("ADD","ADC","SUB","SBC","AND","XOR","OR","CP"):
        # ADD HL,rr (16-bit) = 1 byte
        if o == "ADD" and len(operands) >= 2 and operands[0].upper() == "HL" and operands[1].upper() in ("BC","DE","HL","SP"):
            return 1
        if len(operands) >= 2 and operands[0].upper() == "A":
            v = operands[1]
        else:
            v = operands[0] if operands else ""
        if v.upper() in R8: return 1
        return 2
    if o == "JP":  return 3
    if o == "JR":  return 2
    if o == "CALL": return 3
    if o in ("PUSH","POP"): return 1
    raise AsmError("unknown op for sizing: %s %s" % (op, operands_list))

def encode(op, operands_list, addr, symtab, pass2):
    """Emit bytes for one instruction at addr (pass2 only)."""
    operands = split_operands(operands_list)
    o = op.upper()
    if o == "NOP":  return [0x00]
    if o == "HALT": return [0x76]
    if o == "RET":  return [0xC9]
    if o == "DI":   return [0xF3]
    if o == "EI":   return [0xFB]
    if o == "RLCA": return [0x07]
    if o == "RRCA": return [0x0F]
    if o == "RLA":  return [0x17]
    if o == "RRA":  return [0x1F]
    if o == "EXX":  return [0xD9]
    CB_SHIFT = {"RLC":0,"RRC":1,"RL":2,"RR":3,"SLA":4,"SRA":5,"SLL":6,"SRL":7}
    R8N = ["B","C","D","E","H","L","(HL)","A"]
    if o in CB_SHIFT:
        r = operands[0].strip().upper()
        if r in R8N:
            return [0xCB, (CB_SHIFT[o] << 3) | R8N.index(r)]
        raise AsmError("CB shift form not supported: %s" % operands)
    if o in ("BIT","RES","SET"):
        # operands already split on comma by split_operands: ["4", "A"]
        b = int(operands[0].strip()) & 7
        r = operands[1].strip().upper()
        if r in R8N:
            base = {"BIT":0x40, "RES":0x80, "SET":0xC0}[o]
            return [0xCB, base | (b << 3) | R8N.index(r)]
        raise AsmError("BIT/RES/SET form not supported: %s" % operands)
    if o in ("INC","DEC"):
        r = operands[0].strip().upper()
        if r in R8:
            # INC r / DEC r: 0x04|0x08*reg or 0x05..., base (o&0xC7): INC=0x04, DEC=0x05, r=(opc>>3)
            base = 0x04 if o == "INC" else 0x05
            return [base | (R8[r] << 3)]
        # INC rr / DEC rr: 0x03|(rp<<4) / 0x0B|(rp<<4), rp 0=BC,1=DE,2=HL,3=SP
        if r in ("BC","DE","HL","SP"):
            rp = {"BC":0,"DE":1,"HL":2,"SP":3}[r]
            base = 0x03 if o == "INC" else 0x0B
            return [base | (rp << 4)]
        raise AsmError("INC/DEC form not supported: %s" % operands)
    if o == "ADD":
        # ADD HL,rr (0x09|(rp<<4)) — the 16-bit add; rp 0=BC,1=DE,2=HL,3=SP
        if len(operands) >= 2 and operands[0].strip().upper() == "HL":
            rr = operands[1].strip().upper()
            if rr in ("BC","DE","HL","SP"):
                rp = {"BC":0,"DE":1,"HL":2,"SP":3}[rr]
                return [0x09 | (rp << 4)]
    if o == "LD":
        a, b = operands
        au, bu = a.strip().upper(), b.strip().upper()
        # LD (nn),A  -> 0x32 lo hi
        if au == "(NN)" or (a.strip().upper().startswith("(") and bu == "A" and au not in ("(BC)","(DE)","(HL)")):
            addr_str = a.strip()
            if addr_str.startswith("(") and addr_str.endswith(")"):
                addr_str = addr_str[1:-1]
            nn = parse_imm(addr_str, symtab, pass2) & 0xFFFF
            return [0x32, nn & 0xFF, (nn>>8) & 0xFF]
        # LD A,(nn) -> 0x3A lo hi
        if au == "A" and bu.startswith("(") and bu not in ("(BC)","(DE)","(HL)"):
            addr_str = b.strip()[1:-1]
            nn = parse_imm(addr_str, symtab, pass2) & 0xFFFF
            return [0x3A, nn & 0xFF, (nn>>8) & 0xFF]
        # LD A,(BC)=0x0A, LD A,(DE)=0x1A
        if au == "A" and bu == "(BC)": return [0x0A]
        if au == "A" and bu == "(DE)": return [0x1A]
        # LD r,(HL) -> 0x46|(r<<3) ; LD (HL),r -> 0x70|r
        if au in R8 and bu == "(HL)": return [0x46 | (R8[au] << 3)]
        if au == "(HL)" and bu in R8: return [0x70 | R8[bu]]
        if au in R8 and bu in R8:
            return [0x40 | (R8[au]<<3) | R8[bu]]
        if au in R8:
            n = parse_imm(b, symtab, pass2) & 0xFF
            return [0x06 | (R8[au]<<3), n]
        # LD rr,nn (BC/DE/HL/SP)
        rp = {"BC":0,"DE":1,"HL":2,"SP":3}.get(au)
        if rp is not None:
            nn = parse_imm(b, symtab, pass2) & 0xFFFF
            return [0x01 | (rp<<4), nn & 0xFF, (nn>>8) & 0xFF]
        raise AsmError("LD form not supported: %s %s" % (a, b))
    if o in ALU_OPS:
        opidx = ALU_OPS[o]
        if len(operands) >= 2 and operands[0].upper() == "A":
            v = operands[1]
        else:
            v = operands[0]
        vu = v.upper()
        if vu in R8:
            return [0x80 | (opidx<<3) | R8[vu]]
        n = parse_imm(v, symtab, pass2) & 0xFF
        n_opc = {0:0xC6, 1:0xCE, 2:0xD6, 3:0xDE, 4:0xE6, 5:0xEE, 6:0xF6, 7:0xFE}[opidx]
        return [n_opc, n]
    if o == "JP":
        if len(operands) >= 2:
            cc = operands[0].strip().upper()
            nnv = parse_imm(operands[1], symtab, pass2) & 0xFFFF
            base = {"NZ":0xC2,"Z":0xCA,"NC":0xD2,"C":0xDA,"PO":0xE2,"PE":0xEA,"P":0xF2,"M":0xFA}[cc]
            return [base, nnv & 0xFF, (nnv>>8) & 0xFF]
        nnv = parse_imm(operands[0], symtab, pass2) & 0xFFFF
        return [0xC3, nnv & 0xFF, (nnv>>8) & 0xFF]
    if o == "JR":
        if len(operands) >= 2:
            cc = operands[0].strip().upper()
            base = JR_CC[cc]
            target = parse_imm(operands[1], symtab, pass2)
        else:
            base = 0x18
            target = parse_imm(operands[0], symtab, pass2)
        disp = (target - (addr + 2)) & 0xFF
        return [base, disp]
    if o == "CALL":
        if len(operands) >= 2:
            cc = operands[0].strip().upper()
            nnv = parse_imm(operands[1], symtab, pass2) & 0xFFFF
            base = {"NZ":0xC4,"Z":0xCC,"NC":0xD4,"C":0xDC}[cc]
            return [base, nnv & 0xFF, (nnv>>8) & 0xFF]
        nnv = parse_imm(operands[0], symtab, pass2) & 0xFFFF
        return [0xCD, nnv & 0xFF, (nnv>>8) & 0xFF]
    if o in ("PUSH","POP"):
        rp = RP_PUSH[operands[0].strip().upper()]
        return [(0xC5 if o=="PUSH" else 0xC1) | (rp<<4)]
    raise AsmError("unsupported op: %s %s" % (op, operands))

def assemble(text, origin=0x0000):
    lines = text.splitlines()
    # Pass 1: parse to IR, assign addresses.
    symtab = {}
    ir = []   # list of (addr, op, operands, srctext)
    addr = origin
    for ln in lines:
        s = ln.split(";",1)[0].strip()   # strip comments
        if not s: continue
        # labels:  "label:" possibly followed by an instruction
        while ":" in s.split()[0] if s else False:
            head, rest = s.split(":",1)
            lab = head.strip()
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", lab):
                raise AsmError("bad label: %s" % lab)
            symtab[lab] = addr
            s = rest.strip()
            if not s: break
        if not s: continue
        # directives
        if s.upper().startswith(".ORG"):
            v = s.split(None,1)[1].strip()
            if v.lower().startswith("0x"): addr = int(v,16)
            elif v.startswith("$"): addr = int(v[1:],16)
            else: addr = int(v,0)
            continue
        if s.upper().startswith(".EQU") or " EQU " in s.upper():
            # label EQU value  (handled as a label with a value)
            parts = re.split(r"\s+EQU\s+|\s+\.EQU\s+", s, maxsplit=1, flags=re.I)
            if len(parts) == 2:
                symtab[parts[0].strip()] = int(parts[1].strip(), 0)
                continue
        # split op and operands
        parts = s.split(None, 1)
        op = parts[0]
        operands = [parts[1]] if len(parts) > 1 else []
        # operands may be a single comma list; keep as one string for size/encode
        try:
            ln_bytes = size_of(op, operands)
        except AsmError as e:
            raise AsmError("line '%s': %s" % (s, e))
        ir.append((addr, op, operands, s))
        addr += ln_bytes
    # Pass 2: resolve + emit
    image = bytearray(addr - origin)
    lst = []
    for (a, op, operands, src) in ir:
        bs = encode(op, operands, a, symtab, True)
        for i, b in enumerate(bs):
            image[(a - origin) + i] = b & 0xFF
        lst.append("%04X: %-20s %s" % (a, " ".join("%02X"%x for x in bs), src))
    return image, symtab, lst

def write_outputs(image, symtab, lst, out_dir, name):
    import os
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, name + ".hex"), "w") as f:
        for b in image:
            f.write("%02X\n" % b)
    with open(os.path.join(out_dir, name + ".bin"), "wb") as f:
        f.write(image)
    with open(os.path.join(out_dir, name + ".lst"), "w") as f:
        f.write("\n".join(lst) + "\n")
    with open(os.path.join(out_dir, name + ".sym.json"), "w") as f:
        json.dump(symtab, f, indent=2)

def main():
    ap = argparse.ArgumentParser(description="PCA-Z80 two-pass assembler")
    ap.add_argument("src")
    ap.add_argument("-o", "--out", default="build")
    ap.add_argument("-n", "--name", default="program")
    ap.add_argument("--origin", default="0x0000")
    a = ap.parse_args()
    with open(a.src) as f: text = f.read()
    origin = int(a.origin, 0)
    image, symtab, lst = assemble(text, origin)
    write_outputs(image, symtab, lst, a.out, a.name)
    print("assembled %s: %d bytes, %d symbols" % (a.src, len(image), len(symtab)))

if __name__ == "__main__":
    main()
