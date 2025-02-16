`timescale 1ns / 1ps

module tb_memory_block_wrapper;

   // System Signals
  reg sys_clock;
  reg reset_rtl;
  wire locked_0;  // Wait for PLL lock before transactions

  // AXI4 Write Signals for S_AXI_0
  reg  [11:0] S_AXI_0_awaddr;
  reg  [7:0]  S_AXI_0_awlen;
  reg  [2:0]  S_AXI_0_awsize;
  reg  [1:0]  S_AXI_0_awburst;
  reg         S_AXI_0_awvalid;
  wire        S_AXI_0_awready;
  reg  [31:0] S_AXI_0_wdata;
  reg  [3:0]  S_AXI_0_wstrb;
  reg         S_AXI_0_wvalid;
  wire        S_AXI_0_wready;
  reg         S_AXI_0_wlast;
  reg         S_AXI_0_bready;
  wire        S_AXI_0_bvalid;
  wire [1:0]  S_AXI_0_bresp;

  // AXI4 Read Signals for S_AXI_0
  reg  [11:0] S_AXI_0_araddr;
  reg  [7:0]  S_AXI_0_arlen;
  reg  [2:0]  S_AXI_0_arsize;
  reg  [1:0]  S_AXI_0_arburst;
  reg         S_AXI_0_arvalid;
  wire        S_AXI_0_arready;
  wire [31:0] S_AXI_0_rdata;
  wire        S_AXI_0_rvalid;
  reg         S_AXI_0_rready;
  wire [1:0]  S_AXI_0_rresp;

  // AXI4 Write Signals for S_AXI_1
  reg  [11:0] S_AXI_1_awaddr;
  reg  [7:0]  S_AXI_1_awlen;
  reg  [2:0]  S_AXI_1_awsize;
  reg  [1:0]  S_AXI_1_awburst;
  reg         S_AXI_1_awvalid;
  wire        S_AXI_1_awready;
  reg  [31:0] S_AXI_1_wdata;
  reg  [3:0]  S_AXI_1_wstrb;
  reg         S_AXI_1_wvalid;
  wire        S_AXI_1_wready;
  reg         S_AXI_1_wlast;
  reg         S_AXI_1_bready;
  wire        S_AXI_1_bvalid;
  wire [1:0]  S_AXI_1_bresp;

  // AXI4 Read Signals for S_AXI_1
  reg  [11:0] S_AXI_1_araddr;
  reg  [7:0]  S_AXI_1_arlen;
  reg  [2:0]  S_AXI_1_arsize;
  reg  [1:0]  S_AXI_1_arburst;
  reg         S_AXI_1_arvalid;
  wire        S_AXI_1_arready;
  wire [31:0] S_AXI_1_rdata;
  wire        S_AXI_1_rvalid;
  reg         S_AXI_1_rready;
  wire [1:0]  S_AXI_1_rresp;

  // Instantiate DUT
  memory_block_wrapper DUT (
      .S_AXI_0_awaddr(S_AXI_0_awaddr),
      .S_AXI_0_awvalid(S_AXI_0_awvalid),
      .S_AXI_0_awready(S_AXI_0_awready),
      .S_AXI_0_wdata(S_AXI_0_wdata),
      .S_AXI_0_wvalid(S_AXI_0_wvalid),
      .S_AXI_0_wready(S_AXI_0_wready),
      .S_AXI_0_bvalid(S_AXI_0_bvalid),
      .S_AXI_0_bready(S_AXI_0_bready),
      .S_AXI_0_araddr(S_AXI_0_araddr),
      .S_AXI_0_arvalid(S_AXI_0_arvalid),
      .S_AXI_0_arready(S_AXI_0_arready),
      .S_AXI_0_rdata(S_AXI_0_rdata),
      .S_AXI_0_rvalid(S_AXI_0_rvalid),
      .S_AXI_0_rready(S_AXI_0_rready),

      .S_AXI_1_awaddr(S_AXI_1_awaddr),
      .S_AXI_1_awvalid(S_AXI_1_awvalid),
      .S_AXI_1_awready(S_AXI_1_awready),
      .S_AXI_1_wdata(S_AXI_1_wdata),
      .S_AXI_1_wvalid(S_AXI_1_wvalid),
      .S_AXI_1_wready(S_AXI_1_wready),
      .S_AXI_1_bvalid(S_AXI_1_bvalid),
      .S_AXI_1_bready(S_AXI_1_bready),
      .S_AXI_1_araddr(S_AXI_1_araddr),
      .S_AXI_1_arvalid(S_AXI_1_arvalid),
      .S_AXI_1_arready(S_AXI_1_arready),
      .S_AXI_1_rdata(S_AXI_1_rdata),
      .S_AXI_1_rvalid(S_AXI_1_rvalid),
      .S_AXI_1_rready(S_AXI_1_rready),

      .reset_rtl(reset_rtl),
      .sys_clock(sys_clock)
  );

  // Generate 100MHz Clock
  always #5 sys_clock = ~sys_clock;

  // Wait for PLL Lock
  task wait_for_locked;
    begin
      $display("[TB] Waiting for PLL to lock...");
      while (locked_0 !== 1) begin
        @(posedge sys_clock);
      end
      $display("[TB] PLL Locked! Starting Transactions...");
    end
  endtask

 task axi4_write(input integer port, input [11:0] addr, input [31:0] data);
  integer timeout_counter;
  begin
    @(posedge sys_clock);

    if (port == 0) begin
      S_AXI_0_awaddr  = addr;
      S_AXI_0_awlen   = 8'h00;      // Single transfer
      S_AXI_0_awsize  = 3'b010;     // 4 bytes per transfer
      S_AXI_0_awburst = 2'b01;      // INCR mode
      S_AXI_0_awvalid = 1;
      @(posedge sys_clock);

      S_AXI_0_awvalid = 0;
      S_AXI_0_wdata  = data;
      S_AXI_0_wstrb  = 4'b1111;     // Full word write
      S_AXI_0_wvalid = 1;
      S_AXI_0_wlast  = 1;
      S_AXI_0_bready = 1;
      @(posedge sys_clock);

      S_AXI_0_wvalid = 0;
      S_AXI_0_wlast  = 0;
      timeout_counter = 10;
      while (S_AXI_0_bvalid !== 1 && timeout_counter > 0) begin
        @(posedge sys_clock);
        timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_bready = 0;
      $display("[TB] Write Complete: S_AXI_0 Addr = 0x%03X, Data = 0x%08X", addr, data);

    end else if (port == 1) begin
      S_AXI_1_awaddr  = addr;
      S_AXI_1_awlen   = 8'h00;
      S_AXI_1_awsize  = 3'b010;
      S_AXI_1_awburst = 2'b01;
      S_AXI_1_awvalid = 1;
      @(posedge sys_clock);

      S_AXI_1_awvalid = 0;
      S_AXI_1_wdata  = data;
      S_AXI_1_wstrb  = 4'b1111;
      S_AXI_1_wvalid = 1;
      S_AXI_1_wlast  = 1;
      S_AXI_1_bready = 1;
      @(posedge sys_clock);

      S_AXI_1_wvalid = 0;
      S_AXI_1_wlast  = 0;
      timeout_counter = 10;
      while (S_AXI_1_bvalid !== 1 && timeout_counter > 0) begin
        @(posedge sys_clock);
        timeout_counter = timeout_counter - 1;
      end
      S_AXI_1_bready = 0;
      $display("[TB] Write Complete: S_AXI_1 Addr = 0x%03X, Data = 0x%08X", addr, data);
    end
  end
endtask

task axi4_read(input integer port, input [11:0] addr);
  integer timeout_counter;
  begin
    @(posedge sys_clock);

    if (port == 0) begin
      S_AXI_0_araddr  = addr;
      S_AXI_0_arlen   = 8'h00;
      S_AXI_0_arsize  = 3'b010;
      S_AXI_0_arburst = 2'b01;
      S_AXI_0_arvalid = 1;

      timeout_counter = 10;
      while (S_AXI_0_arready !== 1 && timeout_counter > 0) begin
        @(posedge sys_clock);
        timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_arvalid = 0;

      S_AXI_0_rready = 1;
      timeout_counter = 10;
      while (S_AXI_0_rvalid !== 1 && timeout_counter > 0) begin
        @(posedge sys_clock);
        timeout_counter = timeout_counter - 1;
      end
      S_AXI_0_rready = 0;
      $display("[TB] Read Complete: S_AXI_0 Addr = 0x%03X, Data = 0x%08X", addr, S_AXI_0_rdata);

    end else if (port == 1) begin
      S_AXI_1_araddr  = addr;
      S_AXI_1_arlen   = 8'h00;
      S_AXI_1_arsize  = 3'b010;
      S_AXI_1_arburst = 2'b01;
      S_AXI_1_arvalid = 1;

      timeout_counter = 10;
      while (S_AXI_1_arready !== 1 && timeout_counter > 0) begin
        @(posedge sys_clock);
        timeout_counter = timeout_counter - 1;
      end
      S_AXI_1_arvalid = 0;

      S_AXI_1_rready = 1;
      timeout_counter = 10;
      while (S_AXI_1_rvalid !== 1 && timeout_counter > 0) begin
        @(posedge sys_clock);
        timeout_counter = timeout_counter - 1;
      end
      S_AXI_1_rready = 0;
      $display("[TB] Read Complete: S_AXI_1 Addr = 0x%03X, Data = 0x%08X", addr, S_AXI_1_rdata);
    end
  end
endtask

initial begin
  sys_clock = 0;
  reset_rtl = 1;
    S_AXI_0_awvalid = 0;
    S_AXI_0_wvalid  = 0;
    S_AXI_0_bready  = 0;
    S_AXI_1_awvalid = 0;
    S_AXI_1_wvalid  = 0;
    S_AXI_1_bready  = 0;
  #100;
  reset_rtl = 0;

    #100;
  // Write and Read for S_AXI_0
  axi4_write(0, 12'h100, 32'hDEADBEEF);
  axi4_read(0, 12'h100);
    #100;
  // Write and Read for S_AXI_1
  axi4_write(1, 12'h200, 32'hFACEFEED);
  axi4_read(1, 12'h200);

  #100;
  $finish;
end


// Timeout mechanism
    initial begin: tb_timeout
        #4000; // Simulation timeout
        $display("ERROR: Simulation timed out.");
        $finish;
    end
endmodule

