`ifndef SATA_DEFINES
    `define SATA_DEFINES
    
    `define SATA_GEN1       2'h1
    `define SATA_GEN2       2'h2
    `define SATA_GEN3       2'h3
    
    `define ALIGN_PRIM      32'h7b4a4abc
    `define SYNC_PRIM       32'hb5b5957c
    `define SOF_PRIM        32'h3737b57c
    `define EOF_PRIM        32'hd5d5b57c
    `define R_RDY_PRIM      32'h4a4a957c
    `define R_IP_PRIM       32'h5555b57c
    `define R_OK_PRIM       32'h3535b57c
    `define R_ERR_PRIM      32'h5656b57c
    `define X_RDY_PRIM      32'h5757b57c
    `define WTRM_PRIM       32'h5858b57c
    `define CONT_PRIM       32'h9999aa7c
    `define HOLD_PRIM       32'hd5d5aa7c
    `define HOLDA_PRIM      32'h9595aa7c
    
    `define DIAL_DATA       32'h4a4a4a4a
    
    `define DWORD_IS_PRIM   1'b1
    `define DWORD_IS_DATA   1'b0
    
    `define SYNC_TX_CODE    4'h0
    `define SOF_TX_CODE     4'h1
    `define EOF_TX_CODE     4'h2
    `define R_RDY_TX_CODE   4'h3
    `define R_IP_TX_CODE    4'h4
    `define R_OK_TX_CODE    4'h5
    `define R_ERR_TX_CODE   4'h6
    `define X_RDY_TX_CODE   4'h7
    `define WTRM_TX_CODE    4'h8
    `define HOLD_TX_CODE    4'h9
    `define HOLDA_TX_CODE   4'ha
    `define DATA_TX_CODE    4'hb
    
    `define CRC_POLYNOMIAL  32'h04c11db7
    `define CRC_INITVALUE   32'h52325032
    
    `define LFSR_POLYNOMIAL 16'ha011
    `define LFSR_INITVALUE  48'hb16e4b431f73
    
    `define REG_FIS_H2D     8'h27
    `define REG_FIS_D2H     8'h34
    `define PIO_SET_FIS     8'h5F
    `define DMA_ACT_FIS     8'h39
    `define DATA_FIS        8'h46
    
`endif


