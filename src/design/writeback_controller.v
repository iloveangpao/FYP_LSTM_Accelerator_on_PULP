// module writeback_controller (
//   input  wire         clk,
//   input  wire         rst,
//   input  wire         start,
//   // Flattened output from the systolic array:
//   // 64 words × 32 bits = 2048 bits
//   input  wire [2047:0] c_in_flat,
//   // Base address (in 32-bit word units) for writing Cout
//   input  wire [11:0]  base_addr,

//   // AXI write address channel (AXI1)
//   output reg [11:0]   m_axi_awaddr,
//   output reg [1:0]    m_axi_awburst,
//   output reg [3:0]    m_axi_awcache,
//   output reg [7:0]    m_axi_awlen,
//   output reg          m_axi_awlock,
//   output reg [2:0]    m_axi_awprot,
//   output reg [2:0]    m_axi_awsize,
//   output reg          m_axi_awvalid,
//   input  wire         m_axi_awready,

//   // AXI write data channel (AXI1)
//   output reg [31:0]   m_axi_wdata,
//   output reg          m_axi_wlast,
//   output reg [3:0]    m_axi_wstrb,
//   output reg          m_axi_wvalid,
//   input  wire         m_axi_wready,

//   // AXI write response channel (AXI1)
//   output reg          m_axi_bready,
//   input  wire [1:0]   m_axi_bresp,
//   input  wire         m_axi_bvalid,

//   // Finished signal (one-cycle pulse when writeback is complete)
//   output reg          done
// );

//   //-------------------------------------------------------------------------
//   // State Encoding
//   //-------------------------------------------------------------------------
//   localparam S_IDLE = 3'd0,
//              S_INIT = 3'd1,
//              S_AW   = 3'd2,
//              S_W    = 3'd3,
//              S_B    = 3'd4,
//              S_DONE = 3'd5;

//   reg [2:0] state;
//   // 6-bit counter to count from 0 to 63 (64 words)
//   reg [5:0] word_count;

//   //-------------------------------------------------------------------------
//   // Write-back FSM
//   //-------------------------------------------------------------------------
//   always @(posedge clk or posedge rst) begin
//     if (rst) begin
//       state           <= S_IDLE;
//       word_count      <= 6'd0;
//       m_axi_awaddr    <= 12'd0;
//       m_axi_awburst   <= 2'b0;
//       m_axi_awcache   <= 4'd0;
//       m_axi_awlen     <= 8'd0;
//       m_axi_awlock    <= 1'b0;
//       m_axi_awprot    <= 3'd0;
//       m_axi_awsize    <= 3'd0;
//       m_axi_awvalid   <= 1'b0;
//       m_axi_wdata     <= 32'd0;
//       m_axi_wlast     <= 1'b0;
//       m_axi_wstrb     <= 4'd0;
//       m_axi_wvalid    <= 1'b0;
//       m_axi_bready    <= 1'b0;
//       done            <= 1'b0;
//     end else begin
//       case (state)
//         S_IDLE: begin
//           done <= 1'b0;
//           // Wait for the start signal from APB control
//           if (start) begin
//             state <= S_INIT;
//           end
//         end

//         S_INIT: begin
//           // Initialize counter and set up the AW (write address) channel
//           word_count      <= 6'd0;
//           m_axi_awaddr    <= base_addr;
//           m_axi_awburst   <= 2'b01;     // INCR burst
//           m_axi_awcache   <= 4'b0011;   // Typical cache setting
//           m_axi_awlen     <= 8'd63;     // 64 transfers: awlen = transfers - 1
//           m_axi_awlock    <= 1'b0;
//           m_axi_awprot    <= 3'b000;
//           m_axi_awsize    <= 3'b010;    // 4 bytes per transfer
//           m_axi_awvalid   <= 1'b1;
//           state           <= S_AW;
//         end

//         S_AW: begin
//           // Wait for the AW handshake from the slave.
//           if (m_axi_awvalid && m_axi_awready) begin
//             m_axi_awvalid <= 1'b0;  // Handshake complete
//             // Prepare first write data:
//             m_axi_wstrb   <= 4'b1111;
//             m_axi_wdata   <= c_in_flat[(word_count*32) +: 32];
//             m_axi_wvalid  <= 1'b1;
//             m_axi_wlast   <= (word_count == 6'd63) ? 1'b1 : 1'b0;
//             state         <= S_W;
//           end
//         end

