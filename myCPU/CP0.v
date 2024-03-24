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
    input         bd        ,
    input         eret      ,
    input  [31:0] BadVAddr  ,
    input         pc_error  ,
    // mtc0
    input         mtc0      ,
    input  [31:0] mtc0_wdata,
    input  [ 4:0] mtc0_waddr
);
wire ex;
assign ex = (ex_code != 5'b0);

// EPC
reg [31:0] cp0_epc;
always @(posedge clk) begin
    if (ex && !cp0_status_exl) begin
        cp0_epc <= (bd & ~pc_error) ? wdata - 3'h4 : 
                                      wdata;
    end
    if (mtc0 & (mtc0_waddr == `CP0_EPC)) begin
        cp0_epc <= mtc0_wdata;
    end
end
// CAUSE
reg cp0_cause_bd;
always @(posedge clk) begin
    if (reset) begin
        cp0_cause_bd <= 1'b0;
    end
    else if (ex && !cp0_status_exl) begin
        cp0_cause_bd <= bd;
    end
end
reg cp0_cause_ti;
always @(posedge clk) begin
    if(reset) begin
        cp0_cause_ti <= 1'b0;
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
// STATUS
reg cp0_status_bev;
always @(posedge clk) begin
    if (reset) begin
        cp0_status_bev <= 1'b1;
    end
end
reg [ 7:0] cp0_status_im;
always @(posedge clk) begin
    if (reset) begin
        cp0_status_im <= 8'b11111111;
    end
    else if (ex) begin
        cp0_status_im <= 8'b0;
    end
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

assign rdata = (raddr == `CP0_EPC)      ? cp0_epc :
               (raddr == `CP0_CAUSE)    ? {cp0_cause_bd,cp0_cause_ti,14'b0,cp0_cause_ip[7:0],1'b0,cp0_cause_excode[4:0],2'b0} :
               (raddr == `CP0_STATUS)   ? {9'b0, cp0_status_bev, 6'b0,cp0_status_im, 6'b0, cp0_status_exl, cp0_status_ie} :
               (raddr == `CP0_BadVAddr) ? cp0_badvaddr :
               32'b0;
endmodule