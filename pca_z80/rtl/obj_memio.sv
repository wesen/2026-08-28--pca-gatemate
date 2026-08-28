`ifndef ROM_FILE
`define ROM_FILE "build/default.hex"
`endif
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
    parameter int ROM_DEPTH = 256,   // bytes
    parameter int RAM_WORDS = 256   // byte RAM
) (
    input  logic      clk,
    input  logic      rst_n,
    input  z80_obj::bus_req_t  bus_req,
    output z80_obj::bus_resp_t bus_resp,
    output logic [7:0] gpio_out       // GPIO output port (write addr 0x0000)
);
    // Program ROM (byte-addressed, synchronous-read for BRAM inference).
    // ROM init at synthesis via $readmemh of the file named by `ROM_FILE
    // (defined on the Yosys command line with -DROM_FILE="path").
    logic [7:0] rom [0:ROM_DEPTH-1];
    logic [7:0] ram [0:RAM_WORDS-1];
    logic [7:0] rom_q;
    logic [7:0] ram_q;
    logic [7:0] gpio;

    logic        captured;
    logic [15:0] addr_q;
    logic        we_q;
    wire sel = bus_req.req && (bus_req.obj == z80_obj::OBJ_MEM);
    // I/O space: addr 0x0000 = GPIO output port (the baseline's only port).
    wire is_gpio = (bus_req.addr == 16'h0000);

    initial begin
        for (int i = 0; i < ROM_DEPTH; i++) rom[i] = 8'h00;  // fill NOP
        for (int i = 0; i < RAM_WORDS; i++) ram[i] = 8'h00;
        $readmemh(`ROM_FILE, rom);   // ROM init (overridden by sim $readmemh after)
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            captured <= 1'b0;
            addr_q   <= 16'h0000;
            we_q     <= 1'b0;
            rom_q    <= 8'h00;
            ram_q    <= 8'h00;
            gpio     <= 8'h00;
        end else begin
            if (sel && !captured) begin
                captured <= 1'b1;
                addr_q    <= bus_req.addr;
                we_q      <= bus_req.we;
                rom_q     <= rom[bus_req.addr[$clog2(ROM_DEPTH)-1:0]];
                ram_q     <= ram[bus_req.addr[$clog2(RAM_WORDS)-1:0]];
                if (bus_req.we) begin
                    if (is_gpio) gpio <= bus_req.wdata[7:0];
                    else ram[bus_req.addr[$clog2(RAM_WORDS)-1:0]] <= bus_req.wdata[7:0];
                end
            end else if (!sel) begin
                captured <= 1'b0;
            end
        end
    end

    assign bus_resp.ack   = sel && captured;
    assign bus_resp.rdata  = we_q ? 16'h0000 : {8'h00, (addr_q < ROM_DEPTH) ? rom_q : ram_q};
    assign gpio_out       = gpio;
endmodule

`default_nettype wire
