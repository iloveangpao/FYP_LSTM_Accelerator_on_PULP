`timescale 1ns/1ps
module axi_read_fsm(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,      // One-cycle pulse to trigger a read
    input  wire [11:0]  read_addr,  // 32-bit word address (for 32-bit read)
    output reg  [31:0]  read_data,  // Captured 32-bit word from memory
    output reg          valid,      // One-cycle valid pulse when read_data is ready
    output reg          busy,       // High while transaction is in progress

    // Exposed AXI Read Interface signals (all initialized to 0)
    output reg  [11:0]  m_axi_araddr,
    output reg  [2:0]   m_axi_arsize,  // Always 3'b010 for 32-bit transfers
    output reg          m_axi_arvalid,
    output reg  [1:0]   m_axi_arburst, // Default 0
    output reg  [3:0]   m_axi_arcache, // Default 0
    output reg  [7:0]   m_axi_arlen,   // Default 0 (single transfer)
    output reg          m_axi_arlock,  // Default 0
    output reg  [2:0]   m_axi_arprot,  // Default 0
    input  wire         m_axi_arready,
    input  wire [31:0]  m_axi_rdata,
    input  wire         m_axi_rvalid,
    input  wire         m_axi_rlast,
    output reg          m_axi_rready
);

    // State encoding
    localparam IDLE               = 3'd0,
               DRIVE_READ         = 3'd1,
               WAIT_FOR_LAST    = 3'd2,
               DONE               = 3'd3;

    reg [2:0] state;
    reg [7:0] timeout_counter;

    always @(posedge clk) begin
        if (rst) begin
            state           <= IDLE;
            read_data       <= 32'd0;
            valid           <= 1'b0;
            busy            <= 1'b0;
            m_axi_araddr    <= 12'd0;
            m_axi_arsize    <= 3'b000;  // 32-bit transfer
            m_axi_arvalid   <= 1'b0;
            m_axi_arburst   <= 2'b00;
            m_axi_arcache   <= 4'd0;
            m_axi_arlen     <= 8'd0;
            m_axi_arlock    <= 1'b0;
            m_axi_arprot    <= 3'd0;
            m_axi_rready    <= 1'b0;
            timeout_counter <= 8'd0;
            // $display("[AXI_READ_FSM] Reset");
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    busy  <= 1'b0;
                    if (start && !m_axi_arready) begin
                        busy <= 1'b1;
                        m_axi_araddr  <= read_addr;
                        m_axi_arlen   <= 8'h00;      // Single transfer
                        m_axi_arsize  <= 3'b010;     // 32-bit read
                        m_axi_arburst <= 2'b00;
                        m_axi_arlock  <= 1'b0;
                        m_axi_arprot  <= 3'd0;
                        m_axi_arvalid <= 1'b1;
                        m_axi_rready  <= 1'b1;
                        timeout_counter <= 8'd0;
                        state <= DRIVE_READ;
                        // $display("[AXI_READ_FSM] Start detected, moving to WAIT_FOR_ARREADY, addr: 0x%08h", read_addr);
                    end
                end

                DRIVE_READ: begin
                    // Drive read signals as per the testbench task
                    timeout_counter <= timeout_counter + 1;
                    if (m_axi_rvalid && timeout_counter <= 10) begin
                        // m_axi_rready  <= 1'b1;
                        timeout_counter <= 8'd0;
                        m_axi_arvalid <= 1'b0;
                        state <= WAIT_FOR_LAST;
                    end 
                end

                WAIT_FOR_LAST: begin
                    timeout_counter <= timeout_counter + 1;
                    if (m_axi_rlast) begin
                        // $display("[AXI_READ_FSM] RVALID asserted");
                        read_data <= m_axi_rdata;
                        m_axi_rready <= 1'b0;
                        m_axi_arvalid <= 1'b0;
                        // $display("[AXI_READ_FSM] Captured RDATA=%0h", m_axi_rdata);
                        state <= DONE;
                    end else if (timeout_counter >= 10) begin
                        // $display("[AXI_READ_FSM] ERROR: Timeout waiting for RLAST, forcing transition");
                        state <= DONE;
                        m_axi_rready <= 1'b0;
                        m_axi_arvalid <= 1'b0;
                    end
                end

                DONE: begin
                    valid <= 1'b1; // Assert valid for one cycle
                    busy  <= 1'b0;
                    m_axi_rready <= 1'b0;
                    m_axi_arvalid <= 1'b0;
                    // $display("[AXI_READ_FSM] Transaction complete, read_data=%0h", read_data);
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule


