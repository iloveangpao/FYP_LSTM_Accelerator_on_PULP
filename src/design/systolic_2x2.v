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
    output wire [data_width-1:0] a0_out,
    output wire [data_width-1:0] a1_out,
    output wire [data_width-1:0] b0_out,
    output wire [data_width-1:0] b1_out,
    output wire [acc_width-1:0] c00_out, // Output C[0][0]
    output wire [acc_width-1:0] c01_out, // Output C[0][1]
    output wire [acc_width-1:0] c10_out, // Output C[1][0]
    output wire [acc_width-1:0] c11_out // Output C[1][1]
    // output wire clock_locked 
);

    // Processing Elements
    wire [data_width-1:0] a01, a11, b10, b11;

    pe #(.data_width(data_width), .acc_width(acc_width)) pe00 (
        .clk(clk),
        .rst(rst),
        .en(start),
        .a_in(a0_in),
        .b_in(b0_in),
        .a_out(a01),
        .b_out(b10),
        .c_out(c00_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe01 (
        .clk(clk),
        .rst(rst),
        .en(start),
        .a_in(a01),
        .b_in(b1_in),
        .a_out(a0_out),
        .b_out(b11),
        .c_out(c01_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe10 (
        .clk(clk),
        .rst(rst),
        .en(start),
        .a_in(a1_in),
        .b_in(b10),
        .a_out(a11),
        .b_out(b0_out),
        .c_out(c10_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe11 (
        .clk(clk),
        .rst(rst),
        .en(start),
        .a_in(a11),
        .b_in(b11),
        .a_out(a1_out),
        .b_out(b1_out),
        .c_out(c11_out)
    );
endmodule













