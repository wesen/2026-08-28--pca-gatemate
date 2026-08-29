`timescale 1ns/1ps
module tb_mesh_hello;
    localparam int BIT_CYC=10_000_000/115_200;
    logic clk_10m=0, fpga_but=1, user_led, uart_tx_pin, uart_rx_pin=1;
    always #50 clk_10m=~clk_10m;
    top #(.ROM_DEPTH(512),.MESH_MODE(1)) dut (.*);
    logic [7:0] bytes[0:1], shift; integer count=0,bit_i;
    task capture;
      begin
        @(negedge uart_tx_pin); repeat(BIT_CYC/2) @(posedge clk_10m);
        for(bit_i=0;bit_i<8;bit_i=bit_i+1) begin
          repeat(BIT_CYC) @(posedge clk_10m); shift[bit_i]=uart_tx_pin;
        end
        bytes[count]=shift; count=count+1; repeat(BIT_CYC) @(posedge clk_10m);
      end
    endtask
    initial begin
      $readmemh("build/hello.hex",dut.g_mesh.u_core.u_memio.rom);
      repeat(20) @(posedge clk_10m);
      fork begin capture; capture; end begin repeat(100000) @(posedge clk_10m); end join_any
      if(count==2 && bytes[0]==8'h48 && bytes[1]==8'h69 && !dut.mesh_protocol_error) begin
        $display("PASS: mesh-backed UART emits Hi; req=%0d resp=%0d accept=%0d",
          dut.mesh_request_count,dut.mesh_response_count,dut.mesh_accept_count);
      end else begin
        $display("FAIL: mesh UART count=%0d bytes=%h %h protocol=%0d",count,bytes[0],bytes[1],dut.mesh_protocol_error);
        $fatal(1);
      end
      $finish;
    end
endmodule
