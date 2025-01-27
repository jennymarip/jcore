// 写请求，写数据
module AW_W_channel(
    input clk  ,
    input reset,
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
    input         wready
);
// controll
wire   write_tran;
assign write_tran = data_sram_req && data_sram_wr;
/* aw controll */

/* w controll */

// AW
assign awid    = awid_reg   ;
assign awaddr  = awaddr_reg ;
assign awlen   = 8'b0       ;
assign awsize  = awsize_reg ;
assign awburst = 2'b1       ;
assign awlock  = 2'b0       ;
assign awcache = 4'b0       ;
assign awprot  = 3'b0       ;
assign awvalid = awvalid_reg;

reg [ 3:0] awid_reg   ;
reg [31:0] awaddr_reg ;
reg [ 2:0] awsize_reg ;
reg        awvalid_reg;

// W
assign wid    = wid_reg   ;
assign wdata  = wdata_reg ;
assign wstrb  = wstrb_reg ;
assign wlast  = 1'b1      ;
assign wvalid = wvalid_reg;

reg [ 3:0] wid_reg   ;
reg [31:0] wdata_reg ;
reg [ 3:0] wstrb_reg ;
reg        wvalid_reg;
endmodule