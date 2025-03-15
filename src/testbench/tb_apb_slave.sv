`timescale 1ns/1ps

module tb_apb_slave;

    // Parameters
    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;  // 100MHz clock (10ns period)

    // APB Signals
    logic PCLK;
    logic PRESETn;
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [ADDR_WIDTH-1:0] PADDR;
    logic [DATA_WIDTH-1:0] PWDATA;
    logic [DATA_WIDTH-1:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    // Read data variable (properly initialized)
    logic [DATA_WIDTH-1:0] read_data = '0;

    // Clock Generation
    always #(CLK_PERIOD / 2) PCLK = ~PCLK;

    // Instantiate APB Slave DUT
    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    // APB Master Tasks
    task apb_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        $display("APB WRITE: Addr = 0x%0h, Data = 0x%0h", addr, data);
        PSEL    = 1'b1;
        PWRITE  = 1'b1;
        PADDR   = addr;
        PWDATA  = data;
        PENABLE = 1'b0;
        #CLK_PERIOD; // Wait 1 cycle
        PENABLE = 1'b1;
        #CLK_PERIOD; // Wait for response
        PSEL    = 1'b0;
        PENABLE = 1'b0;
    endtask

    task apb_read(input [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
        $display("APB READ: Addr = 0x%0h", addr);
        PSEL    = 1'b1;
        PWRITE  = 1'b0;
        PADDR   = addr;
        PENABLE = 1'b0;
        #CLK_PERIOD; // Wait 1 cycle
        PENABLE = 1'b1;
        #CLK_PERIOD; // Wait for response
        data    = PRDATA; // Read data properly initialized
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        $display("APB READ RESPONSE: Addr = 0x%0h, Data = 0x%0h", addr, data);
    endtask

    // Test Sequence
    initial begin
        // Initialize signals
        PCLK    = 0;
        PRESETn = 0;
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;
        read_data = '0; // Proper initialization
        #20; // Hold reset for a few cycles

        // Release Reset
        PRESETn = 1;
        $display("\n=== RESET RELEASED ===\n");

        // Perform APB Transactions
        #CLK_PERIOD;
        
        // Write and Read test
        apb_write(8'h10, 32'hDEADBEEF); // Write 0xDEADBEEF to address 0x10
        apb_read(8'h10, read_data); // Read back from address 0x10
        
        // Check if the read data matches
        if (read_data == 32'hDEADBEEF) 
            $display("TEST PASSED: Read Data Matches Written Data\n");
        else 
            $display("TEST FAILED: Expected 0xDEADBEEF, Got 0x%0h\n", read_data);

        // Additional test cases
        apb_write(8'h20, 32'hCAFEBABE); // Write 0xCAFEBABE to address 0x20
        apb_read(8'h20, read_data);

        // Check correctness
        if (read_data == 32'hCAFEBABE) 
            $display("TEST PASSED: Read Data Matches Written Data\n");
        else 
            $display("TEST FAILED: Expected 0xCAFEBABE, Got 0x%0h\n", read_data);

        $display("\n=== TEST COMPLETE ===\n");
        $finish;
    end

endmodule
