module mycpu_top(
    input         clk              ,
    input         resetn           ,
    // inst sram interface
    output        inst_sram_req    ,
    output        inst_sram_wr     ,
    output [ 1:0] inst_sram_size   ,
    output [ 3:0] inst_sram_wstrb  ,
    output [31:0] inst_sram_addr   ,
    output [31:0] inst_sram_wdata  ,
    input         inst_sram_addr_ok,
    input         inst_sram_data_ok,
    input  [31:0] inst_sram_rdata  ,
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
    .inst_sram_en     (inst_sram_req    ),
    .inst_sram_wr     (inst_sram_wr     ),
    .inst_sram_size   (inst_sram_size   ),
    .inst_sram_wen    (inst_sram_wstrb  ),
    .inst_sram_addr   (inst_sram_addr   ),
    .inst_sram_wdata  (inst_sram_wdata  ),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_data_ok(inst_sram_data_ok),
    .inst_sram_rdata  (inst_sram_rdata  ),
    // EX
    .ERET             (ERET             ),
    .cp0_epc          (cp0_epc          ),
    .ex_word          (ex_word          )
);
wire [ 3:0]               dm_word   ;
wire [ `LD_WORD_LEN -1:0] ld_word   ;
wire [ `MV_WORD_LEN -1:0] mv_word   ;
wire [ `ST_WORD_LEN -1:0] st_word   ;
wire                      MFC0      ; 
wire [ 2:0]               of_test   ;
wire                      MTC0      ;
wire [31:0]               mtc0_wdata;
wire [ 4:0]               mtc0_waddr;
wire                      ES_ERET   ;
wire [31:0]               cause     ;
wire [31:0]               status    ;
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
    .MFC0          (MFC0          ),
    .of_test       (of_test       ),
    // CP0 WRITE
    .MTC0          (MTC0          ),
    .mtc0_wdata    (mtc0_wdata    ),
    .mtc0_waddr    (mtc0_waddr    ),
    // interrupt
    .cause         (cause         ),
    .status        (status        )
);
wire [ 1:0] LDB                 ;
wire [`LD_WORD_LEN-1:0] ld_word_;
wire [31:0] rt_value      ;
wire        mfc0_read     ;
wire [ 4:0] mfc0_cp0_raddr;
wire        _MFC0         ;
wire [31:0] mfc0_rdata    ;
wire        MS_EX         ;
wire        MS_ERET       ;
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
    .MFC0           (MFC0           ),
    ._MFC0          (_MFC0          ),
    .of_test        (of_test        ),
    // READ CP0
    .mfc0_read      (mfc0_read      ),
    .mfc0_cp0_raddr (mfc0_cp0_raddr ),
    .mfc0_rdata     (mfc0_rdata     )
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
    .MS_EX          (MS_EX          ),
    // READ CP0
    .MFC0           (_MFC0          )
);
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
    .WB_dest          (WB_dest          ),
    //forward
    .WB_dest_data     (WB_dest_data     ),
    // EX
    .WS_EX            (WS_EX            ),
    .cp0_epc          (cp0_epc          ),
    .ERET             (ERET             ),
    // READ CP0
    .mfc0_read        (mfc0_read        ),
    .mfc0_cp0_raddr   (mfc0_cp0_raddr   ),
    .mfc0_rdata       (mfc0_rdata       ),
    // MTC0 WRITE
    .MTC0             (MTC0             ),
    .mtc0_wdata       (mtc0_wdata       ),
    .mtc0_waddr       (mtc0_waddr       ),
    // interrupt
    .cause            (cause            ),
    .status           (status           )
);

endmodule
