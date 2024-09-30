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


module systolic_2x2_tb;

    parameter data_width = 8;

    // Inputs
    reg clk, rst, enable;
    reg [data_width-1:0] a0, a1, b0, b1;

    // Outputs
    wire [2*data_width-1:0] c00, c01, c10, c11;
    wire valid00, valid01, valid10, valid11;
    wire busy, done;
    integer i;

    // Instantiate the systolic array
    systolic_2x2 #(.data_width(data_width)) uut (
        .clk(clk), 
        .rst(rst), 
        .enable(enable),
        .a0(a0), 
        .a1(a1), 
        .b0(b0), 
        .b1(b1),
        .c00(c00), 
        .c01(c01), 
        .c10(c10), 
        .c11(c11),
        .valid00(valid00), 
        .valid01(valid01), 
        .valid10(valid10), 
        .valid11(valid11),
        .busy(busy), 
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk; // Clock period of 10 time units

    initial begin
        // Initial settings
        clk = 0;
        rst = 1;
        enable = 0;
        a0 = 0;
        a1 = 0;
        b0 = 0;
        b1 = 0;

        // Apply reset
        #20;
        rst = 0;
        enable = 1;

        // Declare the loop iterator variable inside the initial block

        // Matrices A and B
        // Matrix A = [1 2]
        //            [3 4]
        // Matrix B = [5 6]
        //            [7 8]

        // Expected Result C = A * B:
        // C = [1*5 + 2*7   1*6 + 2*8]
        //     [3*5 + 4*7   3*6 + 4*8]
        //   = [19   22]
        //     [43   50]
        
        // Use a for loop to provide data and then pad with zeros
        for (i = 0; i < 6; i = i + 1) begin
            case (i)
                0: begin
                    // Provide first values for A[0][0] and B[0][0]
                    a0 = 8'd1; b0 = 8'd5;
                    a1 = 8'd0; b1 = 8'd0; // Other inputs are zero for now
                end
                1: begin
                    // Provide next values for A[0][1] and B[1][0]
                    a0 = 8'd2; b0 = 8'd7;
                    a1 = 8'd3; b1 = 8'd6; // Provide additional inputs
                end
                2: begin
                    // Provide next values for A[1][1] and B[1][1]
                    a0 = 8'd0; b0 = 8'd0;
                    a1 = 8'd4; b1 = 8'd8;
                end
                default: begin
                    // Pad zeros to allow data propagation
                    a0 = 8'd0; b0 = 8'd0;
                    a1 = 8'd0; b1 = 8'd0;
                end
            endcase
            #10; // Wait for the next clock cycle
        end

        // Wait until computation is done
        while (!done) begin
            #10;
        end

        // Add a short delay to ensure outputs are latched properly
        #10;

        // Verify Outputs
        // Expected: c00 = 19, c01 = 22, c10 = 43, c11 = 50
        if (valid00 && c00 !== 19) $display("Test failed for c00, expected: 19, got: %d", c00);
        else if (valid00) $display("Test passed for c00");

        if (valid01 && c01 !== 22) $display("Test failed for c01, expected: 22, got: %d", c01);
        else if (valid01) $display("Test passed for c01");

        if (valid10 && c10 !== 43) $display("Test failed for c10, expected: 43, got: %d", c10);
        else if (valid10) $display("Test passed for c10");

        if (valid11 && c11 !== 50) $display("Test failed for c11, expected: 50, got: %d", c11);
        else if (valid11) $display("Test passed for c11");

        // End Simulation
        #10;
        $stop;
    end

endmodule








