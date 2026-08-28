; hello.asm — Phase 6 UART demo. Emits "Hi" over the memory-mapped UART
; (write to address 0x0001 = UART TX byte), then blinks the LED. The UART is
; 8-N-1 at 115200 baud (10 MHz). Each byte takes ~870 cycles to transmit, so a
; DEC B delay loop (256 iterations) between bytes ensures the UART is ready.
; This is the Phase 6 "LED+UART" hardware bring-up (UART half), driven by Z80
; instructions.

    LD A, 0x48        ; 'H'
    LD (0x0001), A     ; UART TX 'H'
    LD B, 0x00         ; delay (256 DEC iterations)
d1:
    DEC B
    JR NZ, d1
    LD A, 0x69        ; 'i'
    LD (0x0001), A     ; UART TX 'i'
    LD B, 0x00
d2:
    DEC B
    JR NZ, d2
    ; blink the LED too
    LD A, 0x01
    LD (0x0000), A     ; LED on
    HALT
