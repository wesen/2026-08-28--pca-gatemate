; selftest.asm — Phase 5 acceptance program.
;
; A real assembled Z80 program the integrated object graph runs to a known-
; good final state, differential-tested against z80_model.py. Uses only the
; implemented baseline (NOP/HALT/LD/8-bit ALU/JP/JR/CALL/RET/PUSH/POP).
;
; Counts A up to 3 in a JR/CP loop, then CALLs a subroutine that adds 5, and
; HALTs. Final A = 8. The "magic" final state is A=0x08.

    LD A, 0          ; sum = 0
loop:
    ADD A, 1         ; sum += 1
    CP 3             ; reached 3?
    JR NZ, loop      ; no -> loop
    CALL add5        ; yes -> A = 3 + 5 = 8
    HALT
add5:
    ADD A, 5
    RET
