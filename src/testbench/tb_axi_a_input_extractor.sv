`timescale 1ns/1ps
module tb_extractor_integration;

 // Clock and reset signals.
  reg sys_clock;
  reg reset_rtl;
  parameter AXI_ADDR_WIDTH = 12;
  parameter BASE_ADDR_A = 12'h000;
  
  // Generate a 100 MHz clock.
  initial begin
      sys_clock = 0;
      forever #5 sys_clock = ~sys_clock;
  end
  
  // Reset generation.
  initial begin
      reset_rtl = 1;
      #20;
      reset_rtl = 0;
  end
  
  //-------------------------------------------------------------------------
  // Signals for Memory Block Wrapper (S_AXI_0 for programming, S_AXI_1 for extractor)
  //-------------------------------------------------------------------------
  // S_AXI_0 signals (for programming the memory)
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
  
  // S_AXI_1 signals (used by the extractor)
  reg [11:0] S_AXI_1_araddr;
  reg [1:0]  S_AXI_1_arburst;
  reg [3:0]  S_AXI_1_arcache;
  reg [7:0]  S_AXI_1_arlen;
  reg        S_AXI_1_arlock;
  reg [2:0]  S_AXI_1_arprot;
  reg        S_AXI_1_arready;
  reg [2:0]  S_AXI_1_arsize;
  reg        S_AXI_1_arvalid;
  reg [11:0] S_AXI_1_awaddr;
  reg [1:0]  S_AXI_1_awburst;
  reg [3:0]  S_AXI_1_awcache;
  reg [7:0]  S_AXI_1_awlen;
  reg        S_AXI_1_awlock;
  reg [2:0]  S_AXI_1_awprot;
  reg        S_AXI_1_awready;
  reg [2:0]  S_AXI_1_awsize;
  reg        S_AXI_1_awvalid;
  reg        S_AXI_1_bready;
  reg [1:0]  S_AXI_1_bresp;
  reg        S_AXI_1_bvalid;
  reg [31:0] S_AXI_1_rdata;
  reg        S_AXI_1_rlast;
  reg        S_AXI_1_rready;
  reg [1:0]  S_AXI_1_rresp;
  reg        S_AXI_1_rvalid;
  reg [31:0] S_AXI_1_wdata;
  reg        S_AXI_1_wlast;
  reg        S_AXI_1_wready;
  reg [3:0]  S_AXI_1_wstrb;
  reg        S_AXI_1_wvalid;
  
  //-------------------------------------------------------------------------
  // Declare testbench helper variables at module scope.
  //-------------------------------------------------------------------------
  integer t, i_idx;
  reg [63:0] expected;
  reg [7:0] expected_byte;
  reg error_flag;
  reg matrix_loaded;
  
  //-------------------------------------------------------------------------
  // Instantiate the memory block wrapper (your provided module)
  //-------------------------------------------------------------------------
  memory_block_wrapper memory_block_i (
    .S_AXI_0_araddr(S_AXI_0_araddr),
    .S_AXI_0_arburst(S_AXI_0_arburst),
    .S_AXI_0_arcache(S_AXI_0_arcache),
    .S_AXI_0_arlen(S_AXI_0_arlen),
    .S_AXI_0_arlock(S_AXI_0_arlock),
    .S_AXI_0_arprot(S_AXI_0_arprot),
    .S_AXI_0_arready(S_AXI_0_arready),
    .S_AXI_0_arsize(S_AXI_0_arsize),
    .S_AXI_0_arvalid(S_AXI_0_arvalid),
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
    .S_AXI_0_rdata(S_AXI_0_rdata),
    .S_AXI_0_rlast(S_AXI_0_rlast),
    .S_AXI_0_rready(S_AXI_0_rready),
    .S_AXI_0_rresp(S_AXI_0_rresp),
    .S_AXI_0_rvalid(S_AXI_0_rvalid),
    .S_AXI_0_wdata(S_AXI_0_wdata),
    .S_AXI_0_wlast(S_AXI_0_wlast),
    .S_AXI_0_wready(S_AXI_0_wready),
    .S_AXI_0_wstrb(S_AXI_0_wstrb),
    .S_AXI_0_wvalid(S_AXI_0_wvalid),
    .S_AXI_1_araddr(S_AXI_1_araddr),
    .S_AXI_1_arburst(S_AXI_1_arburst),
    .S_AXI_1_arcache(S_AXI_1_arcache),
    .S_AXI_1_arlen(S_AXI_1_arlen),
    .S_AXI_1_arlock(S_AXI_1_arlock),
    .S_AXI_1_arprot(S_AXI_1_arprot),
    .S_AXI_1_arready(S_AXI_1_arready),
    .S_AXI_1_arsize(S_AXI_1_arsize),
    .S_AXI_1_arvalid(S_AXI_1_arvalid),
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
    .S_AXI_1_rdata(S_AXI_1_rdata),
    .S_AXI_1_rlast(S_AXI_1_rlast),
    .S_AXI_1_rready(S_AXI_1_rready),
    .S_AXI_1_rresp(S_AXI_1_rresp),
    .S_AXI_1_rvalid(S_AXI_1_rvalid),
    .S_AXI_1_wdata(S_AXI_1_wdata),
    .S_AXI_1_wlast(S_AXI_1_wlast),
    .S_AXI_1_wready(S_AXI_1_wready),
    .S_AXI_1_wstrb(S_AXI_1_wstrb),
    .S_AXI_1_wvalid(S_AXI_1_wvalid),
    .reset_rtl(reset_rtl),
    .sys_clock(sys_clock)
  );
  
  //-------------------------------------------------------------------------
  // Instantiate the extractor module.
  //-------------------------------------------------------------------------
  // Control signals for the extractor.
  reg load_start_extr;
  reg start_extr;
  reg [3:0] cycle_extr;
  wire [63:0] a_flat_out_extr;
  wire valid_extr;
  
  axi_a_input_extractor_top extractor_i (
    .clk(sys_clock),
    .rst(reset_rtl),
    .load_start(load_start_extr),
    .start(start_extr),
    // .cycle(cycle_extr),
    .a_flat_out(a_flat_out_extr),
    // .valid(valid_extr),
    .input_loaded(matrix_loaded),
    // Connect to S_AXI_1 interface from the memory block.
    .m_axi_araddr(S_AXI_1_araddr),
    .m_axi_arsize(S_AXI_1_arsize),
    .m_axi_arvalid(S_AXI_1_arvalid),
    .m_axi_arburst(S_AXI_1_arburst),
    .m_axi_arcache(S_AXI_1_arcache),
    .m_axi_arlen(S_AXI_1_arlen),
    .m_axi_arlock(S_AXI_1_arlock),
    .m_axi_arprot(S_AXI_1_arprot),
    .m_axi_arready(S_AXI_1_arready),
    .m_axi_rdata(S_AXI_1_rdata),
    .m_axi_rvalid(S_AXI_1_rvalid),
    .m_axi_rlast(S_AXI_1_rlast),
    .m_axi_rready(S_AXI_1_rready)
  );
  
  task axi4_single_write(
        input [AXI_ADDR_WIDTH-1:0] addr,
        input [31:0]               data
    );
    integer timeout_counter;
        begin
            // AW
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

            $display("[TB:AXI] Wrote 0x%08h to 0x%03h at time %t", data, addr, $time);
        end
    endtask

    // -------------------------------------------------------------------------
    // AXI4 Single-Read Task (Simplified)
    // -------------------------------------------------------------------------
    task axi4_single_read(
        input  [AXI_ADDR_WIDTH-1:0] addr,
        output [31:0]               data
    );
    integer timeout_counter;
        begin
            // AR
            @(posedge sys_clock);
      timeout_counter = 10;
      while (S_AXI_0_arready !== 0 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_araddr  = addr;
      S_AXI_0_arlen   = 8'h00;      // Single transfer
      S_AXI_0_arsize  = 3'b010;
      S_AXI_0_arburst = 2'b01;
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

            $display("[TB:AXI] Read  0x%08h from 0x%03h at time %t", data, addr, $time);
        end
    endtask

    reg [7:0] byte0, byte1, byte2, byte3;

    // -------------------------------------------------------------------------
    // Utility: Write 8 words (2 for each row) for an 8x8 matrix
    // (Adapt to your memory layout)
    // For demonstration, we store row 0..7 in consecutive addresses
    // -------------------------------------------------------------------------
    task write_matrix_A;
        integer row, col;
        reg [31:0] word;
        begin
            $display("[TB] Writing test matrix A into memory...");
            // Example pattern: For each row, store 2 words (columns 0..3, then 4..7).
            // The user can adapt if the memory layout differs.
            for (row = 0; row < 8; row++) begin
                // Word0 for row
                byte0 = row*8 + 1; // A[row][0]
                byte1 = row*8 + 2; // A[row][1]
                byte2 = row*8 + 3; // A[row][2]
                byte3 = row*8 + 4; // A[row][3]
                word = {byte3, byte2, byte1, byte0}; 
                axi4_single_write(BASE_ADDR_A + row*8 + 0, word);

                // Word1 for row
                byte0 = row*8 + 5; // A[row][4]
                byte1 = row*8 + 6; // A[row][5]
                byte2 = row*8 + 7; // A[row][6]
                byte3 = row*8 + 8; // A[row][7]
                word = {byte3, byte2, byte1, byte0};
                axi4_single_write(BASE_ADDR_A + row*8 + 4, word);
            end
        end
    endtask

    task verify_matrix_A;
        integer row;
        reg [31:0] read_back, expected0, expected1;
        begin
            $display("[TB] Verifying test matrix A in memory...");
            for (row = 0; row < 8; row++) begin
                byte0 = row*8 + 1; // A[row][0]
                byte1 = row*8 + 2; // A[row][1]
                byte2 = row*8 + 3; // A[row][2]
                byte3 = row*8 + 4; // A[row][3]
                expected0 = {byte3, byte2, byte1, byte0}; 
                axi4_single_read(BASE_ADDR_A + row*8, read_back);
                if (read_back !== expected0) begin
                    $display("[ERROR] A row=%0d word0 mismatch. Read=0x%08h, Exp=0x%08h, Addr=0x%03h", 
                             row, read_back, expected0, BASE_ADDR_A + row*8 + 0);
                    $stop;
                end

                // Word1
                byte0 = row*8 + 5; // A[row][4]
                byte1 = row*8 + 6; // A[row][5]
                byte2 = row*8 + 7; // A[row][6]
                byte3 = row*8 + 8; // A[row][7]
                expected1 = {byte3, byte2, byte1, byte0};
                axi4_single_read(BASE_ADDR_A + row*8 + 4, read_back);
                if (read_back !== expected1) begin
                    $display("[ERROR] A row=%0d word1 mismatch. Read=0x%08h, Exp=0x%08h", 
                             row, read_back, expected1);
                    $stop;
                end
            end
            $display("[TB] A matrix verification PASSED!");
        end
    endtask
  
  //-------------------------------------------------------------------------
  // Program the Memory Block with the 8x8 matrix A.
  // A[i][j] = i*8 + j + 1; each row is stored as two words:
  //   word0 = { A[i][3], A[i][2], A[i][1], A[i][0] }
  //   word1 = { A[i][7], A[i][6], A[i][5], A[i][4] }
  //-------------------------------------------------------------------------
  integer row;
  reg [31:0] word_data;
  integer wait_cycles;
  initial begin
    // Initialize S_AXI_0 interface signals.
    S_AXI_0_awaddr = 0; S_AXI_0_awburst = 0; S_AXI_0_arcache = 0;
    S_AXI_0_awlen = 0; S_AXI_0_awlock = 0; S_AXI_0_awprot = 0;
    S_AXI_0_awsize = 0; S_AXI_0_awvalid = 0; S_AXI_0_bready = 0;
    S_AXI_0_wdata = 0; S_AXI_0_wlast = 0; S_AXI_0_wstrb = 0; S_AXI_0_wvalid = 0;
    S_AXI_0_araddr = 0; S_AXI_0_arburst = 0; S_AXI_0_arcache = 0;
    S_AXI_0_arlen = 0; S_AXI_0_arlock = 0; S_AXI_0_arprot = 0;
    S_AXI_0_arsize = 0; S_AXI_0_arvalid = 0; S_AXI_0_rready = 0;


    S_AXI_1_awaddr = 0; S_AXI_1_awburst = 0; S_AXI_1_arcache = 0;
    S_AXI_1_awlen = 0; S_AXI_1_awlock = 0; S_AXI_1_awprot = 0;
    S_AXI_1_awsize = 0; S_AXI_1_awvalid = 0; S_AXI_1_bready = 0;
    S_AXI_1_wdata = 0; S_AXI_1_wlast = 0; S_AXI_1_wstrb = 0; S_AXI_1_wvalid = 0;
    S_AXI_1_araddr = 0; S_AXI_1_arburst = 0; S_AXI_1_arcache = 0;
    S_AXI_1_arlen = 0; S_AXI_1_arlock = 0; S_AXI_1_arprot = 0;
    S_AXI_1_arsize = 0; S_AXI_1_arvalid = 0; S_AXI_1_rready = 0;
    #20;
    reset_rtl = 1;
    #20;
    reset_rtl = 0;
    #20;
    // Program each row.
    // 1) Write matrix A into memory, then verify
    write_matrix_A();
    verify_matrix_A();
    
    $display("Memory programming complete.");
    #100;
    
    //-------------------------------------------------------------------------
    // Extraction Test.
    // First, trigger matrix load via load_start_extr.
    // Then, for cycles 0-14, pulse start_extr and compare the output.
    //-------------------------------------------------------------------------
    error_flag = 0;
    // Trigger matrix load for the extractor.
    $display("Triggering matrix load in extractor...");
    load_start_extr = 1;
    
    wait(matrix_loaded);
    @(posedge sys_clock);
    @(posedge sys_clock);
    
    // Test extraction for cycles 0 to 14.
    for (t = 0; t < 15; t = t + 1) begin
      // If your tool does not support t[3:0], use: cycle_extr = t & 4'hF;
      cycle_extr = t & 4'hF;
      start_extr = 1;
      
      @(posedge sys_clock);
      @(posedge sys_clock);
      // Wait until extraction valid is asserted.
      wait_cycles = 1;
      // while (!valid_extr && wait_cycles < 100) begin
      //   @(posedge sys_clock);
      //   wait_cycles = wait_cycles + 1;
      // end
      
      $display("Waiting for a_flat_out at extraction cycle %0d: %0d clock cycles elapsed", t, wait_cycles);
      
      expected = 64'd0;
      if (t <= 7) begin
        for (i_idx = 0; i_idx <= t; i_idx = i_idx + 1) begin
          expected_byte = (i_idx * 8) + ((t - i_idx) + 1);
          expected = expected | ( {56'd0, expected_byte} << (i_idx*8) );
        end
      end else begin
        for (i_idx = t - 7; i_idx < 8; i_idx = i_idx + 1) begin
          expected_byte = (i_idx * 8) + ((t - i_idx) + 1);
          expected = expected | ( {56'd0, expected_byte} << (i_idx*8) );
        end
      end
      
      if (a_flat_out_extr !== expected)
         $display("[ERROR] Cycle %0d: Expected 0x%016h, Got 0x%016h", t, expected, a_flat_out_extr);
      else
         $display("[PASS] Cycle %0d: Output 0x%016h matches expected.", t, a_flat_out_extr);
         
      // start_extr = 0;
      // wait_cycles = 2;
      // while (valid_extr && wait_cycles < 100) begin
      //   @(posedge sys_clock);
      //   wait_cycles = wait_cycles + 1;
      // end
    end
    
    $display("Extraction tests completed.");
    #50;
    $finish;
  end

  initial begin : timeout_watch
                #500000; // e.g. 100k ns
                $display("[ERROR] TIMEOUT: Stopping simulation.");
                $stop;
            end
  
endmodule