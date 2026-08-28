// tb_pca_mesh.sv — Phase 1 substrate tests (design-doc §13 Phase 1 exit).
//
// Verifies on a 3x3 mesh:
//   T1: A(0,0) -> B(2,0)  (pure East, 2 hops): WRITE delivered exactly once,
//       correct cmd/dest/src/addr/data, single ack, anti-double under stalls.
//   T2: A(0,0) -> C(2,2)  (East then South, XY routing): WRITE delivered to C
//       exactly once, and NOT mis-delivered to B(2,0) (which sits on the path).
//   T3: anti-double — after a send, the destination accept count stays 1 even
//       if we wait many cycles (a held req is never re-accepted).
//
// Destination cells carry a passive held-request target with a random-stall
// ready (the "object/plastic part" placeholder). The initiator at A is a
// held-request requester. Forwarder cells need no target (routers just route).
//
// Local msg bundles are flat `logic [N*PKT_W-1:0]` (matches pca_mesh ports);
// cell id's packet is the slice `[id*PKT_W +: PKT_W]`.
`timescale 1ns/1ps

import pca_types::*;

module tb_pca_mesh;
    localparam int COLS = 3, ROWS = 3, N = COLS*ROWS, PW = PKT_W;
    localparam int A = 0;   // (0,0)
    localparam int B = 2;   // (2,0)
    localparam int C = 8;   // (2,2)

    logic clk = 1'b0, rst_n = 1'b0;
    always #50 clk = ~clk;  // 100 ns period => 10 MHz

    logic        [N-1:0]       l_in_req;
    logic        [N*PW-1:0]    l_in_msg;
    logic        [N-1:0]       l_in_ack;
    logic        [N-1:0]       l_out_req;
    logic        [N*PW-1:0]    l_out_msg;
    logic        [N-1:0]       l_out_ack;

    pca_mesh #(.COLS(COLS), .ROWS(ROWS)) dut (
        .clk(clk), .rst_n(rst_n),
        .l_in_req(l_in_req), .l_in_msg(l_in_msg), .l_in_ack(l_in_ack),
        .l_out_req(l_out_req), .l_out_msg(l_out_msg), .l_out_ack(l_out_ack)
    );

    // Default: cells passive except where overridden (A initiates; B,C ack).
    for (genvar i = 0; i < N; i = i + 1) begin : tie_default
        if (i != A) begin : not_init
            assign l_in_req[i] = 1'b0;
            assign l_in_msg[i*PW +: PW] = '0;
        end
        if (i != B && i != C) begin : not_tgt
            assign l_out_ack[i] = 1'b0;
        end
    end

    // ---- Initiator at A (id 0): a held-request requester. ----
    logic       a_req;
    msg_t       a_msg;
    logic       a_ack;
    assign l_in_req[A]   = a_req;
    assign l_in_msg[A*PW +: PW] = a_msg;
    assign a_ack         = l_in_ack[A];

    task automatic send_packet(input msg_t p);
        begin
            a_msg = p;
            a_req = 1'b1;
            @(posedge clk);
            while (a_ack !== 1'b1) @(posedge clk);
            @(posedge clk);          // one cycle after ack, deassert req
            a_req = 1'b0;
            repeat(6) @(posedge clk);
        end
    endtask

    // ---- Passive held-request targets with random stalls. ----
    logic       t_ready_b, t_ready_c;
    logic       t_acc_b, t_acc_c;
    logic [PW-1:0] t_msg_b, t_msg_c;
    integer     t_cnt_b, t_cnt_c;
    wire [PW-1:0] b_out_pkt = l_out_msg[B*PW +: PW];
    wire [PW-1:0] c_out_pkt = l_out_msg[C*PW +: PW];

    always @(posedge clk) t_ready_b <= ($urandom % 3 == 0);
    always @(posedge clk) t_ready_c <= ($urandom % 3 == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_acc_b <= 1'b0; t_cnt_b <= 0; t_msg_b <= '0;
        end else if (!t_acc_b && l_out_req[B] && t_ready_b) begin
            t_acc_b <= 1'b1; t_msg_b <= b_out_pkt; t_cnt_b <= t_cnt_b + 1;
        end else if (!l_out_req[B]) begin
            t_acc_b <= 1'b0;
        end
    end
    assign l_out_ack[B] = t_acc_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_acc_c <= 1'b0; t_cnt_c <= 0; t_msg_c <= '0;
        end else if (!t_acc_c && l_out_req[C] && t_ready_c) begin
            t_acc_c <= 1'b1; t_msg_c <= c_out_pkt; t_cnt_c <= t_cnt_c + 1;
        end else if (!l_out_req[C]) begin
            t_acc_c <= 1'b0;
        end
    end
    assign l_out_ack[C] = t_acc_c;

    integer errors = 0;
    msg_t pkt, rb, rc;

    function automatic msg_t mkpkt(input cmd_e cmd, input logic [7:0] dx, dy, sx, sy,
                                   input logic [15:0] addr, input logic [15:0] data);
        msg_t m;
        m.cmd = cmd; m.dest_x = dx; m.dest_y = dy; m.src_x = sx; m.src_y = sy;
        m.addr = addr; m.data = data;
        return m;
    endfunction

    initial begin
        $dumpfile("build/pca_mesh.vcd");
        $dumpvars(0, tb_pca_mesh);
        a_req = 1'b0; a_msg = '0;

        rst_n = 1'b0; repeat(4) @(posedge clk);
        rst_n = 1'b1; repeat(4) @(posedge clk);

        // ---- T1: A(0,0) -> B(2,0) WRITE 0xCAFE to addr 0x10 ----
        t_cnt_b = 0; t_cnt_c = 0;
        send_packet(mkpkt(CMD_WRITE, 8'd2, 8'd0, 8'd0, 8'd0, 16'h0010, 16'hCAFE));
        repeat(3) @(posedge clk);
        rb = msg_t'(t_msg_b);
        if (t_cnt_b !== 1) begin
            $display("FAIL T1: B accept count=%0d (expected 1)", t_cnt_b); errors = errors + 1;
        end
        if (rb.cmd !== CMD_WRITE || rb.data !== 16'hCAFE || rb.dest_x !== 8'd2 || rb.dest_y !== 8'd0) begin
            $display("FAIL T1: B got wrong packet cmd=%0d data=%h dx=%0d dy=%0d",
                     rb.cmd, rb.data, rb.dest_x, rb.dest_y); errors = errors + 1;
        end
        repeat(20) @(posedge clk);
        if (t_cnt_b !== 1) begin $display("FAIL T1 anti-double: B count=%0d after wait", t_cnt_b); errors = errors + 1; end
        if (t_cnt_c !== 0) begin $display("FAIL T1: C mis-delivered count=%0d", t_cnt_c); errors = errors + 1; end
        $display("T1: A->B WRITE delivered once (count=%0d)", t_cnt_b);

        // ---- T2: A(0,0) -> C(2,2) WRITE 0xBEEF (East x2 then South x2) ----
        t_cnt_b = 0; t_cnt_c = 0;
        send_packet(mkpkt(CMD_WRITE, 8'd2, 8'd2, 8'd0, 8'd0, 16'h0007, 16'hBEEF));
        repeat(3) @(posedge clk);
        rc = msg_t'(t_msg_c);
        if (t_cnt_c !== 1) begin $display("FAIL T2: C accept count=%0d (expected 1)", t_cnt_c); errors = errors + 1; end
        if (rc.data !== 16'hBEEF) begin $display("FAIL T2: C got wrong data=%h", rc.data); errors = errors + 1; end
        if (t_cnt_b !== 0) begin $display("FAIL T2: B mis-delivered (XY should pass through) count=%0d", t_cnt_b); errors = errors + 1; end
        repeat(20) @(posedge clk);
        if (t_cnt_c !== 1) begin $display("FAIL T2 anti-double: C count=%0d after wait", t_cnt_c); errors = errors + 1; end
        $display("T2: A->C WRITE (XY via B-path) delivered to C once, B untouched (B=%0d C=%0d)", t_cnt_b, t_cnt_c);

        // ---- T3: anti-double under heavy stalls on a fresh send ----
        t_cnt_b = 0;
        send_packet(mkpkt(CMD_WRITE, 8'd2, 8'd0, 8'd0, 8'd0, 16'h0001, 16'h1234));
        repeat(40) @(posedge clk);
        if (t_cnt_b !== 1) begin $display("FAIL T3: B count=%0d after long wait (expected 1)", t_cnt_b); errors = errors + 1; end
        else $display("T3: anti-double holds (B count=1 after 40 cycles)");

        $display("----");
        if (errors == 0) $display("PASS: PCA mesh substrate (routing + single-ack + anti-double)");
        else $display("FAIL: %0d error(s)", errors);
        $finish;
    end

    initial begin #200000; $display("FAIL: watchdog timeout"); $finish; end
endmodule
