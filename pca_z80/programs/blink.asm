; blink.asm — Phase 6 hardware demo. The baseline object graph has no OUT
; instruction; instead, a write to memory address 0x0000 hits the GPIO output
; port (the baseline I/O map: port 0x00 = GPIO_OUT, bit 0 = LED). This program
; blinks the LED: turns it on, delays with a DEC B countdown loop, turns it
; off, delays, and loops forever. The blinking is caused by Z80 instructions
; (LD/DEC/JR/LD (nn),A) executing on the object graph, not a hardware counter.
;
; (The delay loop is short for sim visibility; on the 10 MHz board it blinks
; fast — extend the loop or nest it for a human-visible rate.)

start:
    LD A, 0x01        ; LED on (bit 0)
    LD (0x0000), A     ; write GPIO
delay1:
    LD B, 0x00        ; 256 iterations (0 -> wrap to 255 -> 0)
d1:
    DEC B
    JR NZ, d1
    LD A, 0x00        ; LED off
    LD (0x0000), A
delay2:
    LD B, 0x00
d2:
    DEC B
    JR NZ, d2
    JR start          ; loop forever
