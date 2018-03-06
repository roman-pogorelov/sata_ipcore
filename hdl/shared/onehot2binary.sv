/*
    //------------------------------------------------------------------------------------
    //      Преобразователь позиционного кода в двоичный
    onehot2binary
    #(
        .WIDTH      ()  // Разрядность входа позиционного кода
    )
    the_onehot2binary
    (
        .onehot     (), // i  [WIDTH - 1 : 0]
        .binary     ()  // o  [$clog2(WIDTH) - 1 : 0]
    ); // the_onehot2binary
*/

module onehot2binary
#(
    parameter int unsigned                  WIDTH = 9   // Разрядность входа позиционного кода
)
(
    input  logic [WIDTH - 1 : 0]            onehot,
    output logic [$clog2(WIDTH) - 1 : 0]    binary
);
    //------------------------------------------------------------------------------------
    //      Схема кодирования
    generate
        genvar i, j;
        for (i = 0; i < $clog2(WIDTH); i++) begin: il
            logic [WIDTH - 1 : 0] mask;
            for (j = 0; j < WIDTH; j++) begin: jl
                assign mask[j] = j[i];
            end
            assign binary[i] = |(mask & onehot);
        end
    endgenerate
    
endmodule // onehot2binary