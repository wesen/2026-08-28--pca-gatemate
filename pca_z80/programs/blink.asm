; blink.asm — Phase 6 hardware demo. The Z80 blinks the user LED by writing
; GPIO bit 0 (memory address 0x0000). No OUT instruction (baseline uses
; memory-mapped I/O). The blinking is caused by Z80 instructions (LD/DEC/JR/
; LD (nn),A) executing on the object graph, not a hardware counter.
;
; The delay is a NESTED loop (inner B=256 × outer C=256 = 65536 DEC/JR
; iterations) so the blink is human-visible (~1.6 Hz at 10 MHz). The original
; single-loop version blinked at ~830 Hz (looked like a steady LED).

start:
    LD A, 0x01        ; LED on (bit 0)
    LD (0x0000), A     ; write GPIO
    LD C, 0x00         ; outer 256 iterations (0 -> wrap to 255 -> 0)
outer1:
    LD B, 0x00         ; inner 256 iterations
d1:
    DEC B
    JR NZ, d1
    DEC C
    JR NZ, outer1
    LD A, 0x00         ; LED off
    LD (0x0000), A
    LD C, 0x00
outer2:
    LD B, 0x00
d2:
    DEC B
    JR NZ, d2
    DEC C
    JR NZ, outer2
    JR start          ; loop forever
