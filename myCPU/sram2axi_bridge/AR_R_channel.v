// 负责读事务的模块
module AR_R_channel(
    input clk  ,
    input reset,
    // icache interface
    input         icache_rd_req     ,
    input [ 2:0]  icache_rd_type    ,
    input [31:0]  icache_rd_addr    ,
    output        icache_rd_rdy     ,
    output        icache_rd_ret_vld ,
    output        icache_rd_ret_last,
    output [31:0] icache_rd_rdata   ,
    output        icache_r_handshake,
    // dcache interface
    input         dcache_rd_req     ,
    input [ 2:0]  dcache_rd_type    ,
    input [31:0]  dcache_rd_addr    ,
    output        dcache_rd_rdy     ,
    output        dcache_rd_ret_vld ,
    output        dcache_rd_ret_last,
    output [31:0] dcache_rd_rdata   ,
    output        dcache_r_handshake,
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
    output       rready
);
/* ar controll */
wire   ar_handshake, ar_handshake_flag; // flag 表明存在读请求数据未返回
reg    ar_handshake_reg;
assign ar_handshake      = arvalid && arready;
assign ar_handshake_flag = ar_handshake || ar_handshake_reg;
always @(posedge clk) begin
    if (reset || r_handshake) begin
        ar_handshake_reg <= 1'b0;
    end else if (ar_handshake) begin
        ar_handshake_reg <= 1'b1;
    end
end
/* r controll */
assign r_handshake = rvalid && rready; 
assign icache_r_handshake = r_handshake && (rid == 4'b0);
assign dcache_r_handshake = r_handshake && (rid == 4'b1);
// AR
assign arid    = arid_reg   ;
assign araddr  = araddr_reg ;
assign arlen   = arlen_reg  ;
assign arsize  = arsize_reg ;
assign arburst = 2'b1       ;
assign arlock  = 2'b0       ;
assign arcache = 4'b0       ;
assign arprot  = 3'b0       ;
assign arvalid = arvalid_reg;

reg [ 3:0] arid_reg   ;
reg [31:0] araddr_reg ;
reg [ 7:0] arlen_reg  ;
reg [ 2:0] arsize_reg ;
reg        arvalid_reg;
always @(posedge clk) begin
    if (reset || ar_handshake_flag) begin
        arid_reg    <=  4'b0;
        araddr_reg  <= 32'b0;
        arlen_reg   <=  8'b0;
        arsize_reg  <=  3'b0;
        arvalid_reg <=  1'b0;
    end else if (icache_rd_req && ~arvalid) begin //inst
        arid_reg    <= 4'b0;
        araddr_reg  <= icache_rd_addr;
        arlen_reg   <= 8'b11;
        arsize_reg  <= 3'b010;
        arvalid_reg <= 1'b1;
    end else if(dcache_rd_req && ~arvalid && ~dcache_rd_req_send && ~icache_rd_axi_pending)begin //data
        arid_reg    <= 4'b1;
        araddr_reg  <= dcache_rd_addr;
        arlen_reg   <= 8'b11;
        arsize_reg  <= 3'b010;
        arvalid_reg <= 1'b1;
    end
end
// R
assign rready = rready_reg;
reg    rready_reg;
reg [31:0] rdata_reg ; // 暂存读数据
always @(posedge clk) begin
    if (reset) begin
        rready_reg <=  1'b0;
        rdata_reg  <= 32'b0;
    end else if (rvalid && ~r_handshake) begin
        rready_reg <=  1'b1;
        rdata_reg  <= rdata;
    end else if (r_handshake) begin
        rready_reg <= 1'b0;
    end
end


// cache rsp
assign icache_rd_rdy = ~(icache_rd_axi_pending || dcache_rd_axi_pending || dcache_rd_req);
assign dcache_rd_rdy = ~(icache_rd_axi_pending || dcache_rd_axi_pending || icache_rd_req);
reg icache_rd_axi_pending; // 一个icache引起的猝发读正在进行没有结束
always @(posedge clk)begin
    if(reset)begin
        icache_rd_axi_pending <= 1'b0;
    end else if(icache_rd_req && ~dcache_rd_axi_pending)begin
        icache_rd_axi_pending <= 1'b1;
    end else if(rlast && rvalid && rready)begin
        icache_rd_axi_pending <= 1'b0;
    end
end
// 状态信号
reg dcache_rd_axi_pending; // 一个data读请求引起的axi事务没有结束
reg dcache_rd_req_send; // 数据请求已经发出
always@(posedge clk)begin
    if(reset)begin
        dcache_rd_axi_pending <= 1'b0;
    end else if(dcache_rd_req && ~icache_rd_axi_pending)begin
        dcache_rd_axi_pending <= 1'b1;
    end else if(dcache_rd_axi_pending && rlast && rvalid && rready)begin
        dcache_rd_axi_pending <= 1'b0;
    end
end
always @(posedge clk) begin
    if(reset)begin
        dcache_rd_req_send <= 1'b0;
    end else if(ar_handshake && arid == 4'b1)begin
        dcache_rd_req_send <= 1'b1;
    end else if(dcache_rd_req_send && dcache_rd_axi_pending && rlast && rvalid && rready)begin
        dcache_rd_req_send <= 1'b0;
    end
end

assign icache_rd_ret_vld = ~rid[0] && rvalid;
assign icache_rd_ret_last = ~rid[0] && rlast;
assign icache_rd_rdata = rdata;
assign dcache_rd_ret_vld = rid[0] && rvalid;
assign dcache_rd_ret_last = rid[0] && rlast;
assign dcache_rd_rdata = rdata;

endmodule