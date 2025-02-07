module mycpu_sram(
    input         clk              ,
    input         resetn           ,
    // inst sram interface
    output        inst_sram_req         ,
    output        inst_sram_wr          ,
    output [ 1:0] inst_sram_size        ,
    output [ 3:0] inst_sram_wstrb       ,
    output [31:0] inst_sram_addr        ,
    output [31:0] inst_sram_wdata       ,
    input  [31:0] inst_sram_addr_ok_addr,
    input         inst_sram_addr_ok     ,
    input         inst_sram_data_ok     ,
    input  [31:0] inst_sram_rdata       ,
    // data sram interface
    output        data_sram_req    ,
    output        data_sram_wr     ,
    output [ 1:0] data_sram_size   ,
    output [ 3:0] data_sram_wstrb  ,
    output [31:0] data_sram_addr   ,
    output [31:0] data_sram_wdata  ,
    input         data_sram_addr_ok,
    input         data_sram_data_ok,
    input  [31:0] data_sram_rdata  ,
    // trace debug interface
    output [31:0] debug_wb_pc      ,
    output [ 3:0] debug_wb_rf_wen  ,
    output [ 4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

wire [ 4:0]  EXE_dest  ;
wire [ 4:0]  MEM_dest  ;
wire [ 4:0]  WB_dest   ;
wire         es_load_op;
wire         ms_load_op;

//forward
wire [31:0]  EXE_dest_data;
wire [31:0]  MEM_dest_data;
wire [31:0]  WB_dest_data ;

wire         ds_allowin    ;
wire         es_allowin    ;
wire         ms_allowin    ;
wire         ws_allowin    ;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0] br_bus      ;
wire          WS_EX  ;
wire [31:0]   cp0_epc;
wire          ERET   ;

wire DS_EX;
wire ES_EX;
// EX word
wire [3:0] ex_word;
assign     ex_word = {DS_EX, ES_EX, MS_EX, WS_EX};
// IF stage
if_stage if_stage(
    .clk              (clk              ),
    .reset            (reset            ),
    //allowin
    .ds_allowin       (ds_allowin       ),
    //brbus
    .br_bus           (br_bus           ),
    //outputs
    .fs_to_ds_valid   (fs_to_ds_valid   ),
    .fs_to_ds_bus     (fs_to_ds_bus     ),
    // inst sram interface
    .inst_sram_en           (inst_sram_req         ),
    .inst_sram_wr           (inst_sram_wr          ),
    .inst_sram_size         (inst_sram_size        ),
    .inst_sram_wen          (inst_sram_wstrb       ),
    .inst_sram_addr         (inst_sram_addr        ),
    .inst_sram_wdata        (inst_sram_wdata       ),
    .inst_sram_addr_ok      (inst_sram_addr_ok     ),
    .inst_sram_addr_ok_addr (inst_sram_addr_ok_addr),
    .inst_sram_data_ok      (inst_sram_data_ok     ),
    .inst_sram_rdata        (inst_sram_rdata       ),
    // EX
    .ERET             (ERET             ),
    .cp0_epc          (cp0_epc          ),
    .ex_word          (ex_word          ),
    .tlbwi_inv        (tlbwi_inv        ),
    .tlbwi_pc         (tlbwi_pc         )
);
wire [ 3:0]               dm_word     ;
wire [ `LD_WORD_LEN -1:0] ld_word     ;
wire [ `MV_WORD_LEN -1:0] mv_word     ;
wire [ `ST_WORD_LEN -1:0] st_word     ; 
wire [ 2:0]               of_test     ;
wire                      ES_ERET     ;
wire                      es_inst_mfc0;
wire                      ms_inst_mfc0;
wire                      ws_inst_mfc0;
// ID stage
id_stage id_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    //from fs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //to es
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to fs
    .br_bus         (br_bus         ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //from es,ms,ws
    .es_inst_mfc0      (es_inst_mfc0     ),
    .ms_inst_mfc0      (ms_inst_mfc0     ),
    .ws_inst_mfc0      (ws_inst_mfc0     ),
    .EXE_dest          (EXE_dest         ),
    .MEM_dest          (MEM_dest         ),
    .WB_dest           (WB_dest          ),
    .es_load_op        (es_load_op       ),
    .ms_load_op        (ms_load_op       ),
    .data_sram_data_ok (data_sram_data_ok),
    //forward
    .EXE_dest_data (EXE_dest_data ),
    .MEM_dest_data (MEM_dest_data ),
    .WB_dest_data  (WB_dest_data  ),
    // word of div and mul (div / divu / mult / multu)
    .dm_word       (dm_word       ),
    // ld_word (LB / LBU / LH / LHU / LWL / LWR)
    .ld_word       (ld_word       ),
    // mv_word(MFLO, MFHI, MTLO, MTHI)
    .mv_word       (mv_word       ),
    // st_word (SB / SH / SWL / SWR)
    .st_word       (st_word       ),
    // EX
    .WS_EX         (WS_EX         ),
    .MS_EX         (MS_EX         ),
    .ES_EX         (ES_EX         ),
    .DS_EX         (DS_EX         ),
    .ERET          (ERET          ),
    .ES_ERET       (ES_ERET       ),
    .MS_ERET       (MS_ERET       ),
    .of_test       (of_test       )
);
wire [ 1:0] LDB                 ;
wire [`LD_WORD_LEN-1:0] ld_word_;
wire [31:0] rt_value      ;
wire        MS_EX         ;
wire        MS_ERET       ;
wire        es_inst_tlbp  ;
wire [31:0] cp0_EntryHi   ;
wire        ws_inst_mtc0  ;
wire        ms_inst_mtc0  ;

// EXE stage
exe_stage exe_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ms_allowin     (ms_allowin     ),
    .es_allowin     (es_allowin     ),
    //from ds
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to ms
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    // data sram interface
    .data_sram_en     (data_sram_req    ),
    .data_sram_wr     (data_sram_wr     ),
    .data_sram_size   (data_sram_size   ),
    .data_sram_wstrb  (data_sram_wstrb  ),
    .data_sram_addr   (data_sram_addr   ),
    .data_sram_wdata  (data_sram_wdata  ),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_data_ok(data_sram_data_ok),
    //data dependence
    .inst_mfc0      (es_inst_mfc0   ),
    .EXE_dest       (EXE_dest       ),
    .es_load_op     (es_load_op     ),
    //forward
    .EXE_dest_data  (EXE_dest_data  ),
    // word of div and mul (div / divu / mult / multu)
    .dm_word        (dm_word        ),
    // ld_word LB / LBU / LH / LHU / LWL / LWR & LDB
    .ld_word        (ld_word        ),
    .LDB            (LDB            ),
    .ld_word_       (ld_word_       ),
    // mv_word(MFLO / MFHI / MTHI / MTLO)
    .mv_word        (mv_word        ),
    // rt
    .rt_value       (rt_value       ),
    // st_word (SB / SH / SWL / SWR)
    .st_word        (st_word        ),
    // EX
    .WS_EX          (WS_EX          ),
    .MS_EX          (MS_EX          ),
    .ES_EX          (ES_EX          ),
    .ERET           (ERET           ),
    .MS_ERET        (MS_ERET        ),
    .ES_ERET        (ES_ERET        ),
    .of_test        (of_test        ),
    // tlbp
    .es_inst_tlbp   (es_inst_tlbp   ),
    .ms_inst_mtc0   (ms_inst_mtc0   ),
    .ws_inst_mtc0   (ws_inst_mtc0   )
);
// MEM stage
mem_stage mem_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .ms_allowin     (ms_allowin     ),
    //from es
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    //to ws
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //from data-sram
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata  (data_sram_rdata  ),
    //data dependence
    .inst_mfc0      (ms_inst_mfc0   ),
    .inst_mtc0      (ms_inst_mtc0   ),
    .MEM_dest       (MEM_dest       ),
    //forward
    .MEM_dest_data  (MEM_dest_data  ),
    .ms_load_op     (ms_load_op     ),
    // LDB & LB / LBU / LH / LHU / LWL / LWR
    .LDB            (LDB            ),
    .ld_word        (ld_word_       ),
    // rt
    .rt_value       (rt_value       ),
    // EX
    .WS_EX          (WS_EX          ),
    .ERET           (ERET           ),
    .MS_ERET        (MS_ERET        ),
    .MS_EX          (MS_EX          )
);
wire        tlbwi_inv;
wire [31:0] tlbwi_pc ;
// WB stage
wb_stage wb_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    //from ms
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    //data dependence
    .inst_mfc0        (ws_inst_mfc0     ),
    .WB_dest          (WB_dest          ),
    //forward
    .WB_dest_data     (WB_dest_data     ),
    // EX
    .WS_EX            (WS_EX            ),
    .cp0_epc          (cp0_epc          ),
    .ERET             (ERET             ),
    .tlbwi_inv        (tlbwi_inv        ),
    .tlbwi_pc         (tlbwi_pc         ),
    // tlbp
    .es_inst_tlbp     (es_inst_tlbp     ),
    .s1_found         (s1_found         ),
    .s1_index         (s1_index         ),
    .cp0_EntryHi      (cp0_EntryHi      ),
    .inst_mtc0        (ws_inst_mtc0     ),
    .tlbwi_we         (we               ),
    .tlbwi_index      (w_index          ),
    .tlbwi_vpn2       (w_vpn2           ),
    .tlbwi_asid       (w_asid           ),
    .tlbwi_g          (w_g              ),
    .tlbwi_pfn0       (w_pfn0           ),
    .tlbwi_c0         (w_c0             ),
    .tlbwi_d0         (w_d0             ),
    .tlbwi_v0         (w_v0             ),
    .tlbwi_pfn1       (w_pfn1           ),
    .tlbwi_c1         (w_c1             ), 
    .tlbwi_d1         (w_d1             ),
    .tlbwi_v1         (w_v1             )
);
wire [18:0] s1_vpn2;
wire [ 7:0] s1_asid;
wire s1_found, s1_index;
assign s1_vpn2 = cp0_EntryHi[31:13];
assign s1_asid = cp0_EntryHi[ 7: 0];
wire [ 3:0] w_index;
wire [18:0] w_vpn2 ;
wire [ 7:0] w_asid ;
wire        w_g, we;
wire [19:0] w_pfn0 ;
wire [ 2:0] w_c0   ;
wire        w_d0, w_v0;
wire [19:0] w_pfn1 ;
wire [ 2:0] w_c1   ;
wire        w_d1, w_v1;

