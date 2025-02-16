//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.1 (win64) Build 5076996 Wed May 22 18:37:14 MDT 2024
//Date        : Sun Feb 16 08:45:29 2025
//Host        : LYR running 64-bit major release  (build 9200)
//Command     : generate_target memory_block_wrapper.bd
//Design      : memory_block_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module memory_block_wrapper
   (S_AXI_0_araddr,
    S_AXI_0_arburst,
    S_AXI_0_arcache,
    S_AXI_0_arlen,
    S_AXI_0_arlock,
    S_AXI_0_arprot,
    S_AXI_0_arready,
    S_AXI_0_arsize,
    S_AXI_0_arvalid,
    S_AXI_0_awaddr,
    S_AXI_0_awburst,
    S_AXI_0_awcache,
    S_AXI_0_awlen,
    S_AXI_0_awlock,
    S_AXI_0_awprot,
    S_AXI_0_awready,
    S_AXI_0_awsize,
    S_AXI_0_awvalid,
    S_AXI_0_bready,
    S_AXI_0_bresp,
    S_AXI_0_bvalid,
    S_AXI_0_rdata,
    S_AXI_0_rlast,
    S_AXI_0_rready,
    S_AXI_0_rresp,
    S_AXI_0_rvalid,
    S_AXI_0_wdata,
    S_AXI_0_wlast,
    S_AXI_0_wready,
    S_AXI_0_wstrb,
    S_AXI_0_wvalid,
    S_AXI_1_araddr,
    S_AXI_1_arburst,
    S_AXI_1_arcache,
    S_AXI_1_arlen,
    S_AXI_1_arlock,
    S_AXI_1_arprot,
    S_AXI_1_arready,
    S_AXI_1_arsize,
    S_AXI_1_arvalid,
    S_AXI_1_awaddr,
    S_AXI_1_awburst,
    S_AXI_1_awcache,
    S_AXI_1_awlen,
    S_AXI_1_awlock,
    S_AXI_1_awprot,
    S_AXI_1_awready,
    S_AXI_1_awsize,
    S_AXI_1_awvalid,
    S_AXI_1_bready,
    S_AXI_1_bresp,
    S_AXI_1_bvalid,
    S_AXI_1_rdata,
    S_AXI_1_rlast,
    S_AXI_1_rready,
    S_AXI_1_rresp,
    S_AXI_1_rvalid,
    S_AXI_1_wdata,
    S_AXI_1_wlast,
    S_AXI_1_wready,
    S_AXI_1_wstrb,
    S_AXI_1_wvalid,
    reset_rtl,
    sys_clock);
  input [11:0]S_AXI_0_araddr;
  input [1:0]S_AXI_0_arburst;
  input [3:0]S_AXI_0_arcache;
  input [7:0]S_AXI_0_arlen;
  input S_AXI_0_arlock;
  input [2:0]S_AXI_0_arprot;
  output S_AXI_0_arready;
  input [2:0]S_AXI_0_arsize;
  input S_AXI_0_arvalid;
  input [11:0]S_AXI_0_awaddr;
  input [1:0]S_AXI_0_awburst;
  input [3:0]S_AXI_0_awcache;
  input [7:0]S_AXI_0_awlen;
  input S_AXI_0_awlock;
  input [2:0]S_AXI_0_awprot;
  output S_AXI_0_awready;
  input [2:0]S_AXI_0_awsize;
  input S_AXI_0_awvalid;
  input S_AXI_0_bready;
  output [1:0]S_AXI_0_bresp;
  output S_AXI_0_bvalid;
  output [31:0]S_AXI_0_rdata;
  output S_AXI_0_rlast;
  input S_AXI_0_rready;
  output [1:0]S_AXI_0_rresp;
  output S_AXI_0_rvalid;
  input [31:0]S_AXI_0_wdata;
  input S_AXI_0_wlast;
  output S_AXI_0_wready;
  input [3:0]S_AXI_0_wstrb;
  input S_AXI_0_wvalid;
  input [11:0]S_AXI_1_araddr;
  input [1:0]S_AXI_1_arburst;
  input [3:0]S_AXI_1_arcache;
  input [7:0]S_AXI_1_arlen;
  input S_AXI_1_arlock;
  input [2:0]S_AXI_1_arprot;
  output S_AXI_1_arready;
  input [2:0]S_AXI_1_arsize;
  input S_AXI_1_arvalid;
  input [11:0]S_AXI_1_awaddr;
  input [1:0]S_AXI_1_awburst;
  input [3:0]S_AXI_1_awcache;
  input [7:0]S_AXI_1_awlen;
  input S_AXI_1_awlock;
  input [2:0]S_AXI_1_awprot;
  output S_AXI_1_awready;
  input [2:0]S_AXI_1_awsize;
  input S_AXI_1_awvalid;
  input S_AXI_1_bready;
  output [1:0]S_AXI_1_bresp;
  output S_AXI_1_bvalid;
  output [31:0]S_AXI_1_rdata;
  output S_AXI_1_rlast;
  input S_AXI_1_rready;
  output [1:0]S_AXI_1_rresp;
  output S_AXI_1_rvalid;
  input [31:0]S_AXI_1_wdata;
  input S_AXI_1_wlast;
  output S_AXI_1_wready;
  input [3:0]S_AXI_1_wstrb;
  input S_AXI_1_wvalid;
  input reset_rtl;
  input sys_clock;

  wire [11:0]S_AXI_0_araddr;
  wire [1:0]S_AXI_0_arburst;
  wire [3:0]S_AXI_0_arcache;
  wire [7:0]S_AXI_0_arlen;
  wire S_AXI_0_arlock;
  wire [2:0]S_AXI_0_arprot;
  wire S_AXI_0_arready;
  wire [2:0]S_AXI_0_arsize;
  wire S_AXI_0_arvalid;
  wire [11:0]S_AXI_0_awaddr;
  wire [1:0]S_AXI_0_awburst;
  wire [3:0]S_AXI_0_awcache;
  wire [7:0]S_AXI_0_awlen;
  wire S_AXI_0_awlock;
  wire [2:0]S_AXI_0_awprot;
  wire S_AXI_0_awready;
  wire [2:0]S_AXI_0_awsize;
  wire S_AXI_0_awvalid;
  wire S_AXI_0_bready;
  wire [1:0]S_AXI_0_bresp;
  wire S_AXI_0_bvalid;
  wire [31:0]S_AXI_0_rdata;
  wire S_AXI_0_rlast;
  wire S_AXI_0_rready;
  wire [1:0]S_AXI_0_rresp;
  wire S_AXI_0_rvalid;
  wire [31:0]S_AXI_0_wdata;
  wire S_AXI_0_wlast;
  wire S_AXI_0_wready;
  wire [3:0]S_AXI_0_wstrb;
  wire S_AXI_0_wvalid;
  wire [11:0]S_AXI_1_araddr;
  wire [1:0]S_AXI_1_arburst;
  wire [3:0]S_AXI_1_arcache;
  wire [7:0]S_AXI_1_arlen;
  wire S_AXI_1_arlock;
  wire [2:0]S_AXI_1_arprot;
  wire S_AXI_1_arready;
  wire [2:0]S_AXI_1_arsize;
  wire S_AXI_1_arvalid;
  wire [11:0]S_AXI_1_awaddr;
  wire [1:0]S_AXI_1_awburst;
  wire [3:0]S_AXI_1_awcache;
  wire [7:0]S_AXI_1_awlen;
  wire S_AXI_1_awlock;
  wire [2:0]S_AXI_1_awprot;
  wire S_AXI_1_awready;
  wire [2:0]S_AXI_1_awsize;
  wire S_AXI_1_awvalid;
  wire S_AXI_1_bready;
  wire [1:0]S_AXI_1_bresp;
  wire S_AXI_1_bvalid;
  wire [31:0]S_AXI_1_rdata;
  wire S_AXI_1_rlast;
  wire S_AXI_1_rready;
  wire [1:0]S_AXI_1_rresp;
  wire S_AXI_1_rvalid;
  wire [31:0]S_AXI_1_wdata;
  wire S_AXI_1_wlast;
  wire S_AXI_1_wready;
  wire [3:0]S_AXI_1_wstrb;
  wire S_AXI_1_wvalid;
  wire reset_rtl;
  wire sys_clock;

  memory_block memory_block_i
       (.S_AXI_0_araddr(S_AXI_0_araddr),
        .S_AXI_0_arburst(S_AXI_0_arburst),
        .S_AXI_0_arcache(S_AXI_0_arcache),
        .S_AXI_0_arlen(S_AXI_0_arlen),
        .S_AXI_0_arlock(S_AXI_0_arlock),
        .S_AXI_0_arprot(S_AXI_0_arprot),
        .S_AXI_0_arready(S_AXI_0_arready),
        .S_AXI_0_arsize(S_AXI_0_arsize),
        .S_AXI_0_arvalid(S_AXI_0_arvalid),
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
        .S_AXI_0_rdata(S_AXI_0_rdata),
        .S_AXI_0_rlast(S_AXI_0_rlast),
        .S_AXI_0_rready(S_AXI_0_rready),
        .S_AXI_0_rresp(S_AXI_0_rresp),
        .S_AXI_0_rvalid(S_AXI_0_rvalid),
        .S_AXI_0_wdata(S_AXI_0_wdata),
        .S_AXI_0_wlast(S_AXI_0_wlast),
        .S_AXI_0_wready(S_AXI_0_wready),
        .S_AXI_0_wstrb(S_AXI_0_wstrb),
        .S_AXI_0_wvalid(S_AXI_0_wvalid),
        .S_AXI_1_araddr(S_AXI_1_araddr),
        .S_AXI_1_arburst(S_AXI_1_arburst),
        .S_AXI_1_arcache(S_AXI_1_arcache),
        .S_AXI_1_arlen(S_AXI_1_arlen),
        .S_AXI_1_arlock(S_AXI_1_arlock),
        .S_AXI_1_arprot(S_AXI_1_arprot),
        .S_AXI_1_arready(S_AXI_1_arready),
        .S_AXI_1_arsize(S_AXI_1_arsize),
        .S_AXI_1_arvalid(S_AXI_1_arvalid),
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
        .S_AXI_1_rdata(S_AXI_1_rdata),
        .S_AXI_1_rlast(S_AXI_1_rlast),
        .S_AXI_1_rready(S_AXI_1_rready),
        .S_AXI_1_rresp(S_AXI_1_rresp),
        .S_AXI_1_rvalid(S_AXI_1_rvalid),
        .S_AXI_1_wdata(S_AXI_1_wdata),
        .S_AXI_1_wlast(S_AXI_1_wlast),
        .S_AXI_1_wready(S_AXI_1_wready),
        .S_AXI_1_wstrb(S_AXI_1_wstrb),
        .S_AXI_1_wvalid(S_AXI_1_wvalid),
        .reset_rtl(reset_rtl),
        .sys_clock(sys_clock));
endmodule
