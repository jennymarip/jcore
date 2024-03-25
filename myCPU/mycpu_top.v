module mycpu_top(
    input         clk,
    input         resetn,
    // inst sram interface
    output        inst_sram_en,
    output [ 3:0] inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    // data sram interface
    output        data_sram_en,
    output [ 3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

wire [ 4:0]  EXE_dest;
wire [ 4:0]  MEM_dest;
wire [ 4:0]  WB_dest;
wire es_load_op;

//forward
wire [31:0]  EXE_dest_data;
wire [31:0]  MEM_dest_data;
wire [31:0]  WB_dest_data;

wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0] br_bus;
wire          WS_EX  ;
wire [31:0]   cp0_epc;
wire          ERET   ;

wire DS_EX;
wire ES_EX;

// IF stage
if_stage if_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ds_allowin     (ds_allowin     ),
    //brbus
    .br_bus         (br_bus         ),
    //outputs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    // inst sram interface
    .inst_sram_en   (inst_sram_en   ),
    .inst_sram_wen  (inst_sram_wen  ),
    .inst_sram_addr (inst_sram_addr ),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata),
    // EX
    .WS_EX          (WS_EX          ),
    .ERET           (ERET           ),
    .cp0_epc        (cp0_epc        ),
    .DS_EX          (DS_EX          ),
    .ES_EX          (ES_EX          ),
    .MS_EX          (MS_EX          )
);
wire        is_div    ;
wire        is_divu   ;
wire        is_mult   ;
wire        is_multu  ;
wire        LB        ;
wire        LBU       ;
wire        LH        ;
wire        LHU       ;
wire        LWL       ;
wire        LWR       ;
wire        MFLO      ; 
wire        MFHI      ; 
wire        MTLO      ;
wire        MTHI      ;
wire        SB        ;
wire        SH        ; 
wire        SWL       ; 
wire        SWR       ; 
wire        MFC0      ; 
wire [ 2:0] of_test   ;
wire        MTC0      ;
wire [31:0] mtc0_wdata;
wire [ 4:0] mtc0_waddr;
wire        ES_ERET   ;
wire        time_int  ;
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
    .EXE_dest      (EXE_dest      ),
    .MEM_dest      (MEM_dest      ),
    .WB_dest       (WB_dest       ),
    .es_load_op    (es_load_op    ),
    //forward
    .EXE_dest_data (EXE_dest_data ),
    .MEM_dest_data (MEM_dest_data ),
    .WB_dest_data  (WB_dest_data  ),
    // is div / divu / mult / multu
    .is_div        (is_div        ),
    .is_divu       (is_divu       ),
    .is_mult       (is_mult       ),
    .is_multu      (is_multu      ),
    // LB / LBU / LH / LHU / LWL / LWR
    .LB            (LB            ),
    .LBU           (LBU           ),
    .LH            (LH            ),
    .LHU           (LHU           ),
    .LWL           (LWL           ),
    .LWR           (LWR           ),
    // MFLO, MFHI, MTLO, MTHI
    .MFLO          (MFLO          ),
    .MFHI          (MFHI          ),
    .MTLO          (MTLO          ),
    .MTHI          (MTHI          ),
    // SB / SH / SWL / SWR
    .SB            (SB            ),
    .SH            (SH            ),
    .SWL           (SWL           ),
    .SWR           (SWR           ),
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
    // intern-core time interrupt
    .time_int      (time_int      )
);
wire [ 1:0] LDB      ;
wire        _LB      ;
wire        _LBU     ;
wire        _LH      ;
wire        _LHU     ;
wire        _LWL     ;
wire        _LWR     ;
wire [31:0] rt_value ;
wire        mfc0_read     ;
wire [ 4:0] mfc0_cp0_raddr;
wire        _MFC0     ;
wire [31:0] mfc0_rdata;
wire        MS_EX     ;
wire        MS_ERET   ;
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
    .data_sram_en   (data_sram_en   ),
    .data_sram_wen  (data_sram_wen  ),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata),
    //data dependence
    .EXE_dest       (EXE_dest       ),
    .es_load_op     (es_load_op     ),
    //forward
    .EXE_dest_data  (EXE_dest_data  ),
    // is div / divu / mult / multu
    .is_div         (is_div         ),
    .is_divu        (is_divu        ),
    .is_mult        (is_mult        ),
    .is_multu       (is_multu       ),
    // LB / LBU / LH / LHU / LWL / LWR & LDB
    .LB             (LB             ),
    .LBU            (LBU            ),
    .LH             (LH             ),
    .LHU            (LHU            ),
    .LWL            (LWL            ),
    .LWR            (LWR            ),
    .LDB            (LDB            ),
    ._LB            (_LB            ),
    ._LBU           (_LBU           ),
    ._LH            (_LH            ),
    ._LHU           (_LHU           ),
    ._LWL           (_LWL           ),
    ._LWR           (_LWR           ),
    // MFLO, MFHI, MTHI, MTLO
    .MFLO           (MFLO           ),
    .MFHI           (MFHI           ),
    .MTLO           (MTLO           ),
    .MTHI           (MTHI           ),
    // rt
    .rt_value       (rt_value       ),
    // SB / SH / SWL / SWR
    .SB             (SB             ),
    .SH             (SH             ),
    .SWL            (SWL            ),
    .SWR            (SWR            ),
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
    .data_sram_rdata(data_sram_rdata),
    //data dependence
    .MEM_dest       (MEM_dest       ),
    //forward
    .MEM_dest_data  (MEM_dest_data  ),
    // LDB & LB / LBU / LH / LHU / LWL / LWR
    .LDB            (LDB            ),
    ._LB            (_LB            ),
    ._LBU           (_LBU           ),
    ._LH            (_LH            ),
    ._LHU           (_LHU           ),
    ._LWL           (_LWL           ),
    ._LWR           (_LWR           ),
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
    // intern-core time interrupt
    .time_int         (time_int         )
);

endmodule
