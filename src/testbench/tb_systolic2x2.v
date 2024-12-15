`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2024 04:57:55
// Design Name: 
// Module Name: tb_systolic2x2
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


module tb_systolic_2x2();

    // Parameters
    parameter data_width = 8;
    parameter acc_width = 2 * data_width;

    // DUT Ports
    reg clk;
    reg rst;
    reg start;
    wire active_buffer;
    reg [data_width-1:0] a0_in, a1_in; // Inputs for matrix A
    reg [data_width-1:0] b0_in, b1_in; // Inputs for matrix B
    wire [acc_width-1:0] c00_out, c01_out, c10_out, c11_out; // Outputs for matrix C
    wire done;

    // Instantiate the DUT
    systolic_2x2 #(
        .data_width(data_width),
        .acc_width(acc_width)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a0_in(a0_in),
        .a1_in(a1_in),
        .b0_in(b0_in),
        .b1_in(b1_in),
        .output_buffer_c00_0(c00_out),
        .output_buffer_c01_0(c01_out),
        .output_buffer_c10_0(c10_out),
        .output_buffer_c11_0(c11_out),
        .active_buffer(active_buffer)
    );

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock (10 ns period)

    // Task to reset the DUT
    task reset_dut;
        begin
            rst = 1;
            start = 0;
            a0_in = 0;
            a1_in = 0;
            b0_in = 0;
            b1_in = 0;
            #20; // Hold reset for 2 clock cycles
            rst = 0;
        end
    endtask

    // Pipelined input application
    task apply_pipelined_inputs;
        begin
            // Feed elements of Matrix A and B row/column-wise in a pipelined fashion
            // Example Matrices:
            // Matrix A = [1 2]
            //            [3 4]
            // Matrix B = [5 6]
            //            [7 8]
            // Result C = [19 22]
            //            [43 50]

            // Cycle 1: First row of A and first column of B
            rst = 0;
            start = 1;
            a0_in = 8'd1; a1_in = 8'd0;
            b0_in = 8'd5; b1_in = 8'd0;
            #10; // Wait for one clock cycle

            a0_in = 8'd0; a1_in = 8'd0;
            b0_in = 8'd0; b1_in = 8'd0;
            #20;

            // Cycle 2: Second row of A and second column of B
            a0_in = 8'd2; a1_in = 8'd3;
            b0_in = 8'd7; b1_in = 8'd6;
            #10; // Wait for one clock cycle

            a0_in = 8'd0; a1_in = 8'd0;
            b0_in = 8'd0; b1_in = 8'd0;
            #20;

            // Cycle 3: No new inputs (allow systolic array to finish propagation)
            a0_in = 0; a1_in = 4;
            b0_in = 0; b1_in = 8;
            #10;

            a0_in = 8'd0; a1_in = 8'd0;
            b0_in = 8'd0; b1_in = 8'd0;
            #120;
            // start = 0;
        end
    endtask

    // Debugging output to monitor DUT state
    always @(posedge clk) begin
        $display("Time: %0dns | c00_out = %0d | c01_out = %0d | c10_out = %0d | c11_out = %0d | active_buffer = %0d",
                 $time, c00_out, c01_out, c10_out, c11_out, active_buffer);
    end

    // Testbench process
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        start = 0;
        a0_in = 0;
        a1_in = 0;
        b0_in = 0;
        b1_in = 0;

        // Reset the DUT
        reset_dut();

        // Apply pipelined inputs
        #10;
        apply_pipelined_inputs();

        // Check the output
        // #100;
        $display("C[0][0] = %d", c00_out); // Expected: 19
        $display("C[0][1] = %d", c01_out); // Expected: 22
        $display("C[1][0] = %d", c10_out); // Expected: 43
        $display("C[1][1] = %d", c11_out); // Expected: 50

        // Verify the results
        if (c00_out === 19 && c01_out === 22 && c10_out === 43 && c11_out === 50) begin
            $display("Test Passed!");
        end else begin
            $display("Test Failed!");
        end

        // Finish simulation
        #20;
        $finish;
    end

    // Timeout mechanism
    initial begin
        #1000; // Simulation timeout
        $display("ERROR: Simulation timed out.");
        $finish;
    end

endmodule












