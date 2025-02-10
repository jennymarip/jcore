module d_mmu(
    input  [31:0] vaddr ,
    input         w_or_r, // 1:w, 0:r
    output [31:0] paddr ,
    output [ 4:0] excode,
    output        refill,
    // tlb interface
    output [18:0] s1_vpn2    ,
    output        s1_odd_page,
    input         s1_found   ,
    input  [19:0] s1_pfn     ,
    input         s1_d       ,
    input         s1_v
);
// tlb interface
assign s1_vpn2     = vaddr[31:13];
assign s1_odd_page = vaddr[12]   ;

// paddr
wire   unmapped;
assign unmapped = vaddr[31] && (vaddr[30:28] <= 3'b100);
assign paddr = unmapped ? vaddr : {s1_pfn, vaddr[11:0]};

// ex
// assign excode = ~(s1_found && s1_v) ? (w_or_r ? 5'b00011 : 5'b00010) :
//                 (~s1_d && w_or_r  ) ? 5'b00001                       :
//                                       5'b11111;
assign excode = 5'b11111;
assign refill = ~s1_found;
endmodule