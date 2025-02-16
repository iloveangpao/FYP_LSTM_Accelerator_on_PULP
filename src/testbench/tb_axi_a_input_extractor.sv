`timescale 1ns/1ps
module tb_extractor_integration;

  //===========================================================================
  // Clock & Reset
  //===========================================================================
  reg sys_clock;
  reg reset_rtl;
  
  initial begin
      sys_clock = 0;
      forever #5 sys_clock = ~sys_clock; // 100 MHz clock
  end

  initial begin
      reset_rtl = 1;
      #20;
      reset_rtl = 0;
  end

  //===========================================================================
  // S_AXI_0 Interface (for programming memory)
  //===========================================================================
  reg  [11:0] S_AXI_0_awaddr;
  reg  [1:0]  S_AXI_0_awburst;
  reg  [3:0]  S_AXI_0_awcache;
  reg  [7:0]  S_AXI_0_awlen;
  reg         S_AXI_0_awlock;
  reg  [2:0]  S_AXI_0_awprot;
  wire        S_AXI_0_awready;
  reg  [2:0]  S_AXI_0_awsize;
  reg         S_AXI_0_awvalid;
  reg         S_AXI_0_bready;
  wire [1:0]  S_AXI_0_bresp;
  wire        S_AXI_0_bvalid;
  reg  [31:0] S_AXI_0_wdata;
  reg         S_AXI_0_wlast;
  wire        S_AXI_0_wready;
  reg  [3:0]  S_AXI_0_wstrb;
  reg         S_AXI_0_wvalid;

  reg  [11:0] S_AXI_0_araddr;
  reg  [1:0]  S_AXI_0_arburst;
  reg  [3:0]  S_AXI_0_arcache;
  reg  [7:0]  S_AXI_0_arlen;
  reg         S_AXI_0_arlock;
  reg  [2:0]  S_AXI_0_arprot;
  wire        S_AXI_0_arready;
  reg  [2:0]  S_AXI_0_arsize;
  reg         S_AXI_0_arvalid;
  wire [31:0] S_AXI_0_rdata;
  wire        S_AXI_0_rlast;
  reg         S_AXI_0_rready;
  wire [1:0]  S_AXI_0_rresp;
  wire        S_AXI_0_rvalid;

  //===========================================================================
  // S_AXI_1 Interface (used by the extractor)
  //===========================================================================
  // The memory_block_wrapper provides both S_AXI_0 (for programming)
  // and S_AXI_1 (for extractor read transactions). We assume that the 
  // S_AXI_1 side of the memory block wrapper is fully AXI compliant.
  reg  [11:0] S_AXI_1_awaddr;
  reg  [1:0]  S_AXI_1_awburst;
  reg  [3:0]  S_AXI_1_awcache;
  reg  [7:0]  S_AXI_1_awlen;
  reg         S_AXI_1_awlock;
  reg  [2:0]  S_AXI_1_awprot;
  wire        S_AXI_1_awready;
  reg  [2:0]  S_AXI_1_awsize;
  reg         S_AXI_1_awvalid;
  reg         S_AXI_1_bready;
  wire [1:0]  S_AXI_1_bresp;
  wire        S_AXI_1_bvalid;
  reg  [31:0] S_AXI_1_wdata;
  reg         S_AXI_1_wlast;
  wire        S_AXI_1_wready;
  reg  [3:0]  S_AXI_1_wstrb;
  reg         S_AXI_1_wvalid;

  reg  [11:0] S_AXI_1_araddr;
  reg  [1:0]  S_AXI_1_arburst;
  reg  [3:0]  S_AXI_1_arcache;
  reg  [7:0]  S_AXI_1_arlen;
  reg         S_AXI_1_arlock;
  reg  [2:0]  S_AXI_1_arprot;
  wire        S_AXI_1_arready;
  reg  [2:0]  S_AXI_1_arsize;
  reg         S_AXI_1_arvalid;
  wire [31:0] S_AXI_1_rdata;
  wire        S_AXI_1_rlast;
  reg         S_AXI_1_rready;
  wire [1:0]  S_AXI_1_rresp;
  wire        S_AXI_1_rvalid;

  //===========================================================================
  // Extractor Control Signals
  //===========================================================================
  reg         extractor_start;
  reg  [3:0]  extractor_cycle;
  wire [63:0] extracted_flat;
  wire        extractor_valid;

  //===========================================================================
  // Instantiate Memory Block Wrapper
  //===========================================================================
  // This is your final memory block. It should implement the AXI interfaces 
  // for both S_AXI_0 (programming) and S_AXI_1 (reads for the extractor).
  memory_block_wrapper mem_dut (
    .sys_clock(sys_clock),
    .reset_rtl(reset_rtl),
    // S_AXI_0 connections
    .S_AXI_0_awaddr(S_AXI_0_awaddr),
    .S_AXI_0_awburst(S_AXI_0_awburst),
    .S_AXI_0_awcache(S_AXI_0_awcache),
    .S_AXI_0_awlen(S_AXI_0_awlen),
    .S_AXI_0_awlock(S_AXI_0_awlock),
    .S_AXI_0_awprot(S_AXI_0_awprot),
    .S_AXI_0_awready(S_AXI_0_awready),
    .S_AXI_0_awsize(S_AXI_0_awsize),
    .S_AXI_0_awvalid(S_AXI_0_awvalid),
    .S_AXI_0_bready(S_AXI_0_bready),
    .S_AXI_0_bresp(S_AXI_0_bresp),
    .S_AXI_0_bvalid(S_AXI_0_bvalid),
    .S_AXI_0_wdata(S_AXI_0_wdata),
    .S_AXI_0_wlast(S_AXI_0_wlast),
    .S_AXI_0_wready(S_AXI_0_wready),
    .S_AXI_0_wstrb(S_AXI_0_wstrb),
    .S_AXI_0_wvalid(S_AXI_0_wvalid),
    .S_AXI_0_araddr(S_AXI_0_araddr),
    .S_AXI_0_arburst(S_AXI_0_arburst),
    .S_AXI_0_arcache(S_AXI_0_arcache),
    .S_AXI_0_arlen(S_AXI_0_arlen),
    .S_AXI_0_arlock(S_AXI_0_arlock),
    .S_AXI_0_arprot(S_AXI_0_arprot),
    .S_AXI_0_arready(S_AXI_0_arready),
    .S_AXI_0_arsize(S_AXI_0_arsize),
    .S_AXI_0_arvalid(S_AXI_0_arvalid),
    .S_AXI_0_rdata(S_AXI_0_rdata),
    .S_AXI_0_rlast(S_AXI_0_rlast),
    .S_AXI_0_rready(S_AXI_0_rready),
    .S_AXI_0_rresp(S_AXI_0_rresp),
    .S_AXI_0_rvalid(S_AXI_0_rvalid),
    // S_AXI_1 connections (for extractor read transactions)
    .S_AXI_1_awaddr(S_AXI_1_awaddr),
    .S_AXI_1_awburst(S_AXI_1_awburst),
    .S_AXI_1_awcache(S_AXI_1_awcache),
    .S_AXI_1_awlen(S_AXI_1_awlen),
    .S_AXI_1_awlock(S_AXI_1_awlock),
    .S_AXI_1_awprot(S_AXI_1_awprot),
    .S_AXI_1_awready(S_AXI_1_awready),
    .S_AXI_1_awsize(S_AXI_1_awsize),
    .S_AXI_1_awvalid(S_AXI_1_awvalid),
    .S_AXI_1_bready(S_AXI_1_bready),
    .S_AXI_1_bresp(S_AXI_1_bresp),
    .S_AXI_1_bvalid(S_AXI_1_bvalid),
    .S_AXI_1_wdata(S_AXI_1_wdata),
    .S_AXI_1_wlast(S_AXI_1_wlast),
    .S_AXI_1_wready(S_AXI_1_wready),
    .S_AXI_1_wstrb(S_AXI_1_wstrb),
    .S_AXI_1_wvalid(S_AXI_1_wvalid),
    .S_AXI_1_araddr(S_AXI_1_araddr),
    .S_AXI_1_arburst(S_AXI_1_arburst),
    .S_AXI_1_arcache(S_AXI_1_arcache),
    .S_AXI_1_arlen(S_AXI_1_arlen),
    .S_AXI_1_arlock(S_AXI_1_arlock),
    .S_AXI_1_arprot(S_AXI_1_arprot),
    .S_AXI_1_arready(S_AXI_1_arready),
    .S_AXI_1_arsize(S_AXI_1_arsize),
    .S_AXI_1_arvalid(S_AXI_1_arvalid),
    .S_AXI_1_rdata(S_AXI_1_rdata),
    .S_AXI_1_rlast(S_AXI_1_rlast),
    .S_AXI_1_rready(S_AXI_1_rready),
    .S_AXI_1_rresp(S_AXI_1_rresp),
    .S_AXI_1_rvalid(S_AXI_1_rvalid)
  );

  //===========================================================================
  // Instantiate A-Input Extractor Top Module
  //===========================================================================
  axi_a_input_extractor_top extractor (
    .clk(sys_clock),
    .rst(reset_rtl),
    .start(extractor_start),
    .cycle(extractor_cycle),
    .a_flat_out(extracted_flat),
    .valid(extractor_valid),
    // Connect the AXI read channel to the S_AXI_1 interface.
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

  //========================================================================
// S_AXI_1 Master Signals for Validation (Testbench-driven)
//========================================================================
reg  [11:0] S_AXI_1_araddr_tb;
reg         S_AXI_1_arvalid_tb;
reg  [2:0]  S_AXI_1_arsize_tb;
reg         S_AXI_1_rready_tb;

// Drive the S_AXI_1 master signals from the testbench.
// (Assuming that the memory_block_wrapper’s S_AXI_1 port is not driven
//  by another module during validation.)
assign S_AXI_1_araddr   = S_AXI_1_araddr_tb;
assign S_AXI_1_arsize   = S_AXI_1_arsize_tb;
assign S_AXI_1_arvalid  = S_AXI_1_arvalid_tb;
assign S_AXI_1_rready   = S_AXI_1_rready_tb;

//========================================================================
// Task: axi4_read_S1
//
// Performs a single AXI read transaction on the S_AXI_1 interface.
//========================================================================
task axi4_read_S1(input [11:0] addr, output [31:0] data);
  integer timeout_counter;
    begin
        timeout_counter = 10;
        while (S_AXI_1_arready !== 0 && timeout_counter > 0) begin
           @(posedge sys_clock);
           timeout_counter = timeout_counter - 1;
        end
        S_AXI_1_araddr  = addr;
        S_AXI_1_arlen   = 8'h00;      // Single transfer
        S_AXI_1_arsize  = 3'b010;
        S_AXI_1_arburst = 2'b00;
        S_AXI_1_arlock  = 0;
        S_AXI_1_arvalid = 1;
        S_AXI_1_rready  = 1;
        @(posedge sys_clock);
        S_AXI_1_arvalid = 0;
        timeout_counter = 10;
        while (S_AXI_1_rvalid !== 1 && timeout_counter > 0) begin
           @(posedge sys_clock);
           timeout_counter = timeout_counter - 1;
        end
        data = S_AXI_1_rdata;
        S_AXI_1_rready = 0;
        $display("[TB] S_AXI_0 Read: Addr = 0x%03h, Data = 0x%08h", addr, data);
        @(posedge sys_clock);
    end
endtask

//========================================================================
// Additional Validation for S_AXI_1 Reads
//========================================================================
integer row;
reg [31:0] word_data_s1;
reg [31:0] expected_word;

  //===========================================================================
  // AXI4 Write and Read Tasks for S_AXI_0 (Memory Programming)
  //===========================================================================
  task axi4_write_S0(input [11:0] addr, input [31:0] data);
    integer timeout_counter;
    begin
      @(posedge sys_clock);
      S_AXI_0_awaddr  = addr;
      S_AXI_0_awlen   = 8'h00;      // Single transfer
      S_AXI_0_awsize  = 3'b010;     // 32-bit word
      S_AXI_0_awburst = 2'b01;      // INCR mode
      S_AXI_0_awvalid = 1;
      @(posedge sys_clock);
      S_AXI_0_awvalid = 0;
      S_AXI_0_wdata   = data;
      S_AXI_0_wstrb   = 4'b1111;
      S_AXI_0_wvalid  = 1;
      S_AXI_0_wlast   = 1;
      S_AXI_0_bready  = 1;
      @(posedge sys_clock);
      S_AXI_0_wvalid  = 0;
      S_AXI_0_wlast   = 0;
      S_AXI_0_bready  = 1;
      timeout_counter = 10;
      while (S_AXI_0_bvalid !== 1 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_bready = 0;
      $display("[TB] S_AXI_0 Write: Addr = 0x%03h, Data = 0x%08h", addr, data);
      @(posedge sys_clock);
    end
  endtask

  task axi4_read_S0(input [11:0] addr, output [31:0] data);
    integer timeout_counter;
    begin
      @(posedge sys_clock);
      timeout_counter = 10;
      while (S_AXI_0_arready !== 0 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_araddr  = addr;
      S_AXI_0_arlen   = 8'h00;      // Single transfer
      S_AXI_0_arsize  = 3'b010;
      S_AXI_0_arburst = 2'b00;
      S_AXI_0_arlock  = 0;
      S_AXI_0_arvalid = 1;
      S_AXI_0_rready  = 1;
      @(posedge sys_clock);
      S_AXI_0_arvalid = 0;
      timeout_counter = 10;
      while (S_AXI_0_rvalid !== 1 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      data = S_AXI_0_rdata;
      S_AXI_0_rready = 0;
      $display("[TB] S_AXI_0 Read: Addr = 0x%03h, Data = 0x%08h", addr, data);
    end
  endtask

  //===========================================================================
  // Test Sequence
  //===========================================================================
  integer row, c, timeout, row;
  reg [31:0] word_data;
  reg [31:0] expected_word;
  reg [63:0] expected_extraction;
  reg [7:0]  expected_byte;
  reg [7:0] byte0, byte1, byte2, byte3;
    task reset_signals();
        S_AXI_0_awaddr   = 0;
    S_AXI_0_awburst  = 0;
    S_AXI_0_awcache  = 0;
    S_AXI_0_awlen    = 0;
    S_AXI_0_awlock   = 0;
    S_AXI_0_awprot   = 0;
    S_AXI_0_awsize   = 0;
    S_AXI_0_awvalid  = 0;
    S_AXI_0_bready   = 0;
    S_AXI_0_wdata    = 0;
    S_AXI_0_wlast    = 0;
    S_AXI_0_wstrb    = 0;
    S_AXI_0_wvalid   = 0;
    S_AXI_0_araddr   = 0;
    S_AXI_0_arburst  = 0;
    S_AXI_0_arcache  = 0;
    S_AXI_0_arlen    = 0;
    S_AXI_0_arlock   = 0;
    S_AXI_0_arprot   = 0;
    S_AXI_0_arsize   = 0;
    S_AXI_0_arvalid  = 0;
    S_AXI_0_rready   = 0;

    S_AXI_1_awaddr   = 0;
    S_AXI_1_awburst  = 0;
    S_AXI_1_awcache  = 0;
    S_AXI_1_awlen    = 0;
    S_AXI_1_awlock   = 0;
    S_AXI_1_awprot   = 0;
    S_AXI_1_awsize   = 0;
    S_AXI_1_awvalid  = 0;
    S_AXI_1_bready   = 0;
    S_AXI_1_wdata    = 0;
    S_AXI_1_wlast    = 0;
    S_AXI_1_wstrb    = 0;
    S_AXI_1_wvalid   = 0;
    S_AXI_1_araddr   = 0;
    S_AXI_1_arburst  = 0;
    S_AXI_1_arcache  = 0;
    S_AXI_1_arlen    = 0;
    S_AXI_1_arlock   = 0;
    S_AXI_1_arprot   = 0;
    S_AXI_1_arsize   = 0;
    S_AXI_1_arvalid  = 0;
    S_AXI_1_rready   = 0;
    endtask
  initial begin
    // Initialize S_AXI_0 signals
    S_AXI_0_awaddr   = 0;
    S_AXI_0_awburst  = 0;
    S_AXI_0_awcache  = 0;
    S_AXI_0_awlen    = 0;
    S_AXI_0_awlock   = 0;
    S_AXI_0_awprot   = 0;
    S_AXI_0_awsize   = 0;
    S_AXI_0_awvalid  = 0;
    S_AXI_0_bready   = 0;
    S_AXI_0_wdata    = 0;
    S_AXI_0_wlast    = 0;
    S_AXI_0_wstrb    = 0;
    S_AXI_0_wvalid   = 0;
    S_AXI_0_araddr   = 0;
    S_AXI_0_arburst  = 0;
    S_AXI_0_arcache  = 0;
    S_AXI_0_arlen    = 0;
    S_AXI_0_arlock   = 0;
    S_AXI_0_arprot   = 0;
    S_AXI_0_arsize   = 0;
    S_AXI_0_arvalid  = 0;
    S_AXI_0_rready   = 0;

    S_AXI_1_awaddr   = 0;
    S_AXI_1_awburst  = 0;
    S_AXI_1_awcache  = 0;
    S_AXI_1_awlen    = 0;
    S_AXI_1_awlock   = 0;
    S_AXI_1_awprot   = 0;
    S_AXI_1_awsize   = 0;
    S_AXI_1_awvalid  = 0;
    S_AXI_1_bready   = 0;
    S_AXI_1_wdata    = 0;
    S_AXI_1_wlast    = 0;
    S_AXI_1_wstrb    = 0;
    S_AXI_1_wvalid   = 0;
    S_AXI_1_araddr   = 0;
    S_AXI_1_arburst  = 0;
    S_AXI_1_arcache  = 0;
    S_AXI_1_arlen    = 0;
    S_AXI_1_arlock   = 0;
    S_AXI_1_arprot   = 0;
    S_AXI_1_arsize   = 0;
    S_AXI_1_arvalid  = 0;
    S_AXI_1_rready   = 0;

    // Initialize extractor control signals
    extractor_start  = 0;
    extractor_cycle  = 0;

    // Wait for reset deassertion
    @(negedge reset_rtl);
    #20;
    $display("-----------------------------------------------------");
    $display("[TB] Populating memory with A matrix data...");
    $display("-----------------------------------------------------");
    
    


    for (row = 0; row < 8; row = row + 1) begin
        // For Word0: columns 0-3 for row 'row'
        byte0 = row*8 + 1; // A[row][0]
        byte1 = row*8 + 2; // A[row][1]
        byte2 = row*8 + 3; // A[row][2]
        byte3 = row*8 + 4; // A[row][3]
        expected_word = {byte3, byte2, byte1, byte0}; // Pack MSB-first
        axi4_write_S0(row*8 + 0, expected_word);
        
        // For Word1: columns 4-7 for row 'row'
        byte0 = row*8 + 5; // A[row][4]
        byte1 = row*8 + 6; // A[row][5]
        byte2 = row*8 + 7; // A[row][6]
        byte3 = row*8 + 8; // A[row][7]
        expected_word = {byte3, byte2, byte1, byte0};
        axi4_write_S0(row*8 + 4, expected_word);
    end

//---------------------------------------------------------------------
// S_AXI_0 Read Validation
//---------------------------------------------------------------------
  $display("-----------------------------------------------------");
  $display("[TB] Validating memory contents via S_AXI_0 reads...");
  $display("-----------------------------------------------------");
  for (row = 0; row < 8; row = row + 1) begin
      // Validate first word: columns 0-3 for row 'row'
      axi4_read_S0(row*8 + 0, word_data);
      byte0 = row*8 + 1;  // A[row][0]
      byte1 = row*8 + 2;  // A[row][1]
      byte2 = row*8 + 3;  // A[row][2]
      byte3 = row*8 + 4;  // A[row][3]
      expected_word = {byte3, byte2, byte1, byte0}; // Pack MSB-first
      if (word_data !== expected_word) begin
         $display("[ERROR] S_AXI_0 validation failed at row %0d word0: Expected 0x%08h, Got 0x%08h", 
                  row, expected_word, word_data);
         $finish;
      end

      // Validate second word: columns 4-7 for row 'row'
      axi4_read_S0(row*8 + 4, word_data);
      byte0 = row*8 + 5;  // A[row][4]
      byte1 = row*8 + 6;  // A[row][5]
      byte2 = row*8 + 7;  // A[row][6]
      byte3 = row*8 + 8;  // A[row][7]
      expected_word = {byte3, byte2, byte1, byte0};
      if (word_data !== expected_word) begin
         $display("[ERROR] S_AXI_0 validation failed at row %0d word1: Expected 0x%08h, Got 0x%08h", 
                  row, expected_word, word_data);
         $finish;
      end
      $display("[TB] S_AXI_0: Row %0d validated.", row);
  end

  $display("-----------------------------------------------------");
  $display("[TB] S_AXI_0 memory read validation passed.");
  $display("-----------------------------------------------------");

  //---------------------------------------------------------------------
  // S_AXI_1 Read Validation
  //---------------------------------------------------------------------
  $display("-----------------------------------------------------");
  $display("[TB] Validating memory contents via S_AXI_1 reads...");
  $display("-----------------------------------------------------");
  for (row = 0; row < 8; row = row + 1) begin
      // Validate first word: columns 0-3 for row 'row'
      axi4_read_S1(row*8 + 0, word_data);
      byte0 = row*8 + 1;
      byte1 = row*8 + 2;
      byte2 = row*8 + 3;
      byte3 = row*8 + 4;
      expected_word = {byte3, byte2, byte1, byte0};
      if (word_data !== expected_word) begin
         $display("[ERROR] S_AXI_1 validation failed at row %0d word0: Expected 0x%08h, Got 0x%08h", 
                  row, expected_word, word_data);
         $finish;
      end

      // Validate second word: columns 4-7 for row 'row'
      axi4_read_S1(row*8 + 4, word_data);
      byte0 = row*8 + 5;
      byte1 = row*8 + 6;
      byte2 = row*8 + 7;
      byte3 = row*8 + 8;
      expected_word = {byte3, byte2, byte1, byte0};
      if (word_data !== expected_word) begin
         $display("[ERROR] S_AXI_1 validation failed at row %0d word1: Expected 0x%08h, Got 0x%08h", 
                  row, expected_word, word_data);
         $finish;
      end
      $display("[TB] S_AXI_1: Row %0d validated.", row);
  end

  $display("-----------------------------------------------------");
  $display("[TB] Memory read validation passed for both S_AXI_0 and S_AXI_1.");
  $display("-----------------------------------------------------");
    reset_signals();
    //===========================================================================
    // Extraction Tests
    //===========================================================================
    $display("-----------------------------------------------------");
    $display("[TB] Starting extraction tests on A matrix...");
    $display("-----------------------------------------------------");
    // Test cycles from 0 to 15 (cycle 15 is out-of-range and should yield zeros)
    for (c = 0; c < 16; c = c + 1) begin
      extractor_cycle = c[3:0];
      extractor_start = 1;
      @(posedge sys_clock);
      extractor_start = 0;
      
      // Wait (with timeout) for valid output from extractor
      timeout = 200;
      while (!extractor_valid && timeout > 0) begin
        @(posedge sys_clock);
        timeout = timeout - 1;
      end
      if (timeout == 0) begin
        $display("[ERROR] Extraction timeout for cycle %0d", c);
        $finish;
      end
      
      // Compute expected extraction.
      expected_extraction = 64'd0;
      if (c > 14) begin
         expected_extraction = 64'd0;
      end else begin
         integer start_i, end_i, i;
         if (c <= 7) begin
            start_i = 0;
            end_i   = c;
         end else begin
            start_i = c - 7;
            end_i   = 7;
         end
         for (i = start_i; i <= end_i; i = i + 1) begin
            // For row i, column = c - i.
            expected_byte = i*8 + (c - i) + 1;
            expected_extraction = expected_extraction | ({56'd0, expected_byte} << (i*8));
         end
      end
      
      $display("[TB] Cycle %0d: Expected Extraction = 0x%016h, Got = 0x%016h", c, expected_extraction, extracted_flat);
      if (extracted_flat !== expected_extraction) begin
         $display("[ERROR] Extraction mismatch at cycle %0d", c);
         $finish;
      end else begin
         $display("[TB] Cycle %0d passed.", c);
      end
      repeat(2) @(posedge sys_clock);
    end

    $display("-----------------------------------------------------");
    $display("[TB] All extraction tests passed successfully.");
    $display("-----------------------------------------------------");
    #50;
    $finish;
  end

  //===========================================================================
  // Overall Simulation Timeout
  //===========================================================================
  initial begin
    #10000;
    $display("[ERROR] Simulation timed out.");
    $finish;
  end

endmodule



