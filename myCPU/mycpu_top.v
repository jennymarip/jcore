module mycpu_top(
    input [ 5:0] int,
    // reset, clk
    input    aclk   ,
    input    aresetn,
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
    output       bready,
    // debug interface
    output [31:0] debug_wb_pc      ,
    output [ 3:0] debug_wb_rf_wen  ,
    output [ 4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);
wire        inst_sram_req         ;
wire [ 1:0] inst_sram_size        ;
wire [31:0] inst_sram_addr        ;
wire        inst_sram_addr_ok_i   ;
wire        inst_sram_addr_ok     ;
wire [31:0] inst_sram_addr_ok_addr;
wire [31:0] inst_sram_rdata       ;
wire [ 1:0] data_sram_size        ;
wire [ 3:0] data_sram_wstrb       ;
wire [31:0] data_sram_addr        ;
wire [31:0] data_sram_wdata       ;
wire [31:0] data_sram_rdata       ;
assign inst_sram_addr_ok = inst_sram_addr_ok_i && aresetn;
mycpu_sram cpu_core(
    .clk    (aclk   ),
    .resetn (aresetn),
    // inst sram interface
    .inst_sram_req          (inst_sram_req         ),
    .inst_sram_wr           (inst_sram_wr          ),
    .inst_sram_size         (inst_sram_size        ),
    .inst_sram_wstrb        (inst_sram_wstrb       ),
    .inst_sram_addr         (inst_sram_addr        ),
    .inst_sram_wdata        (inst_sram_wdata       ),
    .inst_sram_addr_ok_addr (inst_sram_addr_ok_addr),
    .inst_sram_addr_ok      (inst_sram_addr_ok     ),
    .inst_sram_data_ok      (inst_sram_data_ok     ),
    .inst_sram_rdata        (inst_sram_rdata       ),
    // data sram interface
    .data_sram_req     (data_sram_req    ),
    .data_sram_wr      (data_sram_wr     ),
    .data_sram_size    (data_sram_size   ),
    .data_sram_wstrb   (data_sram_wstrb  ),
    .data_sram_addr    (data_sram_addr   ),
    .data_sram_wdata   (data_sram_wdata  ),
    .data_sram_addr_ok (data_sram_addr_ok),
    .data_sram_data_ok (data_sram_data_ok),
    .data_sram_rdata   (data_sram_rdata  ),
    // trace debug interface
    .debug_wb_pc       (debug_wb_pc      ),
    .debug_wb_rf_wen   (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata)
);
wire         i_wr_req;
wire [  2:0] i_wr_type;
wire [ 31:0] i_wr_addr;
wire [  3:0] i_wr_wstrb;
wire [127:0] i_wr_data;
wire        i_rd_req;
wire [ 2:0] i_rd_type;
wire [31:0] i_rd_addr;
wire        i_rd_rdy;
wire        i_rd_ret_vld;
wire        i_rd_ret_last;
wire [31:0] i_rd_data;
cache i_cache(
    .clk    (aclk   ),
    .resetn (aresetn),
    // cache <-> cpu
    .valid        (inst_sram_req        ),
    .op           (inst_sram_wr         ),
    .index        (inst_sram_addr[11:4] ),
    .tag          (inst_sram_addr[31:12]),
    .offset       (inst_sram_addr[3:0]  ),
    .wstrb        (inst_sram_wstrb      ),
    .wdata        (inst_sram_wdata      ),
    .addr_ok      (inst_sram_addr_ok_i  ),
    .addr_ok_addr (inst_sram_addr_ok_addr),
    .data_ok      (inst_sram_data_ok    ),
    .rdata        (inst_sram_rdata      ),
    // cache <-> AXI
    // read
    .rd_req      (i_rd_req),
    .rd_type     (i_rd_type),
    .rd_addr     (i_rd_addr),
    .rd_rdy      (i_rd_rdy),
    .ret_valid   (i_rd_ret_vld),
    .ret_last    (i_rd_ret_last),
    .ret_data    (i_rd_data),
    .r_handshake (icache_r_handshake),
    .rready      (rready),
    // write
    .wr_req   (i_wr_req  ),
    .wr_type  (i_wr_type ),
    .wr_addr  (i_wr_addr ),
    .wr_wstrb (i_wr_wstrb),
    .wr_data  (i_wr_data ),
    .wr_rdy   (1'b1      )
);
wire         d_wr_req;
wire [  2:0] d_wr_type;
wire [ 31:0] d_wr_addr;
wire [  3:0] d_wr_wstrb;
wire [127:0] d_wr_data;
wire         d_wr_ready;
wire        d_rd_req;
wire [ 2:0] d_rd_type;
wire [31:0] d_rd_addr;
wire        d_rd_rdy;
wire        d_rd_ret_vld;
wire        d_rd_ret_last;
wire [31:0] d_rd_data;
cache d_cache(
    .clk    (aclk   ),
    .resetn (aresetn),
    // cache <-> cpu
    .valid        (data_sram_req        ),
    .op           (data_sram_wr         ),
    .index        (data_sram_addr[11:4] ),
    .tag          (data_sram_addr[31:12]),
    .offset       (data_sram_addr[3:0]  ),
    .wstrb        (data_sram_wstrb      ),
    .wdata        (data_sram_wdata      ),
    .addr_ok      (data_sram_addr_ok    ),
    .addr_ok_addr (data_sram_addr_ok_addr),
    .data_ok      (data_sram_data_ok    ),
    .rdata        (data_sram_rdata      ),
    // cache <-> AXI
    // read
    .rd_req      (d_rd_req),
    .rd_type     (d_rd_type),
    .rd_addr     (d_rd_addr),
    .rd_rdy      (d_rd_rdy),
    .ret_valid   (d_rd_ret_vld),
    .ret_last    (d_rd_ret_last),
    .ret_data    (d_rd_data),
    .r_handshake (dcache_r_handshake),
    .rready      (rready),
    // write
    .wr_req   (d_wr_req  ),
    .wr_type  (d_wr_type ),
    .wr_addr  (d_wr_addr ),
    .wr_wstrb (d_wr_wstrb),
    .wr_data  (d_wr_data ),
    .wr_rdy   (d_wr_ready)
);
// 转接桥
sram2axi_bridge bridge(
    .clk    (aclk   ),
    .resetn (aresetn),
    // icache interface
    .icache_rd_req          (i_rd_req          ),
    .icache_rd_type         (i_rd_type         ),
    .icache_rd_addr         (i_rd_addr         ),
    .icache_rd_rdy          (i_rd_rdy          ),
    .icache_rd_ret_vld      (i_rd_ret_vld      ),
    .icache_rd_ret_last     (i_rd_ret_last     ),
    .icache_rd_rdata        (i_rd_data         ),
    .icache_r_handshake     (icache_r_handshake),
    // dcache interface
    // rd
    .dcache_rd_req      (d_rd_req          ),
    .dcache_rd_type     (d_rd_type         ),
    .dcache_rd_addr     (d_rd_addr         ),
    .dcache_rd_rdy      (d_rd_rdy          ),
    .dcache_rd_ret_vld  (d_rd_ret_vld      ),
    .dcache_rd_ret_last (d_rd_ret_last     ),
    .dcache_rd_rdata    (d_rd_data         ),
    .dcache_r_handshake (dcache_r_handshake),
    // wr
    .dcache_wr_req      (d_wr_req   ),
    .dcache_wr_type     (d_wr_type  ),
    .dcache_wr_addr     (d_wr_addr  ),
    .dcache_wr_wstrb    (d_wr_wstrb ),
    .dcache_wr_data     (d_wr_data  ),
    .dcache_wr_ready    (d_wr_ready ),
    // axi interface
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
    .rready (rready),
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