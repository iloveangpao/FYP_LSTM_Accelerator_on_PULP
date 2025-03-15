module apb_slave #(
    parameter int ADDR_WIDTH = 8,  // Address width
    parameter int DATA_WIDTH = 32  // Data width
)(
    input  logic                     PCLK,      // APB Clock
    input  logic                     PRESETn,   // Active-low Reset
    input  logic                     PSEL,      // Select signal
    input  logic                     PENABLE,   // Enable signal
    input  logic                     PWRITE,    // Write enable
    input  logic [ADDR_WIDTH-1:0]     PADDR,     // Address bus
    input  logic [DATA_WIDTH-1:0]     PWDATA,    // Write data bus
    output logic [DATA_WIDTH-1:0]     PRDATA,    // Read data bus
    output logic                      PREADY,    // Ready signal
    output logic                      PSLVERR    // Slave error signal
);

    // Define memory/register space for the slave (example: 256 locations)
    logic [DATA_WIDTH-1:0] memory [2**ADDR_WIDTH];

    // Internal control logic
    logic transfer_valid;

    // Determine if the transfer is valid (PSEL and PENABLE asserted)
    assign transfer_valid = PSEL & PENABLE;

    // PREADY: Always ready in this simple model
    assign PREADY = 1'b1;

    // PSLVERR: No errors in this implementation
    assign PSLVERR = 1'b0;

    // Write operation (synchronous with PCLK)
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Reset behavior (optional memory initialization)
            for (int i = 0; i < 2**ADDR_WIDTH; i++) 
                memory[i] <= '0;
        end else if (transfer_valid && PWRITE) begin
            memory[PADDR] <= PWDATA;
        end
    end

    // Read operation (combinational)
    always_comb begin
        if (transfer_valid && !PWRITE) begin
            PRDATA = memory[PADDR];
        end else begin
            PRDATA = '0;
        end
    end

endmodule
