`include "mycpu.h"

module wb_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    output                          ws_allowin    ,
    //from ms
    input                           ms_to_ws_valid,
    input  [`MS_TO_WS_BUS_WD -1:0]  ms_to_ws_bus  ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus  ,
    //trace debug interface
    output [31:0] debug_wb_pc      ,
    output [ 3:0] debug_wb_rf_wen  ,
    output [ 4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata,
    //to ds data dependence
    output        inst_mfc0       ,
    output [ 4:0] WB_dest         ,
    //forward
    output [31:0] WB_dest_data    ,
    // EX
    output        WS_EX           ,
    output [31:0] cp0_epc         ,
    output        ERET            ,
    output        tlb_inv         ,
    output [31:0] tlb_pc          ,
    output        refill          ,
    // tlbp
    input         es_inst_tlbp    ,
    input         s1_found        ,
    input         s1_index        ,
    output [31:0] cp0_EntryHi     ,
    output        inst_mtc0       ,
    output        tlbwi_we        ,
    output [ 3:0] tlbwi_index     ,
    output [18:0] tlbwi_vpn2      ,
    output [ 7:0] tlbwi_asid      ,
    output        tlbwi_g         ,
    output [19:0] tlbwi_pfn0      ,
    output [ 2:0] tlbwi_c0        ,
    output        tlbwi_d0        ,
    output        tlbwi_v0        ,
    output [19:0] tlbwi_pfn1      ,
    output [ 2:0] tlbwi_c1        ,
    output        tlbwi_d1        ,
    output        tlbwi_v1        ,
    output [ 3:0] tlbr_index      ,
    input  [18:0] tlbr_vpn2       ,
    input  [ 7:0] tlbr_asid       ,
    input         tlbr_g          ,
    input  [19:0] tlbr_pfn0       ,
    input  [ 2:0] tlbr_c0         ,
    input         tlbr_d0         ,
    input         tlbr_v0         ,
    input  [19:0] tlbr_pfn1       ,
    input  [ 2:0] tlbr_c1         ,
    input         tlbr_d1         ,
    input         tlbr_v1         ,
    // mmu
    output [ 7:0] ASID
);
assign ASID = asid;

reg         ws_valid;
wire        ws_ready_go;