//         S_W: begin
//           // Write data channel: send one word per handshake.
//           if (m_axi_wvalid && m_axi_wready) begin
//             if (word_count == 6'd63) begin
//               // Last word has been sent.
//               m_axi_wvalid <= 1'b0;
//               state        <= S_B;
//               m_axi_bready <= 1'b1;  // Ready to receive the write response.
//             end else begin
//               // Increment word counter and load the next word.
//               word_count <= word_count + 1;
//               m_axi_wdata   <= c_in_flat[((word_count + 1)*32) +: 32];
//               m_axi_wlast   <= ((word_count + 1) == 6'd63) ? 1'b1 : 1'b0;
//             end
//           end
//         end

//         S_B: begin
//           // Wait for the write response from the slave.
//           if (m_axi_bvalid) begin
//             m_axi_bready <= 1'b0;
//             state        <= S_DONE;
//           end
//         end

//         S_DONE: begin
//           done  <= 1'b1;
//           // One-cycle pulse then return to IDLE
//           state <= S_IDLE;
//         end

//         default: state <= S_IDLE;
//       endcase
//     end
//   end

// endmodule


module writeback_controller (
  input  wire         clk,
  input  wire         rst,
  input  wire         start,
  // Flattened output from the systolic array: 64 words × 32 bits = 2048 bits
  input  wire [2047:0] c_in_flat,
  // Base address (in 32-bit word units) for writing Cout
  input  wire [11:0]  base_addr,

  // AXI write address channel (AXI1)
  output wire [11:0]   m_axi_awaddr,
  output wire [1:0]    m_axi_awburst,
  output wire [3:0]    m_axi_awcache,
  output wire [7:0]    m_axi_awlen,
  output wire          m_axi_awlock,
  output wire [2:0]    m_axi_awprot,
  output wire [2:0]    m_axi_awsize,
  output wire          m_axi_awvalid,
  input  wire          m_axi_awready,

  // AXI write data channel (AXI1)
  output wire [31:0]   m_axi_wdata,
  output wire          m_axi_wlast,
  output wire [3:0]    m_axi_wstrb,
  output wire          m_axi_wvalid,
  input  wire          m_axi_wready,

  // AXI write response channel (AXI1)
  output wire          m_axi_bready,
  input  wire [1:0]    m_axi_bresp,
  input  wire          m_axi_bvalid,

  // Finished signal (one-cycle pulse when writeback is complete)
  output wire          done,

  // Debug monitoring outputs:
  output wire [2:0]    debug_state,      // current FSM state
  output wire [5:0]    debug_word_count  // current word counter
);

  // Internal registers to hold the output values.
  reg [11:0]   m_axi_awaddr_reg;
  reg [1:0]    m_axi_awburst_reg;
  reg [3:0]    m_axi_awcache_reg;
  reg [7:0]    m_axi_awlen_reg;
  reg          m_axi_awlock_reg;
  reg [2:0]    m_axi_awprot_reg;
  reg [2:0]    m_axi_awsize_reg;
  reg          m_axi_awvalid_reg;

  reg [31:0]   m_axi_wdata_reg;
  reg          m_axi_wlast_reg;
  reg [3:0]    m_axi_wstrb_reg;
  reg          m_axi_wvalid_reg;

  reg          m_axi_bready_reg;
  reg          done_reg;

  reg [2:0]    debug_state_reg;
  reg [5:0]    debug_word_count_reg;

  // Continuous assignments drive the output wires.
  assign m_axi_awaddr    = m_axi_awaddr_reg;
  assign m_axi_awburst   = m_axi_awburst_reg;
  assign m_axi_awcache   = m_axi_awcache_reg;
  assign m_axi_awlen     = m_axi_awlen_reg;
  assign m_axi_awlock    = m_axi_awlock_reg;
  assign m_axi_awprot    = m_axi_awprot_reg;
  assign m_axi_awsize    = m_axi_awsize_reg;
  assign m_axi_awvalid   = m_axi_awvalid_reg;

  assign m_axi_wdata     = m_axi_wdata_reg;
  assign m_axi_wlast     = m_axi_wlast_reg;
  assign m_axi_wstrb     = m_axi_wstrb_reg;
  assign m_axi_wvalid    = m_axi_wvalid_reg;

  assign m_axi_bready    = m_axi_bready_reg;

  assign done            = done_reg;

  assign debug_state     = debug_state_reg;
  assign debug_word_count= debug_word_count_reg;

  //-------------------------------------------------------------------------
  // State Encoding and internal counters
  //-------------------------------------------------------------------------
  localparam S_IDLE = 3'd0,
             S_INIT = 3'd1,
             S_AW   = 3'd2,
             S_W    = 3'd3,
             S_N    = 3'd4,
             S_B    = 3'd5,
             S_DONE = 3'd6;

  reg [2:0] state;
  // 6-bit counter to count from 0 to 63 (64 words)
  reg [5:0] word_count;

  //-------------------------------------------------------------------------
  // Write-back FSM with Debug Monitoring
  //-------------------------------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state               <= S_IDLE;
      word_count          <= 6'd0;
      m_axi_awaddr_reg    <= 12'd0;
      m_axi_awburst_reg   <= 2'b0;
      m_axi_awcache_reg   <= 4'd0;
      m_axi_awlen_reg     <= 8'd0;
      m_axi_awlock_reg    <= 1'b0;
      m_axi_awprot_reg    <= 3'd0;
      m_axi_awsize_reg    <= 3'd0;
      m_axi_awvalid_reg   <= 1'b0;
      m_axi_wdata_reg     <= 32'd0;
      m_axi_wlast_reg     <= 1'b0;
      m_axi_wstrb_reg     <= 4'd0;
      m_axi_wvalid_reg    <= 1'b0;
      m_axi_bready_reg    <= 1'b0;
      done_reg            <= 1'b0;
      debug_state_reg     <= S_IDLE;
      debug_word_count_reg<= 6'd0;
      // $display("[WB DEBUG] RESET: FSM in S_IDLE at time %0t", $time);
    end else begin
      // Update debug outputs.
      debug_state_reg      <= state;
      debug_word_count_reg <= word_count;
      
      case (state)
        S_IDLE: begin
          done_reg <= 1'b0;
          if (start) begin
            // $display("[WB DEBUG] Start signal received at time %0t. Transitioning to S_INIT.", $time);
            state <= S_INIT;
          end
        end

        S_INIT: begin
          word_count             <= 6'd0;
          m_axi_awaddr_reg       <= base_addr;
          m_axi_awburst_reg      <= 2'b01;     // INCR burst
          m_axi_awcache_reg      <= 4'b0011;   // Typical cache setting
          m_axi_awlen_reg        <= 8'd63;     // 64 transfers: awlen = transfers - 1
          m_axi_awlock_reg       <= 1'b0;
          m_axi_awprot_reg       <= 3'b000;
          m_axi_awsize_reg       <= 3'b010;    // 4 bytes per transfer
          m_axi_awvalid_reg      <= 1'b1;
          // $display("[WB DEBUG] S_INIT: AW channel configured at time %0t, Base Addr = 0x%03h", $time, base_addr);
          state <= S_AW;
        end

        S_AW: begin
          if (m_axi_awready) begin
            m_axi_bready_reg <= 1'b1;
            // $display("[WB DEBUG] S_AW: AW handshake complete at time %0t, Addr = 0x%03h", $time, m_axi_awaddr_reg);
            m_axi_awvalid_reg <= 1'b0;  // Handshake complete.
            // Prepare first write data.
            m_axi_wstrb_reg   <= 4'b1111;
            m_axi_wdata_reg   <= c_in_flat[(word_count*32) +: 32];
            m_axi_wvalid_reg  <= 1'b1;
            m_axi_wlast_reg   <= (word_count == 6'd63) ? 1'b1 : 1'b0;
            // $display("[WB DEBUG] S_AW: Loading first word: word_count = %0d, Data = 0x%08h", word_count, m_axi_wdata_reg);
            state <= S_W;
          end
        end

        S_W: begin
          if (m_axi_wvalid_reg && m_axi_wready) begin
            // $display("[WB DEBUG] S_W: W handshake at time %0t, Word %0d written, Data = 0x%08h", $time, word_count, m_axi_wdata_reg);
            m_axi_wvalid_reg <= 1'b0;
            state <= S_N;
          end
        end

        S_N: begin
          if (word_count + 1 == 6'd63) begin
            m_axi_wlast_reg  <= 1'b1;
            state            <= S_B;
              // Ready to receive the write response.
            // $display("[WB DEBUG] S_W: Last word written. Transitioning to S_B at time %0t", $time);
          end else begin
            state <= S_W;
          end
          m_axi_wvalid_reg <= 1'b1;
          
          word_count       <= word_count + 1;
          m_axi_wdata_reg  <= c_in_flat[((word_count + 1)*32) +: 32];
        end

        S_B: begin
          if (m_axi_bvalid) begin
            // $display("[WB DEBUG] S_B: B handshake received at time %0t. BRESP = 0x%0h", $time, m_axi_bresp);
            m_axi_bready_reg <= 1'b0;
            m_axi_wlast_reg  <= 1'b0;
            m_axi_wvalid_reg <= 1'b0;
            state            <= S_DONE;
          end
        end

        S_DONE: begin
          done_reg <= 1'b1;
          // $display("[WB DEBUG] S_DONE: Writeback complete at time %0t", $time);
          if (!start)begin
          state <= S_IDLE;
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
