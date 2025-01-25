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
    input wire clk, rst, en,
    input wire [data_width-1:0] a_in, b_in,
    output reg [data_width-1:0] a_out, b_out,
    output reg [acc_width-1:0] c_out
);

    // Internal Registers
    reg [data_width-1:0] a_reg, b_reg;
    reg [acc_width-1:0] dsp_out_reg;  // Pipeline register for DSP output
    wire [acc_width-1:0] dsp_out;  // Intermediate wire for DSP output

    // Clock Enable Logic
    always @(posedge clk) begin
        if (rst) begin
            a_reg <= 0;
            b_reg <= 0;
            c_out <= 0;
            dsp_out_reg <= 0;
            a_out <= 0;
            b_out <= 0;
        end else if (en) begin
            a_reg <= a_in;
            b_reg <= b_in;
            
            // Stage 2: Propagate DSP output and register intermediate values
            dsp_out_reg <= dsp_out;
            c_out <= dsp_out_reg;

            // Propagate `a` and `b` outputs
            a_out <= a_reg;
            b_out <= b_reg;
        end
    end

    // DSP IP Instantiation
    dsp_mul dsp_inst (
        .CLK(clk),                // Connect clock signal
        .SCLR(rst),               // Synchronous clear
        .A(a_reg),                // First operand from internal register
        .B(b_reg),                // Second operand from internal register
        .P(dsp_out)               // DSP output connected to intermediate wire
    );

endmodule









