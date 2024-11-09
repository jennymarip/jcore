`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    //from data-sram
    input                          data_sram_data_ok,
    input  [31:0]                  data_sram_rdata  ,
    //to ds data dependence
    output [ 4:0]                  MEM_dest      ,
    //forward
    output [31:0]                  MEM_dest_data ,
    output                         ms_load_op    ,
    // LDB & LB / LBU / LH / LHU / LWL
    input  [ 1:0]                  LDB           ,
    input                          _LB           ,
    input                          _LBU          ,
    input                          _LH           ,
    input                          _LHU          ,
    input                          _LWL          ,
    input                          _LWR          ,
    // rt
    input  [31:0]                  rt_value      ,
    // EX
    input                          WS_EX         ,
    input                          ERET          ,
    output                         MS_ERET       ,
    output                         MS_EX         ,
    // READ CP0
    input                          MFC0
);

reg         ms_valid;
wire        ms_ready_go;

reg [ 1:0] ldb ;
reg        lb  ;
reg        lbu ;
reg        lh  ;
reg        lhu ;
reg        lwl ;
reg        lwr ;
reg [31:0] rt  ;
reg        mfc0;
always @(posedge clk) begin
    if(reset) begin
        ldb <=  2'b0;
        lb  <=  1'b0;
        lbu <=  1'b0;
        lh  <=  1'b0;
        lhu <=  1'b0;
        lwl <=  1'b0;
        lwr <=  1'b0;
        rt  <= 32'b0;
        mfc0<=  1'b0;
    end
    else begin
        ldb <= LDB     ;
        lb  <= _LB     ;
        lbu <= _LBU    ;
        lh  <= _LH     ;
        lhu <= _LHU    ;
        lwl <= _LWL    ;
        lwr <= _LWR    ;
        rt  <= rt_value;
        mfc0<= MFC0    ;
    end
end

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire        ms_res_from_mem;
wire        ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc   ;
wire        slot    ;
wire        eret    ;
wire [ 4:0] ex_code ;
wire [31:0] BadVAddr;
wire        pc_error;
wire        mem_access;
assign {mem_access     ,  //111:111
        pc_error       ,  //110:110
        BadVAddr       ,  //109:78
        ex_code        ,  //77:73
        eret           ,  //72:72
        slot           ,  //71:71
        ms_res_from_mem,  //70:70
        ms_gr_we       ,  //69:69
        ms_dest        ,  //68:64
        ms_alu_result  ,  //63:32
        ms_pc             //31:0
       } = es_to_ms_bus_r;
assign MS_EX   = (ex_code != `NO_EX);
assign MS_ERET = eret;

wire [ 7:0] single_B       ;
wire [15:0] double_B       ; 
wire [31:0] LB_result      ;
wire [31:0] LBU_result     ;
wire [31:0] LH_result      ;
wire [31:0] LHU_result     ;
wire [31:0] LWL_result     ;
wire [31:0] LWR_result     ;
wire [31:0] mem_result     ;
wire [31:0] ms_final_result;

assign MEM_dest = ms_dest & {5{ms_valid}};

assign ms_to_ws_bus = {pc_error       ,  //109:109
                       BadVAddr       ,  //108:77
                       ex_code        ,  //76:72
                       eret           ,  //71:71
                       slot           ,  //70:70
                       ms_gr_we       ,  //69:69
                       ms_dest        ,  //68:64
                       ms_final_result,  //63:32
                       ms_pc             //31:0
                      };

assign ms_ready_go    = mem_access ? data_sram_data_ok : 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset | WS_EX | ERET) begin
        ms_valid       <= 1'b0;
        es_to_ms_bus_r <= {33'b0,5'b11111,73'b0};
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  = es_to_ms_bus;
    end
end

assign single_B   =   (ldb == 2'b00)? data_sram_rdata[ 7: 0] 
                    : (ldb == 2'b01)? data_sram_rdata[15: 8] 
                    : (ldb == 2'b10)? data_sram_rdata[23:16] 
                    : data_sram_rdata[31:24];
assign double_B   =   (ldb[1] == 1'b0)? data_sram_rdata[15: 0] : data_sram_rdata[31:16];
assign LB_result  = {{24{single_B[7]}}, single_B[7:0]};
assign LBU_result = {{24{0}}, single_B[7:0]};
assign LH_result  = {{16{double_B[15]}}, double_B[15:0]};
assign LHU_result = {{16{0}}, double_B[15:0]};
assign LWL_result =   (ldb == 2'b00)? {data_sram_rdata[ 7: 0], rt[23: 0]}
                    : (ldb == 2'b01)? {data_sram_rdata[15: 0], rt[15: 0]}
                    : (ldb == 2'b10)? {data_sram_rdata[23: 0], rt[ 7: 0]}
                    : data_sram_rdata[31:0];
assign LWR_result =   (ldb == 2'b00)? data_sram_rdata[31:0]
                    : (ldb == 2'b01)? {rt[31:24], data_sram_rdata[31: 8]}
                    : (ldb == 2'b10)? {rt[31:16], data_sram_rdata[31:16]}
                    : {rt[31: 8], data_sram_rdata[31:24]};
assign mem_result = lb ?  LB_result 
                  : lbu? LBU_result
                  : lh ?  LH_result
                  : lhu? LHU_result 
                  : lwl? LWL_result
                  : lwr? LWR_result
                  :      data_sram_rdata;
assign ms_final_result = ms_res_from_mem ? mem_result :
                                           ms_alu_result;
// forward
assign MEM_dest_data   = ms_final_result & {32{ms_to_ws_valid}};
assign ms_load_op      = ms_res_from_mem;
endmodule
