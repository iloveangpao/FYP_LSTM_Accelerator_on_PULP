`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_systolic_array_4x4
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for systolic_array_4x4 with proper propagation and clear logging
// 
// Dependencies: systolic_array_4x4.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Inputs are staggered to reflect true systolic array behavior
// - Logs individual outputs of the result matrix C in a clear, readable format
//////////////////////////////////////////////////////////////////////////////////

module tb_systolic_array_4x4();

    // Parameters
    parameter data_width = 8;
    parameter acc_width = 2 * data_width;

    // Clock and reset
    reg clk;
    reg rst;
    reg en;

    // Input and output signals
    reg [4 * data_width - 1 : 0] a_in_flat;
    reg [4 * data_width - 1 : 0] b_in_flat;
    wire [4 * data_width - 1 : 0] a_out_flat;
    wire [4 * data_width - 1 : 0] b_out_flat;
    wire [16 * acc_width - 1 : 0] c_out_flat;
    // wire clock_locked;

    // DUT instantiation
    systolic_array_4x4 #(
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
        .clock_locked(clock_locked)
    );

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock (10 ns period)

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

            // Wait for locked signal to assert
            wait(clock_locked == 1);
            #20;
        end
    endtask

    // Task to feed inputs and validate outputs
    task apply_inputs_and_validate;
        reg [4 * data_width - 1 : 0] a_pipeline [0:3]; // Rows of A
        reg [4 * data_width - 1 : 0] b_pipeline [0:3]; // Columns of B
        reg [16 * acc_width - 1 : 0] expected_c_out;  // Expected result matrix
        integer i, j, cycle;

        begin
            // Initialize input matrices (flattened rows of A and columns of B)
            a_pipeline[0] = {8'd1, 8'd2, 8'd3, 8'd4};   // A[0][*]
            a_pipeline[1] = {8'd5, 8'd6, 8'd7, 8'd8};   // A[1][*]
            a_pipeline[2] = {8'd9, 8'd10, 8'd11, 8'd12}; // A[2][*]
            a_pipeline[3] = {8'd13, 8'd14, 8'd15, 8'd16}; // A[3][*]

            b_pipeline[0] = {8'd17, 8'd18, 8'd19, 8'd20}; // B[*][0]
            b_pipeline[1] = {8'd21, 8'd22, 8'd23, 8'd24}; // B[*][1]
            b_pipeline[2] = {8'd25, 8'd26, 8'd27, 8'd28}; // B[*][2]
            b_pipeline[3] = {8'd29, 8'd30, 8'd31, 8'd32}; // B[*][3]

            // Expected result of A * B
            expected_c_out = {
                16'd1528, 16'd1470, 16'd1412, 16'd1354, // Row 3
                16'd1112, 16'd1070, 16'd1028, 16'd986, // Row 2
                16'd696, 16'd670, 16'd644, 16'd618, // Row 1
                16'd280, 16'd270, 16'd260, 16'd250  // Row 0
            };

            // Apply inputs row-by-row and column-by-column diagonally
            for (cycle = 0; cycle < 8; cycle = cycle + 1) begin
                case (cycle)
                    0: begin
                        a_in_flat = {8'd0, 8'd0, 8'd0, 8'd1};
                        b_in_flat = {8'd0, 8'd0, 8'd0, 8'd17};
                    end
                    1: begin
                        a_in_flat = {8'd0, 8'd0, 8'd5, 8'd2};
                        b_in_flat = {8'd0, 8'd0, 8'd18, 8'd21};
                    end
                    2: begin
                        a_in_flat = {8'd0, 8'd9, 8'd6, 8'd3};
                        b_in_flat = {8'd0, 8'd19, 8'd22, 8'd25};
                    end
                    3: begin
                        a_in_flat = {8'd13, 8'd10, 8'd7, 8'd4};
                        b_in_flat = {8'd20, 8'd23, 8'd26, 8'd29};
                    end
                    4: begin
                        a_in_flat = {8'd14, 8'd11, 8'd8, 8'd0};
                        b_in_flat = {8'd24, 8'd27, 8'd30, 8'd0};
                    end
                    5: begin
                        a_in_flat = {8'd15, 8'd12, 8'd0, 8'd0};
                        b_in_flat = {8'd28, 8'd31, 8'd0, 8'd0};
                    end
                    6: begin
                        a_in_flat = {8'd16, 8'd0, 8'd0, 8'd0};
                        b_in_flat = {8'd32, 8'd0, 8'd0, 8'd0};
                    end
                    default: begin
                        a_in_flat = 0;
                        b_in_flat = 0;
                    end
                endcase
                en = 1;
                #10; // Wait for one clock cycle
                a_in_flat = 0;
                b_in_flat = 0;
                #10;
            end

            // Allow additional cycles for data propagation
            // en = 0;
            #90; // Wait 4 extra cycles for propagation to complete

            // Validate final output
            if (c_out_flat !== expected_c_out) begin
                $display("ERROR: Mismatch in final output!");
                $display("Expected: %0h", expected_c_out);
                $display("Got: %0h", c_out_flat);
                $finish;
            end

            $display("Test Passed! Final output matches expected results.");
        end
    endtask

    // Debugging output to monitor DUT state
    always @(posedge clk) begin
        $display("Time: %0dns |", $time);
        $display("C[0][0]=%d, C[0][1]=%d, C[0][2]=%d, C[0][3]=%d", 
                 c_out_flat[acc_width*0 +: acc_width], 
                 c_out_flat[acc_width*1 +: acc_width], 
                 c_out_flat[acc_width*2 +: acc_width], 
                 c_out_flat[acc_width*3 +: acc_width]);
        $display("C[1][0]=%d, C[1][1]=%d, C[1][2]=%d, C[1][3]=%d", 
                 c_out_flat[acc_width*4 +: acc_width], 
                 c_out_flat[acc_width*5 +: acc_width], 
                 c_out_flat[acc_width*6 +: acc_width], 
                 c_out_flat[acc_width*7 +: acc_width]);
        $display("C[2][0]=%d, C[2][1]=%d, C[2][2]=%d, C[2][3]=%d", 
                 c_out_flat[acc_width*8 +: acc_width], 
                 c_out_flat[acc_width*9 +: acc_width], 
                 c_out_flat[acc_width*10 +: acc_width], 
                 c_out_flat[acc_width*11 +: acc_width]);
        $display("C[3][0]=%d, C[3][1]=%d, C[3][2]=%d, C[3][3]=%d", 
                 c_out_flat[acc_width*12 +: acc_width], 
                 c_out_flat[acc_width*13 +: acc_width], 
                 c_out_flat[acc_width*14 +: acc_width], 
                 c_out_flat[acc_width*15 +: acc_width]);
    end

    // Testbench process
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        en = 0;
        a_in_flat = 0;
        b_in_flat = 0;

        // Reset the DUT
        reset_dut();

        // Apply inputs and validate outputs
        #10;
        apply_inputs_and_validate();
        $finish;
    end

    // Timeout mechanism
    initial begin
        #1000; // Simulation timeout
        $display("ERROR: Simulation timed out.");
        $finish;
    end

endmodule
















