/*
    //------------------------------------------------------------------------------------
    //      Арбитр потоковых интерфейсов фреймов SATA с приоритетом младшего
    sata_fis_arbiter
    the_sata_fis_arbiter
    (
        // Сброс и тактирование
        .reset      (), // i
        .clk        (), // i
        
        // Входной потоковый интерфейс #1 фреймов SATA
        .i1_dat     (), // i  [31 : 0]
        .i1_val     (), // i
        .i1_eop     (), // i
        .i1_rdy     (), // o
        
        // Входной потоковый интерфейс #2 фреймов SATA
        .i2_dat     (), // i  [31 : 0]
        .i2_val     (), // i
        .i2_eop     (), // i
        .i2_rdy     (), // o
        
        // Выходной потоковый интерфейс фреймов SATA
        .o_dat      (), // o  [31 : 0]
        .o_val      (), // o
        .o_eop      (), // o
        .o_rdy      ()  // i
    ); // the_sata_fis_arbiter
*/

module sata_fis_arbiter
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,
    
    // Входной потоковый интерфейс #1 фреймов SATA
    input  logic [31 : 0]       i1_dat,
    input  logic                i1_val,
    input  logic                i1_eop,
    output logic                i1_rdy,
    
    // Входной потоковый интерфейс #2 фреймов SATA
    input  logic [31 : 0]       i2_dat,
    input  logic                i2_val,
    input  logic                i2_eop,
    output logic                i2_rdy,
    
    // Выходной потоковый интерфейс фреймов SATA
    output logic [31 : 0]       o_dat,
    output logic                o_val,
    output logic                o_eop,
    input  logic                o_rdy
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                       sop_reg;
    logic                       select;
    logic                       selected_reg;
    logic                       selected;
    
    //------------------------------------------------------------------------------------
    //      Признак начала фрейма выходного потока
    initial sop_reg = 1'b1;
    always @(posedge reset, posedge clk)
        if (reset)
            sop_reg <= 1'b1;
        else if (o_val & o_rdy)
            sop_reg <= o_eop;
        else
            sop_reg <= sop_reg;
    
    //------------------------------------------------------------------------------------
    //      Выбор интерфейса на первом слове фрема с приоритетом интерфейса #1
    assign select = ~i1_val & i2_val;
    
    //------------------------------------------------------------------------------------
    //      Регистр удержания выбранного интерфейса
    always @(posedge reset, posedge clk)
        if (reset)
            selected_reg <= '0;
        else if (o_val & o_rdy & sop_reg)
            selected_reg <= select;
        else
            selected_reg <= selected_reg;
    
    //------------------------------------------------------------------------------------
    //      Выбор интерфейса на всей длительности фрейма
    assign selected = sop_reg ? select : selected_reg;
    
    //------------------------------------------------------------------------------------
    //      Коммутация данных, признаков достоверности и конца фрейма
    assign o_dat = selected ? i2_dat : i1_dat;
    assign o_val = selected ? i2_val : i1_val;
    assign o_eop = selected ? i2_eop : i1_eop;
    
    //------------------------------------------------------------------------------------
    //      Стробирование признаков готовности
    assign i1_rdy = o_rdy & ~selected;
    assign i2_rdy = o_rdy &  selected;
    
endmodule: sata_fis_arbiter