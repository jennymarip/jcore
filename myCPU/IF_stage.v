`include "mycpu.h"

module if_stage(
    input                          clk              ,
    input                          reset            ,
    // allowin
    input                          ds_allowin       ,
    // brbus
    input  [`BR_BUS_WD       -1:0] br_bus           ,
    // to ds
    output                         fs_to_ds_valid   ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus     ,
    // inst sram interface
    output                    inst_sram_en          ,
    output                    inst_sram_wr          ,
    output [ 1:0]             inst_sram_size        ,
    output [ 3:0]             inst_sram_wen         ,
    output [31:0]             inst_sram_addr        ,
    output [31:0]             inst_sram_wdata       ,
    input                     inst_sram_addr_ok     ,
    input  [31:0]             inst_sram_addr_ok_addr,
    input                     inst_sram_data_ok     ,
    input  [31:0]             inst_sram_rdata       ,
    // EX (ex_word[DS, ES, MS, WS])
    input                          ERET             ,
    input  [31:0]                  cp0_epc          ,
    input  [ 3:0]                  ex_word          ,
    input                          tlb_inv        ,
    input  [31:0]                  tlb_pc
);

reg         fs_valid   ;
wire        fs_ready_go;
wire        fs_allowin ;
wire        to_fs_valid;

wire [31:0] seq_pc;
wire [31:0] nextpc;


// BU (pre decode => get is_branch when the instruction is in IF stage)
// branch_in_fs indicates the instruction in the if-stage is branch-type
// is_slot_reg indicates the instruction in the if-stage is a slot
// is_slot_reg is got via is_branch_reg
wire         is_branch    ;
reg          is_branch_reg;
reg          is_slot_reg  ;
wire         branch_in_fs ;
assign       branch_in_fs = is_branch || is_branch_reg;
pre_decode pre_decode(
    .fs_inst   (fs_inst & {32{inst_sram_data_ok && ~quit_a_data_ok_flag}}),
    .is_branch (is_branch                                                ) 
);
always @(posedge clk) begin
    // set is_branch_reg
    if (reset) begin
        is_branch_reg <= 1'b0;
    end
    else if (is_branch) begin
        is_branch_reg <= 1'b1;
    end
    else if (fs_allowin && to_fs_valid) begin
        is_branch_reg <= 1'b0;
    end
    // set is_slot_reg
    if (reset) begin
        is_slot_reg <= 1'b0;
    end
    else if(is_branch_reg && fs_allowin && to_fs_valid) begin
        is_slot_reg <= 1'b1;
    end
    else if (fs_allowin && to_fs_valid) begin
        is_slot_reg <= 1'b0;
    end
end
wire         br                                   ;
wire         br_stall                             ;
wire         br_taken                             ;
wire [31:0]  br_target                            ;
assign {br, br_stall, br_taken} = br_bus[34:32]   ;
assign       br_target = br_taken_reg ? br_target_reg : br_bus[31:0];
// save the branch info
reg          br_taken_reg ;
reg  [31:0]  br_target_reg;
always @(posedge clk) begin
    if (reset) begin
        br_taken_reg  <=  1'b0    ;
        br_target_reg <= 32'b0    ;
    end
    else if (br_taken && ~br_stall && ~br_taken_reg) begin
        br_taken_reg  <= br_taken ;
        br_target_reg <= br_target;
    end
    else if (is_slot_reg && fs_allowin && to_fs_valid) begin
        br_taken_reg  <=  1'b0    ;
    end
end
// 处理异常场景下的一些情况
/* quit a data_ok : 当WB阶段处于异常，但是已经有部分指令地址握手了，那么有可能接下来返回的dataok是无效的，应该被丢弃 */
wire quit_a_data_ok, quit_a_data_ok_flag;
reg  quit_a_data_ok_reg;
assign quit_a_data_ok_flag = quit_a_data_ok || quit_a_data_ok_reg;
assign quit_a_data_ok      = WS_EX && 
                             (fs_valid && ~inst_ready_reg || (to_fs_valid && ~(inst_sram_en && inst_sram_addr_ok && addr_ok_valid)));
always @ (posedge clk) begin
    if (reset) begin
        quit_a_data_ok_reg <= 1'b0;
    end else if (quit_a_data_ok && ~inst_sram_data_ok || inst_sram_addr_ok && ~addr_ok_valid) begin
        quit_a_data_ok_reg <= 1'b1;
    end else if (quit_a_data_ok_reg && inst_sram_data_ok) begin
        quit_a_data_ok_reg <= 1'b0;
    end
end
/* addr_ok_valid : 从转接桥返回的 addr_ok 对应的指令可能并不是 pre_fs 阶段的指令 */
wire   addr_ok_valid;
assign addr_ok_valid = (inst_sram_addr == inst_sram_addr_ok_addr);

// EX unit
wire        WS_EX      ;
reg         WS_EX_reg  ;
reg         tlb_inv_reg;
reg  [31:0] tlb_pc_reg ;
wire [31:0] fs_inst    ;
reg  [31:0] fs_pc      ;
wire [ 4:0] ex_code    ;
wire [31:0] BadVAddr   ;
wire        pc_error   ;

assign WS_EX        = ex_word[0]                                               ;
assign fs_inst      = inst_sram_rdata                                          ;
assign ex_code      = (ex_word == 4'b0) & (fs_pc[1:0] != 2'b0) ? `ADEL : `NO_EX;
assign BadVAddr     = (ex_code == `ADEL) ? fs_pc : 32'b0                       ;
assign pc_error     = (ex_code == `ADEL)                                       ;
assign fs_to_ds_bus = {is_slot_reg,
                       pc_error   ,
                       BadVAddr   ,
                       ex_code    ,
                       fs_inst    ,
                       fs_pc   };
