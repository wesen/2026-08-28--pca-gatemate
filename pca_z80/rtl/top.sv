// top.sv — Phase 0 board-facing top level for PCA-Z80.
//
// This is a *placeholder* that proves the open-source flow (Yosys ->
// nextpnr-himbaechel -> gmpack -> openFPGALoader) works on the GateMateA1-EVB
// and that the verified board pins are correct. A 24-bit counter drives the
// LED so the flow's result is observable. The PCA cell + Z80 object graph
// replace this in Phase 1+ (see design-doc §9, §13). Mirrors the sibling
// MATE-16 Phase-1 blink_top.
`default_nettype none

module top #(
    parameter int LED_BIT = 23   // which counter bit drives the LED
) (
    input  logic clk_10m,
    input  logic fpga_but,        // active-low user button (not used in Phase 0)
    output logic user_led,
    output logic uart_tx_pin,     // held idle-high in Phase 0
    input  logic uart_rx_pin
);
    logic rst_n;
    logic [23:0] counter;

    // GateMate configuration-reset primitive (real in synth, modeled in sim).
    CC_USR_RSTN cc_rstn ();

    reset_sync u_reset (
        .clk    (clk_10m),
        .arst_n (cc_rstn.USR_RSTN),
        .rst_n  (rst_n)
    );

    always_ff @(posedge clk_10m) begin
        if (!rst_n)
            counter <= 24'd0;
        else
            counter <= counter + 24'd1;
    end

    assign user_led     = counter[LED_BIT];
    assign uart_tx_pin   = 1'b1;   // idle high (UART frames added in Phase 5)
endmodule

`default_nettype wire
