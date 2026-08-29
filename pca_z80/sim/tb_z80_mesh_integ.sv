`timescale 1ns/1ps
module tb_z80_mesh_integ #(parameter string ROM_FILE = "build/integ.hex") ();
    logic clk=0, rst_n=0; always #50 clk=~clk;
    logic [7:0] dbg_ir; logic [15:0] dbg_pc; logic [7:0] dbg_r; logic [15:0] dbg_sp;
    logic [31:0] dbg_count, requests, responses, accepts;
    logic halted, faulted, protocol_error;
    z80_mesh_core dut (
      .clk, .rst_n, .dbg_ir, .dbg_pc, .dbg_r, .dbg_sp,
      .gpio_out(), .uart_tx_data(), .uart_tx_start(), .uart_tx_ready(1'b1),
      .dbg_count, .dbg_halted(halted), .dbg_faulted(faulted),
      .mesh_protocol_error(protocol_error), .mesh_request_count(requests),
      .mesh_response_count(responses), .mesh_accept_count(accepts));
    integer i;
`ifdef MESH_TRACE
    always @(posedge clk) begin
      if (dut.alu_resp.ack) $display("TRACE ALU ack data=%h req=%h",dut.alu_resp.rdata,dut.alu_req);
      if (dut.alu_in_req) $display("TRACE ALU response packet=%h",dut.alu_in_msg);
      if (dut.decode_resp.ack) $display("TRACE MASTER ack data=%h obj=%0d addr=%h",dut.decode_resp.rdata,dut.decode_req.obj,dut.decode_req.addr);
    end
`endif
    initial begin
      for(i=0;i<512;i=i+1) dut.u_memio.rom[i]=8'h00;
      $readmemh(ROM_FILE,dut.u_memio.rom);
      repeat(4) @(posedge clk); rst_n=1;
      repeat(300000) begin
        @(posedge clk);
        if(halted || faulted || protocol_error) begin
          repeat(20) @(posedge clk);
          dump_and_finish;
        end
      end
      $display("FAIL: mesh timeout pc=%0d count=%0d req=%0d resp=%0d accept=%0d",dbg_pc,dbg_count,requests,responses,accepts);
      $finish;
    end
    task dump_and_finish;
      integer fh;
      begin
        fh=$fopen("build/mesh_integ_state.txt","w");
        $fdisplay(fh,"PC %0d",dbg_pc); $fdisplay(fh,"R %0d",dbg_r);
        $fdisplay(fh,"SP %0d",dbg_sp); $fdisplay(fh,"COUNT %0d",dbg_count);
        $fdisplay(fh,"HALTED %0d",halted); $fdisplay(fh,"FAULTED %0d",faulted);
        $fdisplay(fh,"A %0d",dut.u_regfile.dbg_a); $fdisplay(fh,"B %0d",dut.u_regfile.dbg_b);
        $fdisplay(fh,"C %0d",dut.u_regfile.dbg_c); $fdisplay(fh,"D %0d",dut.u_regfile.dbg_d);
        $fdisplay(fh,"E %0d",dut.u_regfile.dbg_e); $fdisplay(fh,"F %0d",dut.u_flags.dbg_f);
        $fdisplay(fh,"PROTOCOL %0d",protocol_error); $fdisplay(fh,"REQUESTS %0d",requests);
        $fdisplay(fh,"RESPONSES %0d",responses); $fdisplay(fh,"ACCEPTS %0d",accepts);
        $fclose(fh);
        $display("MESH: halted=%0d faulted=%0d protocol=%0d count=%0d req=%0d resp=%0d accept=%0d",
          halted,faulted,protocol_error,dbg_count,requests,responses,accepts);
        if(requests!=responses || responses!=accepts)
          $display("FAIL: transaction count mismatch");
        $finish;
      end
    endtask
endmodule
