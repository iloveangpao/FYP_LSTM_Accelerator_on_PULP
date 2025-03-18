`timescale 1ns/1ps
module axi_a_input_extractor_top #(
    parameter BASE_ADDR = 12'd0  // Base address of the A matrix in memory
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         load_start,  // Pulse to trigger matrix loading (via S_AXI_1)
    input  wire         start,       // Pulse to trigger diagonal extraction
    input  wire         extract_reset,       // Pulse to trigger diagonal extraction
    output reg  [63:0]  a_flat_out,  // Diagonal extraction output (one byte per row)
    output wire  [3:0]   valid_cycle,       // Asserted when a_flat_out is ready
    output wire         input_loaded,

    // S_AXI_1 Read Interface (connected to your memory block’s S_AXI_1 port)
    output reg  [11:0]  m_axi_araddr,
    output reg  [2:0]   m_axi_arsize,
    output reg          m_axi_arvalid,
    output reg  [1:0]   m_axi_arburst,
    output reg  [3:0]   m_axi_arcache,
    output reg  [7:0]   m_axi_arlen,
    output reg          m_axi_arlock,
    output reg  [2:0]   m_axi_arprot,
    input  wire         m_axi_arready,
    input  wire [31:0]  m_axi_rdata,
    input  wire         m_axi_rvalid,
    input  wire         m_axi_rlast,
    output reg          m_axi_rready
);

  //-------------------------------------------------------------------------
  // FSM State Encoding
  //-------------------------------------------------------------------------
  localparam S_WAIT_LOAD  = 3'd0, // Wait for load_start pulse
             S_LOAD       = 3'd1, // Issue burst-read (assert ARVALID, RREADY)
             S_WAIT_BURST = 3'd2, // Capture burst-read data
             S_BURST = 3'd3,
             S_READY      = 3'd4, // Matrix loaded; idle waiting for extraction trigger
             S_EXTRACT    = 3'd5, // Combinational extraction in one cycle
             S_DONE       = 3'd6; // Extraction done, output valid result

  reg [2:0] state;

  //-------------------------------------------------------------------------
  // Burst-Read Buffering for 8x8 Matrix A
  // The matrix is 8 rows × 8 bytes = 64 bytes = 16 32-bit words.
  // We capture these 16 words (in burst_data) and reassemble them into a 512-bit
  // register (a_matrix_reg), where each 64-bit slice is one row.
  //-------------------------------------------------------------------------
  reg [3:0] burst_cnt;
  reg [31:0] burst_data [0:15];
  reg [511:0] a_matrix_reg;
  reg [3:0]   cycle;
  reg [3:0]   valid_cycle_reg;
  reg matrix_loaded;
  assign input_loaded = matrix_loaded;

  //-------------------------------------------------------------------------
  // Diagonal Extraction (combinational mux)
  // For each row i (0 to 7) if valid then select byte at column j = cycle – i.
  // A row is valid if:
  //   - when cycle <= 7: i <= cycle
  //   - when cycle > 7: i >= (cycle – 7)
  // Otherwise, output 0.
  //-------------------------------------------------------------------------
  wire [7:0] diag_byte [0:7];
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin: diag_extract
      wire valid_row;
      assign valid_row = ((cycle <= 4'd7 && i <= cycle) ||
                          (cycle > 4'd7 && i >= (cycle - 4'd7))) &&
                         ((cycle - i) < 4'd8);
      assign diag_byte[i] = valid_row ? a_matrix_reg[i*64 + ((cycle - i)*8) +: 8] : 8'd0;
    end
  endgenerate

  wire [63:0] comb_extraction;
  assign comb_extraction = {diag_byte[7], diag_byte[6], diag_byte[5], diag_byte[4],
                            diag_byte[3], diag_byte[2], diag_byte[1], diag_byte[0]};
  assign valid_cycle = valid_cycle_reg;

  //-------------------------------------------------------------------------
  // Main FSM
  //-------------------------------------------------------------------------
  integer j;
  always @(posedge clk) begin
    if (rst) begin
      state         <= S_WAIT_LOAD;
      burst_cnt     <= 4'd0;
      matrix_loaded <= 1'b0;
      m_axi_araddr  <= 0;
      m_axi_arlen   <= 8'd0;  // 16-word burst (arlen = burst length - 1)
      m_axi_arsize  <= 3'b0; // 32-bit transfers
      m_axi_arburst <= 2'b0;  // INCR burst
      m_axi_arcache <= 4'd0;
      m_axi_arlock  <= 1'b0;
      m_axi_arprot  <= 3'd0;
      m_axi_arvalid <= 1'b0;
      m_axi_rready  <= 1'b0;
      a_flat_out    <= 64'd0;
      cycle         <= 4'b0;
    end else if (extract_reset) begin
      cycle         <= 3'b0;
      state <= S_READY;
    end else begin
      case (state)
        //---------------------------------------------------------------
        // S_WAIT_LOAD: Wait for the load_start pulse to begin matrix load.
        //---------------------------------------------------------------
        S_WAIT_LOAD: begin
          if (load_start) begin
            matrix_loaded <= 1'b0;
            burst_cnt <= 4'd0;
            m_axi_araddr  <= BASE_ADDR;
            m_axi_arlen   <= 8'd15;
            m_axi_arsize  <= 3'b010;
            m_axi_arburst <= 2'b01;
            m_axi_arvalid <= 1'b1;
            m_axi_rready  <= 1'b1;
            state <= S_LOAD;
          end
        end

        //---------------------------------------------------------------
        // S_LOAD: Ensure the burst address is accepted.
        //---------------------------------------------------------------
        S_LOAD: begin
          
          if (m_axi_arready)
            state <= S_WAIT_BURST;
            m_axi_arvalid <= 1'b0;
            
        end

        //---------------------------------------------------------------
        // S_WAIT_BURST: Capture burst-read data and reassemble into a_matrix_reg.
        //---------------------------------------------------------------
        S_WAIT_BURST: begin
          if (m_axi_rvalid) begin
            burst_data[burst_cnt] <= m_axi_rdata;
            burst_cnt <= burst_cnt + 1;
            if (m_axi_rlast) begin
              m_axi_rready <= 1'b0;
              state <= S_BURST;
            end
          end
        end

        S_BURST: begin

          for (j = 0; j < 8; j = j + 1) begin
            // Each row i is {word1, word0} from burst_data[2*i+1] and burst_data[2*i]
            a_matrix_reg[ 63:  0] <= { burst_data[1],  burst_data[0]  };
            a_matrix_reg[127: 64] <= { burst_data[3],  burst_data[2]  };
            a_matrix_reg[191:128] <= { burst_data[5],  burst_data[4]  };
            a_matrix_reg[255:192] <= { burst_data[7],  burst_data[6]  };
            a_matrix_reg[319:256] <= { burst_data[9],  burst_data[8]  };
            a_matrix_reg[383:320] <= { burst_data[11], burst_data[10] };
            a_matrix_reg[447:384] <= { burst_data[13], burst_data[12] };
            a_matrix_reg[511:448] <= { burst_data[15], burst_data[14] };
          end
          matrix_loaded <= 1'b1;
          state <= S_READY;
          
        end

        //---------------------------------------------------------------
        // S_READY: Matrix loaded; wait for extraction trigger (start).
        //---------------------------------------------------------------
        S_READY: begin
          if (start && matrix_loaded)
            state <= S_EXTRACT;
        end

        //---------------------------------------------------------------
        // S_EXTRACT: In one cycle, mux out the diagonal extraction.
        //---------------------------------------------------------------
        S_EXTRACT: begin
          a_flat_out <= comb_extraction;
          state <= S_READY;
          valid_cycle_reg <= cycle;
          if (cycle < 15) begin
            cycle += 3'b001;
          end else begin
            cycle = 0;
          end
        end

        //---------------------------------------------------------------
        // S_DONE: Wait for start to deassert before returning to S_READY.
        //---------------------------------------------------------------
        S_DONE: begin
          if (!start) begin
            state <= S_READY;
          end
        end

        default: state <= S_WAIT_LOAD;
      endcase
    end
  end

endmodule