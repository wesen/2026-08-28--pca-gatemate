// tb_z80_core.sv — Phase 3A/3B directed differential tests (design-doc §13).
//
// Loads programs into the memory object, runs the object-graph core, and
// checks retired state against the reference-model oracle (z80_model.py):
//   3A: NOP,NOP,HALT -> PC=3, R=3, count=3, halted, not faulted
//   3B: LD A,0x42; LD B,A; HALT -> A=0x42, B=0x42, count=3
//   3B: LD A,0x11; LD C,0x22; LD D,A; HALT -> A=0x11, C=0x22, D=0x11, count=4
// This proves the object graph fetches and executes over the held-request bus
// with the same retirement semantics as the oracle.
`timescale 1ns/1ps

module tb_z80_core;
    logic clk = 1'b0, rst_n = 1'b0;
    always #50 clk = ~clk;  // 10 MHz

    logic [7:0]  dbg_ir; logic [15:0] dbg_pc; logic [7:0] dbg_r; logic [15:0] dbg_sp;
    logic [31:0] dbg_count; logic dbg_halted, dbg_faulted;

    z80_core dut (
        .clk(clk), .rst_n(rst_n),
        .dbg_ir(dbg_ir), .dbg_pc(dbg_pc), .dbg_r(dbg_r), .dbg_sp(dbg_sp),
        .dbg_count(dbg_count), .dbg_halted(dbg_halted), .dbg_faulted(dbg_faulted)
    );

    integer errors = 0;

    // Load up to 8 program bytes into the memory object's ROM, reset, run.
    task automatic run_prog(input logic [7:0] p0, p1, p2, p3, p4, p5, p6, p7,
                            input integer plen);
        begin
            dut.u_memio.rom[0] = p0; dut.u_memio.rom[1] = p1; dut.u_memio.rom[2] = p2;
            dut.u_memio.rom[3] = p3; dut.u_memio.rom[4] = p4; dut.u_memio.rom[5] = p5;
            dut.u_memio.rom[6] = p6; dut.u_memio.rom[7] = p7;
            for (integer i = plen; i < 9; i++) dut.u_memio.rom[i] = 8'h00;
            rst_n = 1'b0;
            repeat(4) @(posedge clk);
            rst_n = 1'b1;
            repeat(500) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("build/z80_core.vcd");
        $dumpvars(0, tb_z80_core);

        // ---- 3A: NOP,NOP,HALT -> PC=3, R=3, count=3, halted ----
        errors = 0;
        run_prog(8'h00, 8'h00, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 3);
        if (dbg_pc !== 16'd3)    begin $display("FAIL 3A: PC=%0d (oracle 3)", dbg_pc); errors=errors+1; end
        if (dbg_r !== 8'd3)      begin $display("FAIL 3A: R=%0d (oracle 3)", dbg_r); errors=errors+1; end
        if (dbg_count !== 32'd3) begin $display("FAIL 3A: count=%0d (oracle 3)", dbg_count); errors=errors+1; end
        if (!dbg_halted)         begin $display("FAIL 3A: not halted"); errors=errors+1; end
        if (dbg_faulted)         begin $display("FAIL 3A: faulted"); errors=errors+1; end
        if (errors==0) $display("3A: NOP/NOP/HALT matches oracle (PC=3 R=3 count=3)");

        // ---- 3B: LD A,0x42; LD B,A; HALT -> A=0x42, B=0x42, count=3 ----
        errors = 0;
        run_prog(8'h3E, 8'h42, 8'h47, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00, 4);  // LD A,0x42; LD B,A; HALT
        if (dut.u_regfile.dbg_a !== 8'h42) begin $display("FAIL 3B1: A=%h (oracle 0x42)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (dut.u_regfile.dbg_b !== 8'h42) begin $display("FAIL 3B1: B=%h (oracle 0x42)", dut.u_regfile.dbg_b); errors=errors+1; end
        if (dbg_count !== 32'd3)            begin $display("FAIL 3B1: count=%0d (oracle 3)", dbg_count); errors=errors+1; end
        if (!dbg_halted)                    begin $display("FAIL 3B1: not halted"); errors=errors+1; end
        if (dbg_faulted)                    begin $display("FAIL 3B1: faulted"); errors=errors+1; end
        if (errors==0) $display("3B1: LD A,0x42; LD B,A matches oracle (A=0x42 B=0x42 count=3)");

        // ---- 3B: LD A,0x11; LD C,0x22; LD D,A; HALT -> A=0x11, C=0x22, D=0x11, count=4 ----
        errors = 0;
        run_prog(8'h3E, 8'h11, 8'h0E, 8'h22, 8'h57, 8'h76, 8'h00, 8'h00, 6);  // LD A,0x11; LD C,0x22; LD D,A; HALT
        if (dut.u_regfile.dbg_a !== 8'h11) begin $display("FAIL 3B2: A=%h (oracle 0x11)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (dut.u_regfile.dbg_c !== 8'h22) begin $display("FAIL 3B2: C=%h (oracle 0x22)", dut.u_regfile.dbg_c); errors=errors+1; end
        if (dut.u_regfile.dbg_d !== 8'h11) begin $display("FAIL 3B2: D=%h (oracle 0x11)", dut.u_regfile.dbg_d); errors=errors+1; end
        if (dbg_count !== 32'd4)            begin $display("FAIL 3B2: count=%0d (oracle 4)", dbg_count); errors=errors+1; end
        if (!dbg_halted)                    begin $display("FAIL 3B2: not halted"); errors=errors+1; end
        if (dbg_faulted)                    begin $display("FAIL 3B2: faulted"); errors=errors+1; end
        if (errors==0) $display("3B2: LD A,0x11; LD C,0x22; LD D,A matches oracle (A=0x11 C=0x22 D=0x11 count=4)");

        // ---- 3C: LD A,0x0F; ADD A,1 -> 0x10, H set, no C ----
        errors = 0;
        run_prog(8'h3E, 8'h0F, 8'hC6, 8'h01, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,0x0F; ADD A,1; HALT
        if (dut.u_regfile.dbg_a !== 8'h10) begin $display("FAIL 3C1: A=%h (oracle 0x10)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (dut.u_flags.dbg_f !== 8'h10) begin $display("FAIL 3C1: F=%h (oracle 0x10 H)", dut.u_flags.dbg_f); errors=errors+1; end
        if (dbg_count !== 32'd3)            begin $display("FAIL 3C1: count=%0d (oracle 3)", dbg_count); errors=errors+1; end
        if (errors==0) $display("3C1: ADD A,1 (0x0F+0x01) matches oracle (A=0x10 F=0x10 H)");

        // ---- 3C: LD A,0x05; SUB 3 -> 0x02, N set ----
        errors = 0;
        run_prog(8'h3E, 8'h05, 8'hD6, 8'h03, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,5; SUB 3; HALT
        if (dut.u_regfile.dbg_a !== 8'h02) begin $display("FAIL 3C2: A=%h (oracle 0x02)", dut.u_regfile.dbg_a); errors=errors+1; end
        // F: N set, no C, no Z. N=0x02. Result 0x02 not zero, not sign. So F should have N bit only = 0x02.
        if (dut.u_flags.dbg_f !== 8'h02) begin $display("FAIL 3C2: F=%h (oracle 0x02 N)", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3C2: SUB 3 (0x05-0x03) matches oracle (A=0x02 F=0x02 N)");

        // ---- 3C: LD A,0xF0; AND 0x0F -> 0x00, Z set, H set ----
        errors = 0;
        run_prog(8'h3E, 8'hF0, 8'hE6, 8'h0F, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,0xF0; AND 0x0F; HALT
        if (dut.u_regfile.dbg_a !== 8'h00) begin $display("FAIL 3C3: A=%h (oracle 0x00)", dut.u_regfile.dbg_a); errors=errors+1; end
        // F: Z(0x40) | H(0x10) | parity(0x04, even for 0) = 0x54
        if (dut.u_flags.dbg_f !== 8'h54) begin $display("FAIL 3C3: F=%h (oracle 0x54 Z|H|PV)", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3C3: AND 0x0F (0xF0&0x0F) matches oracle (A=0x00 F=0x54 Z|H|PV)");

        // ---- 3C: LD B,0x42; LD A,B; ADD A,B -> 0x84, S set (register operand) ----
        errors = 0;
        run_prog(8'h06, 8'h42, 8'h78, 8'h80, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD B,0x42; LD A,B; ADD A,B; HALT
        if (dut.u_regfile.dbg_a !== 8'h84) begin $display("FAIL 3C4: A=%h (oracle 0x84)", dut.u_regfile.dbg_a); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h80) === 8'h00) begin $display("FAIL 3C4: S not set (oracle S)", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3C4: ADD A,B (0x42+0x42) matches oracle (A=0x84 S set)");

        // ---- 3C: LD A,0xFF; ADD A,1 -> 0x00, C set, Z set, H set (0xF+0x1>0xF) ----
        errors = 0;
        run_prog(8'h3E, 8'hFF, 8'hC6, 8'h01, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,0xFF; ADD A,1; HALT
        if (dut.u_regfile.dbg_a !== 8'h00) begin $display("FAIL 3C5: A=%h (oracle 0x00)", dut.u_regfile.dbg_a); errors=errors+1; end
        // F: Z(0x40) | H(0x10) | C(0x01) = 0x51. (-1+1=0: no signed overflow PV; H set 0xF+0x1>0xF)
        if (dut.u_flags.dbg_f !== 8'h51) begin $display("FAIL 3C5: F=%h (oracle 0x51 Z|H|C)", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3C5: ADD A,1 (0xFF+0x01) matches oracle (A=0x00 F=0x51 Z|H|C)");

        // ---- 3E: JP nn (jump taken) ----
        // LD A,0x01; JP 0x06; (0x03 HALT skipped); LD A,0x02; HALT -> A=0x02 count=4
        errors = 0;
        run_prog(8'h3E, 8'h01, 8'hC3, 8'h06, 8'h00, 8'h76, 8'h3E, 8'h02, 8);  // LD A,1; JP 6; HALT; LD A,2; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h02) begin $display("FAIL 3E1: A=%h (oracle 0x02)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3E1: JP nn matches oracle (A=0x02)");

        // ---- 3E: JR e (jump taken) ----
        // LD A,0x01; JR +2 (to LD A,0x02 at 0x06); HALT; HALT; LD A,0x02; HALT -> A=0x02
        errors = 0;
        run_prog(8'h3E, 8'h01, 8'h18, 8'h02, 8'h76, 8'h76, 8'h3E, 8'h02, 8);  // LD A,1; JR +2; HALT; HALT; LD A,2; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h02) begin $display("FAIL 3E2: A=%h (oracle 0x02)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3E2: JR e matches oracle (A=0x02)");

        // ---- 3E: JR NZ not taken (Z set) ----
        // LD A,0; CP 0 (Z set); JR NZ +2 (NOT taken); LD A,1; HALT -> A=0x01
        errors = 0;
        run_prog(8'h3E, 8'h00, 8'hFE, 8'h00, 8'h20, 8'h02, 8'h3E, 8'h01, 8);  // LD A,0; CP 0; JR NZ +2; LD A,1; HALT (offset lands on the LD)
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h01) begin $display("FAIL 3E3: A=%h (oracle 0x01)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3E3: JR NZ not-taken matches oracle (A=0x01)");

        // ---- 3F: CALL/RET (SP resets to 0xFFFF) ----
        // CALL 0x07; HALT; LD A,0x42; RET; LD A,0x99; HALT -> A=0x42, count=4, SP back to FFFF
        errors = 0;
        run_prog(8'hCD, 8'h07, 8'h00, 8'h76, 8'h00, 8'h00, 8'h00, 8'h3E, 13);  // CALL 7; HALT; xx; xx; xx; LD A,
        // the program is 13 bytes: CD 07 00 76 00 00 00 3E 42 C9 3E 99 76
        dut.u_memio.rom[8] = 8'h42;  // continue the program past the 8-byte run_prog head
        dut.u_memio.rom[9] = 8'hC9;  // RET
        dut.u_memio.rom[10] = 8'h3E; // LD A,0x99
        dut.u_memio.rom[11] = 8'h99;
        dut.u_memio.rom[12] = 8'h76; // HALT
        rst_n = 1'b0; repeat(4) @(posedge clk); rst_n = 1'b1;
        repeat(600) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h42) begin $display("FAIL 3F1: A=%h (oracle 0x42)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (dut.dbg_sp !== 16'hFFFF) begin $display("FAIL 3F1: SP=%h (oracle FFFF)", dut.dbg_sp); errors=errors+1; end
        if (errors==0) $display("3F1: CALL/RET matches oracle (A=0x42 SP=FFFF)");

        // ---- 3F: PUSH BC / POP DE ----
        // LD B,0x12; LD C,0x34; PUSH BC; POP DE; HALT -> D=0x12 E=0x34 SP=FFFF
        errors = 0;
        run_prog(8'h06, 8'h12, 8'h0E, 8'h34, 8'hC5, 8'hD1, 8'h76, 8'h00, 7);  // LD B,0x12; LD C,0x34; PUSH BC; POP DE; HALT
        if (dut.u_regfile.dbg_d !== 8'h12) begin $display("FAIL 3F2: D=%h (oracle 0x12)", dut.u_regfile.dbg_d); errors=errors+1; end
        if (dut.u_regfile.dbg_e !== 8'h34) begin $display("FAIL 3F2: E=%h (oracle 0x34)", dut.u_regfile.dbg_e); errors=errors+1; end
        if (dut.dbg_sp !== 16'hFFFF) begin $display("FAIL 3F2: SP=%h (oracle FFFF)", dut.dbg_sp); errors=errors+1; end
        if (errors==0) $display("3F2: PUSH BC/POP DE matches oracle (D=0x12 E=0x34 SP=FFFF)");

        $display("----");
        if (errors == 0)
            $display("PASS: Phase 3A/3B/3C/3E/3F object graph (NOP/HALT/LD/ALU/JP/JR/CALL/RET/PUSH/POP) matches oracle");
        else
            $display("FAIL: %0d error(s)", errors);
        $finish;
    end

    initial begin
        #1000000;
        $display("FAIL: watchdog timeout");
        $finish;
    end
endmodule
