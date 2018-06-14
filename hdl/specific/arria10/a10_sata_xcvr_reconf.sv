/*
    //------------------------------------------------------------------------------------
    //      Модуль реконфигурации высокоскоростного приемопередатчика Arria 10 на
    //      режимы работы стандартов SATA1, SATA2, SATA3
    a10_sata_xcvr_reconf
    the_a10_sata_xcvr_reconf
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i
        
        // Интерфейс команд на ре-конфигурацию
        .cmd_reconfig   (), // i
        .cmd_sata_gen   (), // i  [1 : 0]
        .cmd_ready      (), // o
        
        // Интерфейс доступа к адресному пространству
        // IP-ядра реконфигурации
        .recfg_addr     (), // o  [9 : 0]
        .recfg_wreq     (), // o
        .recfg_wdat     (), // o  [31 : 0]
        .recfg_rreq     (), // o
        .recfg_rdat     (), // i  [31 : 0]
        .recfg_busy     ()  // i
    ); // the_a10_sata_xcvr_reconf
*/

`include "sata_defs.svh"

module a10_sata_xcvr_reconf
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Интерфейс команд на ре-конфигурацию
    input  logic            cmd_reconfig,
    input  logic [1 : 0]    cmd_sata_gen,
    output logic            cmd_ready,
    
    // Интерфейс доступа к адресному пространству
    // IP-ядра реконфигурации
    output logic [9 : 0]    recfg_addr,
    output logic            recfg_wreq,
    output logic [31 : 0]   recfg_wdat,
    output logic            recfg_rreq,
    input  logic [31 : 0]   recfg_rdat,
    input  logic            recfg_busy
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam int unsigned     CFG_LOAD_BIT = 7;
    localparam int unsigned     BUSY_BIT     = 0;
    localparam logic [9 : 0]    CTRL_ADDRESS = 10'h340;
    localparam logic [9 : 0]    STAT_ADDRESS = 10'h341;
    localparam logic [1 : 0]    GEN1_PROFILE = 2'h0;
    localparam logic [1 : 0]    GEN2_PROFILE = 2'h1;
    localparam logic [1 : 0]    GEN3_PROFILE = 2'h2;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                       ready;
    logic                       ready_reg;
    logic [1 : 0]               cfg_sel_reg;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    (* syn_encoding = "gray" *) enum int unsigned {
        st_idle,
        st_wait_for_ready,
        st_initiate_reconfiguration,
        st_wait_for_completion
    } cstate, nstate;
    
    //------------------------------------------------------------------------------------
    //      Регистр текущего состояния конечного автомата и его регистровые выходы
    initial begin
        cstate = st_idle;
        ready_reg = 1'b1;
    end
    always @(posedge reset, posedge clk)
        if (reset) begin
            cstate <= st_idle;
            ready_reg <= 1'b1;
        end
        else begin
            cstate <= nstate;
            ready_reg <= ready;
        end
    
    //------------------------------------------------------------------------------------
    //      Логика формирования следующего состояния конечного автомата и его выходов
    always_comb begin
        // Значения по умолчанию для выходов конечного автомата
        recfg_addr = STAT_ADDRESS;
        recfg_wreq = 1'b0;
        recfg_rreq = 1'b0;
        ready      = 1'b0;
        
        // Выбор в зависимости от текущего состояния
        case (cstate)
            st_idle: begin
                if (cmd_reconfig)
                    nstate = st_wait_for_ready;
                else begin
                    ready = 1'b1;
                    nstate = st_idle;
                end
            end
            
            st_wait_for_ready: begin
                recfg_rreq = 1'b1;
                
                if (recfg_busy | recfg_rdat[BUSY_BIT])
                    nstate = st_wait_for_ready;
                else
                    nstate = st_initiate_reconfiguration;
            end
            
            st_initiate_reconfiguration: begin
                recfg_addr = CTRL_ADDRESS;
                recfg_wreq = 1'b1;
                
                if (recfg_busy)
                    nstate = st_initiate_reconfiguration;
                else
                    nstate = st_wait_for_completion;
            end
            
            st_wait_for_completion: begin
                recfg_rreq = 1'b1;
                
                if (recfg_busy | recfg_rdat[BUSY_BIT])
                    nstate = st_wait_for_completion;
                else begin
                    ready = 1'b1;
                    nstate = st_idle;
                end
            end
            
            default: begin
                ready = 1'b1;
                nstate = st_idle;
            end
        endcase
    end
    
    //------------------------------------------------------------------------------------
    //      Признак готовности к приему команды на реконфигурацию
    assign cmd_ready = ready_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр выбранного профиля реконфигурации
    always @(posedge reset, posedge clk)
        if (reset)
            cfg_sel_reg <= '0;
        else if (cmd_reconfig & cmd_ready)
            case (cmd_sata_gen)
                `SATA_GEN3: cfg_sel_reg <= GEN3_PROFILE;
                `SATA_GEN2: cfg_sel_reg <= GEN2_PROFILE;
                default:    cfg_sel_reg <= GEN1_PROFILE;
            endcase
        else
            cfg_sel_reg <= cfg_sel_reg;
    
    //------------------------------------------------------------------------------------
    //      Формирование записываемых данных
    assign recfg_wdat = {
        {$size(recfg_wdat) - (CFG_LOAD_BIT + 1){1'b0}}, //
        1'b1,                                           // Разряд, инициирующий начало реконфигурации
        {CFG_LOAD_BIT - $size(cfg_sel_reg){1'b0}},      //
        cfg_sel_reg                                     // Номер профиля реконфигурации
    };
    
endmodule: a10_sata_xcvr_reconf