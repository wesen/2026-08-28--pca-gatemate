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
    parameter int ROM_DEPTH = 512,
    // 0: program GPIO, 1: retired-instruction heartbeat, 2: sticky UART start.
    // Diagnostic only; production builds leave this at 0.
    parameter int DEBUG_LED_MODE = 0
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
    logic [7:0]  uart_byte;
    logic        uart_start, uart_ready;
    logic        uart_seen;

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
        .uart_tx_data (uart_byte),
        .uart_tx_start(uart_start),
        .uart_tx_ready (uart_ready),
        .dbg_count  (dbg_count),
        .dbg_halted (dbg_halted),
        .dbg_faulted(dbg_faulted)
    );

    // UART transmitter (8-N-1, 115200 baud at 10 MHz). The Z80 writes a byte
    // to memory address 0x0001 to transmit it (memory-mapped I/O).
    uart_tx #(.CLK_HZ(10_000_000), .BAUD(115_200)) u_uart (
        .clk    (clk_10m),
        .rst_n  (rst_n),
        .start  (uart_start),
        .data   (uart_byte),
        .ready  (uart_ready),
        .tx     (uart_tx_pin)
    );

    // Sticky proof that the CPU issued at least one UART transaction.
    always_ff @(posedge clk_10m or negedge rst_n) begin
        if (!rst_n) uart_seen <= 1'b0;
        else if (uart_start) uart_seen <= 1'b1;
    end

    // Select one observable per diagnostic stage. Production: GPIO from Z80
    // program. Heartbeat: retired-instruction count. UART: sticky start event.
    generate
        if (DEBUG_LED_MODE == 1) begin : g_cpu_heartbeat
            assign user_led = dbg_count[17];
        end else if (DEBUG_LED_MODE == 2) begin : g_uart_seen
            assign user_led = uart_seen;
        end else begin : g_program_gpio
            assign user_led = gpio[0];
        end
    endgenerate
endmodule

`default_nettype wire
