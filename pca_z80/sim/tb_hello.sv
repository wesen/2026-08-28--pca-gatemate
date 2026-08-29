// tb_hello.sv — Phase 6 UART bring-up test. Instantiates the board top, loads
// hello.asm into the ROM, runs, and decodes the memory-mapped UART TX (a
// Z80 write to addr 0x0001) into bytes, verifying it emits "Hi" (0x48 0x69).
// Uses the sim-only CC_USR_RSTN model. This is the Phase 6 "LED+UART" UART half.
`timescale 1ns/1ps

module tb_hello;
    localparam int CLK_HZ = 10_000_000, BAUD = 115_200;
    localparam int BIT_CYC = CLK_HZ / BAUD;   // ~87 cycles/bit

    logic clk_10m = 1'b0, fpga_but = 1'b1, user_led, uart_tx_pin, uart_rx_pin = 1'b1;
    always #50 clk_10m = ~clk_10m;  // 10 MHz

    top #(.ROM_DEPTH(256)) dut (
        .clk_10m(clk_10m), .fpga_but(fpga_but), .user_led(user_led),
        .uart_tx_pin(uart_tx_pin), .uart_rx_pin(uart_rx_pin)
    );

    // UART RX monitor: collect bytes from the tx pin into an array.
    logic [7:0] rx_bytes [0:7];
    integer rx_count = 0;
    logic [7:0] rx_shift;
    integer bit_i;

    task automatic capture_byte();
        begin
            @(negedge uart_tx_pin);                       // start bit
            repeat(BIT_CYC/2) @(posedge clk_10m);          // to middle of start bit
            for (bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
                repeat(BIT_CYC) @(posedge clk_10m);        // to middle of next data bit
                rx_shift[bit_i] = uart_tx_pin;
            end
            rx_bytes[rx_count] = rx_shift;
            $display("UART byte %0d: 0x%02h", rx_count, rx_shift);
            rx_count = rx_count + 1;
            repeat(BIT_CYC) @(posedge clk_10m);            // stop bit
        end
    endtask

    integer errors = 0;
    initial begin
        $dumpfile("build/hello.vcd");
        $dumpvars(0, tb_hello);
        $readmemh("build/hello.hex", dut.g_direct.u_core.u_memio.rom);
        repeat(20) @(posedge clk_10m);   // past CC_USR_RSTN + reset_sync
        fork
            begin : rx_mon
                capture_byte();
                capture_byte();
            end
            begin : timeout
                repeat(30000) @(posedge clk_10m);
            end
        join_any
        disable rx_mon;
        disable timeout;
        $display("received %0d bytes: 0x%02h 0x%02h (LED=%0d)", rx_count, rx_bytes[0], rx_bytes[1], user_led);
        if (rx_count >= 2 && rx_bytes[0] == 8'h48 && rx_bytes[1] == 8'h69) begin
            $display("PASS: Phase 6 LED+UART (Z80 emits 'Hi' over UART, LED=%0d)", user_led);
        end else begin
            $display("FAIL: expected 0x48 0x69 ('Hi'), got %0d bytes", rx_count);
            errors = errors + 1;
            $display("FAIL: %0d error(s)", errors);
        end
        $finish;
    end

    initial begin #50000000; $display("FAIL: watchdog"); $finish; end
endmodule
