/*
    //------------------------------------------------------------------------------------
    //      Генератор псевдослучайной последовательности на сдвиговом линейном регистре
    //      с обратными связями
    lfsr_generator
    #(
        .POLYDEGREE     (), // Степень порождающего полинома
        .POLYNOMIAL     (), // Значение порождающего полинома
        .REGWIDTH       (), // Разрядность сдвигового регистра (REGWIDTH >= POLYDEGREE)
        .STEPSIZE       (), // Количество одноразрядных сдвигов за такт (STEPSIZE > 0)
        .REGINITIAL     ()  // Начальное значение сдвигового регистра (REGINITIAL != 0)
    )
    the_lfsr_generator
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i
        
        // Разрешение тактирования
        .clkena         (), // i
        
        // Синхронный сброс (инициализация)
        .init           (), // i
        
        // Выход
        .data           ()  // o  [REGWIDTH - 1 : 0]
    ); // the_lfsr_generator
*/

module lfsr_generator
#(
    parameter int unsigned                  POLYDEGREE  = 16,               // Степень порождающего полинома
    parameter logic [POLYDEGREE - 1 : 0]    POLYNOMIAL  = 16'hA011,         // Значение порождающего полинома
    parameter int unsigned                  REGWIDTH    = 48,               // Разрядность сдвигового регистра (REGWIDTH >= POLYDEGREE)
    parameter int unsigned                  STEPSIZE    = 32,               // Количество одноразрядных сдвигов за такт (STEPSIZE > 0)
    parameter logic [REGWIDTH - 1 : 0]      REGINITIAL  = 48'hb16e4b431f73  // Начальное значение сдвигового регистра (REGINITIAL != 0)
)
(
    // Сброс и тактирование
    input  logic                            reset,
    input  logic                            clk,
    
    // Разрешение тактирования
    input  logic                            clkena,
    
    // Синхронный сброс (инициализация)
    input  logic                            init,
    
    // Выход
    output logic [REGWIDTH - 1 : 0]         data
);
    //------------------------------------------------------------------------------------
    //      Проверка корректности установки параметров
    initial begin
        if (POLYDEGREE < 2) begin
            $fatal("POLYDEGREE can't be less then 2");
        end
        if (REGWIDTH < POLYDEGREE) begin
            $fatal("REGWIDTH can't be less then POLYDEGREE");
        end
        if (STEPSIZE < 1) begin
            $fatal("STEPSIZE can't be less then 1");
        end
    end
    
    //------------------------------------------------------------------------------------
    //      Расчет нового значения LFSR
    function automatic logic [REGWIDTH - 1 : 0] lfsr_calc(input  logic [REGWIDTH - 1 : 0] lfsr);
        for (int i = 0; i < STEPSIZE; i++) begin
            lfsr_calc[0] = lfsr[POLYDEGREE - 1];
            for (int j = 1; j < REGWIDTH; j++) begin
                if (j < POLYDEGREE)
                    if (POLYNOMIAL[j])
                        lfsr_calc[j] = lfsr[j - 1] ^ lfsr[POLYDEGREE - 1];
                    else
                        lfsr_calc[j] = lfsr[j - 1];
                else
                    lfsr_calc[j] = lfsr[j - 1];
            end
            lfsr = lfsr_calc;
        end
    endfunction
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов сигналов
    logic [REGWIDTH - 1 : 0]    lfs_reg;
    
    //------------------------------------------------------------------------------------
    //      Сдвиговый линейный регистр с обратными связями
    initial lfs_reg = REGINITIAL;
    always @(posedge reset, posedge clk)
        if (reset)
            lfs_reg <= REGINITIAL;
        else if (clkena)
            if (init)
                lfs_reg <= REGINITIAL;
            else
                lfs_reg <= lfsr_calc(lfs_reg);
        else
            lfs_reg <= lfs_reg;
    assign data = lfs_reg;
    
endmodule: lfsr_generator