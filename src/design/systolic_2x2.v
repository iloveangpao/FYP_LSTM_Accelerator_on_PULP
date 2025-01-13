`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2024 05:12:47
// Design Name: 
// Module Name: systolic_2x2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module systolic_2x2 #(
    parameter data_width = 8,            // Width of input data
    parameter acc_width = 2 * data_width,// Width of accumulated output
    parameter MM_CYCLES = 15             // Number of cycles for one operation
)(
    input wire clk,                      // System clock
    input wire rst,                      // Asynchronous reset
    input wire start,                    // Start signal for computation
    input wire [data_width-1:0] a0_in,   // Row 0 of Matrix A
    input wire [data_width-1:0] a1_in,   // Row 1 of Matrix A
    input wire [data_width-1:0] b0_in,   // Column 0 of Matrix B
    input wire [data_width-1:0] b1_in,   // Column 1 of Matrix B
    output wire [acc_width-1:0] c00_out, // Output C[0][0]
    output wire [acc_width-1:0] c01_out, // Output C[0][1]
    output wire [acc_width-1:0] c10_out, // Output C[1][0]
    output wire [acc_width-1:0] c11_out, // Output C[1][1]
    output wire active_buffer            // Active buffer indicator
);

    wire clk_buf;
    BUFG clk_bufg_inst (
        .I(clk),
        .O(clk_buf)
    );

    // FSM States
    localparam IDLE    = 2'b00;
    localparam S_LOAD  = 2'b01;
    localparam COMPUTE = 2'b10;
    localparam DONE    = 2'b11;

    reg [1:0] state, next_state;
    reg [3:0] cycle_count;
    reg active_buffer_reg;

    // FSM State Logic
    always @(posedge clk_buf) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            IDLE:    next_state = start ? S_LOAD : IDLE;
            S_LOAD:  next_state = COMPUTE;
            COMPUTE: next_state = (cycle_count == MM_CYCLES - 1) ? DONE : COMPUTE;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Cycle Counter
    always @(posedge clk_buf) begin
        if (rst) begin
            cycle_count <= 0;
            active_buffer_reg <= 0;
        end else if (state == COMPUTE) begin
            if (cycle_count == MM_CYCLES - 1) begin
                cycle_count <= 0;
                active_buffer_reg <= ~active_buffer_reg;
            end else begin
                cycle_count <= cycle_count + 1;
            end
        end else begin
            cycle_count <= 0;
        end
    end

    assign active_buffer = active_buffer_reg;

    // Processing Elements
    wire [data_width-1:0] a01, a11, b10, b11;
    wire [acc_width-1:0] pe00_out, pe01_out, pe10_out, pe11_out;

    pe #(.data_width(data_width), .acc_width(acc_width)) pe00 (
        .clk(clk_buf),
        .rst(rst),
        .en(state == COMPUTE),
        .a_in(a0_in),
        .b_in(b0_in),
        .a_out(a01),
        .b_out(b10),
        .c_out(pe00_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe01 (
        .clk(clk_buf),
        .rst(rst),
        .en(state == COMPUTE),
        .a_in(a01),
        .b_in(b1_in),
        .a_out(),
        .b_out(b11),
        .c_out(pe01_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe10 (
        .clk(clk_buf),
        .rst(rst),
        .en(state == COMPUTE),
        .a_in(a1_in),
        .b_in(b10),
        .a_out(a11),
        .b_out(),
        .c_out(pe10_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe11 (
        .clk(clk_buf),
        .rst(rst),
        .en(state == COMPUTE),
        .a_in(a11),
        .b_in(b11),
        .a_out(),
        .b_out(),
        .c_out(pe11_out)
    );

    // Double Buffering
    reg [acc_width-1:0] buffer_c00[1:0], buffer_c01[1:0];
    reg [acc_width-1:0] buffer_c10[1:0], buffer_c11[1:0];

    reg active_buffer_reg_buf;

    always @(posedge clk_buf) begin
        active_buffer_reg_buf <= active_buffer_reg;
    end

    always @(posedge clk_buf) begin
        if (state == COMPUTE) begin
            if (active_buffer_reg_buf == 0) begin
                buffer_c00[0] <= pe00_out;
                buffer_c01[0] <= pe01_out;
                buffer_c10[0] <= pe10_out;
                buffer_c11[0] <= pe11_out;
            end else begin
                buffer_c00[1] <= pe00_out;
                buffer_c01[1] <= pe01_out;
                buffer_c10[1] <= pe10_out;
                buffer_c11[1] <= pe11_out;
            end
        end
    end

    // Output MUX for c00_out
    assign c00_out = (active_buffer_reg_buf == 0) ? buffer_c00[0] : buffer_c00[1];
    assign c01_out = (active_buffer_reg_buf == 0) ? buffer_c01[0] : buffer_c01[1];
    assign c10_out = (active_buffer_reg_buf == 0) ? buffer_c10[0] : buffer_c10[1];
    assign c11_out = (active_buffer_reg_buf == 0) ? buffer_c11[0] : buffer_c11[1];


endmodule













