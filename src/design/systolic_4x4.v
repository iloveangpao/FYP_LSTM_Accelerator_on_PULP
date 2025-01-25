`timescale 1ns / 1ps

module systolic_array_4x4 #(
    parameter data_width = 8,             // Width of input data
    parameter acc_width = 2 * data_width  // Width of accumulated output
)(
    input wire clk,                       // System clock
    input wire rst,                       // Asynchronous reset
    input wire en,                        // Enable signal
    input wire [4 * data_width-1:0] a_in_flat, // Flattened input for A
    input wire [4 * data_width-1:0] b_in_flat, // Flattened input for B
    output wire [4 * data_width-1:0] a_out_flat, // Flattened output for A
    output wire [4 * data_width-1:0] b_out_flat, // Flattened output for B
    output wire [16 * acc_width-1:0] c_out_flat  // Flattened output for C
);
    // Internal signals for the systolic array
    wire [data_width-1:0] a_inter[0:7];
    wire [data_width-1:0] b_inter[0:7];
    wire [data_width-1:0] a_in[0:3];
    wire [data_width-1:0] b_in[0:3];
    wire [data_width-1:0] a_out[0:3];
    wire [data_width-1:0] b_out[0:3];
    wire [acc_width-1:0] c_out[0:3][0:3];

    // Unpack flattened inputs and pack outputs
    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin
            // Flattened A and B inputs into arrays
            assign a_in[k] = a_in_flat[k * data_width +: data_width];
            assign b_in[k] = b_in_flat[k * data_width +: data_width];
            assign a_out[k] = a_inter[k + 4];
            assign b_out[k] = b_inter[ k + 4];

            // Flattened A and B outputs
            assign a_out_flat[k * data_width +: data_width] = a_out[k];
            assign b_out_flat[k * data_width +: data_width] = b_out[k];
        end

        // Flatten 2D `c_out` array into a 1D `c_out_flat`
        for (k = 0; k < 16; k = k + 1) begin
            assign c_out_flat[k * acc_width +: acc_width] = c_out[k / 4][k % 4];
        end
    endgenerate

    // Instantiate systolic_2x2
    systolic_2x2 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa00 (
        .clk(clk), 
        .rst(rst), 
        .start(en), // Enable signal for computation
        .a0_in( a_in[0] ), 
        .a1_in( a_in[1] ),
        .b0_in( b_in[0] ), 
        .b1_in( b_in[1] ),
        .a0_out(a_inter[0]), 
        .a1_out(a_inter[1]),
        .b0_out(b_inter[0]), 
        .b1_out(b_inter[1]),
        .c00_out(c_out[0][0]), 
        .c01_out(c_out[0][1]), 
        .c10_out(c_out[1][0]), 
        .c11_out(c_out[1][1])
    );

        // Instantiate systolic_2x2
    systolic_2x2 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa01 (
        .clk(clk), 
        .rst(rst), 
        .start(en), // Enable signal for computation
        .a0_in( a_inter[0] ), 
        .a1_in( a_inter[1] ),
        .b0_in( b_in[2] ), 
        .b1_in( b_in[3] ),
        .a0_out(a_inter[4]), 
        .a1_out(a_inter[5]),
        .b0_out(b_inter[2]), 
        .b1_out(b_inter[3]),
        .c00_out(c_out[0][2]), 
        .c01_out(c_out[0][3]), 
        .c10_out(c_out[1][2]), 
        .c11_out(c_out[1][3])
    );
        // Instantiate systolic_2x2
    systolic_2x2 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa10 (
        .clk(clk), 
        .rst(rst), 
        .start(en), // Enable signal for computation
        .a0_in( a_in[2] ), 
        .a1_in( a_in[3] ),
        .b0_in( b_inter[0] ), 
        .b1_in( b_inter[1] ),
        .a0_out(a_inter[2]), 
        .a1_out(a_inter[3]),
        .b0_out(b_inter[4]), 
        .b1_out(b_inter[5]),
        .c00_out(c_out[2][0]), 
        .c01_out(c_out[2][1]), 
        .c10_out(c_out[3][0]), 
        .c11_out(c_out[3][1])
    );
        // Instantiate systolic_2x2
    systolic_2x2 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa11 (
        .clk(clk), 
        .rst(rst), 
        .start(en), // Enable signal for computation
        .a0_in( a_inter[2] ),
        .a1_in( a_inter[3] ),
        .b0_in( b_inter[2] ),
        .b1_in( b_inter[3] ),
        .a0_out(a_inter[6]), 
        .a1_out(a_inter[7]),
        .b0_out(b_inter[6]), 
        .b1_out(b_inter[7]),
        .c00_out(c_out[2][2]), 
        .c01_out(c_out[2][3]), 
        .c10_out(c_out[3][2]), 
        .c11_out(c_out[3][3])
    );
endmodule



