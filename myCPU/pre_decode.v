`include "mycpu.h"

module pre_decode(
    input [31:0] fs_inst  ,
    output       is_branch
);

// 指令字段
wire [ 5:0] op;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [25:0] jidx;
wire [ 2:0] sel;
wire [63:0] op_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [63:0] func_d;

assign op   = fs_inst[31:26];
assign rt   = fs_inst[20:16];
assign rd   = fs_inst[15:11];
assign sa   = fs_inst[10: 6];
assign func = fs_inst[ 5: 0];
assign jidx = fs_inst[25: 0];
assign sel  = fs_inst[ 2: 0];

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));

// 指令类型控制信号
wire        inst_beq   ;
wire        inst_bne   ;
wire        inst_bgez  ;
wire        inst_bgtz  ;
wire        inst_blez  ;
wire        inst_bltz  ;
wire        inst_bgezal;
wire        inst_bltzal;
wire        inst_j     ;
wire        inst_jal   ;
wire        inst_jr    ;
wire        inst_jalr  ;

assign inst_beq    = op_d[6'h04]; // 1
assign inst_bne    = op_d[6'h05]; // 1
assign inst_bgez   = op_d[6'h01] & rt_d[5'h01]; // 1
assign inst_bgtz   = op_d[6'h07] & rt_d[5'h00]; // 1 
assign inst_blez   = op_d[6'h06] & rt_d[5'h00]; // 1
assign inst_bltz   = op_d[6'h01] & rt_d[5'h00]; // 1
assign inst_bgezal = op_d[6'h01] & rt_d[5'h11];
assign inst_bltzal = op_d[6'h01] & rt_d[5'h10];
assign inst_j      = op_d[6'h02];
assign inst_jal    = op_d[6'h03];
assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00]; // 1
assign inst_jalr   = op_d[6'h00] & func_d[6'h09] & rt_d[5'h00] & sa_d[5'h00];

assign is_branch = (inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_bltzal | inst_bgezal | inst_jal | inst_jalr | inst_j | inst_jr);

endmodule