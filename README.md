# jcore
## overview
* MIPS32架构顺序五级流水线，实现了包含tlb在内的58条指令
* 实现cp0（部分）
* 顶层接口实现为axi32
* 实现了基于tlb的存储管理单元，存储管理的页大小固定为4KB
* 集成icache,二路组相联,缓存大小16kB
## 验证方法
* 用于生成trace文件的工程CPU_CDE_AXI/cpu132_gettrace/run_vivado/cpu132_gettrace/cpu132_gettrace.xpr，打开vivado，仿真运行，生成trace文件（生成的golden_trace.txt文件在CPU_CDE_AXI/cpu132_gettrace目录下）
* myCPU文件夹下包含项目rtl，mycpu_top.v为cpu顶层文件
* 将myCPU文件夹复制到CPU_CDE_AXI/mycpu_axi_verify/rtl/目录下
* 点击CPU_CDE_AXI/mycpu_axi_verify/run_vivado/mycpu_prj1/mycpu.xpr工程文件，打开vivado
* 设置顶层文件，需要实例化除法器ip（除数，被除数，余数宽度均为32）,以及bram ip
* 仿真+运行
## 其他
* testbench：CPU_CDE_AXI/mycpu_axi_verify/testbench/mycpu_tb.v
* soc环境请自行琢磨
