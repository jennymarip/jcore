module i_mmu(
    input  [31:0] vaddr ,
    output [31:0] paddr ,
    // tlb interface
    output [18:0] s0_vpn2    ,
    output        s0_odd_page,
    input         s0_found   ,
    input  [19:0] s0_pfn     ,
    input         s0_d       ,
    input         s0_v
);
// tlb interface
assign s0_vpn2     = vaddr[31:13];
assign s0_odd_page = vaddr[12]   ;

// paddr
wire   unmapped;
assign unmapped = vaddr[31] && (vaddr[30:28] <= 3'b100);
assign paddr = unmapped ? vaddr : {s0_pfn, vaddr[11:0]};

endmodule