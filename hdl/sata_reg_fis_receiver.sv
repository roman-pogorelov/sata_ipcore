/*
    //------------------------------------------------------------------------------------
    //      Модуль приема фреймов SATA Register FIS, Setup PIO FIS
    sata_reg_fis_receiver
    the_sata_reg_fis_receiver
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i
        
        // Входной последовательный интерфейс принимаемого фрейма
        .i_dat          (), // i  [31 : 0]
        .i_val          (), // i
        .i_eop          (), // i
        .i_err          (), // i
        .i_rdy          (), // o
        
        // Выходной параллельный интерфейс принятого фрейма
        .o_dat_type     (), // o  [7 : 0]
        .o_dat_status   (), // o  [7 : 0]
        .o_dat_error    (), // o  [7 : 0]
        .o_dat_address  (), // o  [47 : 0]
        .o_dat_scount   (), // o  [15 : 0]
        .o_dat_tcount   (), // o  [15 : 0]
        .o_dat_badcrc   (), // o
        .o_val          ()  // o
    ); // the_sata_reg_fis_receiver
*/

module sata_reg_fis_receiver
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,
    
    // Входной последовательный интерфейс принимаемого фрейма
    input  logic [31 : 0]       i_dat,
    input  logic                i_val,
    input  logic                i_eop,
    input  logic                i_err,
    output logic                i_rdy,
    
    // Выходной параллельный интерфейс принятого фрейма
    output logic [7 : 0]        o_dat_type,
    output logic [7 : 0]        o_dat_status,
    output logic [7 : 0]        o_dat_error,
    output logic [47 : 0]       o_dat_address,
    output logic [15 : 0]       o_dat_scount,
    output logic [15 : 0]       o_dat_tcount,
    output logic                o_dat_badcrc,
    output logic                o_val
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam int unsigned FIS_LEN = 5;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                           val_reg;
    logic [FIS_LEN : 0]             pos_reg;
    logic [FIS_LEN - 1 : 0][31 : 0] fis_reg;
    logic                           crc_reg;
    
    //------------------------------------------------------------------------------------
    //      Постоянная готовность к приему
    assign i_rdy = 1'b1;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака достоверности принятого фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            val_reg <= '0;
        else if (val_reg)
            val_reg <= ~(i_val & ~i_eop);
        else
            val_reg <= i_val & i_eop;
    assign o_val = val_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр позиции текущего слова фрейма
    initial pos_reg = {{FIS_LEN{1'b0}}, 1'b1};
    always @(posedge reset, posedge clk)
        if (reset)
            pos_reg <= {{FIS_LEN{1'b0}}, 1'b1};
        else if (i_val)
            if (i_eop)
                pos_reg <= {{FIS_LEN{1'b0}}, 1'b1};
            else if (pos_reg[$high(pos_reg)])
                pos_reg <= pos_reg;
            else
                pos_reg <= {pos_reg[$high(pos_reg) - 1 : 0], 1'b0};
        else
            pos_reg <= pos_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр накопления фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            fis_reg <= '0;
        else if (i_val)
            for (int i = 0; i < FIS_LEN; i++) begin
                if (i != 0) begin
                    if (pos_reg[0])
                        fis_reg[i] <= '0;
                    else if (pos_reg[i])
                        fis_reg[i] <= i_dat;
                    else
                        fis_reg[i] <= fis_reg[i];
                end
                else begin
                    if (pos_reg[i])
                        fis_reg[i] <= i_dat;
                    else
                        fis_reg[i] <= fis_reg[i];
                end
            end
        else
            fis_reg <= fis_reg;
    
    //------------------------------------------------------------------------------------
    //      Заполнение выходных полей фрейма
    assign o_dat_type    =  fis_reg[0][7 : 0];
    assign o_dat_status  =  fis_reg[0][23 : 16];
    assign o_dat_error   =  fis_reg[0][31 : 24];
    assign o_dat_address = {fis_reg[2][23 : 0], fis_reg[1][23 : 0]};
    assign o_dat_scount  =  fis_reg[3][15 : 0];
    assign o_dat_tcount  =  fis_reg[4][15 : 0];
    
    //------------------------------------------------------------------------------------
    //      Регистр признак ошибки CRC для фрейма
    always @(posedge reset, posedge clk)
        if (reset)
            crc_reg <= '0;
        else if (i_val)
            crc_reg <= i_eop & i_err;
        else
            crc_reg <= crc_reg;
    assign o_dat_badcrc = crc_reg;
    
endmodule: sata_reg_fis_receiver