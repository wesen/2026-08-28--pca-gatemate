// obj_memio.sv — the Z80 memory + I/O object (design-doc §6.4), Phase 6.
//
// A held-request bus slave holding a byte-addressed program ROM (loaded via
// $readmemh at synthesis), a small data RAM, and a GPIO output port (Phase 6).
// The ROM is read-only; writes to addr 0x0000 hit the GPIO output port
// (the baseline I/O map: port 0x00 = GPIO_OUT, bit 0 drives the LED); all
// other writes hit the RAM. Same anti-double captured-transaction handshake.
`default_nettype none

import z80_obj::*;

module obj_memio #(
    parameter int ROM_DEPTH = 512,   // bytes; >=272×8 forces GateMate CC_BRAM_20K
    parameter int RAM_WORDS = 256   // byte RAM
) (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp,
    output logic [7:0] gpio_out,       // GPIO output port (write addr 0x0000)
    output logic [7:0] uart_tx_data,    // UART TX data (write addr 0x0001)
    output logic       uart_tx_start,   // UART TX start pulse (one cycle)
    input  logic       uart_tx_ready    // UART TX ready (from uart_tx)
);
    // Program ROM: registered/synchronous read, the template used by FemtoRV,
    // LiteX SERV/FazyRV/VexRiscv, and ColecoVision on GateMate. ROM_DEPTH=512
    // is intentionally above Yosys's measured 8-bit BRAM threshold (272 words).
    logic [7:0] rom [0:ROM_DEPTH-1];
    logic [7:0] ram [0:RAM_WORDS-1];
    logic [7:0] rom_q;
    logic [7:0] ram_q;
    logic [7:0] gpio;
    logic        captured;
    logic [15:0] addr_q;
    logic        we_q;
    logic [7:0]  uart_byte_q;
    logic        uart_start_q;
    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_MEM);
    // I/O space: addr 0x0000 = GPIO output; addr 0x0001 = UART TX data.
    wire is_gpio = (bus_req.addr == 16'h0000);
    wire is_uart = (bus_req.addr == 16'h0001);

    // Synthesis ROM init. Simulation testbenches load dut.u_memio.rom directly,
    // so ROM_FILE is intentionally undefined there (avoids a hidden default).
`ifdef ROM_FILE
    initial $readmemh(`ROM_FILE, rom);
`endif
    initial begin
        for (int i = 0; i < RAM_WORDS; i++) ram[i] = 8'h00;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            captured <= 1'b0;
            addr_q   <= 16'h0000;
            we_q     <= 1'b0;
            rom_q    <= 8'h00;
            ram_q    <= 8'h00;
            gpio     <= 8'h00;
            uart_byte_q <= 8'h00;
            uart_start_q <= 1'b0;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                addr_q    <= bus_req.addr;
                we_q      <= bus_req.we;
                rom_q     <= rom[bus_req.addr[$clog2(ROM_DEPTH)-1:0]];
                ram_q     <= ram[bus_req.addr[$clog2(RAM_WORDS)-1:0]];
                if (bus_req.we) begin
                    if (is_gpio) gpio <= bus_req.wdata[7:0];
                    else if (is_uart) begin uart_byte_q <= bus_req.wdata[7:0]; uart_start_q <= 1'b1; end
                    else ram[bus_req.addr[$clog2(RAM_WORDS)-1:0]] <= bus_req.wdata[7:0];
                end
            end else if (!sel) begin
                captured <= 1'b0;
                uart_start_q <= 1'b0;   // start is a one-cycle pulse
            end
        end
    end

    assign bus_resp.ack   = sel && captured;
    assign bus_resp.rdata  = we_q ? 16'h0000 : {8'h00, (addr_q < ROM_DEPTH) ? rom_q : ram_q};
    assign gpio_out       = gpio;
    assign uart_tx_data   = uart_byte_q;
    assign uart_tx_start  = uart_start_q & sel;   // pulse only while selected
endmodule

`default_nettype wire
