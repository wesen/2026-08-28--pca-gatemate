// top.sv — Phase 6 board-facing top level for PCA-Z80.
//
// Wires the Z80 object graph (z80_core) to the Olimex GateMateA1-EVB pins,
// with the program ROM initialized at synthesis from build/top_prog.hex via
// $readmemh. The Z80 program drives GPIO bit 0 (a write to memory address
// 0x0000), which lights the onboard LED. This is the Phase 6 hardware demo:
// the LED is driven by Z80 instructions executing on the object graph, not by
// a hardware counter. Board pins reused unchanged from the sibling MATE-16
// project (verified against the Cologne Chip datasheet).
`default_nettype none

module top #(
    parameter int ROM_DEPTH = 256
) (
    input  logic clk_10m,
    input  logic fpga_but,        // active-low user button (unused in the demo)
    output logic user_led,        // GPIO bit 0 from the Z80
    output logic uart_tx_pin,     // held idle-high (UART added later)
    input  logic uart_rx_pin
);
    logic rst_n;
    logic cfg_rst_n;
    logic [7:0]  dbg_ir, dbg_r, gpio;
    logic [15:0] dbg_pc, dbg_sp;
    logic [31:0] dbg_count;
    logic        dbg_halted, dbg_faulted;

    // GateMate configuration-reset primitive (real in synth, modeled in sim).
    CC_USR_RSTN u_cfg_reset (.USR_RSTN(cfg_rst_n));

    reset_sync u_reset (
        .clk    (clk_10m),
        .arst_n (cfg_rst_n),
        .rst_n  (rst_n)
    );

    z80_core #(.ROM_DEPTH(ROM_DEPTH)) u_core (
        .clk        (clk_10m),
        .rst_n      (rst_n),
        .dbg_ir     (dbg_ir),
        .dbg_pc     (dbg_pc),
        .dbg_r      (dbg_r),
        .dbg_sp     (dbg_sp),
        .gpio_out   (gpio),
        .dbg_count  (dbg_count),
        .dbg_halted (dbg_halted),
        .dbg_faulted(dbg_faulted)
    );

    // The Z80 program drives GPIO bit 0 -> the onboard LED.
    assign user_led    = gpio[0];
    assign uart_tx_pin  = 1'b1;   // idle high (UART frames added later)
endmodule

`default_nettype wire
