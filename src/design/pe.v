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


module pe #(parameter data_width = 8)(
    input wire [data_width - 1:0] a_in, b_in,
    input wire clk, rst, enable,
    output reg [data_width - 1:0] a_out, b_out,
    output reg [2*data_width - 1:0] c_out,
    output reg valid, done // Added valid and done flags
    );

    reg [1:0] state;
    
    always @(posedge clk) begin
        if (rst) begin
            a_out <= 0;
            b_out <= 0;
            c_out <= 0;
            valid <= 0;
            done <= 0;
            state <= 0;
        end
        else if (enable) begin
            a_out <= a_in;
            b_out <= b_in;
            c_out <= c_out + a_in * b_in;
            valid <= 1;
            if (state == 0) begin
                done <= 0;
                state <= state + 1;
            end
            else begin
                done <= 1;  // After the first step, computation is "done" for this PE
            end
        end
        else begin
            valid <= 0;
            done <= 0;
        end
    end
endmodule

