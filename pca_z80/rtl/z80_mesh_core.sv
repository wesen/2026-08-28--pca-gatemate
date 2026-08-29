// z80_mesh_core.sv — Z80 object graph transported over the 3x3 PCA mesh.
`default_nettype none

module z80_mesh_core #(
    parameter int ROM_DEPTH = 512,
    parameter int RAM_WORDS = 256
) (
    input logic clk, input logic rst_n,
    output logic [7:0] dbg_ir, output logic [15:0] dbg_pc,
    output logic [7:0] dbg_r, output logic [15:0] dbg_sp,
    output logic [7:0] gpio_out,
    output logic [7:0] uart_tx_data, output logic uart_tx_start, input logic uart_tx_ready,
    output logic [31:0] dbg_count, output logic dbg_halted, output logic dbg_faulted,
    output logic mesh_protocol_error,
    output logic [31:0] mesh_request_count, output logic [31:0] mesh_response_count,
    output logic [31:0] mesh_accept_count
);
    localparam int N = pca_placement_pkg::PCA_COLS * pca_placement_pkg::PCA_ROWS;
    localparam int PW = pca_types::PKT_W;

    logic [N-1:0] l_in_req, l_in_ack, l_out_req, l_out_ack;
    logic [N*PW-1:0] l_in_msg, l_out_msg;
    pca_mesh #(.COLS(pca_placement_pkg::PCA_COLS), .ROWS(pca_placement_pkg::PCA_ROWS)) u_mesh (
        .clk, .rst_n, .l_in_req, .l_in_msg, .l_in_ack,
        .l_out_req, .l_out_msg, .l_out_ack
    );

    z80_obj::bus_req_t decode_req;
    z80_obj::bus_resp_t decode_resp;
    logic [7:0] target_x, target_y;
    always_comb begin
        target_x = 8'hff; target_y = 8'hff;
        case (decode_req.obj)
            z80_obj::OBJ_PC: begin target_x=pca_placement_pkg::OBJ_PC_X; target_y=pca_placement_pkg::OBJ_PC_Y; end
            z80_obj::OBJ_MEM: begin target_x=pca_placement_pkg::OBJ_MEM_X; target_y=pca_placement_pkg::OBJ_MEM_Y; end
            z80_obj::OBJ_REG: begin target_x=pca_placement_pkg::OBJ_REG_X; target_y=pca_placement_pkg::OBJ_REG_Y; end
            z80_obj::OBJ_ALU: begin target_x=pca_placement_pkg::OBJ_ALU_X; target_y=pca_placement_pkg::OBJ_ALU_Y; end
            z80_obj::OBJ_FLAGS: begin target_x=pca_placement_pkg::OBJ_FLAGS_X; target_y=pca_placement_pkg::OBJ_FLAGS_Y; end
            default: begin target_x=8'hff; target_y=8'hff; end
        endcase
    end

    obj_decode u_decode (
        .clk, .rst_n, .bus_req(decode_req), .bus_resp(decode_resp),
        .dbg_ir, .dbg_pc_val(), .dbg_count, .dbg_halted, .dbg_faulted
    );

    pca_types::msg_t dec_in_msg, dec_out_msg;
    logic dec_in_req, dec_out_ack, dec_error;
    z80_mesh_master_adapter #(
        .SRC_X(pca_placement_pkg::OBJ_DECODE_X), .SRC_Y(pca_placement_pkg::OBJ_DECODE_Y)
    ) u_master (
        .clk, .rst_n, .bus_req(decode_req), .bus_resp(decode_resp), .target_x, .target_y,
        .l_in_req(dec_in_req), .l_in_msg(dec_in_msg),
        .l_in_ack(l_in_ack[pca_placement_pkg::OBJ_DECODE_CELL]),
        .l_out_req(l_out_req[pca_placement_pkg::OBJ_DECODE_CELL]),
        .l_out_msg(dec_out_msg), .l_out_ack(dec_out_ack),
        .protocol_error(dec_error), .request_count(mesh_request_count),
        .response_count(mesh_response_count)
    );
    assign dec_out_msg = pca_types::msg_t'(l_out_msg[pca_placement_pkg::OBJ_DECODE_CELL*PW +: PW]);

    z80_obj::bus_req_t pc_req, mem_req, reg_req, alu_req, flags_req;
    z80_obj::bus_resp_t pc_resp, mem_resp, reg_resp, alu_resp, flags_resp;
    pca_types::msg_t pc_in_msg, mem_in_msg, reg_in_msg, alu_in_msg, flags_in_msg;
    pca_types::msg_t pc_out_msg, mem_out_msg, reg_out_msg, alu_out_msg, flags_out_msg;
    logic pc_in_req, mem_in_req, reg_in_req, alu_in_req, flags_in_req;
    logic pc_out_ack, mem_out_ack, reg_out_ack, alu_out_ack, flags_out_ack;
    logic pc_err, mem_err, reg_err, alu_err, flags_err;
    logic [31:0] pc_count, mem_count, reg_count, alu_count, flags_count;

    assign pc_out_msg = pca_types::msg_t'(l_out_msg[pca_placement_pkg::OBJ_PC_CELL*PW +: PW]);
    assign mem_out_msg = pca_types::msg_t'(l_out_msg[pca_placement_pkg::OBJ_MEM_CELL*PW +: PW]);
    assign reg_out_msg = pca_types::msg_t'(l_out_msg[pca_placement_pkg::OBJ_REG_CELL*PW +: PW]);
    assign alu_out_msg = pca_types::msg_t'(l_out_msg[pca_placement_pkg::OBJ_ALU_CELL*PW +: PW]);
    assign flags_out_msg = pca_types::msg_t'(l_out_msg[pca_placement_pkg::OBJ_FLAGS_CELL*PW +: PW]);

`define SLAVE_ADAPTER(INST, ID, PFX, NAME, REQ, RESP, ERR, COUNT) \
    z80_mesh_slave_adapter #(.OBJ_ID(ID), .SELF_X(pca_placement_pkg::OBJ_``NAME``_X), \
      .SELF_Y(pca_placement_pkg::OBJ_``NAME``_Y)) INST ( \
      .clk, .rst_n, .bus_req(REQ), .bus_resp(RESP), \
      .l_in_req(PFX``_in_req), .l_in_msg(PFX``_in_msg), \
      .l_in_ack(l_in_ack[pca_placement_pkg::OBJ_``NAME``_CELL]), \
      .l_out_req(l_out_req[pca_placement_pkg::OBJ_``NAME``_CELL]), \
      .l_out_msg(PFX``_out_msg), .l_out_ack(PFX``_out_ack), \
      .protocol_error(ERR), .accept_count(COUNT));

    `SLAVE_ADAPTER(u_pc_adapter, z80_obj::OBJ_PC, pc, PC, pc_req, pc_resp, pc_err, pc_count)
    `SLAVE_ADAPTER(u_mem_adapter, z80_obj::OBJ_MEM, mem, MEM, mem_req, mem_resp, mem_err, mem_count)
    `SLAVE_ADAPTER(u_reg_adapter, z80_obj::OBJ_REG, reg, REG, reg_req, reg_resp, reg_err, reg_count)
    `SLAVE_ADAPTER(u_alu_adapter, z80_obj::OBJ_ALU, alu, ALU, alu_req, alu_resp, alu_err, alu_count)
    `SLAVE_ADAPTER(u_flags_adapter, z80_obj::OBJ_FLAGS, flags, FLAGS, flags_req, flags_resp, flags_err, flags_count)
`undef SLAVE_ADAPTER

    always_comb begin
        l_in_req = '0; l_in_msg = '0; l_out_ack = '0;
        l_in_req[pca_placement_pkg::OBJ_DECODE_CELL] = dec_in_req;
        l_in_msg[pca_placement_pkg::OBJ_DECODE_CELL*PW +: PW] = dec_in_msg;
        l_out_ack[pca_placement_pkg::OBJ_DECODE_CELL] = dec_out_ack;
        l_in_req[pca_placement_pkg::OBJ_PC_CELL] = pc_in_req;
        l_in_msg[pca_placement_pkg::OBJ_PC_CELL*PW +: PW] = pc_in_msg;
        l_out_ack[pca_placement_pkg::OBJ_PC_CELL] = pc_out_ack;
        l_in_req[pca_placement_pkg::OBJ_MEM_CELL] = mem_in_req;
        l_in_msg[pca_placement_pkg::OBJ_MEM_CELL*PW +: PW] = mem_in_msg;
        l_out_ack[pca_placement_pkg::OBJ_MEM_CELL] = mem_out_ack;
        l_in_req[pca_placement_pkg::OBJ_REG_CELL] = reg_in_req;
        l_in_msg[pca_placement_pkg::OBJ_REG_CELL*PW +: PW] = reg_in_msg;
        l_out_ack[pca_placement_pkg::OBJ_REG_CELL] = reg_out_ack;
        l_in_req[pca_placement_pkg::OBJ_ALU_CELL] = alu_in_req;
        l_in_msg[pca_placement_pkg::OBJ_ALU_CELL*PW +: PW] = alu_in_msg;
        l_out_ack[pca_placement_pkg::OBJ_ALU_CELL] = alu_out_ack;
        l_in_req[pca_placement_pkg::OBJ_FLAGS_CELL] = flags_in_req;
        l_in_msg[pca_placement_pkg::OBJ_FLAGS_CELL*PW +: PW] = flags_in_msg;
        l_out_ack[pca_placement_pkg::OBJ_FLAGS_CELL] = flags_out_ack;
    end

    obj_pc u_pc (.clk, .rst_n, .bus_req(pc_req), .bus_resp(pc_resp), .dbg_pc, .dbg_r, .dbg_sp);
    obj_memio #(.ROM_DEPTH(ROM_DEPTH), .RAM_WORDS(RAM_WORDS)) u_memio (
        .clk, .rst_n, .bus_req(mem_req), .bus_resp(mem_resp), .gpio_out,
        .uart_tx_data, .uart_tx_start, .uart_tx_ready);
    obj_regfile u_regfile (.clk, .rst_n, .bus_req(reg_req), .bus_resp(reg_resp),
        .dbg_b(), .dbg_c(), .dbg_d(), .dbg_e(), .dbg_h(), .dbg_l(), .dbg_a(), .dbg_f(), .dbg_ix(), .dbg_iy());
    obj_alu u_alu (.clk, .rst_n, .bus_req(alu_req), .bus_resp(alu_resp));
    obj_flags u_flags (.clk, .rst_n, .bus_req(flags_req), .bus_resp(flags_resp), .dbg_f());

    assign mesh_protocol_error = dec_error | pc_err | mem_err | reg_err | alu_err | flags_err;
    assign mesh_accept_count = pc_count + mem_count + reg_count + alu_count + flags_count;
endmodule

`default_nettype wire
