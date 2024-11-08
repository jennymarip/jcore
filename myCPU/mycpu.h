`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD            35
    `define FS_TO_DS_BUS_WD     102
    `define DS_TO_ES_BUS_WD     184
    `define ES_TO_MS_BUS_WD     112
    `define MS_TO_WS_BUS_WD     110
    `define WS_TO_RF_BUS_WD      38

    `define ST_WORD_LEN           4
    `define LD_WORD_LEN           6

    `define CP0_EPC         5'b1110
    `define CP0_CAUSE       5'b1101
    `define CP0_STATUS      5'b1100
    `define CP0_BadVAddr    5'b1000
    `define CP0_COUNT       5'b1001
    `define CP0_COMPARE     5'b1011

    `define SYSCALL         5'b01000
    `define BREAK           5'b01001
    `define OVERFLOW        5'b01100
    `define INT             5'b00000
    `define ADEL            5'b00100
    `define ADES            5'b00101
    `define RI              5'b01010
    `define NO_EX           5'b11111
`endif
