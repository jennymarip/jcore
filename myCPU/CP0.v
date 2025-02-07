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
    output [31:0] status    ,
    // tlbp
    input         es_inst_tlbp,
    input         s1_found    ,
    input         s1_index    ,
    output [ 3:0] index       ,
    output [18:0] vpn2        ,
    output [ 7:0] asid        ,
    output        g           ,
    output [19:0] pfn0        ,
    output [ 2:0] c0          ,
    output        d0          ,
    output        v0          ,
    output [19:0] pfn1        ,
    output [ 2:0] c1          ,
    output        d1          ,
    output        v1

);
assign index = cp0_index_index  ;
assign vpn2  = cp0_EnrtyHi_VPN2 ;
assign asid  = cp0_EnrtyHi_ASID ;
assign g     = cp0_EnrtyLo1_G1 && cp0_EnrtyLo0_G0;
assign pfn0  = cp0_EnrtyLo0_PFN0;
assign c0    = cp0_EnrtyLo0_C0  ;
assign d0    = cp0_EnrtyLo0_D0  ;
assign v0    = cp0_EnrtyLo0_V0  ;
assign pfn1  = cp0_EnrtyLo1_PFN1;
assign c1    = cp0_EnrtyLo1_C1  ;
assign d1    = cp0_EnrtyLo1_D1  ;
assign v1    = cp0_EnrtyLo1_V1  ;

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
assign cp0_cause = {cp0_cause_bd, cp0_cause_ti, 14'b0,cp0_cause_ip[7:0], 1'b0, cp0_cause_excode[4:0], 2'b0};

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

// index (tlb)
wire [31:0] cp0_index;
reg cp0_index_p;
always @ (posedge clk) begin
    if (reset) begin
        cp0_index_p <= 1'b0;
    end else if (es_inst_tlbp && s1_found) begin
        cp0_index_p <= 1'b0;
    end else if (es_inst_tlbp && ~s1_found) begin
        cp0_index_p <= 1'b1;
    end
end
reg [ 3:0] cp0_index_index;
always @ (posedge clk) begin
    if (reset) begin
        cp0_index_index <= 4'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_INDEX)) begin
        cp0_index_index <= mtc0_wdata[3:0];
    end else if (es_inst_tlbp && s1_found) begin
        cp0_index_index <= s1_index;
    end
end
assign cp0_index = {cp0_index_p, 26'b0, cp0_index_index};

// EnrtyLo0 (tlb)
wire [31:0] cp0_EnrtyLo0;
reg [19:0] cp0_EnrtyLo0_PFN0;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo0_PFN0 <= 20'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo0)) begin
        cp0_EnrtyLo0_PFN0 <= mtc0_wdata[25:6];
    end
end
reg [ 2:0] cp0_EnrtyLo0_C0;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo0_C0 <= 3'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo0)) begin
        cp0_EnrtyLo0_C0 <= mtc0_wdata[5:3];
    end
end
reg cp0_EnrtyLo0_D0;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo0_D0 <= 1'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo0)) begin
        cp0_EnrtyLo0_D0 <= mtc0_wdata[2];
    end
end
reg cp0_EnrtyLo0_V0;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo0_V0 <= 1'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo0)) begin
        cp0_EnrtyLo0_V0 <= mtc0_wdata[1];
    end
end
reg cp0_EnrtyLo0_G0;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo0_G0 <= 1'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo0)) begin
        cp0_EnrtyLo0_G0 <= mtc0_wdata[0];
    end
end
assign cp0_EnrtyLo0 = {6'b0, cp0_EnrtyLo0_PFN0, cp0_EnrtyLo0_C0, cp0_EnrtyLo0_D0, cp0_EnrtyLo0_V0, cp0_EnrtyLo0_G0};

// EnrtyLo1 (tlb)
wire [31:0] cp0_EnrtyLo1;
reg [19:0] cp0_EnrtyLo1_PFN1;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo1_PFN1 <= 20'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo1)) begin
        cp0_EnrtyLo1_PFN1 <= mtc0_wdata[25:6];
    end
end
reg [ 2:0] cp0_EnrtyLo1_C1;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo1_C1 <= 3'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo1)) begin
        cp0_EnrtyLo1_C1 <= mtc0_wdata[5:3];
    end
end
reg cp0_EnrtyLo1_D1;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo1_D1 <= 1'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo1)) begin
        cp0_EnrtyLo1_D1 <= mtc0_wdata[2];
    end
end
reg cp0_EnrtyLo1_V1;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo1_V1 <= 1'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo1)) begin
        cp0_EnrtyLo1_V1 <= mtc0_wdata[1];
    end
end
reg cp0_EnrtyLo1_G1;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyLo1_G1 <= 1'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyLo1)) begin
        cp0_EnrtyLo1_G1 <= mtc0_wdata[0];
    end
end
assign cp0_EnrtyLo1 = {6'b0, cp0_EnrtyLo1_PFN1, cp0_EnrtyLo1_C1, cp0_EnrtyLo1_D1, cp0_EnrtyLo1_V1, cp0_EnrtyLo1_G1};

// EnrtyHi (tlb)
wire [31:0] cp0_EnrtyHi;
reg [18:0] cp0_EnrtyHi_VPN2;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyHi_VPN2 <= 19'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyHi)) begin
        cp0_EnrtyHi_VPN2 <= mtc0_wdata[31:13];
    end
end
reg [ 7:0] cp0_EnrtyHi_ASID;
always @ (posedge clk) begin
    if (reset) begin
        cp0_EnrtyHi_ASID <= 8'b0;
    end else if (mtc0 && (mtc0_waddr == `CP0_EnrtyHi)) begin
        cp0_EnrtyHi_ASID <= mtc0_wdata[7:0];
    end
end
assign cp0_EnrtyHi = {cp0_EnrtyHi_VPN2, 5'b0, cp0_EnrtyHi_ASID};

// int
assign time_int = (cp0_count == cp0_compare);

assign rdata = (raddr == `CP0_EPC     ) ? cp0_epc      :
               (raddr == `CP0_CAUSE   ) ? cp0_cause    :
               (raddr == `CP0_STATUS  ) ? cp0_status   :
               (raddr == `CP0_BadVAddr) ? cp0_badvaddr :
               (raddr == `CP0_COUNT   ) ? cp0_count    :
               (raddr == `CP0_COMPARE ) ? cp0_compare  :
               (raddr == `CP0_INDEX   ) ? cp0_index    :
               (raddr == `CP0_EnrtyHi ) ? cp0_EnrtyHi  :
               (raddr == `CP0_EnrtyLo0) ? cp0_EnrtyLo0 :
               (raddr == `CP0_EnrtyLo1) ? cp0_EnrtyLo1 :
               32'b0;
endmodule