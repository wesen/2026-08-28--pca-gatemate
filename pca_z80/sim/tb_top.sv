// tb_top.sv — testbench for the Phase 0 placeholder top (sibling §1.7 style).
// Checks reset deassertion and that the counter increments exactly once per
// rising clock edge after reset, then lets the LED bit toggle.
`timescale 1ns/1ps

module tb_top;
    logic clk_10m = 1'b0;
    logic fpga_but = 1'b1;
    logic user_led;
    logic uart_tx_pin;
    logic uart_rx_pin = 1'b1;

    // Low bit so the LED is observable in a few microseconds of sim time.
    top #(.LED_BIT(3)) dut (
        .clk_10m     (clk_10m),
        .fpga_but    (fpga_but),
        .user_led    (user_led),
        .uart_tx_pin (uart_tx_pin),
        .uart_rx_pin (uart_rx_pin)
    );

    always #50 clk_10m = ~clk_10m; // 100 ns period => 10 MHz

    integer errors = 0;
    logic [23:0] c0;

    initial begin
        $dumpfile("build/top.vcd");
        $dumpvars(0, tb_top);

        // Run well past configuration-derived reset (CC_USR_RSTN deasserts at 250 ns)
        // plus the two reset_sync pipeline stages.
        @(posedge clk_10m);
        repeat(8) @(posedge clk_10m);

        // Check 1: internal reset has deasserted.
        if (dut.rst_n !== 1'b1) begin
            $display("FAIL: rst_n not deasserted after config reset (rst_n=%0b)", dut.rst_n);
            errors = errors + 1;
        end

        // Check 2: counter is incrementing (not stuck at 0).
        if (dut.counter === 24'd0) begin
            $display("FAIL: counter never incremented past reset");
            errors = errors + 1;
        end

        // Check 3: counter increments by exactly one per rising edge.
        #1; // let the previous edge's nonblocking update settle before sampling
        c0 = dut.counter;
        @(posedge clk_10m);
        #1; // settle past this edge
        if (dut.counter !== c0 + 24'd1) begin
            $display("FAIL: counter did not increment by 1 (was %0d, now %0d)", c0, dut.counter);
            errors = errors + 1;
        end

        // Let it run long enough for LED bit 3 to toggle at least once
        // (bit 3 toggles every 2^3 = 8 cycles = 800 ns).
        repeat(20) @(posedge clk_10m);

        $display("Simulation completed; LED=%0b counter=%0d", user_led, dut.counter);
        if (errors == 0)
            $display("PASS: Phase 0 top self-test");
        else
            $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule
