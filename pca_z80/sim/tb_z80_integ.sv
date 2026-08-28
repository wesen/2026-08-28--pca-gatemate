// tb_z80_integ.sv — Phase 5 integration test (design-doc §13 Phase 5).
//
// Loads an assembled program (program.hex) into the object graph's memory
// object via $readmemh, runs the core, and exposes the retired register
// state for a Python differential harness to compare against z80_model.py
// running the same bytes. This closes the loop: .asm -> zasm.py -> .hex ->
// object graph, differential-tested vs the model.
//
// The ROM_INIT_FILE parameter selects the program; the harness (sim/run_integ.py)
// assembles a program, writes its .hex, and runs this testbench with the file
// set, then reads the dumped state.
`timescale 1ns/1ps

module tb_z80_integ #(parameter string ROM_FILE = "build/integ.hex") ();
    logic clk = 1'b0, rst_n = 1'b0;
    always #50 clk = ~clk;  // 10 MHz

    logic [7:0]  dbg_ir; logic [15:0] dbg_pc; logic [7:0] dbg_r; logic [15:0] dbg_sp;
    logic [31:0] dbg_count; logic dbg_halted, dbg_faulted;

    z80_core dut (
        .clk(clk), .rst_n(rst_n),
        .dbg_ir(dbg_ir), .dbg_pc(dbg_pc), .dbg_r(dbg_r), .dbg_sp(dbg_sp),
        .gpio_out(), .uart_tx_data(), .uart_tx_start(), .uart_tx_ready(1'b1),
        .dbg_count(dbg_count), .dbg_halted(dbg_halted), .dbg_faulted(dbg_faulted)
    );

    integer i;
    initial begin
        $dumpfile("build/z80_integ.vcd");
        $dumpvars(0, tb_z80_integ);
        // clear ROM, then load the assembled program via $readmemh
        for (i = 0; i < 256; i = i + 1) dut.u_memio.rom[i] = 8'h00;
        $readmemh(ROM_FILE, dut.u_memio.rom);
        rst_n = 1'b0;
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        // run generously (each instruction is several bus transactions)
        repeat(20000) @(posedge clk);
        // dump state to a file the Python harness reads
        begin : dump
            integer fh;
            fh = $fopen("build/integ_state.txt", "w");
            $fdisplay(fh, "PC %0d", dbg_pc);
            $fdisplay(fh, "R %0d", dbg_r);
            $fdisplay(fh, "SP %0d", dbg_sp);
            $fdisplay(fh, "COUNT %0d", dbg_count);
            $fdisplay(fh, "HALTED %0d", dbg_halted);
            $fdisplay(fh, "FAULTED %0d", dbg_faulted);
            $fdisplay(fh, "A %0d", dut.u_regfile.dbg_a);
            $fdisplay(fh, "B %0d", dut.u_regfile.dbg_b);
            $fdisplay(fh, "C %0d", dut.u_regfile.dbg_c);
            $fdisplay(fh, "D %0d", dut.u_regfile.dbg_d);
            $fdisplay(fh, "E %0d", dut.u_regfile.dbg_e);
            $fdisplay(fh, "F %0d", dut.u_flags.dbg_f);
            $fclose(fh);
        end
        $display("INTEG: halted=%0d faulted=%0d count=%0d A=%0d B=%0d C=%0d D=%0d E=%0d",
                 dbg_halted, dbg_faulted, dbg_count,
                 dut.u_regfile.dbg_a, dut.u_regfile.dbg_b, dut.u_regfile.dbg_c,
                 dut.u_regfile.dbg_d, dut.u_regfile.dbg_e);
        $finish;
    end

    initial begin
        #5000000;
        $display("FAIL: watchdog timeout");
        $finish;
    end
endmodule
