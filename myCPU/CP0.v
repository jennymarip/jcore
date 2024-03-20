`include "mycpu.h"
module CP0(
    input         clk  ,
    input         reset,
    // READ PORT
    input  [ 4:0] raddr,
    output [31:0] rdata,
    // WRITE PORT 
    input  [ 4:0] waddr,
    input  [31:0] wdata,
    // control
    input         ex
);
reg [31:0] cp0_epc;
always @(posedge clk) begin
    if (ex) begin
        cp0_epc <= wdata;
    end
end

assign rdata = (raddr == `CP0_EPC) ? cp0_epc : 32'b0;
endmodule