reg [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;
wire        ws_gr_we;
wire [ 4:0] ws_dest;
wire [31:0] ws_final_result;
wire [31:0] ws_pc        ;
wire        slot         ;
wire        eret         ;
wire [ 4:0] ex_code      ;
wire [31:0] BadVAddr     ;
wire        pc_error     ;
wire        ws_inst_mtc0 ;
wire        ws_inst_mfc0 ;
wire        ws_inst_tlbwi;
wire        ws_inst_tlbr ;
wire [ 4:0] rd           ;
wire        refill       ;
assign {refill         ,  //119:119
        rd             ,  //118:114
        ws_inst_tlbr   ,  //113:113
        ws_inst_tlbwi  ,  //112:112
        ws_inst_mfc0   ,  //111:111
        ws_inst_mtc0   ,  //110:110
        pc_error       ,  //109:109
        BadVAddr          //108: 77
       } = ms_to_ws_bus_r[119:77];
assign {eret           ,  //71:71
        slot           ,  //70:70
        ws_gr_we       ,  //69:69
        ws_dest        ,  //68:64
        ws_final_result,  //63:32
        ws_pc             //31: 0
       } = ms_to_ws_bus_r[71:0];
wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;

assign WB_dest   = ws_dest & {5{ws_valid}};
assign inst_mfc0 = ws_inst_mfc0;

assign ws_to_rf_bus = {rf_we   ,  //37:37
                       rf_waddr,  //36:32
                       rf_wdata   //31:0
                      };

assign ws_ready_go = 1'b1;
assign ws_allowin  = !ws_valid || ws_ready_go;
always @(posedge clk) begin
    if (reset | (ex_code != `NO_EX) | eret) begin
        ws_valid       <= 1'b0;
        ms_to_ws_bus_r <= {33'b0, 5'b11111,72'b0};
    end
    else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
        ms_to_ws_bus_r <= ms_to_ws_bus;
    end
end

assign rf_we    = ws_gr_we&&ws_valid & ~WS_EX;
assign rf_waddr = ws_dest;
assign rf_wdata = ws_inst_mfc0 ? cp0_rdata : ws_final_result;

// forward
assign WB_dest_data = rf_wdata;

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = rf_wdata;

// EX
wire [31:0] cause    ;
wire [31:0] status   ;
wire        interrupt;
assign interrupt = ((cause[15:8] & status[15:8]) != 8'b0) && (status[1:0] == 2'b01) && ws_valid;
assign ex_code = interrupt ? `INT :
                              ms_to_ws_bus_r[76:72];

assign WS_EX = (ex_code != `NO_EX);
assign ERET  = eret ;
assign tlb_inv = (ex_code == `TLB_INV) && ws_valid;
assign tlb_pc  = ws_pc        ;

wire [ 4:0] cp0_raddr;
wire [31:0] cp0_rdata;
wire [ 4:0] cp0_waddr;
wire [31:0] cp0_wdata;

assign cp0_epc    = eret ? cp0_rdata : 32'b0;
assign cp0_raddr = ws_inst_mfc0 ? rd           :
                   eret         ? `CP0_EPC     :
                   es_inst_tlbp ? `CP0_EnrtyHi :
                   ws_inst_tlbr ? `CP0_INDEX   :
                                  5'b11111;
assign cp0_EntryHi = cp0_rdata;
assign inst_mtc0 = ws_inst_mtc0 && ws_valid;
assign cp0_waddr   = WS_EX ? `CP0_EPC :  5'b11111;
assign cp0_wdata   = WS_EX ? (pc_error ? BadVAddr : ws_pc) : 31'b0;

// tlb
wire [ 3:0] index ;
wire [18:0] vpn2  ;
wire [ 7:0] asid  ;
wire        g     ;
wire [19:0] pfn0  ;
wire [ 2:0] c0    ;
wire        d0, v0;
wire [19:0] pfn1  ;
wire [ 2:0] c1    ;
wire        d1, v1;
assign tlbwi_we = ws_inst_tlbwi && ws_valid;
assign {tlbwi_index, tlbwi_vpn2, tlbwi_asid, tlbwi_g, tlbwi_pfn0, tlbwi_c0, tlbwi_d0, tlbwi_v0, tlbwi_pfn1, tlbwi_c1, tlbwi_d1, tlbwi_v1} = {
    index, vpn2, asid, g, pfn0, c0, d0, v0, pfn1, c1, d1, v1
};
assign tlbr_index = ws_inst_tlbr ? cp0_rdata[3:0] : 4'b0;
// CP0
CP0 CP0(
    .clk        (clk          ),
    .reset      (reset        ),
    // read
    .raddr      (cp0_raddr    ),
    .rdata      (cp0_rdata    ),
    // write
    .waddr      (cp0_waddr    ),
    .wdata      (cp0_wdata    ),
    // control
    .ex_code    (ex_code      ),
    .slot       (slot         ),
    .eret       (eret         ),
    .BadVAddr   (BadVAddr     ),
    .pc_error   (pc_error     ),
    // mtc0
    .mtc0       (ws_inst_mtc0    ),
    .mtc0_wdata (ws_final_result ),
    .mtc0_waddr (ws_dest         ),
    // interrupt generate
    .cause      (cause        ),
    .status     (status       ),
    // tlbp
    .es_inst_tlbp (es_inst_tlbp),
    .s1_found     (s1_found    ),
    .s1_index     (s1_index    ),
    // tlbwi
    .index        (index       ),
    .vpn2         (vpn2        ),
    .asid         (asid        ),
    .g            (g           ),
    .pfn0         (pfn0        ),
    .c0           (c0          ),
    .d0           (d0          ),
    .v0           (v0          ),
    .pfn1         (pfn1        ),
    .c1           (c1          ),
    .d1           (d1          ),
    .v1           (v1          ),
    // tlbr
    .ws_inst_tlbr (ws_inst_tlbr && ws_valid),
    .r_vpn2       (tlbr_vpn2   ),
    .r_asid       (tlbr_asid   ),
    .r_g          (tlbr_g      ),
    .r_pfn0       (tlbr_pfn0   ),
    .r_c0         (tlbr_c0     ),
    .r_d0         (tlbr_d0     ),
    .r_v0         (tlbr_v0     ),
    .r_pfn1       (tlbr_pfn1   ),
    .r_c1         (tlbr_c1     ),
    .r_d1         (tlbr_d1     ),
    .r_v1         (tlbr_v1     )
    );
endmodule