always @ (posedge clk) begin
    if (reset) begin
        WS_EX_reg <= 1'b0;
    end else if (WS_EX && ~ pre_fs_ready_go_flag) begin
        WS_EX_reg <= 1'b1;
    end else if (pre_fs_ready_go && fs_allowin) begin
        WS_EX_reg <= 1'b0;
    end
end
always @ (posedge clk) begin
    if (reset) begin
        tlb_inv_reg <=  1'b0;
        tlb_pc_reg  <= 32'b0;
    end else if (tlb_inv && ~ pre_fs_ready_go_flag) begin
        tlb_inv_reg <= 1'b1    ;
        tlb_pc_reg  <= tlb_pc;
    end else if (pre_fs_ready_go && fs_allowin) begin
        tlb_inv_reg <=  1'b0;
        tlb_pc_reg  <= 32'b0;
    end
end

// pre-IF stage
wire   pre_fs_ready_go     ;
reg    pre_fs_ready_go_reg ;
wire   pre_fs_ready_go_flag;
assign pre_fs_ready_go_flag = pre_fs_ready_go || pre_fs_ready_go_reg;
assign to_fs_valid  = ~reset && pre_fs_ready_go_flag;
assign seq_pc       = fs_pc + 3'h4                  ;
assign nextpc       = (WS_EX || WS_EX_reg) && ~(tlb_inv || tlb_inv_reg) ? 32'hbfc00380                                   : 
                      tlb_inv || tlb_inv_reg ? ((tlb_pc != 32'b0) ? tlb_pc : tlb_pc_reg)                                 :
                      ERET  || ERET_reg      ? (ERET ? cp0_epc : cp0_epc_reg)                                            :
                      is_slot_reg            ? ((br_taken | br_taken_reg) ? (br_taken?br_target:br_target_reg) : seq_pc) : 
                                               seq_pc;

assign pre_fs_ready_go  = ~br_stall && (inst_sram_en && inst_sram_addr_ok && addr_ok_valid);
always@ (posedge clk) begin
    if (reset) begin
        pre_fs_ready_go_reg <= 1'b0;
    end
    else if (pre_fs_ready_go && ~fs_allowin) begin
        pre_fs_ready_go_reg <= 1'b1;
    end
    else if (pre_fs_ready_go_reg && fs_allowin) begin
        pre_fs_ready_go_reg <= 1'b0;
    end
end
reg        ERET_reg   ;
reg [31:0] cp0_epc_reg;
always @ (posedge clk) begin
    if (reset) begin
        ERET_reg    <=  1'b0;
        cp0_epc_reg <= 32'b0;
    end
    else if (ERET && ~pre_fs_ready_go_flag) begin
        ERET_reg    <=    1'b1;
        cp0_epc_reg <= cp0_epc;
    end
    else if (pre_fs_ready_go && fs_allowin) begin
        ERET_reg <= 1'b0;
    end
end

// IF stage
// 保证跳转指令与延迟槽在相邻流水级
assign fs_ready_go    = branch_in_fs ? to_fs_valid :
                                      (inst_ready_reg | (inst_sram_data_ok && ~quit_a_data_ok_flag));
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin;
assign fs_to_ds_valid =  fs_valid && fs_ready_go              ;

always @(posedge clk) begin
    // set fs_valid
    if (reset) begin
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;
    end
    else if (WS_EX) begin
        fs_valid <= 1'b0;
    end
    // set fs_pc
    if (reset) begin
        fs_pc <= 32'hbfbffffc;  // trick: to make seq_pc be 0xbfc00000 during reset 
    end
    else if (to_fs_valid && fs_allowin || ERET) begin
        fs_pc <= nextpc;
    end
end

// inst sram interface
// 注意，这里确保 fs_allowin 为 1 才可以发地址请求，虽然降低效率但是可以隐藏一些指令请求的问题
// 同时，在必要时将请求信号拉低，保证在一个事务结束之前，不发起另一个请求，简化设计难度，降低性能
wire   inst_sram_req;
assign inst_sram_req = (branch_in_fs? 1'b1 :
                                     fs_allowin && ~br_stall) || (WS_EX || WS_EX_reg);

// inst_ready_reg 寄存器和 inst_sram_data_ok 信号共同决定取值阶段指令是否就绪（二者至少一方有效则指令就绪）
reg    inst_sram_en_reg, inst_ready_reg;
always@(posedge clk) begin
    if (reset) begin
        inst_sram_en_reg <= inst_sram_req;
    end else if (inst_sram_addr_ok && addr_ok_valid) begin
        inst_sram_en_reg <= 1'b0         ;
    end else if (branch_in_fs ? ~pre_fs_ready_go_flag : fs_allowin) begin
        inst_sram_en_reg <= inst_sram_req;
    end
end
always @(posedge clk) begin
    if (reset) begin
        inst_ready_reg <= 1'b0;
    end else if (inst_sram_data_ok && ~quit_a_data_ok_flag) begin
        inst_ready_reg <= 1'b1;
    end else if (inst_sram_addr_ok && addr_ok_valid && inst_sram_en) begin
        inst_ready_reg <= 1'b0;
    end
end

assign inst_sram_en    = inst_sram_en_reg;
assign inst_sram_wr    = 1'b0            ;
assign inst_sram_size  = 2'b10           ;
assign inst_sram_wen   = 4'h0            ;
assign inst_sram_addr  = nextpc          ;
assign inst_sram_wdata = 32'b0           ;

endmodule