// tlb
tlb #(.TLBNUM(16)) tlb
(
    .clk (clk),
    // search port 0
    .s0_vpn2     (s0_vpn2    ),
    .s0_odd_page (s0_odd_page),
    .s0_asid     (s0_asid    ),
    .s0_found    (s0_found   ),
    .s0_index    (s0_index   ),
    .s0_pfn      (s0_pfn     ),
    .s0_c        (s0_c       ),
    .s0_d        (s0_d       ),
    .s0_v        (s0_v       ),
    // search port 1
    .s1_vpn2     (s1_vpn2    ),
    .s1_odd_page (s1_odd_page),
    .s1_asid     (s1_asid    ),
    .s1_found    (s1_found   ),
    .s1_index    (s1_index   ),
    .s1_pfn      (s1_pfn     ),
    .s1_c        (s1_c       ),
    .s1_d        (s1_d       ),
    .s1_v        (s1_v       ),
    // write port
    .we      (we     ),
    .w_index (w_index),
    .w_vpn2  (w_vpn2 ),
    .w_asid  (w_asid ),
    .w_g     (w_g    ),
    .w_pfn0  (w_pfn0 ),
    .w_c0    (w_c0   ),
    .w_d0    (w_d0   ),
    .w_v0    (w_v0   ),
    .w_pfn1  (w_pfn1 ),
    .w_c1    (w_c1   ),
    .w_d1    (w_d1   ),
    .w_v1    (w_v1   ),
    // read port
    .r_index (r_index),
    .r_vpn2  (r_vpn2 ),
    .r_asid  (r_asid ),
    .r_g     (r_g    ),
    .r_pfn0  (r_pfn0 ),
    .r_c0    (r_c0   ),
    .r_d0    (r_d0   ),
    .r_v0    (r_v0   ),
    .r_pfn1  (r_pfn1 ),
    .r_c1    (r_c1   ),
    .r_d1    (r_d1   ),
    .r_v1    (r_v1   )
);

endmodule
