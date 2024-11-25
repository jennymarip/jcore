`include "mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    // data sram interface
    output        data_sram_en     ,
    output        data_sram_wr     ,
    output [ 1:0] data_sram_size   ,
    output [ 3:0] data_sram_wstrb  ,
    output [31:0] data_sram_addr   ,
    output [31:0] data_sram_wdata  ,
    input         data_sram_addr_ok,
    input         data_sram_data_ok,
    // to ds data dependence
    output [ 4:0] EXE_dest      ,
    output        es_load_op    ,
    // forward
    output [31:0] EXE_dest_data ,
    // word of div and mul (div / divu / mult / multu)
    input  [ 3:0] dm_word       ,
    /// ld_word LB / LBU / LH / LHU / LWL / LWR & LDB
    input  [`LD_WORD_LEN - 1 :0] ld_word ,
    output [               1 :0] LDB     ,
    output [`LD_WORD_LEN - 1 :0] ld_word_,
    // mv_word(MFLO / MFHI / MTHI / MTLO)
    input  [`MV_WORD_LEN - 1 :0] mv_word, 
    // rt
    output [31:0] rt_value      ,
    // st_word (SB / SH / SWL / SWR)
    input [`ST_WORD_LEN - 1 :0] st_word,
    // EX
    input         WS_EX         ,
    input         MS_EX         ,
    output        ES_EX         ,
    input         ERET          ,
    input         MS_ERET       ,
    output        ES_ERET       ,
    input         MFC0          ,
    output        _MFC0         ,
    input  [ 2:0] of_test       , // single hot
    // READ CP0
    output        mfc0_read     ,
    output [ 4:0] mfc0_cp0_raddr,
    input  [31:0] mfc0_rdata
); 

reg         es_valid      ;
wire        es_ready_go   ;

assign      rt_value = es_rt_value;
assign      ES_EX    = (ex_code != `NO_EX) & es_valid;

reg         div_unfinished            ;
reg         mflo, mfhi, mtlo, mthi    ;
reg         lb, lbu, lh, lhu, lwl, lwr;
reg         sb, sh, swl, swr          ;
reg         mfc0                      ;
// 接受译码阶段传来的信息，当执行阶段停滞，这些信息也应该随之保留
always @(posedge clk) begin
    if (reset) begin
        {mflo,mfhi,mtlo,mthi,lb,lbu,lh,lhu,lwl,lwr,sb,sh,swl,swr,mfc0} <= 15'b0;
    end
    else if (ds_to_es_valid && es_allowin) begin
        {mflo, mfhi, mtlo, mthi}     <= mv_word;
        {lb, lbu, lh, lhu, lwl, lwr} <= ld_word;
        {sb, sh, swl, swr}           <= st_word;
        mfc0                         <= MFC0   ;
    end
end
assign ld_word_ = {lb, lbu, lh, lhu, lwl, lwr};
assign _MFC0    = mfc0;
wire   _LW, SW;
assign _LW   = es_load_op & ~lb & ~lbu & ~lh & ~lhu & ~lwl & ~lwr;
assign SW    = es_mem_we & ~sb & ~sh & ~swl & ~swr;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [13:0] es_alu_op          ;
wire        es_src1_is_sa      ;  
wire        es_src1_is_pc      ;
wire        es_src2_is_imm     ; 
wire        es_src2_is_imm_zero;
wire        es_src2_is_8       ;
wire        es_gr_we           ;
wire        es_mem_we          ;
wire [ 4:0] es_dest            ;
wire [15:0] es_imm             ;
wire [31:0] es_rs_value        ;
wire [31:0] es_rt_value        ;
wire [31:0] es_pc              ;
wire [ 4:0] ex_code            ;
wire [ 4:0] rd                 ;
wire        slot               ;
wire        eret               ;
wire        pc_error           ;
wire        mem_access         ;
assign {eret               ,  //145:145
        slot               ,  //144:144
        rd                 ,  //143:139
        es_alu_op          ,  //138:125
        es_load_op         ,  //124:124
        es_src1_is_sa      ,  //123:123
        es_src1_is_pc      ,  //122:122
        es_src2_is_imm     ,  //121:121
        es_src2_is_imm_zero,  //120:120
        es_src2_is_8       ,  //119:119
        es_gr_we           ,  //118:118
        es_mem_we          ,  //117:117
        es_dest            ,  //116:112
        es_imm             ,  //111:96
        es_rs_value        ,  //95 :64
        es_rt_value        ,  //63 :32
        es_pc                 //31 :0
       } = ds_to_es_bus_r;

