/*
    //------------------------------------------------------------------------------------
    //      Модуль вычисления значения значения контрольной суммы CRC
    crc_calculator
    #(
        .DATAWIDTH  (), // Разрядность данных
        .CRCWIDTH   (), // Разрядность CRC
        .POLYNOMIAL ()  // Порождающий полином
    )
    the_crc_calculator
    (
        // Входные данные
        .i_dat      (), // i  [DATAWIDTH - 1 : 0]
        
        // Входное (текущее) значение CRC
        .i_crc      (), // i  [CRCWIDTH - 1 : 0]
        
        // Выходное (расчитанное) значение CRC
        .o_crc      ()  // o  [CRCWIDTH - 1 : 0]
    ); // the_crc_calculator
*/

module crc_calculator
#(
    parameter int unsigned              DATAWIDTH   = 8,        // Разрядность данных
    parameter int unsigned              CRCWIDTH    = 16,       // Разрядность CRC
    parameter logic [CRCWIDTH - 1 : 0]  POLYNOMIAL  = 16'h8005  // Порождающий полином
)
(
    // Входные данные
    input  logic [DATAWIDTH - 1 : 0]    i_dat,
    
    // Входное (текущее) значение CRC
    input  logic [CRCWIDTH - 1 : 0]     i_crc,
    
    // Выходное (расчитанное) значение CRC
    output logic [CRCWIDTH - 1 : 0]     o_crc
);
    //------------------------------------------------------------------------------------
    //      Расчет значения CRC
    function automatic logic [CRCWIDTH - 1 : 0] crc_calc(input  logic [CRCWIDTH - 1 : 0] crc, input logic [DATAWIDTH - 1 : 0] i_dat);
        for (int i = 0; i < DATAWIDTH; i++) begin
            for (int j = 0; j < CRCWIDTH; j++) begin
                if (j == 0) begin
                    crc_calc[j] = POLYNOMIAL[j] ? crc[CRCWIDTH - 1] ^ i_dat[DATAWIDTH - 1 - i] : 1'b0;
                end
                else begin
                    crc_calc[j] = POLYNOMIAL[j] ? crc[j - 1] ^ crc[CRCWIDTH - 1] ^ i_dat[DATAWIDTH - 1 - i] : crc[j - 1];
                end
            end
            crc = crc_calc;
        end
    endfunction
    
    //------------------------------------------------------------------------------------
    //      Выходное (расчитанное) значение CRC
    assign o_crc = crc_calc(i_crc, i_dat);
    
endmodule: crc_calculator