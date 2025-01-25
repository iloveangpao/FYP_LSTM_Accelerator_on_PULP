`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_systolic_2x2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for systolic_2x2 with output validation for a0_out, a1_out, b0_out, b1_out
// 
// Dependencies: systolic_2x2.v
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
    reg [data_width-1:0] a0_in, a1_in; // Inputs for matrix A
    reg [data_width-1:0] b0_in, b1_in; // Inputs for matrix B
    wire [data_width-1:0] a0_out, a1_out; // Outputs for matrix A (forwarded)
    wire [data_width-1:0] b0_out, b1_out; // Outputs for matrix B (forwarded)
    wire [acc_width-1:0] c00_out, c01_out, c10_out, c11_out; // Outputs for matrix C
    wire clock_locked;

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
        .a0_out(a0_out),
        .a1_out(a1_out),
        .b0_out(b0_out),
        .b1_out(b1_out),
        .c00_out(c00_out),
        .c01_out(c01_out),
        .c10_out(c10_out),
        .c11_out(c11_out),
        .clock_locked(clock_locked)
    );

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock (10 ns period)

    // Task to reset the DUT
    task reset_dut;
        begin
            rst = 1;
            start = 1;
            a0_in = 0;
            a1_in = 0;
            b0_in = 0;
            b1_in = 0;
            #10; // Hold reset for 2 clock cycles
            rst = 0;

            // Wait for locked signal to assert
            wait(clock_locked == 1);
            #20;
        end
    endtask

    // Task to apply pipelined inputs and validate outputs
    task apply_pipelined_inputs_and_validate;
        reg [data_width-1:0] expected_a0_out, expected_a1_out;
        reg [data_width-1:0] expected_b0_out, expected_b1_out;
        reg [acc_width-1:0] expected_c00_out, expected_c01_out, expected_c10_out, expected_c11_out;
        integer cycle;

        begin
            // Initialize expected values
            expected_a0_out = 0; expected_a1_out = 0;
            expected_b0_out = 0; expected_b1_out = 0;
            expected_c00_out = 0; expected_c01_out = 0;
            expected_c10_out = 0; expected_c11_out = 0;

            // Cycle 1: Feed A[0][0] and B[0][0]
            cycle = 1;
            start = 1;
            a0_in = 8'd1; a1_in = 8'd0;
            b0_in = 8'd5; b1_in = 8'd0;
            #10; // Wait for one clock cycle

            a0_in = 8'd0; a1_in = 8'd0;
            b0_in = 8'd0; b1_in = 8'd0;
            #10; // Wait for one clock cycle

            // // Validate intermediate forwarded outputs
            // expected_a0_out = 8'd0; // Forwarded A[0][0]
            // expected_a1_out = 8'd0; // Forwarded A[1][0]
            // expected_b0_out = 8'd0; // Forwarded B[0][0]
            // expected_b1_out = 8'd0; // Forwarded B[1][0]
            // if (a0_out !== expected_a0_out || a1_out !== expected_a1_out ||
            //     b0_out !== expected_b0_out || b1_out !== expected_b1_out) begin
            //     $display("ERROR at cycle %0d: Mismatch in forwarded A or B outputs!", cycle);
            //     $finish;
            // end
            
            // Cycle 2: Feed A[0][1] and B[1][0]
            cycle = 3;
            a0_in = 8'd2; a1_in = 8'd3;
            b0_in = 8'd7; b1_in = 8'd6;
            #10;

            a0_in = 8'd0; a1_in = 8'd0;
            b0_in = 8'd0; b1_in = 8'd0;
            #10; // Wait for one clock cycle

            // // Validate intermediate forwarded outputs
            // expected_a0_out = 8'd1; // Forwarded A[0][1]
            // expected_a1_out = 8'd0; // Forwarded A[1][1]
            // expected_b0_out = 8'd5; // Forwarded B[0][1]
            // expected_b1_out = 8'd0; // Forwarded B[1][1]
            // if (a0_out !== expected_a0_out || a1_out !== expected_a1_out ||
            //     b0_out !== expected_b0_out || b1_out !== expected_b1_out) begin
            //     $display("ERROR at cycle %0d: Mismatch in forwarded A or B outputs!", cycle);
            //     $finish;
            // end

            // Cycle 3: Let data propagate (no new inputs)
            cycle = 5;
            a0_in = 0; a1_in = 8'd4;
            b0_in = 0; b1_in = 8'd8;
            #10;

            cycle = 6;
            a0_in = 0; a1_in = 0;
            b0_in = 0; b1_in = 0;
            #10;

            // Validate forwarded outputs
            expected_a0_out = 8'd2; // Forwarded A[0][2]
            expected_a1_out = 8'd3; // Forwarded A[1][2]
            expected_b0_out = 8'd7; // Forwarded B[0][2]
            expected_b1_out = 8'd6; // Forwarded B[1][2]
            if (a0_out !== expected_a0_out || a1_out !== expected_a1_out ||
                b0_out !== expected_b0_out || b1_out !== expected_b1_out) begin
                $display("ERROR at cycle %0d: Mismatch in forwarded A or B outputs!", cycle);
                $finish;
            end

            cycle = 8;
            #20;

            // Validate forwarded outputs
            expected_a0_out = 8'd0; // Forwarded A[0][2]
            expected_a1_out = 8'd4; // Forwarded A[1][2]
            expected_b0_out = 8'd0; // Forwarded B[0][2]
            expected_b1_out = 8'd8; // Forwarded B[1][2]
            if (a0_out !== expected_a0_out || a1_out !== expected_a1_out ||
                b0_out !== expected_b0_out || b1_out !== expected_b1_out) begin
                $display("ERROR at cycle %0d: Mismatch in forwarded A or B outputs!", cycle);
                $finish;
            end

            // Cycle 4: No more inputs, allow final computation
            cycle = 10;
            a0_in = 0; a1_in = 0;
            b0_in = 0; b1_in = 0;
            #60; // Wait for final computation to complete

            // Validate final matrix C outputs
            expected_c00_out = 19; expected_c01_out = 22;
            expected_c10_out = 43; expected_c11_out = 50;
            if (c00_out !== expected_c00_out || c01_out !== expected_c01_out ||
                c10_out !== expected_c10_out || c11_out !== expected_c11_out) begin
                $display("ERROR: Mismatch in Matrix C outputs!");
                $finish;
            end

            $display("Test Passed! All outputs match expected results.");
        end
    endtask

    // Debugging output to monitor DUT state
    always @(posedge clk) begin
        $display("Time: %0dns | c00_out = %0d | c01_out = %0d | c10_out = %0d | c11_out = %0d| a0_out = %0d | a1_out = %0d | b0_out = %0d | b1_out = %0d",
                 $time, c00_out, c01_out, c10_out, c11_out, a0_out, a1_out, b0_out, b1_out);
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

        // Apply pipelined inputs and validate outputs
        #10;
        apply_pipelined_inputs_and_validate();
        $finish;
    end

    // Timeout mechanism
    initial begin
        #1000; // Simulation timeout
        $display("ERROR: Simulation timed out.");
        $finish;
    end

endmodule













