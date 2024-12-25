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
    output wire [acc_width-1:0] output_buffer_c00_0, output_buffer_c00_1,
    output wire [acc_width-1:0] output_buffer_c01_0, output_buffer_c01_1,
    output wire [acc_width-1:0] output_buffer_c10_0, output_buffer_c10_1,
    output wire [acc_width-1:0] output_buffer_c11_0, output_buffer_c11_1,
    output wire active_buffer
);

    // ======== Synchronize the Reset Signal ==========
    reg rst_sync_1, rst_sync_2;

    always @(posedge clk_mmcm_bufg or posedge rst) begin
        if (rst) begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= 1'b1;
        end else begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Use synchronized reset
    wire rst_sync = rst_sync_2;

    // ======== MMCM Configuration for Clock ==========
    wire clk_mmcm_out, clk_mmcm_bufg, locked;

    MMCME2_BASE #(
        .CLKIN1_PERIOD(5.0),    // Input clock period = 5 ns (200 MHz)
        .CLKFBOUT_MULT_F(5.0),  // VCO frequency = 1000 MHz (200 MHz * 5)
        .DIVCLK_DIVIDE(1),      // No pre-division
        .CLKOUT0_DIVIDE_F(2.5)  // Output clock = 400 MHz (1000 MHz / 2.5)
    ) u_mmcm (
        .CLKIN1(clk),           // Input clock
        .CLKOUT0(clk_mmcm_out), // MMCM output clock
        .CLKFBIN(clk_mmcm_out), // Feedback clock
        .CLKFBOUT(),            // Feedback clock output
        .LOCKED(locked),        // MMCM lock status
        .PWRDWN(1'b0),          // Power-down MMCM
        .RST(rst_sync)          // MMCM reset
    );

    BUFG u_bufg (
        .I(clk_mmcm_out),
        .O(clk_mmcm_bufg)
    );

    // ======== Buffered Control Signals ==========
    wire rst_bufg, start_bufg;

    BUFGCE rst_bufg_inst (
        .I(rst_sync),
        .CE(1'b1),
        .O(rst_bufg)
    );

    BUFGCE start_bufg_inst (
        .I(start),
        .CE(1'b1),
        .O(start_bufg)
    );

    // ======== Control Logic ==========
    reg active_buffer_reg;
    reg [3:0] cycle_count;

    wire en = (cycle_count < MM_CYCLES);

    always @(posedge clk_mmcm_bufg) begin
        if (rst_bufg) begin
            cycle_count <= 0;
            active_buffer_reg <= 0;
        end else if (start_bufg) begin
            if (cycle_count < MM_CYCLES) begin
                cycle_count <= cycle_count + 1;
            end else begin
                cycle_count <= 0;
                active_buffer_reg <= ~active_buffer_reg;
            end
        end else begin
            cycle_count <= 0;
        end
    end

    // ======== PEs Instantiation ==========
    wire [data_width-1:0] a01, a11, b10, b11;
    wire [acc_width-1:0] pe00_out, pe01_out, pe10_out, pe11_out;

    pe #(.data_width(data_width), .acc_width(acc_width)) pe00 (
        .clk(clk_mmcm_bufg),
        .rst(rst_bufg),
        .en(en),
        .a_in(a0_in),
        .b_in(b0_in),
        .a_out(a01),
        .b_out(b10),
        .c_out(pe00_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe01 (
        .clk(clk_mmcm_bufg),
        .rst(rst_bufg),
        .en(en),
        .a_in(a01),
        .b_in(b1_in),
        .a_out(),
        .b_out(b11),
        .c_out(pe01_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe10 (
        .clk(clk_mmcm_bufg),
        .rst(rst_bufg),
        .en(en),
        .a_in(a1_in),
        .b_in(b10),
        .a_out(a11),
        .b_out(),
        .c_out(pe10_out)
    );

    pe #(.data_width(data_width), .acc_width(acc_width)) pe11 (
        .clk(clk_mmcm_bufg),
        .rst(rst_bufg),
        .en(en),
        .a_in(a11),
        .b_in(b11),
        .a_out(),
        .b_out(),
        .c_out(pe11_out)
    );

    // ======== Output Buffers ==========
    reg [acc_width-1:0] output_buffer_c00_0_reg, output_buffer_c00_1_reg;

    always @(posedge clk_mmcm_bufg) begin
        if (!active_buffer_reg) begin
            output_buffer_c00_0_reg <= pe00_out;
        end else begin
            output_buffer_c00_1_reg <= pe00_out;
        end
    end

    assign active_buffer = active_buffer_reg;
    assign output_buffer_c00_0 = output_buffer_c00_0_reg;
    assign output_buffer_c00_1 = output_buffer_c00_1_reg;

endmodule











