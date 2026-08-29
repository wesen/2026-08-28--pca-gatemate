// z80_mesh_adapter.sv — held object-bus transactions over PCA packets.
`default_nettype none

module z80_mesh_master_adapter #(
    parameter logic [7:0] SRC_X = 0,
    parameter logic [7:0] SRC_Y = 0
) (
    input logic clk, input logic rst_n,
    input z80_obj::bus_req_t bus_req,
    output z80_obj::bus_resp_t bus_resp,
    input logic [7:0] target_x, input logic [7:0] target_y,
    output logic l_in_req, output pca_types::msg_t l_in_msg, input logic l_in_ack,
    input logic l_out_req, input pca_types::msg_t l_out_msg, output logic l_out_ack,
    output logic protocol_error,
    output logic [31:0] request_count, output logic [31:0] response_count
);
    typedef enum logic [2:0] {M_IDLE, M_INJECT, M_WAIT_RESP, M_DRAIN_RESP, M_ACK_BUS} state_e;
    state_e state;
    z80_obj::bus_req_t req_q;
    pca_types::msg_t request_pkt;
    logic [15:0] response_data;
    logic response_match;

    always_comb begin
        l_in_req = 1'b0; l_in_msg = request_pkt; l_out_ack = 1'b0;
        bus_resp = '0;
        if (state == M_INJECT) l_in_req = 1'b1;
        if (state == M_WAIT_RESP && l_out_req) l_out_ack = 1'b1;
        if (state == M_DRAIN_RESP) l_out_ack = l_out_req;
        if (state == M_ACK_BUS) begin
            bus_resp.ack = 1'b1;
            bus_resp.rdata = response_data;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= M_IDLE; req_q <= '0; request_pkt <= '0; response_data <= '0;
            response_match <= 1'b0; protocol_error <= 1'b0;
            request_count <= 0; response_count <= 0;
        end else case (state)
            M_IDLE: if (bus_req.req) begin
                req_q <= bus_req;
                if (bus_req.we) request_pkt.cmd <= pca_types::CMD_WRITE;
                else request_pkt.cmd <= pca_types::CMD_READ;
                request_pkt.dest_x <= target_x; request_pkt.dest_y <= target_y;
                request_pkt.src_x <= SRC_X; request_pkt.src_y <= SRC_Y;
                request_pkt.addr <= bus_req.addr; request_pkt.data <= bus_req.wdata;
                state <= M_INJECT;
            end
            M_INJECT: if (l_in_ack) begin
                request_count <= request_count + 1;
                state <= M_WAIT_RESP;
            end
            M_WAIT_RESP: if (l_out_req) begin
                response_match <= l_out_msg.cmd == pca_types::CMD_RESP &&
                    l_out_msg.dest_x == SRC_X && l_out_msg.dest_y == SRC_Y &&
                    l_out_msg.src_x == request_pkt.dest_x &&
                    l_out_msg.src_y == request_pkt.dest_y &&
                    l_out_msg.addr == req_q.addr;
                if (l_out_msg.cmd == pca_types::CMD_RESP &&
                    l_out_msg.dest_x == SRC_X && l_out_msg.dest_y == SRC_Y &&
                    l_out_msg.src_x == request_pkt.dest_x &&
                    l_out_msg.src_y == request_pkt.dest_y &&
                    l_out_msg.addr == req_q.addr) begin
                    response_data <= l_out_msg.data;
                    response_count <= response_count + 1;
                end else protocol_error <= 1'b1;
                state <= M_DRAIN_RESP;
            end
            M_DRAIN_RESP: if (!l_out_req) begin
                if (response_match) state <= M_ACK_BUS;
                else state <= M_WAIT_RESP;
            end
            M_ACK_BUS: if (!bus_req.req) state <= M_IDLE;
            default: state <= M_IDLE;
        endcase
    end
endmodule

module z80_mesh_slave_adapter #(
    parameter logic [3:0] OBJ_ID = 0,
    parameter logic [7:0] SELF_X = 0,
    parameter logic [7:0] SELF_Y = 0
) (
    input logic clk, input logic rst_n,
    output z80_obj::bus_req_t bus_req,
    input z80_obj::bus_resp_t bus_resp,
    output logic l_in_req, output pca_types::msg_t l_in_msg, input logic l_in_ack,
    input logic l_out_req, input pca_types::msg_t l_out_msg, output logic l_out_ack,
    output logic protocol_error, output logic [31:0] accept_count
);
    typedef enum logic [2:0] {S_WAIT_REQ, S_WAIT_OBJECT, S_ACK_NET, S_INJECT_RESP} state_e;
    state_e state;
    pca_types::msg_t request_q, response_pkt;
    logic [15:0] response_data;
    logic request_bad;

    always_comb begin
        bus_req = '0; l_in_req = 1'b0; l_in_msg = response_pkt; l_out_ack = 1'b0;
        if (state == S_WAIT_OBJECT) begin
            bus_req.req = 1'b1;
            bus_req.we = request_q.cmd == pca_types::CMD_WRITE;
            bus_req.obj = OBJ_ID;
            bus_req.addr = request_q.addr;
            bus_req.wdata = request_q.data;
        end
        if (state == S_ACK_NET) l_out_ack = l_out_req;
        if (state == S_INJECT_RESP) l_in_req = 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_WAIT_REQ; request_q <= '0; response_pkt <= '0;
            response_data <= '0; request_bad <= 1'b0;
            protocol_error <= 1'b0; accept_count <= 0;
        end else case (state)
            S_WAIT_REQ: if (l_out_req) begin
                request_q <= l_out_msg;
                if ((l_out_msg.cmd != pca_types::CMD_READ && l_out_msg.cmd != pca_types::CMD_WRITE) ||
                    l_out_msg.dest_x != SELF_X || l_out_msg.dest_y != SELF_Y) begin
                    request_bad <= 1'b1; protocol_error <= 1'b1;
                    state <= S_ACK_NET;
                end else begin
                    request_bad <= 1'b0;
                    state <= S_WAIT_OBJECT;
                end
            end
            S_WAIT_OBJECT: if (bus_resp.ack) begin
                // `we` describes the request direction, not whether rdata matters:
                // ALU operations carry operands as writes and return {flags,result}.
                response_data <= bus_resp.rdata;
                accept_count <= accept_count + 1;
                state <= S_ACK_NET;
            end
            S_ACK_NET: if (!l_out_req) begin
                if (request_bad) state <= S_WAIT_REQ;
                else begin
                    response_pkt.cmd <= pca_types::CMD_RESP;
                    response_pkt.dest_x <= request_q.src_x; response_pkt.dest_y <= request_q.src_y;
                    response_pkt.src_x <= SELF_X; response_pkt.src_y <= SELF_Y;
                    response_pkt.addr <= request_q.addr; response_pkt.data <= response_data;
                    state <= S_INJECT_RESP;
                end
            end
            S_INJECT_RESP: if (l_in_ack) state <= S_WAIT_REQ;
            default: state <= S_WAIT_REQ;
        endcase
    end
endmodule

`default_nettype wire
