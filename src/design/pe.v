`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2024 03:50:38
// Design Name: 
// Module Name: Systolic2x2
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


module pe #(
    parameter data_width = 8,
    parameter acc_width = 2 * data_width
)(
    input wire clk, rst, en,                  // Added en (enable) signal
    input wire [data_width - 1:0] a_in, b_in,
    output reg [data_width - 1:0] a_out, b_out,
    output reg [acc_width - 1:0] c_out
);

    // Pipeline registers
    reg [data_width - 1:0] a_reg, b_reg;
    reg [acc_width - 1:0] mul_reg;
    reg [acc_width - 1:0] acc_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all pipeline registers
            a_reg <= 0;
            b_reg <= 0;
            mul_reg <= 0;
            acc_reg <= 0;
            c_out <= 0;
            a_out <= 0;
            b_out <= 0;
        end else if (en) begin
            // Pipeline data and perform calculations
            a_reg <= a_in;
            b_reg <= b_in;
            mul_reg <= a_reg * b_reg;
            acc_reg <= mul_reg + acc_reg;
            c_out <= acc_reg;
            a_out <= a_reg;
            b_out <= b_reg;
        end
    end
endmodule






