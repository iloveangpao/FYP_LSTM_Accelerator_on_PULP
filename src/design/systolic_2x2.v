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


module systolic_2x2 #(parameter data_width = 8)(
    input wire clk, rst,
    input wire enable, // Global enable signal for the systolic array
    input wire [data_width - 1:0] a0, a1, b0, b1,
    output wire [2*data_width - 1:0] c00, c01, c10, c11,
    output wire valid00, valid01, valid10, valid11, // Output valid signals
    output reg busy, done // Added busy and done flags
    );

    wire [data_width - 1:0] a00, a10, b00, b10;
    wire done00, done01, done10, done11;  // Done signals from each PE
    wire valid00, valid01, valid10, valid11;  // Valid signals from each PE

    // Processing Element 00
    pe #(.data_width(data_width)) pe00 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a0), .b_in(b0),
        .a_out(a00), .b_out(b00),
        .c_out(c00),
        .valid(valid00),
        .done(done00)  // Done signal for PE00
    );

    // Processing Element 01
    pe #(.data_width(data_width)) pe01 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a00), .b_in(b1),
        .a_out(), .b_out(b10),
        .c_out(c01),
        .valid(valid01),
        .done(done01)  // Done signal for PE01
    );

    // Processing Element 10
    pe #(.data_width(data_width)) pe10 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a1), .b_in(b00),
        .a_out(a10), .b_out(),
        .c_out(c10),
        .valid(valid10),
        .done(done10)  // Done signal for PE10
    );

    // Processing Element 11
    pe #(.data_width(data_width)) pe11 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a10), .b_in(b10),
        .a_out(), .b_out(),
        .c_out(c11),
        .valid(valid11),
        .done(done11)  // Done signal for PE11
    );

    // Busy flag: if any PE is not done, the systolic array is busy
    always @(*) begin
        busy = !(done00 && done01 && done10 && done11);
    end

    // Done flag: the systolic array is done when all PEs are done
    always @(*) begin
        done = (done00 && done01 && done10 && done11);
    end
endmodule

