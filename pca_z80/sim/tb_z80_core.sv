// tb_z80_core.sv — Phase 3A directed differential test (design-doc §13, 3A).
//
// Loads NOP,NOP,HALT into the memory object, runs the object-graph core, and
// checks retired state against the reference-model oracle (z80_model.py):
//   oracle: PC=3, R=3, instruction_count=3, halted=True, faulted=False
//   (the program is NOP,NOP,HALT; HALT retires, matching the model).
// This proves the object graph fetches and executes over the held-request bus
// with the same retirement semantics as the oracle.
`timescale 1ns/1ps

module tb_z80_core;
    logic clk = 1'b0, rst_n = 1'b0;
    always #50 clk = ~clk;  // 10 MHz

    logic [7:0]  dbg_ir; logic [15:0] dbg_pc; logic [7:0] dbg_r;
    logic [31:0] dbg_count; logic dbg_halted, dbg_faulted;

    z80_core dut (
        .clk(clk), .rst_n(rst_n),
        .dbg_ir(dbg_ir), .dbg_pc(dbg_pc), .dbg_r(dbg_r),
        .dbg_count(dbg_count), .dbg_halted(dbg_halted), .dbg_faulted(dbg_faulted)
    );

    integer errors = 0;

    initial begin
        $dumpfile("build/z80_core.vcd");
        $dumpvars(0, tb_z80_core);
        // Load NOP,NOP,HALT into the memory object's ROM (byte 0..2).
        dut.u_memio.rom[0] = 8'h00;  // NOP
        dut.u_memio.rom[1] = 8'h00;  // NOP
        dut.u_memio.rom[2] = 8'h76;  // HALT

        rst_n = 1'b0;
        repeat(4) @(posedge clk);
        rst_n = 1'b1;

        // Run enough cycles for 3 instructions through the multi-state FSM
        // (each instruction takes several bus transactions).
        repeat(200) @(posedge clk);

        // ---- differential checks vs the oracle (z80_model.py) ----
        // NOP,NOP,HALT -> PC=3, R=3, count=3, halted, not faulted
        if (dbg_pc !== 16'd3) begin
            $display("FAIL: PC=%0d (oracle 3)", dbg_pc); errors = errors + 1;
        end
        if (dbg_r !== 8'd3) begin
            $display("FAIL: R=%0d (oracle 3)", dbg_r); errors = errors + 1;
        end
        if (dbg_count !== 32'd3) begin
            $display("FAIL: count=%0d (oracle 3)", dbg_count); errors = errors + 1;
        end
        if (!dbg_halted) begin
            $display("FAIL: not halted (oracle halted)"); errors = errors + 1;
        end
        if (dbg_faulted) begin
            $display("FAIL: faulted (oracle not faulted)"); errors = errors + 1;
        end
        if (dbg_ir !== 8'h76) begin
            $display("FAIL: IR=%h (oracle 0x76)", dbg_ir); errors = errors + 1;
        end

        $display("----");
        if (errors == 0)
            $display("PASS: Phase 3A object graph (NOP/NOP/HALT) matches oracle");
        else
            $display("FAIL: %0d error(s)", errors);
        $finish;
    end

    initial begin
        #50000;
        $display("FAIL: watchdog timeout");
        $finish;
    end
endmodule
