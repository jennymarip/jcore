// 负责读事务的模块
module AR_R_channel(
    input clk  ,
    input reset,
    // inst sram interface
    input         inst_sram_req    ,
    input         inst_sram_wr     ,
    input [ 1:0]  inst_sram_size   ,
    input [ 3:0]  inst_sram_wstrb  ,
    input [31:0]  inst_sram_addr   ,
    input [31:0]  inst_sram_wdata  ,
    output        inst_sram_addr_ok,
    output        inst_sram_data_ok,
    output [31:0] inst_sram_rdata  ,
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
// controll
wire   read_tran;
assign read_tran = inst_sram_req || data_sram_req && ~data_sram_wr;
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
wire   r_handshake;
assign r_handshake = rvalid && rready; 

// AR
assign arid    = arid_reg   ;
assign araddr  = araddr_reg ;
assign arlen   = 8'b0       ;
assign arsize  = arsize_reg ;
assign arburst = 2'b1       ;
assign arlock  = 2'b0       ;
assign arcache = 4'b0       ;
assign arprot  = 3'b0       ;
assign arvalid = arvalid_reg;

/* read_data信号区分当 data_sram_req 有效时，是读数据还是写数据 */
wire   read_data;
assign read_data = data_sram_req && ~data_sram_wr;

reg [ 3:0] arid_reg   ;
reg [31:0] araddr_reg ;
reg [ 2:0] arsize_reg ;
reg        arvalid_reg;
always @(posedge clk) begin
    if (reset || ar_handshake_flag) begin
        arid_reg    <=  4'b0;
        araddr_reg  <= 32'b0;
        arsize_reg  <=  3'b0;
        arvalid_reg <=  1'b0;
    end else if (read_tran && ~arvalid) begin // 两种情况，读数据，读指令
        arid_reg    <= read_data ? 4'b1 : 4'b0;
        araddr_reg  <= read_data ? data_sram_addr : inst_sram_addr;
        arsize_reg  <= read_data ? {1'b0, data_sram_size} : {1'b0, inst_sram_size};
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
// sram interface
assign inst_sram_addr_ok = inst_sram_addr_ok_reg;
assign data_sram_addr_ok = data_sram_addr_ok_reg;
assign inst_sram_data_ok = inst_sram_data_ok_reg;
assign data_sram_data_ok = data_sram_data_ok_reg;
assign inst_sram_rdata   = inst_sram_rdata_reg  ;
assign data_sram_rdata   = data_sram_rdata_reg  ;
reg        inst_sram_addr_ok_reg;
reg        data_sram_addr_ok_reg;
reg        inst_sram_data_ok_reg;
reg        data_sram_data_ok_reg;
reg [31:0] inst_sram_rdata_reg  ;
reg [31:0] data_sram_rdata_reg  ;
always @(posedge clk) begin
    // addr_ok
    if (reset) begin
        inst_sram_addr_ok_reg <= 1'b0;
        data_sram_addr_ok_reg <= 1'b0;
    end else if (ar_handshake) begin
        inst_sram_addr_ok_reg <= arid ? 1'b0 : 1'b1;
        data_sram_addr_ok_reg <= arid ? 1'b1 : 1'b0;
    end else if (data_sram_req && data_sram_addr_ok_reg || inst_sram_req && inst_sram_addr_ok_reg) begin
        inst_sram_addr_ok_reg <= 1'b0;
        data_sram_addr_ok_reg <= 1'b0;
    end
end
always @(posedge clk) begin
    // data_ok & data
    if (reset) begin
        inst_sram_data_ok_reg <=  1'b0;
        data_sram_data_ok_reg <=  1'b0;
        inst_sram_rdata_reg   <= 32'b0;
        data_sram_rdata_reg   <= 32'b0;
    end else if (rvalid) begin
        {inst_sram_data_ok_reg, data_sram_data_ok_reg} <= rid ? {           1'b0,  1'b1} : { 1'b1,            1'b0}; 
        {inst_sram_rdata_reg  , data_sram_rdata_reg  } <= rid ? {inst_sram_rdata, rdata} : {rdata, data_sram_rdata};
    end
    if (inst_sram_data_ok) begin // data ok 信号只维持一拍
        inst_sram_data_ok_reg <= 1'b0;
    end
    if (data_sram_data_ok) begin
        data_sram_data_ok_reg <= 1'b0;
    end
end
endmodule