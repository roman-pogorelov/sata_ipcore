/*
    //------------------------------------------------------------------------------------
    //      Модуль реверса (зеркалирования) разрядов произвольной параллельной шины
    bitreverser
    #(
        .WIDTH      ()  // Разрядность
    )
    the_bitreverser
    (
        // Входные данные
        .i_dat      (), // i  [WIDTH - 1 : 0] 
        
        // Выходные данные
        .o_dat      ()  // o  [WIDTH - 1 : 0]
    ); // the_bitreverser
*/

module bitreverser
#(
    parameter int unsigned      WIDTH = 8   // Разрядность
)
(
    // Входные данные
    input  wire [WIDTH - 1 : 0] i_dat,
    
    // Выходные данные
    output wire [WIDTH - 1 : 0] o_dat
);
    //------------------------------------------------------------------------------------
    //      Генерация реверса
    generate
        genvar i;
        for (i = 0; i < WIDTH; i++) begin: reverse_gen_loop
            assign o_dat[i] = i_dat[WIDTH - 1 - i];
        end
    endgenerate
    
endmodule // bitreverser