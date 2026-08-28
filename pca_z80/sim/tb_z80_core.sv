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

    logic [7:0]  gpio; logic [7:0] uart_d; logic uart_s, uart_r = 1'b1;
    z80_core dut (
        .clk(clk), .rst_n(rst_n),
        .dbg_ir(dbg_ir), .dbg_pc(dbg_pc), .dbg_r(dbg_r), .dbg_sp(dbg_sp),
        .gpio_out(gpio), .uart_tx_data(uart_d), .uart_tx_start(uart_s), .uart_tx_ready(uart_r),
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

        // ---- 3F.5: INC B (0x7F -> 0x80, S+PV+H) ----
        errors = 0;
        run_prog(8'h06, 8'h7F, 8'h04, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00, 4);  // LD B,0x7F; INC B; HALT
        if (dut.u_regfile.dbg_b !== 8'h80) begin $display("FAIL 3F5a: B=%h (oracle 0x80)", dut.u_regfile.dbg_b); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h80) === 8'h00) begin $display("FAIL 3F5a: S not set", dut.u_flags.dbg_f); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h04) === 8'h00) begin $display("FAIL 3F5a: PV not set", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3F5a: INC B (0x7F->0x80) matches oracle (S+PV)");

        // ---- 3F.5: DEC A (0x00 -> 0xFF, S+N+H) ----
        errors = 0;
        run_prog(8'h3E, 8'h00, 8'h3D, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00, 4);  // LD A,0; DEC A; HALT
        if (dut.u_regfile.dbg_a !== 8'hFF) begin $display("FAIL 3F5b: A=%h (oracle 0xFF)", dut.u_regfile.dbg_a); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h02) === 8'h00) begin $display("FAIL 3F5b: N not set", dut.u_flags.dbg_f); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h10) === 8'h00) begin $display("FAIL 3F5b: H not set", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3F5b: DEC A (0->0xFF) matches oracle (N+H+S)");

        // ---- 3F.5: DEC B loop (LD B,3; loop: DEC B; JR NZ,loop; HALT -> B=0) ----
        errors = 0;
        run_prog(8'h06, 8'h03, 8'h05, 8'h20, 8'hFD, 8'h76, 8'h00, 8'h00, 6);  // LD B,3; DEC B; JR NZ,-3; HALT
        repeat(300) @(posedge clk);
        if (dut.u_regfile.dbg_b !== 8'h00) begin $display("FAIL 3F5c: B=%h (oracle 0x00)", dut.u_regfile.dbg_b); errors=errors+1; end
        if (errors==0) $display("3F5c: DEC B countdown loop matches oracle (B=0)");

        // ---- 3D: ADD HL,BC (LD BC,2; LD HL,0x0FFF; ADD HL,BC -> 0x1001, H set) ----
        errors = 0;
        run_prog(8'h01, 8'h02, 8'h00, 8'h21, 8'hFF, 8'h0F, 8'h09, 8'h76, 8);  // LD BC,2; LD HL,0x0FFF; ADD HL,BC; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_h !== 8'h10 || dut.u_regfile.dbg_l !== 8'h01) begin $display("FAIL 3D1: HL=%h%h (oracle 0x1001)", dut.u_regfile.dbg_h, dut.u_regfile.dbg_l); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h10) === 8'h00) begin $display("FAIL 3D1: H not set", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3D1: ADD HL,BC matches oracle (HL=0x1001 H)");

        // ---- 3D: INC BC (LD BC,0xFFFF; INC BC -> 0x0000) ----
        errors = 0;
        run_prog(8'h01, 8'hFF, 8'hFF, 8'h03, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD BC,0xFFFF; INC BC; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_b !== 8'h00 || dut.u_regfile.dbg_c !== 8'h00) begin $display("FAIL 3D2: BC=%h%h (oracle 0x0000)", dut.u_regfile.dbg_b, dut.u_regfile.dbg_c); errors=errors+1; end
        if (errors==0) $display("3D2: INC BC matches oracle (BC=0x0000)");

        // ---- 3D: DEC HL (LD HL,0; DEC HL -> 0xFFFF) ----
        errors = 0;
        run_prog(8'h21, 8'h00, 8'h00, 8'h2B, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD HL,0; DEC HL; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_h !== 8'hFF || dut.u_regfile.dbg_l !== 8'hFF) begin $display("FAIL 3D3: HL=%h%h (oracle 0xFFFF)", dut.u_regfile.dbg_h, dut.u_regfile.dbg_l); errors=errors+1; end
        if (errors==0) $display("3D3: DEC HL matches oracle (HL=0xFFFF)");

        // ---- 3D.5: LD A,(HL) (LD HL,0x0100; LD A,(HL); ram[0]=0x99; reads at >=256 hit RAM) ----
        errors = 0;
        dut.u_memio.ram[8'h00] = 8'h99;   // addr 0x0100 -> ram index 0x00 (reads >=ROM_DEPTH hit RAM)
        run_prog(8'h21, 8'h00, 8'h01, 8'h7E, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD HL,0x0100; LD A,(HL); HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h99) begin $display("FAIL 3D5a: A=%h (oracle 0x99)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3D5a: LD A,(HL) matches oracle (A=0x99)");

        // ---- 3D.5: LD (HL),r (LD HL,0x0100; LD B,0x55; LD (HL),B -> ram[0]=0x55) ----
        errors = 0;
        run_prog(8'h21, 8'h00, 8'h01, 8'h06, 8'h55, 8'h70, 8'h76, 8'h00, 7);  // LD HL,0x0100; LD B,0x55; LD (HL),B; HALT
        repeat(200) @(posedge clk);
        if (dut.u_memio.ram[8'h00] !== 8'h55) begin $display("FAIL 3D5b: ram[0]=%h (oracle 0x55)", dut.u_memio.ram[8'h00]); errors=errors+1; end
        if (errors==0) $display("3D5b: LD (HL),B matches oracle (ram[0]=0x55)");

        // ---- 3D.5: LD A,(nn) (LD A,(0x0100); ram[0]=0x88) ----
        errors = 0;
        dut.u_memio.ram[8'h00] = 8'h88;
        run_prog(8'h3A, 8'h00, 8'h01, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00, 4);  // LD A,(0x0100); HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h88) begin $display("FAIL 3D5c: A=%h (oracle 0x88)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3D5c: LD A,(nn) matches oracle (A=0x88)");

        // ---- 3D.6: CB shifts (RLC A 0x81->0x03 C; SRL A 0x0F->0x07 C) ----
        errors = 0;
        run_prog(8'h3E, 8'h81, 8'hCB, 8'h07, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,0x81; RLC A; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h03) begin $display("FAIL 3D6a: A=%h (oracle 0x03)", dut.u_regfile.dbg_a); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h01) === 8'h00) begin $display("FAIL 3D6a: C not set", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3D6a: RLC A (0x81->0x03) matches oracle (C)");

        errors = 0;
        run_prog(8'h3E, 8'h0F, 8'hCB, 8'h3F, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,0x0F; SRL A; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h07) begin $display("FAIL 3D6b: A=%h (oracle 0x07)", dut.u_regfile.dbg_a); errors=errors+1; end
        if ((dut.u_flags.dbg_f & 8'h01) === 8'h00) begin $display("FAIL 3D6b: C not set", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3D6b: SRL A (0x0F->0x07) matches oracle (C)");

        // ---- 3D.6: BIT 4,A (A=4 -> Z set); SET 0,A (A=0 -> 0x01); RES 0,A (A=0xFF -> 0xFE) ----
        errors = 0;
        run_prog(8'h3E, 8'h04, 8'hCB, 8'h60, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,4; BIT 4,A; HALT
        repeat(200) @(posedge clk);
        if ((dut.u_flags.dbg_f & 8'h40) === 8'h00) begin $display("FAIL 3D6c: Z not set (BIT 4,A=4)", dut.u_flags.dbg_f); errors=errors+1; end
        if (errors==0) $display("3D6c: BIT 4,A (A=4) matches oracle (Z set)");

        errors = 0;
        run_prog(8'h3E, 8'h00, 8'hCB, 8'hC7, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,0; SET 0,A; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'h01) begin $display("FAIL 3D6d: A=%h (oracle 0x01)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3D6d: SET 0,A (0->0x01) matches oracle");

        errors = 0;
        run_prog(8'h3E, 8'hFF, 8'hCB, 8'h87, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD A,0xFF; RES 0,A; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'hFE) begin $display("FAIL 3D6e: A=%h (oracle 0xFE)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3D6e: RES 0,A (0xFF->0xFE) matches oracle");

        // ---- 3D.7: DD/FD (IX/IY) prefix: LD IX,0x1234 ----
        errors = 0;
        run_prog(8'hDD, 8'h21, 8'h34, 8'h12, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD IX,0x1234; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_ix !== 16'h1234) begin $display("FAIL 3D7a: IX=%h (oracle 0x1234)", dut.u_regfile.dbg_ix); errors=errors+1; end
        if (errors==0) $display("3D7a: LD IX,0x1234 matches oracle");

        // ---- 3D.7: LD IX,0x1234; INC IX -> 0x1235 ----
        errors = 0;
        run_prog(8'hDD, 8'h21, 8'h34, 8'h12, 8'hDD, 8'h23, 8'h76, 8'h00, 7);  // LD IX,0x1234; INC IX; HALT
        repeat(300) @(posedge clk);
        if (dut.u_regfile.dbg_ix !== 16'h1235) begin $display("FAIL 3D7b: IX=%h (oracle 0x1235)", dut.u_regfile.dbg_ix); errors=errors+1; end
        if (errors==0) $display("3D7b: INC IX matches oracle (IX=0x1235)");

        // ---- 3D.7: LD A,(IX+2) (LD IX,0x0100; LD A,(IX+2); ram[2]=0xAB) ----
        errors = 0;
        dut.u_memio.ram[8'h02] = 8'hAB;   // addr 0x0102 -> ram index 0x02
        run_prog(8'hDD, 8'h21, 8'h00, 8'h01, 8'hDD, 8'h7E, 8'h02, 8'h76, 8);  // LD IX,0x0100; LD A,(IX+2); HALT
        repeat(300) @(posedge clk);
        if (dut.u_regfile.dbg_a !== 8'hAB) begin $display("FAIL 3D7c: A=%h (oracle 0xAB)", dut.u_regfile.dbg_a); errors=errors+1; end
        if (errors==0) $display("3D7c: LD A,(IX+2) matches oracle (A=0xAB)");

        // ---- 3D.7: LD IY,0xABCD (FD prefix) ----
        errors = 0;
        run_prog(8'hFD, 8'h21, 8'hCD, 8'hAB, 8'h76, 8'h00, 8'h00, 8'h00, 5);  // LD IY,0xABCD; HALT
        repeat(200) @(posedge clk);
        if (dut.u_regfile.dbg_iy !== 16'hABCD) begin $display("FAIL 3D7d: IY=%h (oracle 0xABCD)", dut.u_regfile.dbg_iy); errors=errors+1; end
        if (errors==0) $display("3D7d: LD IY,0xABCD matches oracle");

        $display("----");
        if (errors == 0)
            $display("PASS: Phase 3A-3F/3F5/3D/3D5/3D6/3D7 object graph (NOP/HALT/LD/ALU/JP/JR/CALL/RET/PUSH/POP/INC-DEC/16-bit/mem-LD/CB/IX-IY) matches oracle");
        else
            $display("FAIL: %0d error(s)", errors);
        $finish;
    end

    initial begin
        #5000000;
        $display("FAIL: watchdog timeout");
        $finish;
    end
endmodule
