/*
    // FlipFlop synchronizer
    ff_synchronizer
    #(
        .WIDTH          (), // Synchronized bus width
        .EXTRA_STAGES   (), // The number of extra stages
        .RESET_VALUE    ()  // The sync stages default value
    )
    the_ff_synchronizer
    (
        // Reset and clock
        .reset          (), // i
        .clk            (), // i

        // Asynchronous input
        .async_data     (), // i  [WIDTH - 1 : 0]

        // Synchronous output
        .sync_data      ()  // o  [WIDTH - 1 : 0]
    ); // the_ff_synchronizer
*/


module ff_synchronizer
#(
    parameter int unsigned          WIDTH        = 1,   // Synchronized bus width
    parameter int unsigned          EXTRA_STAGES = 0,   // The number of extra stages
    parameter logic [WIDTH - 1 : 0] RESET_VALUE  = 0    // The sync stages default value
)
(
    // Reset and clock
    input  logic                    reset,
    input  logic                    clk,

    // Asynchronous input
    input  logic [WIDTH - 1 : 0]    async_data,

    // Synchronous output
    output logic [WIDTH - 1 : 0]    sync_data
);
    // Constants declaration
    localparam int unsigned STAGES = 1 + EXTRA_STAGES;  // The total number of sync stages


    // Signals declaration
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON; -name SDC_STATEMENT \"set_false_path -to [get_keepers {*ff_synchronizer:*|stage0[*]}]\" "} *) reg [WIDTH - 1 : 0] stage0;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON"} *) reg [STAGES - 1 : 0][WIDTH - 1 : 0] stage_chain;


    // The first sync stage
    initial stage0 = RESET_VALUE;
    always @(posedge reset, posedge clk)
        if (reset)
            stage0 <= RESET_VALUE;
        else
            stage0 <= async_data;


    // The rest stages
    initial stage_chain = {STAGES{RESET_VALUE}};
    always @(posedge reset, posedge clk)
        if (reset)
            stage_chain <= {STAGES{RESET_VALUE}};
        else if (STAGES > 1)
            stage_chain <= {stage_chain[STAGES - 2 : 0], stage0};
        else
            stage_chain <= stage0;
    assign sync_data = stage_chain[STAGES - 1];


endmodule: ff_synchronizer