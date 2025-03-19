module apb_slave #(
    parameter int ADDR_WIDTH = 8,  // Address width
    parameter int DATA_WIDTH = 32,  // Data width
    parameter int ADDR_CONTROL = 0, // Data width
    parameter int ADDR_STATUS = 1  // Data width
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
    output logic                      PSLVERR,    // Slave error signal
    input  logic [DATA_WIDTH-1:0]   ext_status,   // read-only from top
    output logic [DATA_WIDTH-1:0]   ext_control   // writeable from APB
);
    logic [DATA_WIDTH-1:0] control_reg;
    // Define memory/register space for the slave (example: 256 locations)
    // logic [DATA_WIDTH-1:0] memory [2**ADDR_WIDTH];

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
            control_reg <= '0;
            // // Reset behavior (optional memory initialization)
            // for (int i = 0; i < 2**ADDR_WIDTH; i++) 
            //     memory[i] <= '0;
        end else if (transfer_valid && PWRITE) begin
            if (PADDR == ADDR_CONTROL) begin
                control_reg <= PWDATA;
            end
        end
    end

    assign ext_control = control_reg;

    // Read operation (combinational)
    always_comb begin
        if (transfer_valid && !PWRITE) begin
            if (PADDR == ADDR_CONTROL) begin
                PRDATA = control_reg;
            end else if (PADDR == ADDR_STATUS) begin
                PRDATA = ext_status;
            end
        end else begin
            PRDATA = '0;
        end
    end

endmodule
