`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_systolic_array_8x8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for systolic_array_8x8 with proper diagonal propagation
//              and clear logging of inputs and outputs.
//
// Dependencies: systolic_array_8x8.v
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Inputs are staggered to reflect true systolic array behavior
// - Inputs are cleared for one cycle after injection
// - Logs individual outputs of the result matrix C in a clear, readable format
//////////////////////////////////////////////////////////////////////////////////

module tb_systolic_array_8x8();

    // Parameters
    parameter data_width = 8;           // Input data width (e.g., 8 bits)
    parameter acc_width = 2 * data_width; // Accumulated data width

    // Clock and reset signals
    reg clk;
    reg rst;
    reg en;

    // Flattened input and output signals
    reg [8 * 8 * data_width - 1:0] a_in_flat;
    reg [8 * 8 * data_width - 1:0] b_in_flat;
    wire [8 * 8 * data_width - 1:0] a_out_flat;
    wire [8 * 8 * data_width - 1:0] b_out_flat;
    wire [64 * acc_width - 1:0] c_out_flat;
    wire locked;

    // DUT instantiation
    systolic_array_8x8 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .a_in_flat(a_in_flat),
        .b_in_flat(b_in_flat),
        .a_out_flat(a_out_flat),
        .b_out_flat(b_out_flat),
        .c_out_flat(c_out_flat),
        .locked(locked)
    );

    // Clock generation (100 MHz clock = 10 ns period)
    always #5 clk = ~clk;

    // Task to reset the DUT
    task reset_dut;
        begin
            rst = 1;
            en = 0;
            a_in_flat = 0;
            b_in_flat = 0;
            #20; // Hold reset for 2 clock cycles
            rst = 0;
            en = 1;
            wait(locked == 1);
            #10;
            
        end
    endtask

    // Task to inject inputs diagonally and clear them for one cycle
    task inject_inputs;
        input integer t; // Current timestep
        reg [8 * data_width - 1:0] a_row; // A input row for this timestep
        reg [8 * data_width - 1:0] b_col; // B input column for this timestep
        integer i;
        begin
            a_row = 0;
            b_col = 0;

            // Inject diagonal elements based on timestep
            for (i = 0; i <= t; i = i + 1) begin
                if (i < 8 && (t - i) < 8) begin
                    // Inject A[i][t-i] into a_row
                    a_row[(i * data_width) +: data_width] = (i * 8) + (t - i) + 1;
                    // Inject B[t-i][i] into b_col
                    b_col[(i * data_width) +: data_width] = 64 - ((t - i) * 8 + i);
                end
            end

            // Assign to flattened inputs
            a_in_flat = a_row;
            b_in_flat = b_col;

            // Wait for one clock cycle
            #10;

            // Clear inputs for the next cycle
            a_in_flat = 0;
            b_in_flat = 0;

            // Wait for one clock cycle to propagate cleared inputs
            #10;
        end
    endtask

    // Task to display a matrix in row-by-row format
        // Task to display a matrix in row-by-row format
    task display_matrix;
        input [64 * acc_width - 1:0] flat_matrix; // Flattened matrix input
        input [80*8:0] matrix_name;              // Name of the matrix to display (fixed-width reg)
        integer i, j;
        reg [acc_width - 1:0] element;
        begin
            $display("%s:", matrix_name);
            for (i = 0; i < 8; i = i + 1) begin
                $write("[ ");
                for (j = 0; j < 8; j = j + 1) begin
                    element = flat_matrix[(i * 8 + j) * acc_width +: acc_width];
                    $write("%5d ", element); // Print each element in a padded format
                end
                $display("]");
            end
            $display(""); // Add a blank line for spacing
        end
    endtask


    // Task to validate outputs and display them in a readable format
        // Task to validate outputs and display them in a readable format
    task validate_outputs;
        input [64 * acc_width - 1:0] expected_c_out; // Expected result matrix
        begin
            // Display both matrices
            display_matrix(expected_c_out, "Expected Output Matrix (C)");
            display_matrix(c_out_flat, "Actual Output Matrix (C)");

            // Perform comparison
            if (c_out_flat !== expected_c_out) begin
                $display("ERROR: Mismatch in final output!");
                $finish;
            end else begin
                $display("Test Passed! Final output matches expected results.");
            end
        end
    endtask

    // Testbench process
    initial begin: tb_main
        integer t;
        reg [64 * acc_width - 1:0] expected_c_out;

        // Initialize signals
        clk = 0;
        rst = 0;
        en = 0;
        a_in_flat = 0;
        b_in_flat = 0;

        // Reset the DUT
        reset_dut();

        // Define expected result matrix for validation
                // Define expected result of C for validation
        expected_c_out = {
            16'd13700, 16'd14184, 16'd14668, 16'd15152, 16'd15636, 16'd16120, 16'd16604, 16'd17088, // Row 7
            16'd11844, 16'd12264, 16'd12684, 16'd13104, 16'd13524, 16'd13944, 16'd14364, 16'd14784, // Row 6
            16'd9988,  16'd10344, 16'd10700, 16'd11056, 16'd11412, 16'd11768, 16'd12124, 16'd12480, // Row 5
            16'd8132,  16'd8424,  16'd8716,  16'd9008,  16'd9300,  16'd9592,  16'd9884,  16'd10176, // Row 4
            16'd6276,  16'd6504,  16'd6732,  16'd6960,  16'd7188,  16'd7416,  16'd7644,  16'd7872,  // Row 3
            16'd4420,  16'd4584,  16'd4748,  16'd4912,  16'd5076,  16'd5240,  16'd5404,  16'd5568,  // Row 2
            16'd2564,  16'd2664,  16'd2764,  16'd2864,  16'd2964,  16'd3064,  16'd3164,  16'd3264,  // Row 1
            16'd708,   16'd744,   16'd780,   16'd816,   16'd852,   16'd888,   16'd924,   16'd960     // Row 0
        };

        // Apply inputs diagonally and clear them
        for (t = 0; t < 15; t = t + 1) begin
            inject_inputs(t);
        end

        // Allow time for full propagation
        #200;

        // Validate outputs
        validate_outputs(expected_c_out);

        // End simulation
        $finish;
    end

    // Timeout mechanism
    initial begin: tb_timeout
        #4000; // Simulation timeout
        $display("ERROR: Simulation timed out.");
        $finish;
    end

endmodule





