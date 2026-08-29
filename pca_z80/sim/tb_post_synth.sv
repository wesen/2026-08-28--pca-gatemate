`timescale 1ns/1ps
// Gate-level smoke test: proves the synthesized GateMate netlist retained the
// initialized program ROM and executes far enough to drive GPIO/LED.
module tb_post_synth;
    logic clk_10m = 1'b0;
    logic fpga_but = 1'b1;
    wire user_led;
    wire uart_tx_pin;
    logic uart_rx_pin = 1'b1;
    integer cycles;

    top dut (
        .clk_10m(clk_10m), .fpga_but(fpga_but), .user_led(user_led),
        .uart_tx_pin(uart_tx_pin), .uart_rx_pin(uart_rx_pin)
    );
    always #50 clk_10m = ~clk_10m;

    initial begin
        // blink.asm turns GPIO on within the first few retired instructions.
        for (cycles = 0; cycles < 3000 && user_led !== 1'b1; cycles = cycles + 1)
            @(posedge clk_10m);
        if (user_led !== 1'b1) begin
            $display("FAIL: post-synth ROM/CPU did not drive LED in 3000 cycles");
            $fatal(1);
        end
        $display("PASS: post-synth initialized ROM executed; LED=1 after %0d cycles", cycles);
        $finish;
    end
endmodule
