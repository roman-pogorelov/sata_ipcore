/*
    // Asynchronous reset/preset synchronizer
    areset_synchronizer
    #(
        .EXTRA_STAGES   (), // The number of extra sync stages
        .ACTIVE_LEVEL   ()  // Active level of a reset/preset signal
    )
    the_areset_synchronizer
    (
        // Clock
        .clk            (), // i

        // Asynchronous reset/preset signal
        .areset         (), // i

        // Synchronous reset/preset signal
        .sreset         ()  // o
    ); // the_areset_synchronizer
*/

module areset_synchronizer
#(
    parameter int unsigned  EXTRA_STAGES = 1,   // The number of extra sync stages
    parameter logic         ACTIVE_LEVEL = 1'b1 // Active level of a reset/preset signal
)
(
    // Clock
    input  logic            clk,

    // Asynchronous reset/preset signal
    input  logic            areset,

    // Synchronous reset/preset signal
    output logic            sreset
);
    // Constants declaration
    localparam int unsigned STAGES = 1 + EXTRA_STAGES;


    // Signals and constraints declaration
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -through [get_pins -compatibility_mode {*areset_synchronizer*stage0|clrn}] -to [get_registers {*areset_synchronizer:*|stage0}]\" "} *) reg stage0;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -through [get_pins -compatibility_mode {*areset_synchronizer*stage_chain[*]|clrn}] -to [get_registers {*areset_synchronizer:*|stage_chain[*]}]\" "} *) reg [STAGES - 1 : 0] stage_chain;


    // Active level selection
    wire reset = ACTIVE_LEVEL ? areset : ~areset;


    // The first synchronization stage
    initial stage0 = ACTIVE_LEVEL;
    always @(posedge reset, posedge clk)
        if (reset)
            stage0 <= ACTIVE_LEVEL;
        else
            stage0 <= ~ACTIVE_LEVEL;


    // Rest synchronization stages
    initial stage_chain = {STAGES{ACTIVE_LEVEL}};
    always @(posedge reset, posedge clk)
        if (reset)
            stage_chain <= {STAGES{ACTIVE_LEVEL}};
        else if (STAGES > 1)
            stage_chain <= {stage_chain[STAGES - 2 : 0], stage0};
        else
            stage_chain <= stage0;
    assign sreset = stage_chain[STAGES - 1];


endmodule: areset_synchronizer