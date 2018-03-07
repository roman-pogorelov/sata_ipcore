`ifndef SATA_DEFINES
    `define SATA_DEFINES
    
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
    `define HOLD_ACK_PRIM   32'h9595aa7c
    
    `define DIAL_DATA       32'h4a4a4a4a
    
    `define DWORD_IS_PRIM   4'h1
    `define DWORD_IS_DATA   4'h0
    
    `define CRC_POLYNOMIAL  32'h04c11db7
    `define CRC_INITVALUE   32'h52325032
    
    `define LFSR_POLYNOMIAL 16'ha011
    `define LFSR_INITVALUE  48'hb16e4b431f73
`endif


