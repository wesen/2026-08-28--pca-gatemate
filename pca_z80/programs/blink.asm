; blink.asm — Phase 6 hardware demo. The baseline object graph has no OUT
; instruction; instead, a write to memory address 0x0000 hits the GPIO output
; port (the baseline I/O map: port 0x00 = GPIO_OUT). This program turns the
; LED on, then HALTs — the minimal "Z80 instructions drive the LED" demo.
; (A blinking loop needs INC/DEC r for the delay, which is 3D/3F.5; for the
; Phase 6 bring-up, LED-on-then-halt proves the Z80 drives the board pin.)

    LD A, 0x01        ; bit 0 = LED on
    LD (0x0000), A     ; write GPIO -> LED on
    HALT
