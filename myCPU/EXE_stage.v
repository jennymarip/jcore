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
    output        data_sram_en   ,
    output [ 3:0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    // to ds data dependence
    output [ 4:0] EXE_dest      ,
    output        es_load_op    ,
    // forward
    output [31:0] EXE_dest_data ,
    // is div / divu / mult / multu
    input         is_div        ,
    input         is_divu       ,
    input         is_mult       ,
    input         is_multu      ,
    // LB / LBU / LH / LHU / LWL / LWR & LDB
    input         LB            ,
    input         LBU           ,
    input         LH            ,
    input         LHU           ,
    input         LWL           ,
    input         LWR           ,
    output [ 1:0] LDB           ,
    output        _LB           ,
    output        _LBU          ,
    output        _LH           ,
    output        _LHU          ,
    output        _LWL          ,
    output        _LWR          ,
    // MFLO, MFHI, MTHI, MTLO
    input         MFLO          ,
    input         MFHI          ,
    input         MTLO          ,
    input         MTHI          ,
    // rt
    output [31:0] rt_value      ,
    // SB / SH / SWL / SWR
    input         SB            ,
    input         SH            ,
    input         SWL           ,
    input         SWR           ,
    // EX
    input         WS_EX         ,
    input         MFC0          ,
    output        _MFC0         ,
    // READ CP0
    output        mfc0_read     ,
    output [ 4:0] mfc0_cp0_raddr,
    input  [31:0] mfc0_rdata
); 

reg         es_valid      ;
wire        es_ready_go   ;

assign      rt_value = es_rt_value;

reg         div_unfinished;
reg         mflo;
reg         mfhi;
reg         mtlo;
reg         mthi;
reg         lb  ;
reg         lbu ;
reg         lh  ;
reg         lhu ;
reg         lwl ;
reg         lwr ;
reg         sb  ;
reg         sh  ;
reg         swl ;
reg         swr ;
reg         mfc0;
always @(posedge clk) begin
    if (reset) begin
        mflo <= 1'b0;
        mfhi <= 1'b0;
        mtlo <= 1'b0;
        mthi <= 1'b0;
        lb   <= 1'b0;
        lbu  <= 1'b0;
        lh   <= 1'b0;
        lhu  <= 1'b0;
        lwl  <= 1'b0;
        lwr  <= 1'b0;
        sb   <= 1'b0;
        sh   <= 1'b0;
        swl  <= 1'b0;
        swr  <= 1'b0;
        mfc0 <= 1'b0;
    end
    else begin
        mflo <= MFLO;
        mfhi <= MFHI;
        mtlo <= MTLO;
        mthi <= MTHI;
        lb   <= LB  ;
        lbu  <= LBU ;
        lh   <= LH  ;
        lhu  <= LHU ;
        lwl  <= LWL ;
        lwr  <= LWR ;
        sb   <= SB  ;
        sh   <= SH  ;
        swl  <= SWL ;
        swr  <= SWR ;
        mfc0 <= MFC0;
    end
end
assign _LB  = lb ;
assign _LBU = lbu;
assign _LH  = lh ;
assign _LHU = lhu;
assign _LWL = lwl;
assign _LWR = lwr;
assign _MFC0= mfc0;

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
wire        es_ex              ;
wire [ 4:0] rd                 ;
assign {rd                 ,  //144:140
        es_ex              ,  //139:139
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

wire [31:0] es_alu_src1    ;
wire [31:0] es_alu_src2    ;
wire [31:0] es_alu_result  ;
wire [31:0] es_final_result;

wire        es_res_from_mem;

assign es_res_from_mem = es_load_op;
assign es_to_ms_bus = {es_ex            ,  //71:71
                       es_res_from_mem  ,  //70:70
                       es_gr_we         ,  //69:69
                       es_dest          ,  //68:64
                       es_final_result  ,  //63:32
                       es_pc               //31:0
                      };
assign EXE_dest = es_dest & {5{es_valid}};


assign es_ready_go    = ~div_unfinished;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset | WS_EX) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
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

// HI LO reg
reg [31:0] HI;
reg [31:0] LO;

always @(posedge clk) begin
    if (reset) begin
        HI   <= 1'b0;
        LO   <= 1'b0;
    end
    else if (mthi) begin
        HI   <= es_rs_value;
    end
    else if (mtlo) begin
        LO   <= es_rs_value;
    end
end

// DIV, DIVU
wire [31:0] divider_dividend    ;
wire [31:0] divider_divisor     ;
wire [63:0] signed_divider_res  ;
wire [63:0] unsigned_divider_res;
reg  [31:0] quotient            ;
reg  [31:0] remainder           ;

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
    else if (is_div) begin
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
        div_unfinished         <=  1'b0;
    end
    else if (is_divu) begin
        unsigned_dividend_tvalid <= 1'b1;
        unsigned_divisor_tvalid  <= 1'b1;
        div_unfinished         <= 1'b1;
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
reg         mult_exe ;
wire [63:0] mult_res ;
reg         multu_exe;
wire [63:0] multu_res;

assign mult_res  = $signed(es_rs_value) * $signed(es_rt_value);
assign multu_res = es_rs_value * es_rt_value;

always @(posedge clk) begin
    if (reset) begin
        mult_exe <= 1'b0;
    end
    else begin
        mult_exe <= is_mult;
    end
    if(mult_exe) begin
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
    if(multu_exe) begin
        HI <= multu_res[63:32];
        LO <= multu_res[31: 0];
    end
end
assign EXE_dest_data   = es_final_result & {32{es_valid}}; // forward

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

assign data_sram_en    = 1'b1;
assign data_sram_wen   = es_mem_we&&es_valid  ?
                         (
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

assign LDB             = es_alu_result[ 1:0] & {2{lb | lbu | lh | lhu | lwl | lwr | sb | sh | swl | swr}};

// READ CP0
assign mfc0_read      = mfc0;
assign mfc0_cp0_raddr = rd  ;

endmodule
