`include "mycpu.h"
module CP0(
    input         clk   ,
    input         reset ,
    // READ PORT
    input  [ 4:0] raddr ,
    output [31:0] rdata ,
    // WRITE PORT 
    input  [ 4:0] waddr ,
    input  [31:0] wdata ,
    // control
    input  [ 4:0] ex_code   ,
    input         slot      ,
    input         eret      ,
    input  [31:0] BadVAddr  ,
    input         pc_error  ,
    // mtc0
    input         mtc0      ,
    input  [31:0] mtc0_wdata,
    input  [ 4:0] mtc0_waddr,
    // interrupt generate
    output [31:0] cause     ,
    output [31:0] status
);
wire   ex                          ;
assign ex     = (ex_code != `NO_EX);
assign cause  = cp0_cause          ;
assign status = cp0_status         ;

// EPC
reg [31:0] cp0_epc;
always @(posedge clk) begin
    if (ex && !cp0_status_exl) begin
        cp0_epc <= (slot & ~pc_error) ? wdata - 3'h4 : 
                                        wdata;
    end
    if (mtc0 & (mtc0_waddr == `CP0_EPC)) begin
        cp0_epc <= mtc0_wdata;
    end
end
// CAUSE
wire [31:0] cp0_cause;
reg cp0_cause_bd;
always @(posedge clk) begin
    if (reset) begin
        cp0_cause_bd <= 1'b0;
    end
    else if (ex && !cp0_status_exl) begin
        cp0_cause_bd <= slot;
    end
end
reg    cp0_cause_ti;
wire   count_eq_compare;
assign count_eq_compare = (cp0_count == cp0_compare);
always @(posedge clk) begin
    if(reset) begin
        cp0_cause_ti <= 1'b0;
    end
    else if (count_eq_compare) begin
        cp0_cause_ti <= 1'b1;
    end
end
reg [ 7:0] cp0_cause_ip;
always @(posedge clk) begin
    if(reset) begin
        cp0_cause_ip[7:0] <= 8'b0;
    end
    else if (mtc0 & (mtc0_waddr == `CP0_CAUSE)) begin
        cp0_cause_ip[7:0] <= mtc0_wdata[15:8];
    end
    else begin
        cp0_cause_ip[7] <= cp0_cause_ti;
    end
end
reg [ 4:0] cp0_cause_excode;
always @(posedge clk) begin
    if(reset) begin
        cp0_cause_excode <= 5'b0;
    end
    else if (ex) begin
        cp0_cause_excode <= ex_code;
    end
end
assign cp0_cause = {cp0_cause_bd,cp0_cause_ti,14'b0,cp0_cause_ip[7:0],1'b0,cp0_cause_excode[4:0],2'b0};
// STATUS
wire [31:0] cp0_status;
reg cp0_status_bev;
always @(posedge clk) begin
    if (reset) begin
        cp0_status_bev <= 1'b1;
    end
end
reg [ 7:0] cp0_status_im;
always @(posedge clk) begin
    if (mtc0 & (mtc0_waddr == `CP0_STATUS)) begin
        cp0_status_im <= mtc0_wdata[15:8];
    end
end
reg cp0_status_exl;
always @(posedge clk) begin
    if (reset | eret) begin
        cp0_status_exl <= 1'b0;
    end
    else if (ex) begin
        cp0_status_exl <= 1'b1;
    end
    if (mtc0 & (mtc0_waddr == `CP0_STATUS)) begin
        cp0_status_exl <= mtc0_wdata[1];
    end
end
reg cp0_status_ie;
always @(posedge clk) begin
    if (reset) begin
        cp0_status_ie <= 1'b0;
    end
    else if (mtc0 & (mtc0_waddr == `CP0_STATUS)) begin
        cp0_status_ie <= mtc0_wdata[0];
    end
end
assign cp0_status = {9'b0, cp0_status_bev, 6'b0,cp0_status_im, 6'b0, cp0_status_exl, cp0_status_ie};
// BadVAddr
reg [31: 0] cp0_badvaddr;
always @(posedge clk) begin
    if (reset) begin
        cp0_badvaddr <= 32'b0;
    end
    else if (ex & (ex_code == `ADEL | ex_code == `ADES)) begin
        cp0_badvaddr <= BadVAddr;
    end
end
// COUNT
reg [31:0] cp0_count;
reg        tick     ;
always @(posedge clk) begin
    if (reset) begin
        tick      <=  1'b0;
    end
    else begin
        tick <= ~tick;
    end
    if (mtc0 & (mtc0_waddr == `CP0_COUNT)) begin
        cp0_count <= mtc0_wdata;
    end
    else if (tick) begin
        cp0_count <= cp0_count + 1'b1;
    end
end
// COMPARE
reg [31:0] cp0_compare;
always @(posedge clk) begin
    if (mtc0 & (mtc0_waddr == `CP0_COMPARE)) begin
        cp0_compare  <= mtc0_wdata;
        cp0_cause_ti <= 1'b0;
    end
end
// int
assign time_int = (cp0_count == cp0_compare);

assign rdata = (raddr == `CP0_EPC     ) ? cp0_epc      :
               (raddr == `CP0_CAUSE   ) ? cp0_cause    :
               (raddr == `CP0_STATUS  ) ? cp0_status   :
               (raddr == `CP0_BadVAddr) ? cp0_badvaddr :
               (raddr == `CP0_COUNT   ) ? cp0_count    :
               (raddr == `CP0_COMPARE ) ? cp0_compare  :
               32'b0;
endmodule