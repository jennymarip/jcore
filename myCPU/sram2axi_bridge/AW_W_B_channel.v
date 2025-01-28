// 写请求，写数据
module AW_W_B_channel(
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
// controll
wire   write_tran;
assign write_tran = data_sram_req && data_sram_wr;
/* aw controll */
wire   aw_handshake, aw_handshake_flag;
reg    aw_handshake_reg;
assign aw_handshake      = awvalid && awready;
assign aw_handshake_flag = aw_handshake || aw_handshake_reg;
always @(posedge clk) begin
    if (reset || b_handshake) begin
        aw_handshake_reg <= 1'b0;
    end else if (aw_handshake) begin
        aw_handshake_reg <= 1'b1;
    end
end
/* w controll */
wire   w_handshake, w_handshake_flag;
reg    w_handshake_reg;
assign w_handshake      = wvalid && wready;
assign w_handshake_flag = w_handshake || w_handshake_reg;
always @(posedge clk) begin
    if (reset || b_handshake) begin
        w_handshake_reg <= 1'b0;
    end else if (w_handshake) begin
        w_handshake_reg <= 1'b1;
    end
end
/* b controll */
wire   b_handshake;
assign b_handshake = bvalid && bready;
// AW & W
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

assign wid    = wid_reg   ;
assign wdata  = wdata_reg ;
assign wstrb  = wstrb_reg ;
assign wlast  = 1'b1      ;
assign wvalid = wvalid_reg;

reg [ 3:0] wid_reg   ;
reg [31:0] wdata_reg ;
reg [ 3:0] wstrb_reg ;
reg        wvalid_reg;
always @(posedge clk) begin
    if (reset) begin
        awid_reg    <=  4'b0;
        awaddr_reg  <= 32'b0;
        awsize_reg  <=  3'b0;
        awvalid_reg <=  1'b0;
        wid_reg     <=  4'b0;
        wdata_reg   <= 32'b0;
        wstrb_reg   <=  4'b0;
        wvalid_reg  <=  1'b0;
    end else if (write_tran) begin
        awid_reg    <= 1'b1;
        awaddr_reg  <= data_sram_addr;
        awsize_reg  <= {1'b0, data_sram_size};
        awvalid_reg <= 1'b1;
        wid_reg     <= 1'b1;
        wdata_reg   <= data_sram_wdata;
        wstrb_reg   <= data_sram_wstrb;
        wvalid_reg  <= 1'b1;
    end
end

// B
assign bready = bready_reg;
reg bready_reg;
always @(posedge clk) begin
    if (reset) begin
        bready_reg <= 1'b0;
    end else if (bvalid && ~b_handshake) begin
        bready_reg <= 1'b1;
    end else if (b_handshake) begin
        bready_reg <= 1'b0;
    end
end

// data sram interface
assign data_sram_addr_ok = data_sram_addr_ok_reg;
assign data_sram_data_ok = data_sram_data_ok_reg;

reg        data_sram_addr_ok_reg;
reg        data_sram_data_ok_reg;
always @(posedge clk) begin
    // addr_ok
    if (reset) begin
        data_sram_addr_ok_reg <= 1'b0;
    end else if (aw_handshake_flag && w_handshake_flag) begin
        data_sram_addr_ok_reg <= 1'b1;
    end else if (data_sram_req && data_sram_addr_ok_reg) begin
        data_sram_addr_ok_reg <= 1'b0;
    end else begin
        data_sram_addr_ok_reg <= 1'b0;
    end
end
always @(posedge clk) begin
    // data_ok
    if (reset || data_sram_data_ok) begin
        data_sram_data_ok_reg <= 1'b0;
    end else if (bvalid) begin
        data_sram_data_ok_reg <= 1'b1;
    end else begin
        data_sram_data_ok_reg <= 1'b0;
    end
end
endmodule