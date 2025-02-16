`timescale 1ns / 1ps

module tb_memory_block_wrapper;

    // Signals
    reg sys_clock;
    reg reset_rtl;
    
    // AXI4 Signals for S_AXI_1 (WRITE + READ Transactions)
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

    // READ SIGNALS
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
//   AXI4 Signals for S_AXI_0 (WRITE + READ Transactions)
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

    // READ SIGNALS
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

    // Instantiate DUT
    memory_block_wrapper DUT (
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
        .S_AXI_1_rvalid(S_AXI_1_rvalid),
        .reset_rtl(reset_rtl),
        .sys_clock(sys_clock)
    );

    // Generate 100MHz Clock
    always #5 sys_clock = ~sys_clock;

  // AXI4 WRITE Task (Single Transaction)
    task axi4_write(input flag, input [11:0] addr, input [31:0] data);
        integer timeout_counter;
        begin
            if (flag) begin
                @(posedge sys_clock);
                S_AXI_1_awaddr  = addr;
                S_AXI_1_awlen   = 8'h00;      // Single transfer
                S_AXI_1_awsize  = 3'b010;     // 4 bytes per transfer
                S_AXI_1_awburst = 2'b01;      // INCR mode
                S_AXI_1_awvalid = 1;
                // Wait for AWREADY
                @(posedge sys_clock);

                S_AXI_1_awvalid = 0;
                // Send Data
                S_AXI_1_wdata  = data;
                S_AXI_1_wstrb  = 4'b1111;     // Full word write
                S_AXI_1_wvalid = 1;
                S_AXI_1_wlast  = 1;
                S_AXI_1_bready = 1;
                @(posedge sys_clock);

                S_AXI_1_wvalid = 0;
                S_AXI_1_wlast  = 0;
                S_AXI_1_bready = 1;
                timeout_counter = 10;
                while (S_AXI_1_bvalid !== 1 && timeout_counter > 0) begin
                    @(posedge sys_clock);
                    timeout_counter = timeout_counter - 1;
                end
                S_AXI_1_bready = 0;

                $display("[TB] Write Complete: Addr = 0x%03X, Data = 0x%08X", addr, data);
            end
            else begin
                @(posedge sys_clock);
                S_AXI_0_awaddr  = addr;
                S_AXI_0_awlen   = 8'h00;      // Single transfer
                S_AXI_0_awsize  = 3'b010;     // 4 bytes per transfer
                S_AXI_0_awburst = 2'b01;      // INCR mode
                S_AXI_0_awvalid = 1;
                // Wait for AWREADY
                @(posedge sys_clock);

                S_AXI_0_awvalid = 0;
                // Sen0 Data
                S_AXI_0_wdata  = data;
                S_AXI_0_wstrb  = 4'b1111;     // Full word write
                S_AXI_0_wvalid = 1;
                S_AXI_0_wlast  = 1;
                S_AXI_0_bready = 1;
                @(posedge sys_clock);

                S_AXI_0_wvalid = 0;
                S_AXI_0_wlast  = 0;
                S_AXI_0_bready = 1;
                timeout_counter = 10;
                while (S_AXI_0_bvalid !== 1 && timeout_counter > 0) begin
                    @(posedge sys_clock);
                    timeout_counter = timeout_counter - 1;
                end
                S_AXI_0_bready = 0;

                $display("[TB] Write Complete: Addr = 0x%03X, Data = 0x%08X", addr, data);
            end
        end
    endtask

    task axi4_read(input flag, input [11:0] addr);
        integer timeout_counter;
        begin
            if (flag) begin
                @(posedge sys_clock);
                timeout_counter = 10;
                while (S_AXI_1_arready !== 1 && timeout_counter > 0) begin
                    @(posedge sys_clock);
                    timeout_counter = timeout_counter - 1;
                end
                S_AXI_1_araddr  = addr;
                S_AXI_1_arlen   = 8'h00;      // Single transfer
                S_AXI_1_arsize  = 3'b010;     // 4 bytes per transfer
                S_AXI_1_arburst = 2'b0;      // INCR mode
                S_AXI_1_arlock = 2'b0; 
                S_AXI_1_arvalid = 1;
                S_AXI_1_rready = 1;

                @(posedge sys_clock);
                S_AXI_1_arvalid = 0;
                timeout_counter = 10;
                while (S_AXI_1_rvalid !== 1 && S_AXI_1_rlast !== 1 && timeout_counter > 0) begin
                    @(posedge sys_clock);
                    timeout_counter = timeout_counter - 1;
                end
                $display("[TB] Read Complete: Addr = 0x%03X, Data = 0x%08X", addr, S_AXI_1_rdata);
                S_AXI_1_rready = 0;
            end
            else begin
                @(posedge sys_clock);
                timeout_counter = 10;
                while (S_AXI_0_arready !== 1 && timeout_counter > 0) begin
                    @(posedge sys_clock);
                    timeout_counter = timeout_counter - 1;
                end
                S_AXI_0_araddr  = addr;
                S_AXI_0_arlen   = 8'h00;      // Single transfer
                S_AXI_0_arsize  = 3'b010;     // 4 bytes per transfer
                S_AXI_0_arburst = 2'b0;      // INCR mode
                S_AXI_0_arlock = 2'b0; 
                S_AXI_0_arvalid = 1;
                S_AXI_0_rready = 1;

                @(posedge sys_clock);
                S_AXI_0_arvalid = 0;
                timeout_counter = 10;
                while (S_AXI_0_rvalid !== 1 && S_AXI_0_rlast !== 1 && timeout_counter > 0) begin
                    @(posedge sys_clock);
                    timeout_counter = timeout_counter - 1;
                end
                $display("[TB] Read Complete: Addr = 0x%03X, Data = 0x%08X", addr, S_AXI_0_rdata);
                S_AXI_0_rready = 0;
            end
        end
    endtask

    // Test Sequence
    initial begin
        // Initialize signals
        sys_clock   = 0;
        reset_rtl   = 1;
        S_AXI_1_awvalid = 0;
        S_AXI_1_wvalid  = 0;
        S_AXI_1_bready  = 0;
        S_AXI_0_awvalid = 0;
        S_AXI_0_wvalid  = 0;
        S_AXI_0_bready  = 0;

        S_AXI_1_arvalid  = 0;
        S_AXI_1_rready  = 0;
        S_AXI_0_arvalid  = 0;
        S_AXI_0_rready  = 0;
        S_AXI_1_arlock = 2'b0; 
        S_AXI_0_arlock = 2'b0; 

        // Apply Reset
        #10;
        reset_rtl = 0;
        #10;
        $display("[TB] Reset Deasserted.");

        // Perform an AXI4 Write Transaction
        axi4_write(1, 12'h100, 32'hDEADBEEF);
        axi4_read(1, 12'h100);
        axi4_read(0, 12'h100);
        axi4_write(0, 12'h100, 32'hBEEFDEAD);
        axi4_read(0, 12'h100);
        axi4_read(1, 12'h100);

        // End Simulation
        #10;
        $display("[TB] Test Completed.");
        $finish;
    end

// Timeout mechanism
    initial begin: tb_timeout
        #4000; // Simulation timeout
        $display("ERROR: Simulation timed out.");
        $finish;
    end
endmodule

