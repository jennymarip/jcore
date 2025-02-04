module tlb #(
    parameter TLBNUM = 16
)(
    input clk,
    // search port 0
    input  [              18:0] s0_vpn2    ,
    input                       s0_odd_page,
    input  [               7:0] s0_asid    ,
    output                      s0_found   ,
    output [$clog2(TLBNUM)-1:0] s0_index   ,
    output [              19:0] s0_pfn     ,
    output [               2:0] s0_c       ,
    output                      s0_d       ,
    output                      s0_v       ,
    // search port 1
    input  [              18:0] s1_vpn2    ,
    input                       s1_odd_page,
    input  [               7:0] s1_asid    ,
    output                      s1_found   ,
    output [$clog2(TLBNUM)-1:0] s1_index   ,
    output [              19:0] s1_pfn     ,
    output [               2:0] s1_c       ,
    output                      s1_d       ,
    output                      s1_v       ,
    // write port
    input                      we     ,
    input [$clog2(TLBNUM)-1:0] w_index,
    input [              18:0] w_vpn2 ,
    input [               7:0] w_asid ,
    input                      w_g    ,
    input [              19:0] w_pfn0 ,
    input [               2:0] w_c0   ,
    input                      w_d0   ,
    input                      w_v0   ,
    input [              19:0] w_pfn1 ,
    input [               2:0] w_c1   ,
    input                      w_d1   ,
    input                      w_v1   ,
    // read port
    input  [$clog2(TLBNUM)-1:0] r_index,
    output [              18:0] r_vpn2 ,
    output [               7:0] r_asid ,
    output                      r_g    ,
    output [              19:0] r_pfn0 ,
    output [               2:0] r_c0   ,
    output                      r_d0   ,
    output                      r_v0   ,
    output [              19:0] r_pfn1 ,
    output [               2:0] r_c1   ,
    output                      r_d1   ,
    output                      r_v1
);
// tlb table
reg [18:0] tlb_vpn2 [TLBNUM-1:0];
reg [ 7:0] tlb_asid [TLBNUM-1:0];
reg        tlb_g    [TLBNUM-1:0];
reg [19:0] tlb_pfn0 [TLBNUM-1:0];
reg [ 2:0] tlb_c0   [TLBNUM-1:0];
reg        tlb_d0   [TLBNUM-1:0];
reg        tlb_v0   [TLBNUM-1:0];
reg [19:0] tlb_pfn1 [TLBNUM-1:0];
reg [ 2:0] tlb_c1   [TLBNUM-1:0];
reg        tlb_d1   [TLBNUM-1:0];
reg        tlb_v1   [TLBNUM-1:0];

// write
always @ (posedge clk) begin
    if (we) begin
        tlb_vpn2[w_index] <= w_vpn2;
        tlb_asid[w_index] <= w_asid;
        tlb_g   [w_index] <= w_g   ;
        tlb_pfn0[w_index] <= w_pfn0;
        tlb_c0  [w_index] <= w_c0  ;
        tlb_d0  [w_index] <= w_d0  ;
        tlb_v0  [w_index] <= w_v0  ;
        tlb_pfn1[w_index] <= w_pfn1;
        tlb_c1  [w_index] <= w_c1  ;
        tlb_d1  [w_index] <= w_d1  ;
        tlb_v1  [w_index] <= w_v1  ;
    end
end

// read
assign r_vpn2 = tlb_vpn2[r_index];
assign r_asid = tlb_asid[r_index];
assign r_g    = tlb_g   [r_index];
assign r_pfn0 = tlb_pfn0[r_index];
assign r_c0   = tlb_c0  [r_index];
assign r_d0   = tlb_d0  [r_index];
assign r_v0   = tlb_v0  [r_index];
assign r_pfn1 = tlb_pfn1[r_index];
assign r_c1   = tlb_c1  [r_index];
assign r_d1   = tlb_d1  [r_index];
assign r_v1   = tlb_v1  [r_index];

// search
wire [TLBNUM-1:0] match0;
wire [TLBNUM-1:0] match1;
assign s0_found = (match0 != 16'b0);
assign s1_found = (match1 != 16'b0);

genvar i;
generate
    for(i=0;i<TLBNUM;i=i+1)
    begin: set_match
        assign match0[i] = (s0_vpn2==tlb_vpn2[i]) && ((s0_asid==tlb_asid[i])||tlb_g[i]);
        assign match1[i] = (s1_vpn2==tlb_vpn2[i]) && ((s1_asid==tlb_asid[i])||tlb_g[i]);
    end
endgenerate
encoder_16_4 enc0(
    .in  (match0  ),
    .out (s0_index)
);
encoder_16_4 enc1(
    .in  (match1  ),
    .out (s1_index)
);
assign {s0_pfn, s0_c, s0_d, s0_v} = s0_odd_page ? {tlb_pfn1[s0_index], tlb_c1[s0_index], tlb_d1[s0_index], tlb_v1[s0_index]} :
                                                  {tlb_pfn0[s0_index], tlb_c0[s0_index], tlb_d0[s0_index], tlb_v0[s0_index]};
assign {s1_pfn, s1_c, s1_d, s1_v} = s1_odd_page ? {tlb_pfn1[s1_index], tlb_c1[s1_index], tlb_d1[s1_index], tlb_v1[s1_index]} :
                                                  {tlb_pfn0[s1_index], tlb_c0[s1_index], tlb_d0[s1_index], tlb_v0[s1_index]};
endmodule