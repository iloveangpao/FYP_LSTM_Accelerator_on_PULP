`timescale 1ns/1ps
module axi_a_input_extractor_top #(
    parameter BASE_ADDR = 12'd0  // Base address of the A matrix in memory
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,       // One-cycle pulse to trigger extraction
    input  wire [3:0]   cycle,       // Computation cycle index (0 to 14 valid)
    output reg  [63:0]  a_flat_out,  // Final 64-bit flat A input output
    output reg          valid,       // Asserted when a_flat_out is ready

    // Exposed AXI Read Interface signals (from the memory_block_wrapper)
    output wire [11:0]  m_axi_araddr,
    output wire [2:0]   m_axi_arsize,
    output wire         m_axi_arvalid,
    output wire [1:0]   m_axi_arburst,
    output wire [3:0]   m_axi_arcache,
    output wire [7:0]   m_axi_arlen,
    output wire         m_axi_arlock,
    output wire [2:0]   m_axi_arprot,
    input  wire         m_axi_arready,
    input  wire [31:0]  m_axi_rdata,
    input  wire         m_axi_rvalid,
    input  wire         m_axi_rlast,
    output wire         m_axi_rready
);

  //-------------------------------------------------------------------------
  // Internal signals to interface with the AXI read FSM
  //-------------------------------------------------------------------------
  reg         axi_start;
  reg  [11:0] axi_read_addr;
  wire [31:0] fsm_read_data;
  wire        fsm_valid;
  wire        fsm_busy;
  
  // Instantiate the AXI read FSM.
  axi_read_fsm fsm_inst (
      .clk(clk),
      .rst(rst),
      .start(axi_start),
      .read_addr(axi_read_addr),
      .read_data(fsm_read_data),
      .valid(fsm_valid),
      .busy(fsm_busy),
      // Expose all AXI signals directly from the FSM.
      .m_axi_araddr(m_axi_araddr),
      .m_axi_arsize(m_axi_arsize),
      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arburst(m_axi_arburst),
      .m_axi_arcache(m_axi_arcache),
      .m_axi_arlen(m_axi_arlen),
      .m_axi_arlock(m_axi_arlock),
      .m_axi_arprot(m_axi_arprot),
      .m_axi_arready(m_axi_arready),
      .m_axi_rdata(m_axi_rdata),
      .m_axi_rvalid(m_axi_rvalid),
      .m_axi_rlast(m_axi_rlast),
      .m_axi_rready(m_axi_rready)
  );
  
  //-------------------------------------------------------------------------
  // Extraction FSM: Assemble a 64-bit word with one byte per valid row.
  // For cycle c:
  //   - if (c <= 7): valid rows = 0 ... c.
  //   - if (c > 7): valid rows = (c - 7) ... 7.
  // For each valid row i, the element chosen is A[i][j] with j = c - i.
  // For rows not valid in the cycle, the corresponding byte is 0.
  //-------------------------------------------------------------------------
  localparam T_IDLE  = 3'd0,
             T_READ  = 3'd1,
             T_WAIT  = 3'd2,
             T_STORE = 3'd3,
             T_DONE  = 3'd4;
  reg [2:0] state;
  reg [3:0] current_i;      // Current row being processed
  reg [63:0] result_reg;    // Assembled output word
  
  // Compute valid row range based on cycle.
  reg [3:0] start_i, end_i;
  always @(*) begin
      if (cycle <= 4'd7) begin
          start_i = 4'd0;
          end_i   = cycle;
      end else begin
          start_i = cycle - 4'd7;
          end_i   = 4'd7;
      end
  end

  // Compute column index j = cycle - current_i for the current read.
  reg [3:0] j_val;
  always @(*) begin
      j_val = cycle - current_i;
  end

  // Compute the memory word address for element A[current_i][j]:
  // Each row occupies 8 bytes (2 words of 4 bytes each). If j < 4, the element is in word0; if j >= 4, in word1.
  wire [11:0] computed_addr = BASE_ADDR + (current_i << 3) + ((j_val >= 4'd4) ? 12'd4 : 12'd0);

  // Compute byte offset within the 32-bit word.
  reg [1:0] byte_offset;
  always @(*) begin
      if (j_val >= 4'd4)
          byte_offset = j_val - 4'd4;
      else
          byte_offset = j_val[1:0];
  end

  // Mux to extract the correct 8-bit element from fsm_read_data.
  reg [7:0] extracted_byte;
  always @(*) begin
      case (byte_offset)
          2'd0: extracted_byte = fsm_read_data[7:0];
          2'd1: extracted_byte = fsm_read_data[15:8];
          2'd2: extracted_byte = fsm_read_data[23:16];
          2'd3: extracted_byte = fsm_read_data[31:24];
          default: extracted_byte = 8'd0;
      endcase
  end

  // Top-level extraction FSM.
  always @(posedge clk) begin
      if (rst) begin
          state         <= T_IDLE;
          result_reg    <= 64'd0;
          a_flat_out    <= 64'd0;
          valid         <= 1'b0;
          current_i     <= 4'd0;
          axi_start     <= 1'b0;
          axi_read_addr <= 12'd0;
      end else begin
          case (state)
              T_IDLE: begin
                  valid <= 1'b0;
                  result_reg <= 64'd0;
                  if (start) begin
                      // For cycles > 7, start from row = c - 7; otherwise, start at 0.
                      if (cycle <= 4'd7)
                          current_i <= 4'd0;
                      else
                          current_i <= cycle - 4'd7;
                      $display("[Extractor] Cycle=%0d, start_i=%0d, end_i=%0d", cycle, (cycle<=7?0:cycle-7), (cycle<=7?cycle:7));
                      state <= T_READ;
                  end
              end

              T_READ: begin
                  // Issue read for element A[current_i][cycle - current_i]
                  axi_read_addr <= computed_addr;
                  axi_start <= 1'b1;
                  $display("[Extractor] T_READ: current_i=%0d, j_val=%0d, computed_addr=%0h", current_i, j_val, computed_addr);
                  state <= T_WAIT;
              end

              T_WAIT: begin
                  axi_start <= 1'b0;
                  if (fsm_valid) begin
                      $display("[Extractor] T_WAIT: fsm_valid asserted, extracted_byte=0x%02h", extracted_byte);
                      state <= T_STORE;
                  end
              end

              T_STORE: begin
                  // Store the extracted byte into the result at the byte lane corresponding to current_i.
                  result_reg[(current_i*8) +: 8] <= extracted_byte;
                  $display("[Extractor] T_STORE: Stored byte=0x%02h at row %0d", extracted_byte, current_i);
                  if (current_i < end_i) begin
                      current_i <= current_i + 1;
                      state <= T_READ;
                  end else begin
                      state <= T_DONE;
                  end
              end

              T_DONE: begin
                  a_flat_out <= result_reg;
                  valid <= 1'b1;
                  $display("[Extractor] T_DONE: Final extracted word=0x%016h", result_reg);
                  if (!start)
                      state <= T_IDLE;
              end

              default: state <= T_IDLE;
          endcase
      end
  end

endmodule
