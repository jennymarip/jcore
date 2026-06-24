module sram2axi_bridge(
    input clk   ,
    input resetn,
    // icache interface
    input         icache_rd_req         ,
    input [ 2:0]  icache_rd_type        , // 驱动arlen
    input [31:0]  icache_rd_addr        ,
    output        icache_rd_rdy         ,
    output        icache_rd_ret_vld     ,
    output        icache_rd_ret_last    ,
    output [31:0] icache_rd_rdata       ,
    output        icache_r_handshake    ,
    // dcache interface
    // rd
    input         dcache_rd_req         ,
    input [ 2:0]  dcache_rd_type        , // 驱动arlen
    input [31:0]  dcache_rd_addr        ,
    output        dcache_rd_rdy         ,
    output        dcache_rd_ret_vld     ,
    output        dcache_rd_ret_last    ,
    output [31:0] dcache_rd_rdata       ,
    output        dcache_r_handshake    ,
    // wr
    input         dcache_wr_req  ,
    input [ 2:0]  dcache_wr_type ,
    input [31:0]  dcache_wr_addr ,
    input [ 3:0]  dcache_wr_wstrb,
    input [127:0] dcache_wr_data ,
    output        dcache_wr_ready,
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
// AR & R
AR_R_channel ar_r_channel(
    .clk   (clk  ),
    .reset (reset),
    // inst interface
    .icache_rd_req          (icache_rd_req         ),
    .icache_rd_type         (icache_rd_type        ),
    .icache_rd_addr         (icache_rd_addr        ),
    .icache_rd_rdy          (icache_rd_rdy         ),
    .icache_rd_ret_vld      (icache_rd_ret_vld     ),
    .icache_rd_ret_last     (icache_rd_ret_last    ),
    .icache_rd_rdata        (icache_rd_rdata       ),
    .icache_r_handshake     (icache_r_handshake    ),
    // data interface
    .dcache_rd_req          (dcache_rd_req         ),
    .dcache_rd_type         (dcache_rd_type        ),
    .dcache_rd_addr         (dcache_rd_addr        ),
    .dcache_rd_rdy          (dcache_rd_rdy         ),
    .dcache_rd_ret_vld      (dcache_rd_ret_vld     ),
    .dcache_rd_ret_last     (dcache_rd_ret_last    ),
    .dcache_rd_rdata        (dcache_rd_rdata       ),
    .dcache_r_handshake     (dcache_r_handshake    ),
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
    // dcache interface
    .dcache_wr_req   (dcache_wr_req  ),
    .dcache_wr_type  (dcache_wr_type ),
    .dcache_wr_addr  (dcache_wr_addr ),
    .dcache_wr_wstrb (dcache_wr_wstrb),
    .dcache_wr_data  (dcache_wr_data ),
    .dcache_wr_ready (dcache_wr_ready),
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