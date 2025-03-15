`timescale 1ns/1ps

module top_systolic_integration #(
    //--------------------------------------------------------------------------
    // Parameterization
    //--------------------------------------------------------------------------
    parameter APB_ADDR_WIDTH = 8,
    parameter AXI_ADDR_WIDTH = 12,
    parameter AXI_DATA_WIDTH = 32,
    parameter DATA_WIDTH     = 8,    // Per-element data width for the systolic array
    parameter ACC_WIDTH      = 32,   // Accumulator width per systolic cell
    parameter BASE_ADDR_A    = 12'h000,
    parameter BASE_ADDR_B    = 12'h100,
    parameter BASE_ADDR_C    = 12'h200
)(
    //--------------------------------------------------------------------------
    // Global Clock/Reset for System Logic
    //--------------------------------------------------------------------------
    input  wire                     sys_clock,
    input  wire                     sys_reset, // Active-high or active-low as needed

    //--------------------------------------------------------------------------
    // APB Interface
    //--------------------------------------------------------------------------
    input  wire                     PCLK,
    input  wire                     PRESETn,    // Active-low
    input  wire                     PSEL,
    input  wire                     PENABLE,
    input  wire                     PWRITE,
    input  wire [APB_ADDR_WIDTH-1:0]PADDR,
    input  wire [31:0]             PWDATA,
    output wire [31:0]             PRDATA,
    output wire                     PREADY,
    output wire                     PSLVERR,

    //--------------------------------------------------------------------------
    // AXI4 Slave Interface #0 (SoC → memory_block_wrapper)
    //--------------------------------------------------------------------------
    input  wire [AXI_ADDR_WIDTH-1:0] S_AXI_0_awaddr,
    input  wire [1:0]                S_AXI_0_awburst,
    input  wire [3:0]                S_AXI_0_awcache,
    input  wire [7:0]                S_AXI_0_awlen,
    input  wire                      S_AXI_0_awlock,
    input  wire [2:0]                S_AXI_0_awprot,
    output wire                      S_AXI_0_awready,
    input  wire [2:0]                S_AXI_0_awsize,
    input  wire                      S_AXI_0_awvalid,
    input  wire                      S_AXI_0_bready,
    output wire [1:0]                S_AXI_0_bresp,
    output wire                      S_AXI_0_bvalid,
    input  wire [AXI_DATA_WIDTH-1:0] S_AXI_0_wdata,
    input  wire                      S_AXI_0_wlast,
    output wire                      S_AXI_0_wready,
    input  wire [3:0]                S_AXI_0_wstrb,
    input  wire                      S_AXI_0_wvalid,
    input  wire [AXI_ADDR_WIDTH-1:0] S_AXI_0_araddr,
    input  wire [1:0]                S_AXI_0_arburst,
    input  wire [3:0]                S_AXI_0_arcache,
    input  wire [7:0]                S_AXI_0_arlen,
    input  wire                      S_AXI_0_arlock,
    input  wire [2:0]                S_AXI_0_arprot,
    output wire                      S_AXI_0_arready,
    input  wire [2:0]                S_AXI_0_arsize,
    input  wire                      S_AXI_0_arvalid,
    output wire [AXI_DATA_WIDTH-1:0] S_AXI_0_rdata,
    output wire                      S_AXI_0_rlast,
    input  wire                      S_AXI_0_rready,
    output wire [1:0]                S_AXI_0_rresp,
    output wire                      S_AXI_0_rvalid
);

    //--------------------------------------------------------------------------
    // APB Slave (with simple memory array)
    //--------------------------------------------------------------------------
    apb_slave #(
        .ADDR_WIDTH (APB_ADDR_WIDTH),
        .DATA_WIDTH (32)
    ) u_apb_slave (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );

    // For demonstration, define addresses for simple control/status:
    localparam int  ADDR_CONTROL  = 0, // bit0: START, bit1: ???, etc.
                    ADDR_STATUS   = 1; // bit0: BUSY, bit1: DONE, etc.

    // Wires to hold register values from apb_slave memory
    reg  [31:0] reg_control;
    reg  [31:0] reg_status;

    wire start = reg_control[0];  // external "start" bit from the SoC (via APB)
    // We'll produce busy/done internally

    // Read from slave memory on each APB clock
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg_control <= 32'b0;
            reg_status  <= 32'b0;
        end else begin
            reg_control <= u_apb_slave.memory[ADDR_CONTROL];
            // We will write reg_status back into memory[ADDR_STATUS] below
        end
    end

    //--------------------------------------------------------------------------
    // Dual-Port Memory for HPC
    //--------------------------------------------------------------------------
    reg [AXI_ADDR_WIDTH-1:0] S_AXI_1_awaddr;
    reg [1:0]                S_AXI_1_awburst;
    reg [3:0]                S_AXI_1_awcache;
    reg [7:0]                S_AXI_1_awlen;
    reg                      S_AXI_1_awlock;
    reg [2:0]                S_AXI_1_awprot;
    reg                      S_AXI_1_awready;
    reg [2:0]                S_AXI_1_awsize;
    reg                      S_AXI_1_awvalid;
    reg                      S_AXI_1_bready;
    reg [1:0]                S_AXI_1_bresp;
    reg                      S_AXI_1_bvalid;
    reg [AXI_DATA_WIDTH-1:0] S_AXI_1_wdata;
    reg                      S_AXI_1_wlast;
    reg                      S_AXI_1_wready;
    reg [3:0]                S_AXI_1_wstrb;
    reg                      S_AXI_1_wvalid;

    reg [AXI_ADDR_WIDTH-1:0] S_AXI_1_araddr;
    reg [1:0]                S_AXI_1_arburst;
    reg [3:0]                S_AXI_1_arcache;
    reg [7:0]                S_AXI_1_arlen;
    reg                      S_AXI_1_arlock;
    reg [2:0]                S_AXI_1_arprot;
    reg                      S_AXI_1_arready;
    reg [2:0]                S_AXI_1_arsize;
    reg                      S_AXI_1_arvalid;
    reg [AXI_DATA_WIDTH-1:0] S_AXI_1_rdata;
    reg                      S_AXI_1_rlast;
    reg                      S_AXI_1_rready;
    reg [1:0]                S_AXI_1_rresp;
    reg                      S_AXI_1_rvalid;

    memory_block_wrapper u_memory (
        .sys_clock      (sys_clock),
        .reset_rtl      (sys_reset),

        // SoC side (S_AXI_0)
        .S_AXI_0_awaddr (S_AXI_0_awaddr),
        .S_AXI_0_awburst(S_AXI_0_awburst),
        .S_AXI_0_awcache(S_AXI_0_awcache),
        .S_AXI_0_awlen  (S_AXI_0_awlen),
        .S_AXI_0_awlock (S_AXI_0_awlock),
        .S_AXI_0_awprot (S_AXI_0_awprot),
        .S_AXI_0_awready(S_AXI_0_awready),
        .S_AXI_0_awsize (S_AXI_0_awsize),
        .S_AXI_0_awvalid(S_AXI_0_awvalid),
        .S_AXI_0_bready (S_AXI_0_bready),
        .S_AXI_0_bresp  (S_AXI_0_bresp),
        .S_AXI_0_bvalid (S_AXI_0_bvalid),
        .S_AXI_0_wdata  (S_AXI_0_wdata),
        .S_AXI_0_wlast  (S_AXI_0_wlast),
        .S_AXI_0_wready (S_AXI_0_wready),
        .S_AXI_0_wstrb  (S_AXI_0_wstrb),
        .S_AXI_0_wvalid (S_AXI_0_wvalid),
        .S_AXI_0_araddr (S_AXI_0_araddr),
        .S_AXI_0_arburst(S_AXI_0_arburst),
        .S_AXI_0_arcache(S_AXI_0_arcache),
        .S_AXI_0_arlen  (S_AXI_0_arlen),
        .S_AXI_0_arlock (S_AXI_0_arlock),
        .S_AXI_0_arprot (S_AXI_0_arprot),
        .S_AXI_0_arready(S_AXI_0_arready),
        .S_AXI_0_arsize (S_AXI_0_arsize),
        .S_AXI_0_arvalid(S_AXI_0_arvalid),
        .S_AXI_0_rdata  (S_AXI_0_rdata),
        .S_AXI_0_rlast  (S_AXI_0_rlast),
        .S_AXI_0_rready (S_AXI_0_rready),
        .S_AXI_0_rresp  (S_AXI_0_rresp),
        .S_AXI_0_rvalid (S_AXI_0_rvalid),

        // Local side (S_AXI_1)
        .S_AXI_1_awaddr (S_AXI_1_awaddr),
        .S_AXI_1_awburst(S_AXI_1_awburst),
        .S_AXI_1_awcache(S_AXI_1_awcache),
        .S_AXI_1_awlen  (S_AXI_1_awlen),
        .S_AXI_1_awlock (S_AXI_1_awlock),
        .S_AXI_1_awprot (S_AXI_1_awprot),
        .S_AXI_1_awready(S_AXI_1_awready),
        .S_AXI_1_awsize (S_AXI_1_awsize),
        .S_AXI_1_awvalid(S_AXI_1_awvalid),
        .S_AXI_1_bready (S_AXI_1_bready),
        .S_AXI_1_bresp  (S_AXI_1_bresp),
        .S_AXI_1_bvalid (S_AXI_1_bvalid),
        .S_AXI_1_wdata  (S_AXI_1_wdata),
        .S_AXI_1_wlast  (S_AXI_1_wlast),
        .S_AXI_1_wready (S_AXI_1_wready),
        .S_AXI_1_wstrb  (S_AXI_1_wstrb),
        .S_AXI_1_wvalid (S_AXI_1_wvalid),
        .S_AXI_1_araddr (S_AXI_1_araddr),
        .S_AXI_1_arburst(S_AXI_1_arburst),
        .S_AXI_1_arcache(S_AXI_1_arcache),
        .S_AXI_1_arlen  (S_AXI_1_arlen),
        .S_AXI_1_arlock (S_AXI_1_arlock),
        .S_AXI_1_arprot (S_AXI_1_arprot),
        .S_AXI_1_arready(S_AXI_1_arready),
        .S_AXI_1_arsize (S_AXI_1_arsize),
        .S_AXI_1_arvalid(S_AXI_1_arvalid),
        .S_AXI_1_rdata  (S_AXI_1_rdata),
        .S_AXI_1_rlast  (S_AXI_1_rlast),
        .S_AXI_1_rready (S_AXI_1_rready),
        .S_AXI_1_rresp  (S_AXI_1_rresp),
        .S_AXI_1_rvalid (S_AXI_1_rvalid)
    );

    //--------------------------------------------------------------------------
    // A & B Extractors (cycle‐based) - We'll feed them an internal cycle count
    //--------------------------------------------------------------------------
    wire [63:0] a_flat_out;
    wire        a_valid;
    reg         a_extractor_start;
    reg  [3:0]  a_extractor_cycle;

    axi_a_input_extractor_top #(
        .BASE_ADDR (BASE_ADDR_A)
    )extractorA (
        .clk         (sys_clock),
        .rst         (sys_reset),
        .start       (a_extractor_start),
        .cycle       (a_extractor_cycle),
        .a_flat_out  (a_flat_out),
        .valid       (a_valid),
        // Connect S_AXI_1 read for A
        .m_axi_araddr(S_AXI_1_araddr),
        .m_axi_arsize(S_AXI_1_arsize ),
        .m_axi_arvalid(S_AXI_1_arvalid),
        .m_axi_arburst(S_AXI_1_arburst),
        .m_axi_arcache(S_AXI_1_arcache),
        .m_axi_arlen(S_AXI_1_arlen  ),
        .m_axi_arlock(S_AXI_1_arlock ),
        .m_axi_arprot(S_AXI_1_arprot ),
        .m_axi_arready(S_AXI_1_arready),
        .m_axi_rdata(S_AXI_1_rdata),
        .m_axi_rvalid(S_AXI_1_rvalid),
        .m_axi_rready(S_AXI_1_rready),
        .m_axi_rlast(S_AXI_1_rlast)
    );

    wire [63:0] b_flat_out;
    wire        b_valid;
    reg         b_extractor_start;
    reg  [3:0]  b_extractor_cycle;

    axi_a_input_extractor_top #(
        .BASE_ADDR (BASE_ADDR_B)
    ) extractorB (
        .clk         (sys_clock),
        .rst         (sys_reset),
        .start       (b_extractor_start),
        .cycle       (b_extractor_cycle),
        .a_flat_out  (b_flat_out), // effectively B
        .valid       (b_valid),
        // S_AXI_1 read channel for B
        .m_axi_araddr(S_AXI_1_araddr),
        .m_axi_arsize(S_AXI_1_arsize ),
        .m_axi_arvalid(S_AXI_1_arvalid),
        .m_axi_arburst(S_AXI_1_arburst),
        .m_axi_arcache(S_AXI_1_arcache),
        .m_axi_arlen(S_AXI_1_arlen  ),
        .m_axi_arlock(S_AXI_1_arlock ),
        .m_axi_arprot(S_AXI_1_arprot ),
        .m_axi_arready(S_AXI_1_arready),
        .m_axi_rdata(S_AXI_1_rdata),
        .m_axi_rvalid(S_AXI_1_rvalid),
        .m_axi_rready(S_AXI_1_rready),
        .m_axi_rlast(S_AXI_1_rlast)
    );

    // We will combine a_flat_out, b_flat_out into the systolic array input.
    reg [8*DATA_WIDTH -1:0] a_in_flat;
    reg [8*DATA_WIDTH -1:0] b_in_flat;
    // You have a function or mapping from 64 bits to 8×8 bytes inside the top
    // or you do it in the extractor. 
    // For simplicity, let's directly assume a_flat_out is the correct 64 bits for the array:
   

    function [8*8*DATA_WIDTH-1:0] diag64_to_8x8;
        input [63:0] diag;
        integer i;
        begin
            diag64_to_8x8 = 0;
            for (i=0; i<8; i=i+1) begin
                diag64_to_8x8[i*DATA_WIDTH +: DATA_WIDTH] = diag[i*8 +: 8];
            end
        end
    endfunction

    task display_matrix;
        input [64 * ACC_WIDTH - 1:0] flat_matrix; // Flattened matrix input
        input [80*8:0] matrix_name;              // Name of the matrix to display (fixed-width reg)
        integer i, j;
        reg [ACC_WIDTH - 1:0] element;
        begin
            $display("%s:", matrix_name);
            for (i = 0; i < 8; i = i + 1) begin
                $write("[ ");
                for (j = 0; j < 8; j = j + 1) begin
                    element = flat_matrix[(i * 8 + j) * ACC_WIDTH +: ACC_WIDTH];
                    $write("%5d ", element); // Print each element in a padded format
                end
                $display("]");
            end
            $display(""); // Add a blank line for spacing
        end
    endtask

    //--------------------------------------------------------------------------
    // 8×8 Systolic Array
    //--------------------------------------------------------------------------
    reg [8*DATA_WIDTH -1:0] a_out_flat;
    reg [8*DATA_WIDTH -1:0] b_out_flat;
    wire [64*ACC_WIDTH   -1:0] c_out_flat;
    wire                       locked;
    reg                       systol_en;
    reg                       systol_reset;

    systolic_array_8x8 #(
        .data_width (DATA_WIDTH),
        .acc_width  (ACC_WIDTH)
    ) u_systolic (
        .clk         (sys_clock),
        .rst         (systol_reset),
        .en          (systol_en),
        .a_in_flat   (a_in_flat),
        .b_in_flat   (b_in_flat),
        .a_out_flat  (a_out_flat),
        .b_out_flat  (b_out_flat),
        .c_out_flat  (c_out_flat),
        .locked      (locked)
    );

    //--------------------------------------------------------------------------
    // Writeback Controller
    //--------------------------------------------------------------------------
    reg writeback_done;
    reg writeback_start;
    writeback_controller u_writeback (
        .clk         (sys_clock),
        .rst         (sys_reset),
        .start       (writeback_start),
        .c_in_flat   (c_out_flat),
        .base_addr   (BASE_ADDR_C),

        // AXI Master (S_AXI_1) to do writes
        .m_axi_awaddr (S_AXI_1_awaddr),
        .m_axi_awburst(S_AXI_1_awburst),
        .m_axi_awcache(S_AXI_1_awcache),
        .m_axi_awlen  (S_AXI_1_awlen),
        .m_axi_awlock (S_AXI_1_awlock),
        .m_axi_awprot (S_AXI_1_awprot),
        .m_axi_awsize (S_AXI_1_awsize),
        .m_axi_awvalid(S_AXI_1_awvalid),
        .m_axi_awready(S_AXI_1_awready),

        .m_axi_wdata  (S_AXI_1_wdata),
        .m_axi_wlast  (S_AXI_1_wlast),
        .m_axi_wstrb  (S_AXI_1_wstrb),
        .m_axi_wvalid (S_AXI_1_wvalid),
        .m_axi_wready (S_AXI_1_wready),

        .m_axi_bready (S_AXI_1_bready),
        .m_axi_bresp  (S_AXI_1_bresp),
        .m_axi_bvalid (S_AXI_1_bvalid),

        .done         (writeback_done),
        .debug_state  (),
        .debug_word_count()
    );

    //--------------------------------------------------------------------------
    // Internal FSM: Single "start", multiple cycles
    //--------------------------------------------------------------------------
    reg  busy;
    reg  done;
    reg  [3:0] cycle_counter;
    reg  [5:0] pipeline_counter;
    reg  [2:0] state;

    // State definitions
    localparam ST_IDLE   = 0,
           ST_A_EXTR   = 1, // Start A extraction, wait for a_valid
           ST_B_EXTR   = 2,
           ST_CYCLE = 4, // Present diagonal for 1 clock
           ST_ZERO   = 3, // Bubble cycle for 1 clock
           ST_PIPE   = 5, // Wait 19 cycles after last diagonal
           ST_WRITEB = 6, // Start writeback
           ST_DONE   = 7;

    always @(posedge sys_clock or posedge sys_reset) begin
        
        if (sys_reset) begin
            state <= ST_IDLE;
            a_extractor_start <= 0;
            b_extractor_start <= 0;
            a_extractor_cycle <= 0;
            b_extractor_cycle <= 0;
            cycle_counter     <= 0;
            busy              <= 0;
            done              <= 0;
            systol_en            <= 0;
            systol_reset        <= 1;
            a_in_flat <= 0;
            b_in_flat <= 0;

            // Also zero out the systolic array inputs if you store them in regs
        end else begin
            case (state)

                ST_IDLE: begin
                    systol_reset        <= 0;
                    if (start && locked) begin
                        // Start the first diagonal
                        busy <= 1'b1;
                        done <= 0;
                        cycle_counter <= 0;
                        a_extractor_cycle <= 0;
                        b_extractor_cycle <= 0;
                        a_extractor_start <= 1'b1;
                        b_extractor_start <= 1'b0;
                        systol_en            <= 1'b1;
                        state <= ST_A_EXTR;
                    end
                end

                //--------------------------------------------------------
                // ST_A_EXTR: Wait for A extractor to produce valid
                //--------------------------------------------------------
                ST_A_EXTR: begin
                    // Keep a_extractor_start = 1 until we see a_valid,
                    // or deassert after 1 cycle if that's how your extractor works
                    if (a_valid) begin
                        // We have A's diagonal data. Next, do B extraction
                        
                        b_extractor_start <= 1'b1; // start B
                        state <= ST_B_EXTR;
                    end
                end

                //--------------------------------------------------------
                // ST_B_EXTR: Wait for B extractor to produce valid
                //--------------------------------------------------------
                ST_B_EXTR: begin
                    // Keep b_extractor_start = 1 until b_valid
                    if (b_valid) begin
                        b_extractor_start <= 1'b0; // done with B
                        a_extractor_start <= 1'b0; // done with A
                        // Now we have a_flat_out, b_flat_out
                        // Present them to the systolic array for 1 clock
                        a_in_flat <= a_flat_out;
                        b_in_flat <= b_flat_out;

                        state <= ST_ZERO;
                    end
                end

                // ST_INJECT: Present the diagonal to the systolic array for 1 clock
                // (The diagonal data is in a_flat_out / b_flat_out from the extractors.)
                ST_ZERO: begin
                    // We do one clock of diagonal injection
                    // Next cycle, we zero the inputs
                    a_in_flat <= 0;
                    b_in_flat <= 0; 
                    state <= ST_CYCLE;
                end

                // ST_ZERO: Insert a bubble cycle (zero all inputs) for exactly 1 clock
                ST_CYCLE: begin
                    // Zero everything for the next cycle
                    // Then move on to next diagonal or finish
                    if (cycle_counter < 14) begin
                        display_matrix(c_out_flat, "Actual Output Matrix (C)");
                        cycle_counter <= cycle_counter + 1;
                        a_extractor_cycle <= cycle_counter + 1;
                        b_extractor_cycle <= cycle_counter + 1;
                        // Fire new extraction
                        a_extractor_start <= 1'b1;
                        b_extractor_start <= 1'b0;
                        state <= ST_A_EXTR;
                    end
                    else begin
                        // All diagonals processed
                        $display("[top] all cycles piped in");
                        pipeline_counter <= 0;
                        state <= ST_PIPE;
                    end
                end
                //==========================================================
                // ST_PIPE: Wait 19 cycles for systolic array to flush
                //==========================================================
                ST_PIPE: begin
                    if (pipeline_counter < 25) begin
                        display_matrix(c_out_flat, "Actual Output Matrix (C)");
                        pipeline_counter <= pipeline_counter + 1;
                    end
                    else begin
                        $display("writeback start");
                        // Now we trigger writeback
                        writeback_start <= 1'b1;
                        
                        // We might also set the base_addr if not done outside
                        // wb_base_addr <= 12'd300;
                        state <= ST_WRITEB;
                    end
                end

                //==========================================================
                // ST_WRITEB: Start the writeback controller, wait for done
                //==========================================================
                ST_WRITEB: begin
                    // Deassert writeback_start after 1 cycle
                    
                    if (writeback_done) begin
                        $display("writeback done");
                        // Once the writeback is done, we can finish
                        systol_reset        <= 1;
                        writeback_start <= 1'b0;
                        state <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    systol_reset        <= 0;
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= ST_IDLE; // or remain in ST_DONE if you want latched done
                end

                default: state <= ST_IDLE;
            endcase
        end
    end


    // Map busy/done into your APB status register
    always @(posedge sys_clock or posedge sys_reset) begin
        if (sys_reset) begin
            reg_status <= 32'b0;
        end else begin
            reg_status[0] <= busy;
            reg_status[1] <= done;
            // others bits 2..31 => 0 or other flags
            u_apb_slave.memory[ADDR_STATUS] <= reg_status;
        end
    end

endmodule
