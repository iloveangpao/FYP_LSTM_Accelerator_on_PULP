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
    output wire                      S_AXI_0_rvalid,
    output wire                     clk_locked
);

    reg                       locked;
    assign clk_locked = locked;
    wire clk_buf;
    clk_2x2 clk_inst(
        .reset(rst),
        .clk_in1(sys_clock),
        .clk_out1(clk_buf),
        .locked(locked)
    );

    // For demonstration, define addresses for simple control/status:
    localparam int  ADDR_CONTROL  = 0, // bit0: START, bit1: ???, etc.
                    ADDR_STATUS   = 1; // bit0: BUSY, bit1: DONE, etc.

    // Wires to hold register values from apb_slave memory
    reg  [31:0] reg_control;
    reg  [31:0] reg_status;

    //--------------------------------------------------------------------------
    // APB Slave (with simple memory array)
    //--------------------------------------------------------------------------
    apb_slave #(
        .ADDR_WIDTH (APB_ADDR_WIDTH),
        .DATA_WIDTH (32),
        .ADDR_CONTROL(ADDR_CONTROL),
        .ADDR_STATUS(ADDR_STATUS)
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
        .PSLVERR (PSLVERR),
        // Tie in your top-level signals
        .ext_status  (reg_status),
        .ext_control (reg_control)
    );

    reg  busy;
    reg  done;

    wire start = reg_control[0];  // external "start" bit from the SoC (via APB)
    // We'll produce busy/done internally

    // Map busy/done into your APB status register
    always @(posedge clk_buf or posedge sys_reset) begin
        if (sys_reset) begin
            reg_status <= 32'b0;
        end else begin
            reg_status[0] <= busy;
            reg_status[1] <= done;
            // others bits 2..31 => 0 or other flags
            // u_apb_slave.memory[ADDR_STATUS] <= reg_status;
        end
    end

    // // Read from slave memory on each APB clock
    // always_ff @(posedge PCLK or negedge PRESETn) begin
    //     if (!PRESETn) begin
    //         reg_control <= 32'b0;
    //         reg_status  <= 32'b0;
    //     end else begin
    //         reg_control <= u_apb_slave.memory[ADDR_CONTROL];
    //         // We will write reg_status back into memory[ADDR_STATUS] below
    //     end
    // end

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

    wire [AXI_ADDR_WIDTH-1:0] S_AXI_1_araddr;
    wire [1:0]                S_AXI_1_arburst;
    wire [3:0]                S_AXI_1_arcache;
    wire [7:0]                S_AXI_1_arlen;
    wire                      S_AXI_1_arlock;
    wire [2:0]                S_AXI_1_arprot;
    wire                      S_AXI_1_arready;
    wire [2:0]                S_AXI_1_arsize;
    wire                      S_AXI_1_arvalid;
    wire [AXI_DATA_WIDTH-1:0] S_AXI_1_rdata;
    wire                      S_AXI_1_rlast;
    wire                      S_AXI_1_rready;
    wire [1:0]                S_AXI_1_rresp;
    wire                      S_AXI_1_rvalid;

    wire [AXI_ADDR_WIDTH-1:0] extractor_A_araddr;
    wire [1:0]                extractor_A_arburst;
    wire [3:0]                extractor_A_arcache;
    wire [7:0]                extractor_A_arlen;
    wire                      extractor_A_arlock;
    wire [2:0]                extractor_A_arprot;
    wire                      extractor_A_arready;
    wire [2:0]                extractor_A_arsize;
    wire                      extractor_A_arvalid;
    wire [AXI_DATA_WIDTH-1:0] extractor_A_rdata;
    wire                      extractor_A_rlast;
    wire                      extractor_A_rready;
    wire [1:0]                extractor_A_rresp;
    wire                      extractor_A_rvalid;

    wire [AXI_ADDR_WIDTH-1:0] extractor_B_araddr;
    wire [1:0]                extractor_B_arburst;
    wire [3:0]                extractor_B_arcache;
    wire [7:0]                extractor_B_arlen;
    wire                      extractor_B_arlock;
    wire [2:0]                extractor_B_arprot;
    wire                      extractor_B_arready;
    wire [2:0]                extractor_B_arsize;
    wire                      extractor_B_arvalid;
    wire [AXI_DATA_WIDTH-1:0] extractor_B_rdata;
    wire                      extractor_B_rlast;
    wire                      extractor_B_rready;
    wire [1:0]                extractor_B_rresp;
    wire                      extractor_B_rvalid;

    // reg                      extractor_switch;

    memory_block_wrapper u_memory (
        .sys_clock      (clk_buf),
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
    reg matrix_A_loaded;
    reg matrix_B_loaded;
    reg load_start_extr_A;

    axi_a_input_extractor_top #(
        .BASE_ADDR (BASE_ADDR_A)
    )extractorA (
        .clk         (clk_buf),
        .rst         (sys_reset),
        .start       (a_extractor_start),
        .load_start(load_start_extr_A),
        // .cycle       (a_extractor_cycle),
        .a_flat_out  (a_flat_out),
        .input_loaded(matrix_A_loaded),
        // .valid       (a_valid),
        // Connect S_AXI_1 read for A
        .m_axi_araddr(extractor_A_araddr),
        .m_axi_arsize(extractor_A_arsize ),
        .m_axi_arvalid(extractor_A_arvalid),
        .m_axi_arburst(extractor_A_arburst),
        .m_axi_arcache(extractor_A_arcache),
        .m_axi_arlen(extractor_A_arlen  ),
        .m_axi_arlock(extractor_A_arlock ),
        .m_axi_arprot(extractor_A_arprot ),
        .m_axi_arready(extractor_A_arready),
        .m_axi_rdata(extractor_A_rdata),
        .m_axi_rvalid(extractor_A_rvalid),
        .m_axi_rready(extractor_A_rready),
        .m_axi_rlast(extractor_A_rlast)
    );

    wire [63:0] b_flat_out;
    wire        b_valid;
    reg         b_extractor_start;
    reg  [3:0]  b_extractor_cycle;
    reg        load_start_extr_B;
    

    axi_a_input_extractor_top #(
        .BASE_ADDR (BASE_ADDR_B)
    ) extractorB (
        .clk         (clk_buf),
        .rst         (sys_reset),
        .start       (b_extractor_start),
        .load_start(load_start_extr_B),
        // .cycle       (b_extractor_cycle),
        .a_flat_out  (b_flat_out), // effectively B
        .input_loaded(matrix_B_loaded),
        // .valid       (b_valid),
        // S_AXI_1 read channel for B
        .m_axi_araddr(extractor_B_araddr),
        .m_axi_arsize(extractor_B_arsize ),
        .m_axi_arvalid(extractor_B_arvalid),
        .m_axi_arburst(extractor_B_arburst),
        .m_axi_arcache(extractor_B_arcache),
        .m_axi_arlen(extractor_B_arlen  ),
        .m_axi_arlock(extractor_B_arlock ),
        .m_axi_arprot(extractor_B_arprot ),
        .m_axi_arready(extractor_B_arready),
        .m_axi_rdata(extractor_B_rdata),
        .m_axi_rvalid(extractor_B_rvalid),
        .m_axi_rready(extractor_B_rready),
        .m_axi_rlast(extractor_B_rlast)
    );

    // Arbitration select signal: 
    // 0 selects extractor A, 1 selects extractor B.
    reg sel_extractor;

    // Mux for the read address channel:
    assign S_AXI_1_araddr  = (sel_extractor == 1'b0) ? extractor_A_araddr : extractor_B_araddr;
    assign S_AXI_1_arburst = (sel_extractor == 1'b0) ? extractor_A_arburst : extractor_B_arburst;
    assign S_AXI_1_arcache = (sel_extractor == 1'b0) ? extractor_A_arcache : extractor_B_arcache;
    assign S_AXI_1_arlen   = (sel_extractor == 1'b0) ? extractor_A_arlen   : extractor_B_arlen;
    assign S_AXI_1_arlock  = (sel_extractor == 1'b0) ? extractor_A_arlock  : extractor_B_arlock;
    assign S_AXI_1_arprot  = (sel_extractor == 1'b0) ? extractor_A_arprot  : extractor_B_arprot;
    assign S_AXI_1_arsize  = (sel_extractor == 1'b0) ? extractor_A_arsize  : extractor_B_arsize;
    assign S_AXI_1_arvalid = (sel_extractor == 1'b0) ? extractor_A_arvalid : extractor_B_arvalid;

    // Route the ARREADY signal back to the appropriate extractor:
    assign extractor_A_arready = (sel_extractor == 1'b0) ? S_AXI_1_arready : 1'b0;
    assign extractor_B_arready = (sel_extractor == 1'b1) ? S_AXI_1_arready : 1'b0;
    // Mux for the read data channel:
    // Return the read data to the active extractor; the inactive one gets a default value.
    assign extractor_A_rdata  = (sel_extractor == 1'b0) ? S_AXI_1_rdata : {AXI_DATA_WIDTH{1'b0}};
    assign extractor_A_rlast  = (sel_extractor == 1'b0) ? S_AXI_1_rlast : 1'b0;
    assign extractor_A_rresp  = (sel_extractor == 1'b0) ? S_AXI_1_rresp : 2'b0;
    assign extractor_A_rvalid = (sel_extractor == 1'b0) ? S_AXI_1_rvalid : 1'b0;
    assign extractor_B_rdata  = (sel_extractor == 1'b1) ? S_AXI_1_rdata : {AXI_DATA_WIDTH{1'b0}};
    assign extractor_B_rlast  = (sel_extractor == 1'b1) ? S_AXI_1_rlast : 1'b0;
    assign extractor_B_rresp  = (sel_extractor == 1'b1) ? S_AXI_1_rresp : 2'b0;
    assign extractor_B_rvalid = (sel_extractor == 1'b1) ? S_AXI_1_rvalid : 1'b0;

    // The memory's rready comes from whichever extractor is active:
    assign S_AXI_1_rready = (sel_extractor == 1'b0) ? extractor_A_rready : extractor_B_rready;

    // We will combine a_flat_out, b_flat_out into the systolic array input.
    reg [8*DATA_WIDTH -1:0] a_in_flat;
    reg [8*DATA_WIDTH -1:0] b_in_flat;
    // You have a function or mapping from 64 bits to 8×8 bytes inside the top
    // or you do it in the extractor. 
    // For simplicity, let's directly assume a_flat_out is the correct 64 bits for the array:
   

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
    reg                       systol_en;
    reg                       systol_reset;

    systolic_array_8x8 #(
        .data_width (DATA_WIDTH),
        .acc_width  (ACC_WIDTH)
    ) u_systolic (
        .clk_buf         (clk_buf),
        .rst         (systol_reset),
        .en          (systol_en),
        .a_in_flat   (a_in_flat),
        .b_in_flat   (b_in_flat),
        .a_out_flat  (a_out_flat),
        .b_out_flat  (b_out_flat),
        .c_out_flat  (c_out_flat)
    );

    //--------------------------------------------------------------------------
    // Writeback Controller
    //--------------------------------------------------------------------------
    reg writeback_done;
    reg writeback_start;
    writeback_controller u_writeback (
        .clk         (clk_buf),
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
    
    reg  [3:0] cycle_counter;
    reg  [5:0] pipeline_counter;
    reg  [2:0] state;

    // State definitions
    localparam ST_IDLE   = 0,
           ST_MATR_EXTR   = 1, // Start A extraction, wait for a_valid
           ST_MATR_PROP   = 2,
           ST_CYCLE = 4, // Present diagonal for 1 clock
           ST_ZERO   = 3, // Bubble cycle for 1 clock
           ST_PIPE   = 5, // Wait 19 cycles after last diagonal
           ST_WRITEB = 6, // Start writeback
           ST_DONE   = 7;

    always @(posedge clk_buf or posedge sys_reset) begin
        
        if (sys_reset) begin
            state <= ST_IDLE;
            a_extractor_start <= 0;
            b_extractor_start <= 0;
            a_extractor_cycle <= 0;
            b_extractor_cycle <= 0;
            cycle_counter     <= 0;
            busy              <= 0;
            done              <= 0;
            load_start_extr_A <= 0;
            load_start_extr_B <= 0;
            systol_en            <= 0;
            systol_reset        <= 1;
            a_in_flat <= 0;
            b_in_flat <= 0;
            sel_extractor <= 0;

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
                        load_start_extr_A <= 1;
                        
                        systol_en            <= 1'b1;
                        state <= ST_MATR_EXTR;
                    end
                end

                //--------------------------------------------------------
                // ST_MATR_EXTR: Wait for A extractor to produce valid
                //--------------------------------------------------------
                ST_MATR_EXTR: begin
                    // Keep a_extractor_start = 1 until we see a_valid,
                    // or deassert after 1 cycle if that's how your extractor works
                    if (matrix_A_loaded) begin
                        load_start_extr_B <= 1;
                        sel_extractor <= 1;
                    end
                    if (matrix_B_loaded) begin
                        a_extractor_start <= 1;
                        b_extractor_start <= 1;
                        state <= ST_MATR_PROP;
                    end
                end

                //--------------------------------------------------------
                // ST_MATR_PROP: Wait for B extractor to produce valid
                //--------------------------------------------------------
                ST_MATR_PROP: begin
                    a_in_flat <= a_flat_out;
                    b_in_flat <= b_flat_out;
                    state <= ST_ZERO;
                end

                // ST_INJECT: Present the diagonal to the systolic array for 1 clock
                // (The diagonal data is in a_flat_out / b_flat_out from the extractors.)
                ST_ZERO: begin
                    // We do one clock of diagonal injection
                    // Next cycle, we zero the inputs
                    a_in_flat <= 0;
                    b_in_flat <= 0; 
                    if (cycle_counter < 15) begin
                        display_matrix(c_out_flat, "Actual Output Matrix (C)");
                        cycle_counter <= cycle_counter + 1;
                        // Fire new extraction
                        state <= ST_MATR_PROP;
                    end
                    else begin
                        // All diagonals processed
                        $display("[top] all cycles piped in");
                        pipeline_counter <= 0;
                        a_extractor_start <= 1'b0;
                        b_extractor_start <= 1'b0;
                        state <= ST_PIPE;
                    end
                end
                //==========================================================
                // ST_PIPE: Wait 19 cycles for systolic array to flush
                //==========================================================
                ST_PIPE: begin
                    if (pipeline_counter < 20) begin
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
                    if(!start) begin
                    state <= ST_IDLE; // or remain in ST_DONE if you want latched done
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end


    

endmodule
