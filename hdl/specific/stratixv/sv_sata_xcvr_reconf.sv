/*
    //------------------------------------------------------------------------------------
    //      Модуль реконфигурации высокоскоростного приемопередатчика Arria V на
    //      режимы работы стандартов SATA1, SATA2, SATA3
    sv_sata_xcvr_reconf
    the_sv_sata_xcvr_reconf
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
        .recfg_addr     (), // o  [6 : 0]
        .recfg_wreq     (), // o
        .recfg_wdat     (), // o  [31 : 0]
        .recfg_rreq     (), // o
        .recfg_rdat     (), // i  [31 : 0]
        .recfg_busy     ()  // i
    ); // the_sv_sata_xcvr_reconf
*/

`include "sata_defs.svh"

module sv_sata_xcvr_reconf
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
    output logic [6 : 0]    recfg_addr,
    output logic            recfg_wreq,
    output logic [31 : 0]   recfg_wdat,
    output logic            recfg_rreq,
    input  logic [31 : 0]   recfg_rdat,
    input  logic            recfg_busy
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam logic [6 : 0]    CHAN_ADDR   = 7'h38;
    localparam logic [6 : 0]    CTRL_ADDR   = 7'h3A;
    localparam logic [6 : 0]    OFFSET_ADDR = 7'h3B;
    localparam logic [6 : 0]    DATA_ADDR   = 7'h3C;
    //
    localparam int unsigned     WR_COUNT    = 4;
    localparam int unsigned     WR_PAUSE    = 4;
    localparam int unsigned     BUSY_BIT    = 8;
    //
    localparam logic [WR_COUNT - 1 : 0][31 : 0] PARAM_OFFSET = {32'h00000000, 32'h00000002, 32'h0000000C, 32'h00000016};
    localparam logic [WR_COUNT - 1 : 0][31 : 0] SATA1_PARAMS = {32'h00002C40, 32'h00008094, 32'h00005600, 32'h00000296};
    localparam logic [WR_COUNT - 1 : 0][31 : 0] SATA2_PARAMS = {32'h00002A40, 32'h00008094, 32'h00005500, 32'h00000496};
    localparam logic [WR_COUNT - 1 : 0][31 : 0] SATA3_PARAMS = {32'h00002840, 32'h000080D4, 32'h00005400, 32'h00000496};
    //
    localparam logic [31 : 0]   CHAN_CODE   = 32'h00000000;
    localparam logic [31 : 0]   MODE_CODE   = 32'h00000004;
    localparam logic [31 : 0]   WRITE_CODE  = 32'h00000005;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [$clog2(WR_COUNT + 1) - 1 : 0]    write_cnt;
    logic [$clog2(WR_PAUSE) - 1 : 0]        wait_cnt;
    logic                                   ready_reg;
    logic [WR_COUNT - 1 : 0][31 : 0]        offset_reg;
    logic [WR_COUNT - 1 : 0][31 : 0]        param_reg;
    logic [6 : 0]                           addr_reg;
    logic                                   wreq_reg;
    logic [31 : 0]                          wdat_reg;
    logic                                   rreq_reg;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    enum logic [3 : 0] {
        st_idle          = 4'h0,
        st_set_channel   = 4'h1,
        st_wait_channel  = 4'h2,
        st_check_channel = 4'h3,
        st_set_mode      = 4'h4,
        st_wait_mode     = 4'h5,
        st_check_mode    = 4'h6,
        st_set_offset    = 4'h7,
        st_wait_offset   = 4'h8,
        st_check_offset  = 4'h9,
        st_set_value     = 4'hA,
        st_wait_value    = 4'hB,
        st_check_value   = 4'hC,
        st_set_write     = 4'hD,
        st_wait_write    = 4'hE,
        st_check_write   = 4'hF
    } cstate, nstate;
    
    //------------------------------------------------------------------------------------
    //      Регистр текущего состояния конечного автомата
    always @(posedge reset, posedge clk)
        if (reset)
            cstate <= st_idle;
        else
            cstate <= nstate;
    
    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата
    always_comb begin
        case (cstate)
            st_idle:
                if (cmd_reconfig)
                    nstate = st_set_channel;
                else
                    nstate = st_idle;
            
            st_set_channel:
                if (~recfg_busy)
                    nstate = st_wait_channel;
                else
                    nstate = st_set_channel;
            
            st_wait_channel:
                if (wait_cnt == (WR_PAUSE - 1))
                    nstate = st_check_channel;
                else
                    nstate = st_wait_channel;
            
            st_check_channel:
                if (~recfg_busy & ~recfg_rdat[BUSY_BIT])
                    nstate = st_set_mode;
                else
                    nstate = st_check_channel;
            
            st_set_mode:
                if (~recfg_busy)
                    nstate = st_wait_mode;
                else
                    nstate = st_set_mode;
            
            st_wait_mode:
                if (wait_cnt == (WR_PAUSE - 1))
                    nstate = st_check_mode;
                else
                    nstate = st_wait_mode;
            
            st_check_mode:
                if (~recfg_busy & ~recfg_rdat[BUSY_BIT])
                    nstate = st_set_offset;
                else
                    nstate = st_check_mode;
            
            st_set_offset:
                if (~recfg_busy)
                    nstate = st_wait_offset;
                else
                    nstate = st_set_offset;
            
            st_wait_offset:
                if (wait_cnt == (WR_PAUSE - 1))
                    nstate = st_check_offset;
                else
                    nstate = st_wait_offset;
            
            st_check_offset:
                if (~recfg_busy & ~recfg_rdat[BUSY_BIT])
                    nstate = st_set_value;
                else
                    nstate = st_check_offset;
            
            st_set_value:
                if (~recfg_busy)
                    nstate = st_wait_value;
                else
                    nstate = st_set_value;
            
            st_wait_value:
                if (wait_cnt == (WR_PAUSE - 1))
                    nstate = st_check_value;
                else
                    nstate = st_wait_value;
            
            st_check_value:
                if (~recfg_busy & ~recfg_rdat[BUSY_BIT])
                    nstate = st_set_write;
                else
                    nstate = st_check_value;
            
            st_set_write:
                if (~recfg_busy)
                    nstate = st_wait_write;
                else
                    nstate = st_set_write;
            
            st_wait_write:
                if (wait_cnt == (WR_PAUSE - 1))
                    nstate = st_check_write;
                else
                    nstate = st_wait_write;
            
            st_check_write:
                if (~recfg_busy & ~recfg_rdat[BUSY_BIT])
                    if (write_cnt == WR_COUNT)
                        nstate = st_idle;
                    else
                        nstate = st_set_offset;
                else
                    nstate = st_check_write;
            
            default:
                nstate = st_idle;
        endcase
    end
    
    //------------------------------------------------------------------------------------
    //      Счетчик операций записи параметров реконфигурации
    always @(posedge reset, posedge clk)
        if (reset)
            write_cnt <= '0;
        else if (cstate == st_idle)
            write_cnt <= '0;
        else if ((cstate == st_set_write) & ~recfg_busy)
            write_cnt <= write_cnt + 1'b1;
        else
            write_cnt <= write_cnt;
    
    //------------------------------------------------------------------------------------
    //      Счетчик интервала ожидания после каждой операции записи
    always @(posedge reset, posedge clk)
        if (reset)
            wait_cnt <= '0;
        else if ((cstate == st_wait_channel) | (cstate == st_wait_mode) | (cstate == st_wait_offset) | (cstate == st_wait_value) | (cstate == st_wait_write))
            wait_cnt <= wait_cnt + 1'b1;
        else
            wait_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Регистр готовности
    initial ready_reg = 1'b1;
    always @(posedge reset, posedge clk)
        if (reset)
            ready_reg <= 1'b1;
        else
            ready_reg <= (nstate == st_idle);
    assign cmd_ready = ready_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр смещений записи
    initial offset_reg = PARAM_OFFSET;
    always @(posedge reset, posedge clk)
        if (reset)
            offset_reg <= PARAM_OFFSET;
        else if ((cstate == st_idle) & cmd_reconfig)
            offset_reg <= PARAM_OFFSET;
        else if ((cstate == st_set_offset) & ~recfg_busy)
            offset_reg <= {offset_reg[WR_COUNT - 2 : 0], offset_reg[WR_COUNT - 1]};
        else
            offset_reg <= offset_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр значения записываемых параметров
    initial param_reg = SATA3_PARAMS;
    always @(posedge reset, posedge clk)
        if (reset)
            param_reg <= SATA3_PARAMS;
        else if ((cstate == st_idle) & cmd_reconfig)
            case (cmd_sata_gen)
                `SATA_GEN2: param_reg <= SATA2_PARAMS;
                `SATA_GEN3: param_reg <= SATA3_PARAMS;
                default:    param_reg <= SATA1_PARAMS;
            endcase
        else if ((cstate == st_set_value) & ~recfg_busy)
            param_reg <= {param_reg[WR_COUNT - 2 : 0], param_reg[WR_COUNT - 1]};
        else
            param_reg <= param_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр адреса доступа
    initial addr_reg <= CTRL_ADDR;
    always @(posedge reset, posedge clk)
        if (reset)
            addr_reg <= CTRL_ADDR;
        else case (nstate)
            st_set_channel: addr_reg <= CHAN_ADDR;
            st_set_offset:  addr_reg <= OFFSET_ADDR;
            st_set_value:   addr_reg <= DATA_ADDR;
            default:        addr_reg <= CTRL_ADDR;
        endcase
    assign recfg_addr = addr_reg;
    
    //------------------------------------------------------------------------------------
    //      Регист запроса на запись
    always @(posedge reset, posedge clk)
        if (reset)
            wreq_reg <= '0;
        else
            wreq_reg <= (
                (nstate == st_set_channel) |
                (nstate == st_set_mode) |
                (nstate == st_set_offset) |
                (nstate == st_set_value) |
                (nstate == st_set_write)
            );
    assign recfg_wreq = wreq_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр данных на запись
    always @(posedge reset, posedge clk)
        if (reset)
            wdat_reg <= '0;
        else case (nstate)
            st_set_mode:    wdat_reg <= MODE_CODE;
            st_set_offset:  wdat_reg <= offset_reg[WR_COUNT - 1];
            st_set_value:   wdat_reg <= param_reg[WR_COUNT - 1];
            st_set_write:   wdat_reg <= WRITE_CODE;
            default:        wdat_reg <= CHAN_CODE;
        endcase
    assign recfg_wdat = wdat_reg;
    
    //------------------------------------------------------------------------------------
    //      Регист запроса на чтение
    always @(posedge reset, posedge clk)
        if (reset)
            rreq_reg <= '0;
        else
            rreq_reg <= (
                (nstate == st_check_channel) |
                (nstate == st_check_mode) |
                (nstate == st_check_offset) |
                (nstate == st_check_value) |
                (nstate == st_check_write)
            );
    assign recfg_rreq = rreq_reg;

endmodule: sv_sata_xcvr_reconf