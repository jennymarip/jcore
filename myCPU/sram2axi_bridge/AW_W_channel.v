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

endmodule