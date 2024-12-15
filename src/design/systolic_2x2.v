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
    parameter data_width = 8,
    parameter acc_width = 2 * data_width,
    parameter MM_CYCLES = 15 // Number of cycles needed for each full matrix multiplication
)(
    input wire clk, rst, start,              // Control signals
    input wire [data_width-1:0] a0_in, a1_in, // Input matrices A row elements
    input wire [data_width-1:0] b0_in, b1_in, // Input matrices B column elements
    output reg [acc_width-1:0] output_buffer_c00_0, output_buffer_c00_1,
    output reg [acc_width-1:0] output_buffer_c01_0, output_buffer_c01_1,
    output reg [acc_width-1:0] output_buffer_c10_0, output_buffer_c10_1,
    output reg [acc_width-1:0] output_buffer_c11_0, output_buffer_c11_1,
    output reg active_buffer
    // output reg [acc_width-1:0] c00_out, c01_out, c10_out, c11_out
);

    // Double buffering for outputs - separate registers for each buffer
    // reg [acc_width-1:0] output_buffer_c00_0, output_buffer_c00_1;
    // reg [acc_width-1:0] output_buffer_c01_0, output_buffer_c01_1;
    // reg [acc_width-1:0] output_buffer_c10_0, output_buffer_c10_1;
    // reg [acc_width-1:0] output_buffer_c11_0, output_buffer_c11_1;

    // reg active_buffer;     // Active buffer selector (0 or 1)
    reg [3:0] cycle_count; // Cycle counter

    // Intermediate wires to hold the outputs of each PE
    wire [acc_width-1:0] pe00_out, pe01_out, pe10_out, pe11_out;

    // Internal wires for PE interconnections
    wire [data_width-1:0] a01, a11, b10, b11;

    // Assign the current active input buffer to the systolic array inputs
    reg [data_width-1:0] a00_input;
    reg [data_width-1:0] a01_input;
    reg [data_width-1:0] a10_input;
    reg [data_width-1:0] a11_input;
    reg [data_width-1:0] b00_input;
    reg [data_width-1:0] b01_input;
    reg [data_width-1:0] b10_input;
    reg [data_width-1:0] b11_input;

    // Enable signals for PEs
    wire en = (cycle_count < MM_CYCLES); // Enable PEs during MM operation

    // Toggle between buffers for double buffering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count <= 0;
            active_buffer <= 0;

            a00_input <= 0;
            a01_input <= 0;
            a10_input <= 0;
            a11_input <= 0;
            b00_input <= 0;
            b01_input <= 0;
            b10_input <= 0;
            b11_input <= 0;

            // Initialize output buffers to zero on reset
            output_buffer_c00_0 <= 0;
            output_buffer_c01_0 <= 0;
            output_buffer_c10_0 <= 0;
            output_buffer_c11_0 <= 0;
            output_buffer_c00_1 <= 0;
            output_buffer_c01_1 <= 0;
            output_buffer_c10_1 <= 0;
            output_buffer_c11_1 <= 0;

            // Initialize output registers to zero
            // c00_out <= 0;
            // c01_out <= 0;
            // c10_out <= 0;
            // c11_out <= 0;
        end else if (start) begin
            a00_input <= a0_in;
            a01_input <= a01;
            a10_input <= a1_in;
            a11_input <= a11;
            b00_input <= b0_in;
            b01_input <= b1_in;
            b10_input <= b10;
            b11_input <= b11;
            if (cycle_count < MM_CYCLES) begin
                // Increment cycle count during MM operation
                cycle_count <= cycle_count + 1;
            end else begin
                // Reset cycle counter and toggle buffer once MM operation completes
                cycle_count <= 0;
                active_buffer <= ~active_buffer; // Toggle buffer
            end
        end else begin
            cycle_count <= 0;
        end
    end

    // Instantiate the PEs in a 2x2 configuration

    // PE (0,0)
    pe #(.data_width(data_width), .acc_width(acc_width)) pe00 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .a_in(a00_input),
        .b_in(b00_input),
        .a_out(a01),
        .b_out(b10),
        .c_out(pe00_out)  // Connect directly to wire
    );

    // PE (0,1)
    pe #(.data_width(data_width), .acc_width(acc_width)) pe01 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .a_in(a01_input),
        .b_in(b01_input),
        .a_out(),
        .b_out(b11),
        .c_out(pe01_out)  // Connect directly to wire
    );

    // PE (1,0)
    pe #(.data_width(data_width), .acc_width(acc_width)) pe10 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .a_in(a10_input),
        .b_in(b10_input),
        .a_out(a11),
        .b_out(),
        .c_out(pe10_out)  // Connect directly to wire
    );

    // PE (1,1)
    pe #(.data_width(data_width), .acc_width(acc_width)) pe11 (
        .clk(clk),
        .rst(rst),
        .en(en),
        .a_in(a11_input),
        .b_in(b11_input),
        .a_out(),
        .b_out(),
        .c_out(pe11_out)  // Connect directly to wire
    );

    // Write PE outputs to the correct buffer based on active_buffer
    always @(posedge clk) begin
        if (en) begin
            if (active_buffer == 0) begin
                output_buffer_c00_0 <= pe00_out;
                output_buffer_c01_0 <= pe01_out;
                output_buffer_c10_0 <= pe10_out;
                output_buffer_c11_0 <= pe11_out;
            end else begin
                output_buffer_c00_1 <= pe00_out;
                output_buffer_c01_1 <= pe01_out;
                output_buffer_c10_1 <= pe10_out;
                output_buffer_c11_1 <= pe11_out;
            end
        end
    end

    // // Output result assignments (from the inactive buffer, which holds stable data)
    // always @(posedge clk) begin
    //     if (~active_buffer) begin
    //         c00_out <= output_buffer_c00_0;
    //         c01_out <= output_buffer_c01_0;
    //         c10_out <= output_buffer_c10_0;
    //         c11_out <= output_buffer_c11_0;
    //     end else begin
    //         c00_out <= output_buffer_c00_1;
    //         c01_out <= output_buffer_c01_1;
    //         c10_out <= output_buffer_c10_1;
    //         c11_out <= output_buffer_c11_1;
    //     end
    // end

endmodule










