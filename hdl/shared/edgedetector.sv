/*
    // Signal edge detector
    edgedetector
    #(
        .INIT           ()  // Initial register state (1'b0 | 1'b1)
    )
    the_edgedetector
    (
        // Reset and clock
        .reset          (),
        .clk            (),

        // Input signal
        .i_pulse        (),

        // Edge indicators
        .o_rise         (),
        .o_fall         (),
        .o_either       ()
    ); // the_edgedetector
*/


module edgedetector
#(
    parameter logic         INIT = 1'b1     // Initial register state (1'b0 | 1'b1)
)
(
    // Reset and clock
    input  logic            reset,
    input  logic            clk,

    // Input signal
    input  logic            i_pulse,

    // Edges indicators
    output logic            o_rise,
    output logic            o_fall,
    output logic            o_either
);
    // Signals declaration
    logic pulse_reg;


    // Signal delay register
    initial pulse_reg = INIT;
    always @(posedge reset, posedge clk)
        if (reset)
            pulse_reg <= INIT;
        else
            pulse_reg <= i_pulse;


    // Edges indicators
    assign o_rise   =  i_pulse & ~pulse_reg;
    assign o_fall   = ~i_pulse &  pulse_reg;
    assign o_either =  i_pulse ^  pulse_reg;


endmodule // edgedetector