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
    parameter acc_width = 4 * data_width; // Accumulated data width

    // Clock and reset signals
    reg clk;
    reg rst;
    reg en;

    // Flattened input and output signals
    reg [8 * data_width - 1:0] a_in_flat;
    reg [8 * data_width - 1:0] b_in_flat;
    wire [8 * data_width - 1:0] a_out_flat;
    wire [8 * data_width - 1:0] b_out_flat;
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
    // task inject_inputs;
    //     input integer t; // Current timestep
    //     reg [8 * data_width - 1:0] a_row; // A input row for this timestep
    //     reg [8 * data_width - 1:0] b_col; // B input column for this timestep
    //     integer i;
    //     begin
    //         a_row = 0;
    //         b_col = 0;

    //         // Inject diagonal elements based on timestep
    //         for (i = 0; i <= t; i = i + 1) begin
    //             if (i < 8 && (t - i) < 8) begin
    //                 // Inject A[i][t-i] into a_row
    //                 a_row[(i * data_width) +: data_width] = (i * 8) + (t - i) + 1;
    //                 // Inject B[t-i][i] into b_col
    //                 b_col[(i * data_width) +: data_width] = 64 - ((t - i) * 8 + i);
    //             end
    //         end

    //         // Assign to flattened inputs
    //         a_in_flat = a_row;
    //         b_in_flat = b_col;

    //         // Wait for one clock cycle
    //         #10;

    //         // Clear inputs for the next cycle
    //         a_in_flat = 0;
    //         b_in_flat = 0;

    //         // Wait for one clock cycle to propagate cleared inputs
    //         #10;
    //     end
    // endtask

    task inject_inputs;
        input integer t; // Current timestep
        // Flattened input buses for one row of matrix A and one column of matrix B.
        reg [8 * data_width - 1:0] a_row;
        reg [8 * data_width - 1:0] b_col;
        integer i;
        begin
            a_row = 0;
            b_col = 0;

            // For each valid diagonal index at this timestep,
            // inject the corresponding elements from A and B.
            // The values are now computed as:
            //   A[i][t-i] = (i * 8) + (t-i) + 1
            //   B[t-i][i] = (i * 8) + (t-i) + 1   (since B is the transpose of A)
            // Examples:
            //   t = 0:
            //     i = 0 => A[0][0] = 0*8 + 0 + 1 = 1,  B[0][0] = 1
            //
            //   t = 1:
            //     i = 0 => A[0][1] = 0*8 + 1 + 1 = 2,  B[1][0] = 2
            //     i = 1 => A[1][0] = 1*8 + 0 + 1 = 9,  B[0][1] = 9
            for (i = 0; i <= t; i = i + 1) begin
                if ((i < 8) && ((t - i) < 8)) begin
                    // Inject the diagonal element from matrix A.
                    a_row[(i * data_width) +: data_width] = (i * 8) + (t - i) + 1;
                    // Inject the corresponding diagonal element from matrix B.
                    b_col[(i * data_width) +: data_width] = (i * 8) + (t - i) + 1;
                end
            end

            // Drive the computed diagonal values onto the flattened input signals.
            a_in_flat = a_row;
            b_in_flat = b_col;

            // Hold the values for one clock cycle.
            #10;

            // Clear the inputs for the next cycle.
            a_in_flat = 0;
            b_in_flat = 0;

            // Wait one more clock cycle to ensure proper propagation.
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
            if (c_out_flat != expected_c_out) begin
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
            32'd13700, 32'd14184, 32'd14668, 32'd15152, 32'd15636, 32'd16120, 32'd16604, 32'd17088, // Row 7
            32'd11844, 32'd12264, 32'd12684, 32'd13104, 32'd13524, 32'd13944, 32'd14364, 32'd14784, // Row 6
            32'd9988,  32'd10344, 32'd10700, 32'd11056, 32'd11412, 32'd11768, 32'd12124, 32'd12480, // Row 5
            32'd8132,  32'd8424,  32'd8716,  32'd9008,  32'd9300,  32'd9592,  32'd9884,  32'd10176, // Row 4
            32'd6276,  32'd6504,  32'd6732,  32'd6960,  32'd7188,  32'd7416,  32'd7644,  32'd7872,  // Row 3
            32'd4420,  32'd4584,  32'd4748,  32'd4912,  32'd5076,  32'd5240,  32'd5404,  32'd5568,  // Row 2
            32'd2564,  32'd2664,  32'd2764,  32'd2864,  32'd2964,  32'd3064,  32'd3164,  32'd3264,  // Row 1
            32'd708,   32'd744,   32'd780,   32'd816,   32'd852,   32'd888,   32'd924,   32'd960     // Row 0
        };



        // Apply inputs diagonally and clear them
        for (t = 0; t < 15; t = t + 1) begin
            inject_inputs(t);
        end

        // Allow time for full propagation
        #190;

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





