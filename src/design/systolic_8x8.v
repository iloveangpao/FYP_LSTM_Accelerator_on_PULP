`timescale 1ns / 1ps

module systolic_array_8x8 #(
    parameter data_width = 8,              // Width of input data (e.g., 8 bits)
    parameter acc_width = 2 * data_width   // Width of accumulated output
)(
    input wire clk,                        // System clock
    input wire rst,                        // Asynchronous reset
    input wire en,                         // Enable signal
    input wire [8 * 8 * data_width - 1:0] a_in_flat, // Flattened input for A (8x8 matrix)
    input wire [8 * 8 * data_width - 1:0] b_in_flat, // Flattened input for B (8x8 matrix)
    output wire [8 * 8 * data_width - 1:0] a_out_flat, // Flattened output for A
    output wire [8 * 8 * data_width - 1:0] b_out_flat, // Flattened output for B
    output wire [64 * acc_width - 1:0] c_out_flat,       // Flattened output for C (8x8 matrix)
    output wire locked
);

    wire clk_buf;
    wire locked;
    reg rst_sync;
    clk_2x2 clk_inst(
        .reset(rst),
        .clk_in1(clk),
        .clk_out1(clk_buf),
        .locked(locked)
    );
    assign clock_locked = locked;
    // Synchronized Reset Logic
    always @(posedge clk_buf or posedge rst) begin
        if (rst) begin
            rst_sync <= 1'b1;
        end else if (!locked) begin
            rst_sync <= 1'b1;
        end else begin
            rst_sync <= 1'b0;
        end
    end

    wire [4 * data_width - 1:0] a_inter[0:1][0:1];   // Intermediate A signals between 4x4 blocks
    wire [4 * data_width - 1:0] b_inter[0:1][0:1];   // Intermediate B signals between 4x4 blocks
    wire [16 * acc_width - 1:0] c_inter[0:1][0:1];   // Intermediate C signals for each 4x4 block

    // Flattened inputs for the four 4x4 blocks
    wire [4 * data_width - 1:0] a_in_4x4[0:1];
    wire [4 * data_width - 1:0] b_in_4x4[0:1];

    // Flattened outputs for the four 4x4 blocks
    wire [4 * data_width - 1:0] a_out_4x4[0:1];
    wire [4 * data_width - 1:0] b_out_4x4[0:1];

    // Assign input signals to the top row and left column of the systolic array
    assign a_in_4x4[0] = a_in_flat[0 +: 4 * data_width];    // Top-left 4 A inputs
    assign b_in_4x4[0] = b_in_flat[0 +: 4 * data_width];    // Top-left 4 B inputs
    assign a_in_4x4[1] = a_in_flat[4 * data_width +: 4 * data_width]; // Top-right 4 A inputs
    assign b_in_4x4[1] = b_in_flat[4 * data_width +: 4 * data_width]; // Top-right 4 B inputs

    // Assign final outputs to the flattened output arrays
    assign a_out_flat[0 +: 4 * data_width] = a_out_4x4[0];  // Bottom-left A outputs
    assign b_out_flat[0 +: 4 * data_width] = b_out_4x4[0];  // Top-right B outputs
    assign a_out_flat[4 * data_width +: 4 * data_width] = a_out_4x4[1]; // Bottom-right A outputs
    assign b_out_flat[4 * data_width +: 4 * data_width] = b_out_4x4[1]; // Bottom-right B outputs

    // Assign the outputs of each 4x4 block to the appropriate slice in the 8x8 output matrix
    genvar i, j, row, col;
    generate
        for (i = 0; i < 2; i = i + 1) begin                // Loop over 4x4 block rows
            for (j = 0; j < 2; j = j + 1) begin            // Loop over 4x4 block columns
                for (row = 0; row < 4; row = row + 1) begin // Loop over rows within each 4x4 block
                    for (col = 0; col < 4; col = col + 1) begin // Loop over columns within each 4x4 block
                        assign c_out_flat[
                            ((i * 4 + row) * 8 + (j * 4 + col)) * acc_width +: acc_width
                        ] = c_inter[i][j][(row * 4 + col) * acc_width +: acc_width];
                    end
                end
            end
        end
    endgenerate

    // Instantiate four 4x4 systolic array blocks to tile into an 8x8 systolic array

    // Top-left 4x4 block
    systolic_array_4x4 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa00 (
        .clk(clk_buf),
        .rst(rst_sync),
        .en(en),
        .a_in_flat(a_in_4x4[0]),     // Top-left A input
        .b_in_flat(b_in_4x4[0]),     // Top-left B input
        .a_out_flat(a_inter[0][0]),  // Connects to the next row
        .b_out_flat(b_inter[0][0]),  // Connects to the next column
        .c_out_flat(c_inter[0][0])   // Top-left 4x4 of the 8x8 C output
    );

    // Top-right 4x4 block
    systolic_array_4x4 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa01 (
        .clk(clk_buf),
        .rst(rst_sync),
        .en(en),
        .a_in_flat(a_inter[0][0]),   // Receive A input from top-left block
        .b_in_flat(b_in_4x4[1]),     // Top-right B input
        .a_out_flat(a_out_4x4[0]),   // Connects to the next row
        .b_out_flat(b_inter[0][1]),  // Connects to the next column
        .c_out_flat(c_inter[0][1])   // Top-right 4x4 of the 8x8 C output
    );

    // Bottom-left 4x4 block
    systolic_array_4x4 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa10 (
        .clk(clk_buf),
        .rst(rst_sync),
        .en(en),
        .a_in_flat(a_in_4x4[1]),     // Bottom-left A input
        .b_in_flat(b_inter[0][0]),   // Receive B input from top-left block
        .a_out_flat(a_inter[1][0]),  // Connects to the next row
        .b_out_flat(b_out_4x4[0]),   // Connects to the next column
        .c_out_flat(c_inter[1][0])   // Bottom-left 4x4 of the 8x8 C output
    );

    // Bottom-right 4x4 block
    systolic_array_4x4 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) sa11 (
        .clk(clk_buf),
        .rst(rst_sync),
        .en(en),
        .a_in_flat(a_inter[1][0]),   // Receive A input from bottom-left block
        .b_in_flat(b_inter[0][1]),   // Receive B input from top-right block
        .a_out_flat(a_out_4x4[1]),   // Final A output
        .b_out_flat(b_out_4x4[1]),   // Final B output
        .c_out_flat(c_inter[1][1])   // Bottom-right 4x4 of the 8x8 C output
    );
endmodule