assign ES_ERET = eret;
wire [31:0] es_alu_src1    ;
wire [31:0] es_alu_src2    ;
wire [31:0] es_alu_result  ;
wire [31:0] es_final_result;

wire        es_res_from_mem;

assign es_res_from_mem = es_load_op;
assign es_to_ms_bus = {mem_access       ,  //111:111
                       pc_error         ,  //110:110
                       BadVAddr         ,  //109:78
                       ex_code          ,  //77:73
                       eret             ,  //72:72
                       slot             ,  //71:71
                       es_res_from_mem  ,  //70:70
                       es_gr_we         ,  //69:69
                       es_dest          ,  //68:64
                       es_final_result  ,  //63:32
                       es_pc               //31:0
                      };
assign EXE_dest = es_dest & {5{es_valid}};

reg [ 2:0] OF_TEST;

assign es_ready_go    = data_sram_req ? ((data_sram_en && data_sram_addr_ok) || data_sram_en_and_ok) : 
                                        (~div_unfinished | ES_EX | MS_EX | WS_EX);
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset | WS_EX | ERET) begin
        es_valid <= 1'b0;
        ds_to_es_bus_r <= {33'b0,5'b11111,146'b0};
        OF_TEST <= 3'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
        OF_TEST <= of_test;
    end
end

assign es_alu_src1 = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                     es_src1_is_pc  ? es_pc[31:0] :
                                      es_rs_value;
assign es_alu_src2 = es_src2_is_imm_zero? {16'b0           , es_imm[15:0]} :
                     es_src2_is_imm     ? {{16{es_imm[15]}}, es_imm[15:0]} : 
                     es_src2_is_8       ? 32'd8 :
                                          es_rt_value;

alu u_alu(
    .alu_op        (es_alu_op    ),
    .alu_src1      (es_alu_src1  ),
    .alu_src2      (es_alu_src2  ),
    .alu_result    (es_alu_result)
    );
assign es_final_result = mfc0 ? mfc0_rdata : 
                         mflo ? LO : 
                         mfhi ? HI : es_alu_result;
// overflow test
wire [ 2:0] OF_TEST_;
assign OF_TEST_ = OF_TEST;

wire [ 2:0] of_flag;
wire   sign1;
wire   sign2;
wire   sign3;
assign sign1 = es_alu_src1[31]  ;
assign sign2 = es_alu_src2[31]  ;
assign sign3 = es_alu_result[31];
assign of_flag = ((OF_TEST_ == 3'b001) & ((sign1 == sign2) & (sign1 != sign3))) ? 3'b001 :
                 ((OF_TEST_ == 3'b010) & ((sign1 == sign2) & (sign1 != sign3))) ? 3'b010 :
                 ((OF_TEST_ == 3'b100) & ((sign1 != sign2) & (sign1 != sign3))) ? 3'b100 :
                                                                                  3'b0;
assign ex_code = (ds_to_es_bus_r[150:146] != `NO_EX) ? ds_to_es_bus_r[150:146]:
                 (of_flag != 3'b0)                   ? `OVERFLOW : 
                 BadAddr_R                           ? `ADEL     :
                 BadAddr_W                           ? `ADES     :
                                                       ds_to_es_bus_r[150:146];

// HI LO reg
reg [31:0] HI;
reg [31:0] LO;

always @(posedge clk) begin
    if (reset) begin
        HI   <= 32'b0;
        LO   <= 32'b0;
    end
    else if (mthi & ~(WS_EX | MS_EX)) begin
        HI   <= es_rs_value;
    end
    else if (mtlo & ~(WS_EX | MS_EX)) begin
        LO   <= es_rs_value;
    end
end

// DIV, DIVU
wire        is_div              ;
wire        is_divu             ;
wire [31:0] divider_dividend    ;
wire [31:0] divider_divisor     ;
wire [63:0] signed_divider_res  ;
wire [63:0] unsigned_divider_res;
reg  [31:0] quotient            ;
reg  [31:0] remainder           ;

assign is_div           = dm_word[3] ;
assign is_divu          = dm_word[2] ;
assign divider_dividend = es_rs_value;
assign divider_divisor  = es_rt_value;

// signed
wire signed_dividend_tready;
reg  signed_dividend_tvalid;
wire signed_divisor_tready;
reg  signed_divisor_tvalid;
wire signed_dout_tvalid;

// unsigned
wire unsigned_dividend_tready;
reg  unsigned_dividend_tvalid;
wire unsigned_divisor_tready;
reg  unsigned_divisor_tvalid;
wire unsigned_dout_tvalid;

my_divider_signed my_divider_signed (
    .aclk                   (clk                   ),
    .s_axis_dividend_tdata  (divider_dividend      ),
    .s_axis_dividend_tready (signed_dividend_tready),
    .s_axis_dividend_tvalid (signed_dividend_tvalid),
    .s_axis_divisor_tdata   (divider_divisor       ),
    .s_axis_divisor_tready  (signed_divisor_tready ),
    .s_axis_divisor_tvalid  (signed_divisor_tvalid ),
    .m_axis_dout_tdata      (signed_divider_res    ),
    .m_axis_dout_tvalid     (signed_dout_tvalid    )
);

always @(posedge clk) begin
    if (reset) begin
        signed_dividend_tvalid <=  1'b0;
        signed_divisor_tvalid  <=  1'b0;
        div_unfinished         <=  1'b0;
    end
    else if (is_div & (ex_code == `NO_EX) & ~MS_EX) begin
        signed_dividend_tvalid <= 1'b1;
        signed_divisor_tvalid  <= 1'b1;
        div_unfinished         <= 1'b1;
    end
end

always @(posedge clk) begin
    if(signed_dividend_tready & signed_dividend_tvalid) begin
        signed_dividend_tvalid <= 1'b0;
    end
    if(signed_divisor_tready  & signed_divisor_tvalid ) begin
        signed_divisor_tvalid  <= 1'b0;
    end
    if(signed_dout_tvalid) begin
        quotient       <= signed_divider_res[63:32];
        remainder      <= signed_divider_res[31: 0];
        LO             <= signed_divider_res[63:32];
        HI             <= signed_divider_res[31: 0];
        div_unfinished <= 1'b0;
    end
end

my_divider_unsigned my_divider_unsigned (
    .aclk                   (clk                   ),
    .s_axis_dividend_tdata  (divider_dividend      ),
    .s_axis_dividend_tready (unsigned_dividend_tready),
    .s_axis_dividend_tvalid (unsigned_dividend_tvalid),
    .s_axis_divisor_tdata   (divider_divisor       ),
    .s_axis_divisor_tready  (unsigned_divisor_tready ),
    .s_axis_divisor_tvalid  (unsigned_divisor_tvalid ),
    .m_axis_dout_tdata      (unsigned_divider_res    ),
    .m_axis_dout_tvalid     (unsigned_dout_tvalid    )
);

always @(posedge clk) begin
    if (reset) begin
        unsigned_dividend_tvalid <=  1'b0;
        unsigned_divisor_tvalid  <=  1'b0;
        div_unfinished           <=  1'b0;
    end
    else if (is_divu & (ex_code == `NO_EX) & ~MS_EX) begin
        unsigned_dividend_tvalid <= 1'b1;
        unsigned_divisor_tvalid  <= 1'b1;
        div_unfinished           <= 1'b1;
    end
end

always @(posedge clk) begin
    if(unsigned_dividend_tready & unsigned_dividend_tvalid) begin
        unsigned_dividend_tvalid <= 1'b0;
    end
    if(unsigned_divisor_tready  & unsigned_divisor_tvalid ) begin
        unsigned_divisor_tvalid  <= 1'b0;
    end
    if(unsigned_dout_tvalid) begin
        quotient       <= unsigned_divider_res[63:32];
        remainder      <= unsigned_divider_res[31: 0];
        LO             <= unsigned_divider_res[63:32];
        HI             <= unsigned_divider_res[31: 0];
        div_unfinished <= 1'b0;
    end
end

// MULT, MULTU
wire        is_mult  ;
wire        is_multu ;
reg         mult_exe ;
wire [63:0] mult_res ;
reg         multu_exe;
wire [63:0] multu_res;

assign is_mult   = dm_word[1]                                 ;
assign is_multu  = dm_word[0]                                 ;
assign mult_res  = $signed(es_rs_value) * $signed(es_rt_value);
assign multu_res = es_rs_value * es_rt_value                  ;

always @(posedge clk) begin
    if (reset) begin
        mult_exe <= 1'b0;
    end
    else begin
        mult_exe <= is_mult;
    end
    if(mult_exe & (ex_code == `NO_EX) & ~MS_EX) begin
        HI <= mult_res[63:32];
        LO <= mult_res[31: 0];
    end
end
always @(posedge clk) begin
    if (reset) begin
        multu_exe <= 1'b0;
    end
    else begin
        multu_exe <= is_multu;
    end
    if(multu_exe & (ex_code == `NO_EX) & ~MS_EX) begin
        HI <= multu_res[63:32];
        LO <= multu_res[31: 0];
    end
end
assign EXE_dest_data   = es_final_result & {32{es_valid}}; // forward

// Bad Addr Test
wire        BadAddr_R;
wire        BadAddr_W;
wire [31:0] BadVAddr;
assign      BadAddr_R = (_LW & (LDB != 2'b0)) | ((lh | lhu) & LDB[0]);
assign      BadAddr_W = (SW & (LDB != 2'b0) ) | (sh & LDB[0]);
assign      BadVAddr  = (ds_to_es_bus_r[182:151] != 32'b0) ? ds_to_es_bus_r[182:151] :
                                   (BadAddr_R | BadAddr_W) ? data_sram_addr          :
                                                             32'b0;
assign      pc_error  = ds_to_es_bus_r[183];
// R / W
wire [31:0]  st_data;
assign st_data = sb ? {4{es_rt_value[ 7:0]}} :
                 sh ? {2{es_rt_value[15:0]}} :
                 (swl & (LDB == 2'b00))?{24'b0, es_rt_value[31:24]} :
                 (swl & (LDB == 2'b01))?{16'b0, es_rt_value[31:16]} :
                 (swl & (LDB == 2'b10))?{8'b0, es_rt_value[31:8]} :
                 (swl & (LDB == 2'b11))?es_rt_value[31:0] :
                 (swr & (LDB == 2'b00))?es_rt_value[31:0] :
                 (swr & (LDB == 2'b01))?{es_rt_value[23:0], 8'b0} :
                 (swr & (LDB == 2'b10))?{es_rt_value[15:0], 16'b0} :
                 (swr & (LDB == 2'b11))?{es_rt_value[7:0], 24'b0} :
                 es_rt_value[31:0];
// data sram interface
wire   data_sram_req;
assign data_sram_req = (es_load_op || es_mem_we) && es_valid && ~ES_EX;
assign mem_access    = data_sram_req         ;
reg    data_sram_en_reg   ;
reg    data_sram_en_and_ok; // 表示数据请求地址握手成功但是指令仍然在ex
always @(posedge clk) begin
    // set data_sram_en_reg
    if (reset) begin
        data_sram_en_reg    <= 1'b0;
    end
    else if (data_sram_req && ~data_sram_en && ~data_sram_en_and_ok) begin
        data_sram_en_reg    <= data_sram_req;
    end
    else if (data_sram_addr_ok && data_sram_en) begin
        data_sram_en_reg    <= 1'b0;
    end
    // set data_sram_en_and_ok
    if (reset) begin
        data_sram_en_and_ok <= 1'b0;
    end
    else if (es_allowin && ds_to_es_valid) begin
        data_sram_en_and_ok <= 1'b0;
    end
    else if (data_sram_addr_ok && data_sram_en && ~ms_allowin) begin
        data_sram_en_and_ok <= 1'b1;
    end
end
assign data_sram_en    = data_sram_en_reg && es_valid; // 只有es阶段有效,数据请求才能拉高
assign data_sram_wr    = es_mem_we                   ;
assign data_sram_size  = 2'b10                       ; // to change
assign data_sram_wstrb = es_mem_we&&es_valid & ~BadAddr_W & ~MS_ERET & ~ERET ?
                         (
                            (WS_EX || MS_EX      )? 4'b0000 :
                            (sb  & (LDB == 2'b00))? 4'b0001 :
                            (sb  & (LDB == 2'b01))? 4'b0010 :
                            (sb  & (LDB == 2'b10))? 4'b0100 :
                            (sb  & (LDB == 2'b11))? 4'b1000 :
                            (sh  & (LDB == 2'b00))? 4'b0011 :
                            (sh  & (LDB == 2'b10))? 4'b1100 :
                            (swl & (LDB == 2'b00))? 4'b0001 :
                            (swl & (LDB == 2'b01))? 4'b0011 :
                            (swl & (LDB == 2'b10))? 4'b0111 :
                            (swl & (LDB == 2'b11))? 4'b1111 :
                            (swr & (LDB == 2'b00))? 4'b1111 :
                            (swr & (LDB == 2'b01))? 4'b1110 :
                            (swr & (LDB == 2'b10))? 4'b1100 :
                            (swr & (LDB == 2'b11))? 4'b1000 :
                            4'b1111
                         ) :
                         4'h0;
assign data_sram_addr  = es_alu_result;
assign data_sram_wdata = st_data;

assign LDB             = es_alu_result[ 1:0] & {2{lb | lbu | lh | lhu | lwl | lwr | sb | sh | swl | swr | _LW | SW | sh}};

// READ CP0
assign mfc0_read      = mfc0;
assign mfc0_cp0_raddr = rd  ;

endmodule
