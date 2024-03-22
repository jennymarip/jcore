`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD       34
    `define FS_TO_DS_BUS_WD 64
    `define DS_TO_ES_BUS_WD 149
    `define ES_TO_MS_BUS_WD 76
    `define MS_TO_WS_BUS_WD 75
    `define WS_TO_RF_BUS_WD 38

    `define CP0_EPC         5'b1110
    `define CP0_CAUSE       5'b1101
    `define CP0_STATUS      5'b1100

    `define SYSCALL         3'b001
    `define BREAK           3'b010
    `define OVERFLOW        3'b100
`endif
