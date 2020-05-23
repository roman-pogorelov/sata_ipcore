/*
    // One hot to binary converter
    onehot2binary
    #(
        .WIDTH      ()  // One hot bus width
    )
    the_onehot2binary
    (
        .onehot     (), // i  [WIDTH - 1 : 0]
        .binary     ()  // o  [$clog2(WIDTH) - 1 : 0]
    ); // the_onehot2binary
*/

module onehot2binary
#(
    parameter int unsigned                  WIDTH = 9   // One hot bus width
)
(
    input  logic [WIDTH - 1 : 0]            onehot,
    output logic [$clog2(WIDTH) - 1 : 0]    binary
);
    // Encoding
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