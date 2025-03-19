`timescale 1ns/1ps

module tb_top_systolic_integration;

    // -------------------------------------------------------------------------
    // Parameters (match your top_systolic_integration if needed)
    // -------------------------------------------------------------------------
    parameter APB_ADDR_WIDTH = 8;
    parameter AXI_ADDR_WIDTH = 12;
    parameter AXI_DATA_WIDTH = 32;
    parameter DATA_WIDTH     = 8;
    parameter ACC_WIDTH      = 32;

    // These addresses must match the base addresses in your design
    parameter BASE_ADDR_A = 12'h000;
    parameter BASE_ADDR_B = 12'h100;
    parameter BASE_ADDR_C = 12'h200;

    // For an 8x8 multiply, we typically have 15 diagonals (0..14).
    // The top module might be hard-coded to do that many cycles.

    // -------------------------------------------------------------------------
    // DUT I/O
    // -------------------------------------------------------------------------
    logic                     sys_clock;
    logic                     sys_reset;   // Active-high or active-low, adapt as needed

    // APB
    logic                     PCLK;
    logic                     PRESETn;     // Active-low
    logic                     PSEL;
    logic                     PENABLE;
    logic                     PWRITE;
    logic [APB_ADDR_WIDTH-1:0] PADDR;
    logic [31:0]             PWDATA;
    logic [31:0]             PRDATA;
    logic                     PREADY;
    logic                     PSLVERR;

    // AXI4 Slave Interface #0 (for SoC → memory)
    logic [AXI_ADDR_WIDTH-1:0] S_AXI_0_awaddr;
    logic [1:0]                S_AXI_0_awburst;
    logic [3:0]                S_AXI_0_awcache;
    logic [7:0]                S_AXI_0_awlen;
    logic                      S_AXI_0_awlock;
    logic [2:0]                S_AXI_0_awprot;
    logic                      S_AXI_0_awready;
    logic [2:0]                S_AXI_0_awsize;
    logic                      S_AXI_0_awvalid;
    logic                      S_AXI_0_bready;
    logic [1:0]                S_AXI_0_bresp;
    logic                      S_AXI_0_bvalid;
    logic [AXI_DATA_WIDTH-1:0] S_AXI_0_wdata;
    logic                      S_AXI_0_wlast;
    logic                      S_AXI_0_wready;
    logic [3:0]                S_AXI_0_wstrb;
    logic                      S_AXI_0_wvalid;
    logic [AXI_ADDR_WIDTH-1:0] S_AXI_0_araddr;
    logic [1:0]                S_AXI_0_arburst;
    logic [3:0]                S_AXI_0_arcache;
    logic [7:0]                S_AXI_0_arlen;
    logic                      S_AXI_0_arlock;
    logic [2:0]                S_AXI_0_arprot;
    logic                      S_AXI_0_arready;
    logic [2:0]                S_AXI_0_arsize;
    logic                      S_AXI_0_arvalid;
    logic [AXI_DATA_WIDTH-1:0] S_AXI_0_rdata;
    logic                      S_AXI_0_rlast;
    logic                      S_AXI_0_rready;
    logic [1:0]                S_AXI_0_rresp;
    logic                      S_AXI_0_rvalid;
    logic locked;

    // -------------------------------------------------------------------------
    // Instantiate the DUT
    // -------------------------------------------------------------------------
    top_systolic_integration #(
        .APB_ADDR_WIDTH (APB_ADDR_WIDTH),
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ACC_WIDTH      (ACC_WIDTH),
        .BASE_ADDR_A    (BASE_ADDR_A),
        .BASE_ADDR_B    (BASE_ADDR_B),
        .BASE_ADDR_C    (BASE_ADDR_C)
    ) dut (
        .sys_clock       (sys_clock),
        .sys_reset       (sys_reset),

        // APB
        .PCLK            (PCLK),
        .PRESETn         (PRESETn),
        .PSEL            (PSEL),
        .PENABLE         (PENABLE),
        .PWRITE          (PWRITE),
        .PADDR           (PADDR),
        .PWDATA          (PWDATA),
        .PRDATA          (PRDATA),
        .PREADY          (PREADY),
        .PSLVERR         (PSLVERR),

        // AXI4 #0
        .S_AXI_0_awaddr  (S_AXI_0_awaddr),
        .S_AXI_0_awburst (S_AXI_0_awburst),
        .S_AXI_0_awcache (S_AXI_0_awcache),
        .S_AXI_0_awlen   (S_AXI_0_awlen),
        .S_AXI_0_awlock  (S_AXI_0_awlock),
        .S_AXI_0_awprot  (S_AXI_0_awprot),
        .S_AXI_0_awready (S_AXI_0_awready),
        .S_AXI_0_awsize  (S_AXI_0_awsize),
        .S_AXI_0_awvalid (S_AXI_0_awvalid),
        .S_AXI_0_bready  (S_AXI_0_bready),
        .S_AXI_0_bresp   (S_AXI_0_bresp),
        .S_AXI_0_bvalid  (S_AXI_0_bvalid),
        .S_AXI_0_wdata   (S_AXI_0_wdata),
        .S_AXI_0_wlast   (S_AXI_0_wlast),
        .S_AXI_0_wready  (S_AXI_0_wready),
        .S_AXI_0_wstrb   (S_AXI_0_wstrb),
        .S_AXI_0_wvalid  (S_AXI_0_wvalid),
        .S_AXI_0_araddr  (S_AXI_0_araddr),
        .S_AXI_0_arburst (S_AXI_0_arburst),
        .S_AXI_0_arcache (S_AXI_0_arcache),
        .S_AXI_0_arlen   (S_AXI_0_arlen),
        .S_AXI_0_arlock  (S_AXI_0_arlock),
        .S_AXI_0_arprot  (S_AXI_0_arprot),
        .S_AXI_0_arready (S_AXI_0_arready),
        .S_AXI_0_arsize  (S_AXI_0_arsize),
        .S_AXI_0_arvalid (S_AXI_0_arvalid),
        .S_AXI_0_rdata   (S_AXI_0_rdata),
        .S_AXI_0_rlast   (S_AXI_0_rlast),
        .S_AXI_0_rready  (S_AXI_0_rready),
        .S_AXI_0_rresp   (S_AXI_0_rresp),
        .S_AXI_0_rvalid  (S_AXI_0_rvalid),
        .clk_locked(locked)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    // sys_clock -> for HPC logic
    always #5 sys_clock = ~sys_clock;

    // PCLK -> for APB logic
    always #7 PCLK = ~PCLK;

    // -------------------------------------------------------------------------
    // Reset logic
    // -------------------------------------------------------------------------
    initial begin
        sys_clock = 0;
        PCLK      = 0;
        sys_reset = 1;
        PRESETn   = 0;

        // Hold reset for ~2 cycles of each clock
        repeat(4) @(posedge sys_clock);
        sys_reset = 0;
        repeat(2) @(posedge PCLK);
        PRESETn   = 1;

        $display("[TB] Reset Deasserted at time %t", $time);
    end

    // -------------------------------------------------------------------------
    // APB Master Tasks
    // -------------------------------------------------------------------------
    task apb_write(
        input [APB_ADDR_WIDTH-1:0] addr,
        input [31:0]               data
    );
        begin
            @(posedge PCLK);
            PSEL    <= 1'b1;
            PWRITE  <= 1'b1;
            PADDR   <= addr;
            PWDATA  <= data;
            PENABLE <= 1'b0;
            @(posedge PCLK);
            // Enable
            PENABLE <= 1'b1;
            @(posedge PCLK);
            // De-assert
            PSEL    <= 1'b0;
            PWRITE  <= 1'b0;
            PENABLE <= 1'b0;
            $display("[TB:APB] Wrote 0x%08h to 0x%02h at time %t", data, addr, $time);
        end
    endtask

    task apb_read(
        input [APB_ADDR_WIDTH-1:0] addr,
        output [31:0]              data
    );
        begin
            @(posedge PCLK);
            PSEL    <= 1'b1;
            PWRITE  <= 1'b0;
            PADDR   <= addr;
            PENABLE <= 1'b0;
            @(posedge PCLK);
            // Enable
            PENABLE <= 1'b1;
            @(posedge PCLK);
            data    = PRDATA;
            // De-assert
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            // $display("[TB:APB] Read 0x%08h from 0x%02h at time %t", data, addr, $time);
        end
    endtask

    reg [7:0] byte0, byte1, byte2, byte3;

    // -------------------------------------------------------------------------
    // AXI4 Single-Write Task (Simplified)
    // -------------------------------------------------------------------------
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

            timeout_counter = 10;
            while (S_AXI_0_awready !== 1 && timeout_counter > 0) begin
                @(posedge sys_clock);
                timeout_counter = timeout_counter - 1;
            end

            // timeout_counter = 10;
            // while (S_AXI_0_awready !== 0 && timeout_counter > 0) begin
            //     @(posedge sys_clock);
            //     timeout_counter = timeout_counter - 1;
            // end
            // @(negedge S_AXI_0_awready);
            S_AXI_0_awvalid = 0;
            S_AXI_0_wdata   = data;
            S_AXI_0_wstrb   = 4'b1111;
            S_AXI_0_wvalid  = 1;
            S_AXI_0_wlast   = 1;
            S_AXI_0_bready  = 1;
            @(posedge sys_clock);
            S_AXI_0_wvalid  = 0;
            S_AXI_0_wlast   = 0;
            
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

    task write_matrix_B;
        integer col;
        reg [31:0] word0, word1;
        begin
            $display("[TB] Writing test matrix B into memory (column-major order)...");
            // Loop over each column (0 through 7)
            for (col = 0; col < 8; col++) begin
                // Pack the first four elements (rows 0..3) of this column into word0
                byte0 = col*8 + 1; // A[row][0]
                byte1 = col*8 + 2; // A[row][1]
                byte2 = col*8 + 3; // A[row][2]
                byte3 = col*8 + 4; // A[row][3]
                word0 = {byte3, byte2, byte1, byte0}; 
                axi4_single_write(BASE_ADDR_B + col*8 + 0, word0);

                byte0 = col*8 + 5; // A[row][4]
                byte1 = col*8 + 6; // A[row][5]
                byte2 = col*8 + 7; // A[row][6]
                byte3 = col*8 + 8; // A[row][7]
                word1 = {byte3, byte2, byte1, byte0};
                axi4_single_write(BASE_ADDR_B + col*8 + 4, word1);
            end
        end
    endtask


    task verify_matrix_B;
        integer col;
        reg [31:0] read_back, expected0, expected1;
        begin
            $display("[TB] Verifying test matrix B in memory (column-major order)...");
            // Loop over each column (0 through 7)
            for (col = 0; col < 8; col++) begin
                // Expected word for rows 0..3 of column 'col'
                byte0 = col*8 + 1; // A[row][0]
                byte1 = col*8 + 2; // A[row][1]
                byte2 = col*8 + 3; // A[row][2]
                byte3 = col*8 + 4; // A[row][3]
                expected0 = {byte3, byte2, byte1, byte0}; 
                axi4_single_read(BASE_ADDR_B + col*8 + 0, read_back);
                if (read_back !== expected0) begin
                    $display("[ERROR] B col=%0d word0 mismatch. Read=0x%08h, Exp=0x%08h, Addr=0x%03h", 
                            col, read_back, expected0, BASE_ADDR_B + col*8 + 0);
                    $stop;
                end

                // Expected word for rows 4..7 of column 'col'

                byte0 = col*8 + 5; // A[row][4]
                byte1 = col*8 + 6; // A[row][5]
                byte2 = col*8 + 7; // A[row][6]
                byte3 = col*8 + 8; // A[row][7]
                expected1 = {byte3, byte2, byte1, byte0};
                axi4_single_read(BASE_ADDR_B + col*8 + 4, read_back);
                if (read_back !== expected1) begin
                    $display("[ERROR] B col=%0d word1 mismatch. Read=0x%08h, Exp=0x%08h", 
                            col, read_back, expected1);
                    $stop;
                end
            end
            $display("[TB] B matrix verification PASSED!");
        end
    endtask

    // -------------------------------------------------------------------------
    // Golden Computation for 8x8 (C = A×B)
    // For demonstration, we do a trivial approach or replicate your known pattern
    // -------------------------------------------------------------------------
    function [64*ACC_WIDTH-1:0] compute_golden_C;
        integer i, j;
        reg [ACC_WIDTH-1:0] element;
        reg [64*ACC_WIDTH-1:0] golden;
        begin
            golden = 0;
            // Loop over rows and columns of matrix C
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    // Each C[i][j] is computed as: 
                    // 512*i*j + 288*i + 288*j + 204
                    element = 512 * i * j + 288 * i + 288 * j + 204;
                    // Pack element into the flattened golden vector
                    // Assuming row-major packing: position = (i*8 + j)
                    golden = golden | (element << ((i*8 + j)*ACC_WIDTH));
                end
            end
            compute_golden_C = golden;
        end

    endfunction

    // -------------------------------------------------------------------------
    // Check final memory for the computed matrix C
    // (the writeback_controller presumably wrote it starting at BASE_ADDR_C)
    // -------------------------------------------------------------------------
    task check_matrix_C;
        reg [31:0] read_word;
        reg [64*ACC_WIDTH-1:0] golden_C;
        reg [ACC_WIDTH-1:0]    c_element;
        integer i;
        begin
            $display("[TB] Checking final matrix C in memory...");
            golden_C = compute_golden_C();
            // The user must adapt how C is stored in memory. 
            // If the writeback writes 64 words at consecutive addresses, do:
            for (i = 0; i < 64; i++) begin
                // e.g. read BASE_ADDR_C + i
                axi4_single_read(BASE_ADDR_C + i*4, read_word);
                // Compare read_word to golden_C (we must parse which bits).
                // This depends on how the writeback wrote them out (acc_width? partial?)
                // We'll do a simple placeholder check:
                c_element = golden_C[(i*ACC_WIDTH)+:ACC_WIDTH];
                if (read_word !== c_element[31:0]) begin
                    $display("[ERROR] Mismatch at C[%0d]: read=0x%08h, gold=0x%08h", i, read_word, c_element[31:0]);
                    $stop;
                end
            end
            $display("[TB] Final matrix C check passed (assuming simplified compare).");
        end
    endtask
    reg [31:0] status_val;
    // -------------------------------------------------------------------------
    // Test Sequences
    // -------------------------------------------------------------------------
    initial begin : MAIN_TEST
        
        reg [31:0] read_data;

        S_AXI_0_awaddr = 0;
        S_AXI_0_awburst = 0;
        S_AXI_0_awcache = 0;
        S_AXI_0_awlen = 0;
        S_AXI_0_awlock = 0;
        S_AXI_0_awprot = 0;
        S_AXI_0_awsize = 0;
        S_AXI_0_awvalid = 0;
        S_AXI_0_bready = 0;
        S_AXI_0_wdata = 0;
        S_AXI_0_wlast = 0;
        S_AXI_0_wstrb = 0;
        S_AXI_0_wvalid = 0;
        S_AXI_0_araddr = 0;
        S_AXI_0_arburst = 0;
        S_AXI_0_arcache = 0;
        S_AXI_0_arlen = 0;
        S_AXI_0_arlock = 0;
        S_AXI_0_arprot = 0;
        S_AXI_0_arsize = 0;
        S_AXI_0_arvalid = 0;
        S_AXI_0_rready = 0;
        S_AXI_0_rresp = 0;

        // Wait until reset is deasserted
        @(posedge locked);
        sys_reset = 1;
        repeat(10) @(posedge sys_clock);
        sys_reset = 0;
        repeat(10) @(posedge sys_clock);
        $display("\n[TB] Starting MAIN TEST at time %t", $time);

        // 1) Write matrix A into memory, then verify
        // S_AXI_0_bready  = 1;
        write_matrix_A();
        // verify_matrix_A();

        // S_AXI_0_awaddr = 0;
        // S_AXI_0_awburst = 0;
        // S_AXI_0_awcache = 0;
        // S_AXI_0_awlen = 0;
        // S_AXI_0_awlock = 0;
        // S_AXI_0_awprot = 0;
        // S_AXI_0_awsize = 0;
        // S_AXI_0_awvalid = 0;
        // S_AXI_0_bready = 0;
        // S_AXI_0_wdata = 0;
        // S_AXI_0_wlast = 0;
        // S_AXI_0_wstrb = 0;
        // S_AXI_0_wvalid = 0;
        // S_AXI_0_araddr = 0;
        // S_AXI_0_arburst = 0;
        // S_AXI_0_arcache = 0;
        // S_AXI_0_arlen = 0;
        // S_AXI_0_arlock = 0;
        // S_AXI_0_arprot = 0;
        // S_AXI_0_arsize = 0;
        // S_AXI_0_arvalid = 0;
        // S_AXI_0_rready = 0;
        // S_AXI_0_rresp = 0;
        // repeat(10) @(posedge sys_clock);
        
        // 2) Write matrix B into memory, then verify
        write_matrix_B();
        // $finish;
        verify_matrix_A();
        verify_matrix_B();
        // S_AXI_0_bready  = 0;

        // 3) Write "start=1" in CONTROL register at address 0
        // (bit0 is start)
        apb_write(0, 32'h00000001);
        @(posedge sys_clock);
        
        
        status_val = 32'h0;
        forever begin
            apb_read(1, status_val);
            if (status_val[1] == 1'b1) begin
                $display("[TB] Done=1 => break from poll at time %t", $time);
                
                check_matrix_C();
                $finish;
            end
            #10; // poll interval
        end

        $finish;
    end

    // -------------------------------------------------------------------------
    // Default Signal Initialization
    // -------------------------------------------------------------------------
    initial begin
        // APB signals
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;

        // AXI signals
        S_AXI_0_awvalid = 0;
        S_AXI_0_wvalid  = 0;
        S_AXI_0_bready  = 0;
        S_AXI_0_arvalid = 0;
        S_AXI_0_rready  = 0;
        S_AXI_0_awburst = 2'b01;
        S_AXI_0_awcache = 4'b0;
        S_AXI_0_awlock  = 1'b0;
        S_AXI_0_awprot  = 3'b0;
        S_AXI_0_awsize  = 3'b010;
        S_AXI_0_awlen   = 0;

        S_AXI_0_arburst = 2'b01;
        S_AXI_0_arcache = 4'b0;
        S_AXI_0_arlock  = 1'b0;
        S_AXI_0_arprot  = 3'b0;
        S_AXI_0_arsize  = 3'b010;
        S_AXI_0_arlen   = 0;

        // Wait a bit after reset
        @(negedge sys_reset);
        repeat(5) @(posedge sys_clock);
    end

endmodule
