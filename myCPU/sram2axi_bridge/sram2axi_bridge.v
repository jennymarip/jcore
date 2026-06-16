module sram2axi_bridge(
    input clk   ,
    input resetn,
    // inst sram interface
    input         icache_rd_req         ,
    input [ 2:0]  icache_rd_type        , // 驱动arlen
    input [31:0]  icache_rd_addr        ,
    output        icache_rd_rdy         ,
    output        icache_rd_ret_vld     ,
    output        icache_rd_ret_last    ,
    output [31:0] icache_rd_rdata       ,
    output        icache_r_handshake    ,
    // data sram interface
    input         data_sram_req    ,
    input         data_sram_wr     ,
    input [ 1:0]  data_sram_size   ,
    input [ 3:0]  data_sram_wstrb  ,
    input [31:0]  data_sram_addr   ,
    input [31:0]  data_sram_wdata  ,
    output        data_sram_addr_ok,
    output        data_sram_data_ok,
    output [31:0] data_sram_rdata  ,
    // axi interface
    // AR
    output [ 3:0] arid   ,
    output [31:0] araddr ,
    output [ 7:0] arlen  ,
    output [ 2:0] arsize ,
    output [ 1:0] arburst,
    output [ 1:0] arlock ,
    output [ 3:0] arcache,
    output [ 2:0] arprot ,
    output        arvalid,
    input         arready,
    // R
    input [ 3:0] rid   ,
    input [31:0] rdata ,
    input [ 1:0] rresp ,
    input        rlast ,
    input        rvalid,
    output       rready,
    // AW
    output [ 3:0] awid   ,
    output [31:0] awaddr ,
    output [ 7:0] awlen  ,
    output [ 2:0] awsize ,
    output [ 1:0] awburst,
    output [ 1:0] awlock ,
    output [ 3:0] awcache,
    output [ 2:0] awprot ,
    output        awvalid,
    input         awready,
    // W
    output [ 3:0] wid   ,
    output [31:0] wdata ,
    output [ 3:0] wstrb ,
    output        wlast ,
    output        wvalid,
    input         wready,
    // B
    input [ 3:0] bid   ,
    input [ 1:0] bresp ,
    input        bvalid,
    output       bready
);
reg reset;
always @(posedge clk) reset <= ~resetn;
wire data_sram_data_ok_r;
wire data_sram_data_ok_w;
wire data_sram_addr_ok_r;
wire data_sram_addr_ok_w;
assign data_sram_data_ok = data_sram_data_ok_r || data_sram_data_ok_w;
assign data_sram_addr_ok = data_sram_addr_ok_r || data_sram_addr_ok_w;
// AR & R
AR_R_channel ar_r_channel(
    .clk   (clk  ),
    .reset (reset),
    // inst sram interface
    .icache_rd_req          (icache_rd_req         ),
    .icache_rd_type         (icache_rd_type        ),
    .icache_rd_addr         (icache_rd_addr        ),
    .icache_rd_rdy          (icache_rd_rdy         ),
    .icache_rd_ret_vld      (icache_rd_ret_vld     ),
    .icache_rd_ret_last     (icache_rd_ret_last    ),
    .icache_rd_rdata        (icache_rd_rdata       ),
    .icache_r_handshake     (icache_r_handshake    ),
    // data sram interface
    .data_sram_req     (data_sram_req      ),
    .data_sram_wr      (data_sram_wr       ),
    .data_sram_size    (data_sram_size     ),
    .data_sram_wstrb   (data_sram_wstrb    ),
    .data_sram_addr    (data_sram_addr     ),
    .data_sram_wdata   (data_sram_wdata    ),
    .data_sram_addr_ok (data_sram_addr_ok_r),
    .data_sram_data_ok (data_sram_data_ok_r),
    .data_sram_rdata   (data_sram_rdata    ),
    // AR
    .arid    (arid   ),
    .araddr  (araddr ),
    .arlen   (arlen  ),
    .arsize  (arsize ),
    .arburst (arburst),
    .arlock  (arlock ),
    .arcache (arcache),
    .arprot  (arprot ),
    .arvalid (arvalid),
    .arready (arready),
    // R
    .rid    (rid   ),
    .rdata  (rdata ),
    .rresp  (rresp ),
    .rlast  (rlast ),
    .rvalid (rvalid),
    .rready (rready)
);
// AW & W & B
AW_W_B_channel aw_w_b_channel(
    .clk   (clk  ),
    .reset (reset),
    // data sram interface
    .data_sram_req     (data_sram_req      ),
    .data_sram_wr      (data_sram_wr       ),
    .data_sram_size    (data_sram_size     ),
    .data_sram_wstrb   (data_sram_wstrb    ),
    .data_sram_addr    (data_sram_addr     ),
    .data_sram_wdata   (data_sram_wdata    ),
    .data_sram_addr_ok (data_sram_addr_ok_w),
    .data_sram_data_ok (data_sram_data_ok_w),
    // AW
    .awid    (awid   ),
    .awaddr  (awaddr ),
    .awlen   (awlen  ),
    .awsize  (awsize ),
    .awburst (awburst),
    .awlock  (awlock ),
    .awcache (awcache),
    .awprot  (awprot ),
    .awvalid (awvalid),
    .awready (awready),
    // W
    .wid    (wid   ),
    .wdata  (wdata ),
    .wstrb  (wstrb ),
    .wlast  (wlast ),
    .wvalid (wvalid),
    .wready (wready),
    // B
    .bid    (bid   ),
    .bresp  (bresp ),
    .bvalid (bvalid),
    .bready (bready)
);
endmodule