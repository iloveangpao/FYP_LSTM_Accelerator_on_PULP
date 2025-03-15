`timescale 1ns/1ps
module tb_writeback_integration;

  //===========================================================================
  // Clock & Reset
  //===========================================================================
  reg sys_clock;
  reg reset_rtl;
  
  initial begin
    sys_clock = 0;
    forever #5 sys_clock = ~sys_clock; // 100 MHz
  end

  //===========================================================================
  // S_AXI_0 Interface (for SoC programming & readback)
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
  // S_AXI_1 Interface
  //===========================================================================
  // The memory block wrapper exposes S_AXI_1 which is used by the writeback
  // controller for write transactions (AW, W, B) and by the testbench for reads (AR, R).
  // For the read channels we drive signals via a set of TB registers.
  //-------------------------------------------------------------------------
  // Write channels (driven by the writeback_controller)
  // Intermediate `reg` signals (Driven by `writeback_controller`)

  // `wire` signals (Connected to `memory_block_wrapper`)
  wire [11:0] S_AXI_1_awaddr  ;
  wire [1:0]  S_AXI_1_awburst ;
  wire [3:0]  S_AXI_1_awcache ;
  wire [7:0]  S_AXI_1_awlen   ;
  wire        S_AXI_1_awlock  ;
  wire [2:0]  S_AXI_1_awprot  ;
  wire [2:0]  S_AXI_1_awsize  ;
  wire        S_AXI_1_awvalid ;

  wire [31:0] S_AXI_1_wdata  ;
  wire        S_AXI_1_wlast  ;
  wire [3:0]  S_AXI_1_wstrb  ;
  wire        S_AXI_1_wvalid ;

  wire        S_AXI_1_bready;
  wire        S_AXI_1_awready, S_AXI_1_wready;
  wire [1:0]  S_AXI_1_bresp;
  wire        S_AXI_1_bvalid;
  
  // Read channels (driven by the testbench master)
  reg  [11:0] S_AXI_1_araddr;
  reg  [1:0]  S_AXI_1_arburst;
  reg  [3:0]  S_AXI_1_arcache;
  reg  [7:0]  S_AXI_1_arlen;
  reg         S_AXI_1_arlock;
  reg  [2:0]  S_AXI_1_arprot;
  reg  [2:0]  S_AXI_1_arsize;
  reg         S_AXI_1_arvalid;
  wire        S_AXI_1_arready;
  
  reg         S_AXI_1_rready;
  wire [31:0] S_AXI_1_rdata;
  wire        S_AXI_1_rlast;
  wire [1:0]  S_AXI_1_rresp;
  wire        S_AXI_1_rvalid;

  //===========================================================================
  // Instantiate Memory Block Wrapper
  //===========================================================================
  memory_block_wrapper mem_dut (
    .sys_clock(sys_clock),
    .reset_rtl(reset_rtl),
    // S_AXI_0: exposed to the SoC (programming and readback)
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
    // S_AXI_1: For write transactions use signals from writeback controller,
    // and for reads, the testbench drives AR and rready.
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
    // For read channels, connect to testbench-driven signals:
    .S_AXI_1_araddr(S_AXI_1_araddr),      // Not driven internally by another module.
    .S_AXI_1_arburst(S_AXI_1_arburst),
    .S_AXI_1_arcache(S_AXI_1_arcache),
    .S_AXI_1_arlen(S_AXI_1_arlen),
    .S_AXI_1_arlock(S_AXI_1_arlock),
    .S_AXI_1_arprot(S_AXI_1_arprot),
    .S_AXI_1_arready(S_AXI_1_arready),     // Will be driven by the memory.
    .S_AXI_1_arsize(S_AXI_1_arsize),
    .S_AXI_1_arvalid(S_AXI_1_arvalid),
    .S_AXI_1_rdata(S_AXI_1_rdata),
    .S_AXI_1_rlast(S_AXI_1_rlast),
    .S_AXI_1_rready(S_AXI_1_rready),       // Not used since testbench drives AR/R externally.
    .S_AXI_1_rresp(S_AXI_1_rresp),
    .S_AXI_1_rvalid(S_AXI_1_rvalid)
  );
  
  //===========================================================================
  // Instantiate Writeback Controller
  //===========================================================================
  // This controller writes 64 words (2048 bits) to memory via AXI1 (write channels).
  // We'll use a dummy Cout pattern.
  reg         wb_start;
  reg [2047:0] dummy_cout;
  reg [11:0]  wb_base_addr;
  wire        wb_done;
  
  writeback_controller wb_ctrl (
    .clk(sys_clock),
    .rst(reset_rtl),
    .start(wb_start),
    .c_in_flat(dummy_cout),
    .base_addr(wb_base_addr),
    
    .m_axi_awaddr(S_AXI_1_awaddr),
    .m_axi_awburst(S_AXI_1_awburst),
    .m_axi_awcache(S_AXI_1_awcache),
    .m_axi_awlen(S_AXI_1_awlen),
    .m_axi_awlock(S_AXI_1_awlock),
    .m_axi_awprot(S_AXI_1_awprot),
    .m_axi_awsize(S_AXI_1_awsize),
    .m_axi_awvalid(S_AXI_1_awvalid),
    .m_axi_awready(S_AXI_1_awready),

    // AXI Write Data Channel
    .m_axi_wdata(S_AXI_1_wdata),
    .m_axi_wlast(S_AXI_1_wlast),
    .m_axi_wstrb(S_AXI_1_wstrb),
    .m_axi_wvalid(S_AXI_1_wvalid),
    .m_axi_wready(S_AXI_1_wready),

    // AXI Write Response Channel
    .m_axi_bready(S_AXI_1_bready),
    .m_axi_bresp(S_AXI_1_bresp),
    .m_axi_bvalid(S_AXI_1_bvalid),
    
    .done(wb_done)
  );
  
  //===========================================================================
  // Testbench Tasks for AXI4 Write/Read on S_AXI_0 and S_AXI_1 (Read Channels)
  //===========================================================================
  // S_AXI_0 Write Task (for programming memory)
  task axi4_write_S0(input [11:0] addr, input [31:0] data);
    integer timeout_counter;
    begin
      // reset_signals();
      @(posedge sys_clock);
      timeout_counter = 10;
      while (S_AXI_0_awready !== 0 && S_AXI_0_wready !== 1 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_awaddr  = addr;
      S_AXI_0_awlen   = 8'h00;
      S_AXI_0_awsize  = 3'b010;
      S_AXI_0_awburst = 2'b00;
      S_AXI_0_awvalid = 1;
      S_AXI_0_wdata   = data;
      S_AXI_0_wstrb   = 4'b1111;
      S_AXI_0_wvalid  = 1;
      S_AXI_0_wlast   = 1;
      S_AXI_0_bready  = 1;
      @(posedge sys_clock);
      S_AXI_0_wvalid  = 0;
      S_AXI_0_awvalid = 0;
      S_AXI_0_wlast   = 0;
      timeout_counter = 10;
      while (S_AXI_0_bvalid !== 1 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_bready = 0;
      $display("[TB] S_AXI_0 Write: Addr = 0x%08h, Data = 0x%08h", addr, data);
    end
  endtask
  
  // S_AXI_0 Read Task
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
      S_AXI_0_arlen   = 8'h00;
      S_AXI_0_arsize  = 3'b010;
      S_AXI_0_arburst = 2'b00;
      S_AXI_0_arlock  = 0;
      S_AXI_0_arvalid = 1;
      @(posedge sys_clock);
      S_AXI_0_arvalid = 0;
      // @(posedge sys_clock);
      // @(posedge sys_clock);
      S_AXI_0_rready  = 1;
      @(posedge sys_clock);
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
  
  // S_AXI_1 Read Task (for read channel; drives TB signals)
  task axi4_read_S1(input [11:0] addr, output [31:0] data);
    integer timeout_counter;
    begin
      @(posedge sys_clock);
      timeout_counter = 10;
      while (S_AXI_1_arready !== 0 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      S_AXI_1_araddr  = addr;
      S_AXI_1_arlen   = 8'h00;
      S_AXI_1_arsize  = 3'b010;
      S_AXI_1_arburst = 2'b00;
      S_AXI_1_arlock  = 0;
      S_AXI_1_arvalid = 1;
      @(posedge sys_clock);
      S_AXI_1_arvalid = 0;
      // @(posedge sys_clock);
      // @(posedge sys_clock);
      S_AXI_1_rready  = 1;
      @(posedge sys_clock);
      timeout_counter = 10;
      while (S_AXI_1_rvalid !== 1 && timeout_counter > 0) begin
         @(posedge sys_clock);
         timeout_counter = timeout_counter - 1;
      end
      data = S_AXI_1_rdata;
      S_AXI_1_rready = 0;
      $display("[TB] S_AXI_1 Read: Addr = 0x%03h, Data = 0x%08h", addr, data);
    end
  endtask

  task reset_signals(); begin
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

    S_AXI_1_araddr = 0;
    S_AXI_1_arburst = 0;
    S_AXI_1_arcache = 0;
    S_AXI_1_arlen = 0;
    S_AXI_1_arlock = 0;
    S_AXI_1_arprot = 0;
    S_AXI_1_arsize = 0;
    S_AXI_1_arvalid = 0;
  end
    endtask
  
  //===========================================================================
  // Test Sequence
  //===========================================================================
  integer i, row;
  reg [31:0] word_data;
  reg [31:0] expected_word;
  
  initial begin

    reset_rtl = 1;
    #20;
    reset_signals();
    // wb_start = 0;
    reset_rtl = 0;
    #50;


    // --- Phase 1: Basic Memory Write/Read Test ---
    $display("-----------------------------------------------------");
    $display("[TB] Phase 1: Testing basic S_AXI_0 and S_AXI_1 write/read");
    $display("-----------------------------------------------------");
    // Write a known pattern to memory via S_AXI_0 at addresses 200-203
    for (i = 0; i < 16; i = i + 4) begin
      axi4_write_S0(12'h200 + i, 32'hA0000000 + i/4);
    end
    reset_signals();
    #20;
    // Read back via S_AXI_0
    for (i = 0; i < 16; i = i + 4) begin
      axi4_read_S0(12'h200 + i, word_data);
      // #20;
      if (word_data !== (32'hA0000000 + i/4)) begin
        $display("[ERROR] S_AXI_0 basic read failed at addr %0d", 200+i);
        $finish;
      end
    end
    reset_signals();
    #20;
    // Read back via S_AXI_1 (using testbench driven read)
    for (i = 0; i < 16; i = i + 4) begin
      axi4_read_S1(12'h200 + i, word_data);
      if (word_data !== (32'hA0000000 + i/4)) begin
        $display("[ERROR] S_AXI_1 basic read failed at addr %0d", 200+i);
        $finish;
      end
    end
    $display("[TB] Basic memory write/read tests passed.");
    
    // --- Phase 2: Writeback Controller Test ---
    $display("-----------------------------------------------------");
    $display("[TB] Phase 2: Testing writeback controller");
    $display("-----------------------------------------------------");
    // Prepare dummy Cout data: 64 words (each word = index+1)
    dummy_cout = 2048'd0;
    for (i = 0; i < 64; i = i + 1) begin
      dummy_cout[i*32 +: 32] = i + 1;
    end
    // Choose a base address for Cout (e.g., 12'd300)
    wb_base_addr = 12'd300;
    
    // Trigger the writeback controller.
    wb_start = 1;
    @(posedge sys_clock);
    wb_start = 0;
    // Wait for wb_done to be asserted.
    wait(wb_done);
    #20;
    $display("[TB] Writeback controller signaled done.");
    
    // Now, read back the 64 written words from memory via S_AXI_0.
    for (i = 0; i < 64; i = i + 1) begin
      axi4_read_S0(wb_base_addr + i * 4, word_data);
      expected_word = i + 1;
      if (word_data !== expected_word) begin
        $display("[ERROR] Writeback data mismatch on S_AXI_0 at addr %08h: Expected 0x%08h, Got 0x%08h",
                 wb_base_addr + i, expected_word, word_data);
        $finish;
      end
    end
    $display("[TB] S_AXI_0 readback after writeback passed.");
    
    // And read back via S_AXI_1.
    for (i = 0; i < 64; i = i + 1) begin
      axi4_read_S1(wb_base_addr + i * 4, word_data);
      expected_word = i + 1;
      if (word_data !== expected_word) begin
        $display("[ERROR] Writeback data mismatch on S_AXI_1 at addr %08h: Expected 0x%08h, Got 0x%08h",
                 wb_base_addr + i, expected_word, word_data);
        $finish;
      end
    end
    $display("[TB] S_AXI_1 readback after writeback passed.");
    
    $display("-----------------------------------------------------");
    $display("[TB] All writeback tests passed successfully.");
    $display("-----------------------------------------------------");
    #50;
    $finish;
  end

  //===========================================================================
  // Overall Simulation Timeout
  //===========================================================================
  initial begin
    #60000;
    $display("[ERROR] Simulation timed out.");
    $finish;
  end

  // initial begin
  //   $monitor("[TB DEBUG] Time=%0t | State=%0d | WordCount=%0d", sys_clock, wb_ctrl.debug_state, wb_ctrl.debug_word_count);
  // end

endmodule
