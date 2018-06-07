/*
    //------------------------------------------------------------------------------------
    //      Модуль компенсации разности между восстановленной и опорной частотами
    //      PCS-уровня
    pcs_rate_match_fifo
    #(
        .BYTES          (), // Количество байт
        .DPATTERN       (), // Шаблон удаляемых/вставляемых данных
        .KPATTERN       (), // Шаблон удаляемых/вставляемых признаков контрольных символов
        .FIFOLEN        (), // Длина FIFO
        .MAXUSED        (), // Максимальное количество слов в FIFO
        .MINUSED        (), // Минимальное количество слов в FIFO
        .RAMTYPE        ()  // Тип блоков встроенной памяти ("MLAB" "M20K" ...)
    )
    the_pcs_rate_match_fifo
    (
        // Общий асинхронный сброс
        .reset          (), // i
        
        // Восстановленная частота тактирования
        .rcv_clk        (), // i
        
        // Опорная частота тактирования
        .ref_clk        (), // i
        
        // Входной поток данных на восстановленной частоте
        .rcv_data       (), // i  [8 * BYTES - 1 : 0]
        .rcv_datak      (), // i  [BYTES - 1 : 0]
        
        // Выходной поток данных на опорной частоте
        .ref_data       (), // o  [8 * BYTES - 1 : 0]
        .ref_datak      (), // o  [BYTES - 1 : 0]
        
        // Статусные сигналы на восстановленной частоте
        .stat_rcv_del   (), // o
        .stat_rcv_ovfl  (), // o
        
        // Статусные сигналы на опорной частоте
        .stat_ref_ins   (), // o
        .stat_ref_unfl  ()  // o
    ); // the_pcs_rate_match_fifo
*/

module pcs_rate_match_fifo
#(
    parameter int unsigned              BYTES       = 8,            // Количество байт
    parameter logic [8 * BYTES - 1 : 0] DPATTERN    = 32'h7B4A4ABC, // Шаблон удаляемых/вставляемых данных
    parameter logic [BYTES - 1 : 0]     KPATTERN    = 4'h1,         // Шаблон удаляемых/вставляемых признаков контрольных символов
    parameter int unsigned              FIFOLEN     = 10,           // Длина FIFO
    parameter int unsigned              MAXUSED     = 7,            // Максимальное количество слов в FIFO
    parameter int unsigned              MINUSED     = 3,            // Минимальное количество слов в FIFO
    parameter                           RAMTYPE     = "AUTO"        // Тип блоков встроенной памяти ("MLAB", "M20K", ...)
)
(
    // Общий асинхронный сброс
    input  logic                        reset,
    
    // Восстановленная частота тактирования
    input  logic                        rcv_clk,
    
    // Опорная частота тактирования
    input  logic                        ref_clk,
    
    // Входной поток данных на восстановленной частоте
    input  logic [8 * BYTES - 1 : 0]    rcv_data,
    input  logic [BYTES - 1 : 0]        rcv_datak,
    
    // Выходной поток данных на опорной частоте
    output logic [8 * BYTES - 1 : 0]    ref_data,
    output logic [BYTES - 1 : 0]        ref_datak,
    
    // Статусные сигналы на восстановленной частоте
    output logic                        stat_rcv_del,
    output logic                        stat_rcv_ovfl,
    
    // Статусные сигналы на опорной частоте
    output logic                        stat_ref_ins,
    output logic                        stat_ref_unfl
);
    //------------------------------------------------------------------------------------
    //      Описание констан
    localparam int unsigned             WTIME = 4;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                               rcv_reset;
    logic                               ref_reset;
    //
    logic [8 * BYTES - 1 : 0]           rcv_data_reg;
    logic [BYTES - 1 : 0]               rcv_datak_reg;
    logic                               rcv_patdet_reg;
    //
    logic [8 * BYTES - 1 : 0]           ref_data_int;
    logic [BYTES - 1 : 0]               ref_datak_int;
    //
    logic [8 * BYTES - 1 : 0]           ref_data_reg;
    logic [BYTES - 1 : 0]               ref_datak_reg;
    logic                               ref_patdet_reg;
    //
    logic                               fifo_wrreq;
    logic                               fifo_wrfull;
    logic                               fifo_wrempty;
    logic [$clog2(FIFOLEN) - 1 : 0]     fifo_wrusedw;
    logic [$clog2(FIFOLEN + 1) - 1 : 0] fifo_wrcnt;
    logic                               fifo_rdreq;
    logic                               fifo_rdfull;
    logic                               fifo_rdempty;
    logic [$clog2(FIFOLEN) - 1 : 0]     fifo_rdusedw;
    logic [$clog2(FIFOLEN + 1) - 1 : 0] fifo_rdcnt;
    //
    logic [$clog2(WTIME) - 1 : 0]       wr_wait_cnt;
    logic                               wr_wait_inc;
    logic [$clog2(WTIME) - 1 : 0]       rd_wait_cnt;
    logic                               rd_wait_inc;
    //
    logic                               rcv_del_reg;
    logic                               rcv_ovfl_reg;
    logic                               ref_ins_reg;
    logic                               ref_unfl_reg;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата записи
    enum logic [1 : 0] {
        wr_st_normal    = 2'b00,
        wr_st_violation = 2'b01,
        wr_st_waiting   = 2'b10
    } wr_state;
    wire [1 : 0] wr_st;
    assign wr_st = wr_state;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата чтения
    enum logic [2 : 0] {
        rd_st_init      = 3'b000,
        rd_st_normal    = 3'b001,
        rd_st_violation = 3'b010,
        rd_st_waiting   = 3'b101
    } rd_state;
    wire [2 : 0] rd_st;
    assign rd_st = rd_state;
    
    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата записи
    always @(posedge rcv_reset, posedge rcv_clk)
        if (rcv_reset)
            wr_state <= wr_st_normal;
        else case (wr_state)
            wr_st_normal:
                if (fifo_wrcnt > MAXUSED)
                    wr_state <= wr_st_violation;
                else
                    wr_state <= wr_st_normal;
            
            wr_st_violation:
                if (rcv_patdet_reg)
                    wr_state <= wr_st_waiting;
                else
                    wr_state <= wr_st_violation;
            
            wr_st_waiting:
                if (wr_wait_cnt == (WTIME - 1))
                    wr_state <= wr_st_normal;
                else
                    wr_state <= wr_st_waiting;
            
            default:
                wr_state <= wr_st_normal;
        endcase
    
    //------------------------------------------------------------------------------------
    //      Управляющие сигналы конечного автомата записи
    assign fifo_wrreq   = ~wr_st[0] | ~rcv_patdet_reg;
    assign wr_wait_inc  =  wr_st[1];
    
    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата чтения
    always @(posedge ref_reset, posedge ref_clk)
        if (ref_reset)
            rd_state <= rd_st_init;
        else case (rd_state)
            rd_st_init:
                if (fifo_rdcnt < MINUSED)
                    rd_state <= rd_st_init;
                else
                    rd_state <= rd_st_normal;
            
            rd_st_normal:
                if (fifo_rdcnt < MINUSED)
                    rd_state <= rd_st_violation;
                else
                    rd_state <= rd_st_normal;
            
            rd_st_violation:
                if (ref_patdet_reg)
                    rd_state <= rd_st_waiting;
                else
                    rd_state <= rd_st_violation;
            
            rd_st_waiting:
                if (rd_wait_cnt == (WTIME - 1))
                    rd_state <= rd_st_normal;
                else
                    rd_state <= rd_st_waiting;
            
            default:
                rd_state <= rd_st_init;
        endcase
    
    //------------------------------------------------------------------------------------
    //      Управляющие сигналы конечного автомата чтения
    assign fifo_rdreq   = rd_st[0] | (rd_st[1] & ~ref_patdet_reg);
    assign rd_wait_inc  = rd_st[2];
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),        // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)      // Активный уровень сигнала сброса
    )
    rcv_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (rcv_clk),  // i
        
        // Входной сброс (асинхронный 
        // относительно сигнала тактирования)
        .areset         (reset),    // i
        
        // Выходной сброс (синхронный 
        // относительно сигнала тактирования)
        .sreset         (rcv_reset) // o
    ); // rcv_reset_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),        // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)      // Активный уровень сигнала сброса
    )
    ref_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (ref_clk),  // i
        
        // Входной сброс (асинхронный 
        // относительно сигнала тактирования)
        .areset         (reset),    // i
        
        // Выходной сброс (синхронный 
        // относительно сигнала тактирования)
        .sreset         (ref_reset) // o
    ); // ref_reset_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Двухклоковое FIFO на ядре от Altera
    dcfifo
    #(
        .lpm_hint               ({"RAM_BLOCK_TYPE=", RAMTYPE}),
        .lpm_numwords           (FIFOLEN),
        .lpm_showahead          ("ON"),
        .lpm_type               ("dcfifo"),
        .lpm_width              (9 * BYTES),
        .lpm_widthu             ($clog2(FIFOLEN)),
        .overflow_checking      ("ON"),
        .rdsync_delaypipe       (4),
        .read_aclr_synch        ("ON"),
        .underflow_checking     ("ON"),
        .use_eab                ("ON"),
        .write_aclr_synch       ("ON"),
        .wrsync_delaypipe       (4)
    )
    rate_match_dcfifo
    (
        .aclr                   (reset),
        .wrclk                  (rcv_clk),
        .wrreq                  (fifo_wrreq),
        .data                   ({rcv_datak_reg, rcv_data_reg}),
        .wrfull                 (fifo_wrfull),
        .rdclk                  (ref_clk),
        .rdreq                  (fifo_rdreq),
        .q                      ({ref_datak_int, ref_data_int}),
        .rdempty                (fifo_rdempty),
        .rdfull                 (fifo_rdfull),
        .rdusedw                (fifo_rdusedw),
        .wrempty                (fifo_wrempty),
        .wrusedw                (fifo_wrusedw)
    ); // rate_match_dcfifo
    
    //------------------------------------------------------------------------------------
    //      Регистр входных данных
    always @(posedge rcv_reset, posedge rcv_clk)
        if (rcv_reset)
            rcv_data_reg <= '0;
        else
            rcv_data_reg <= rcv_data;
    
    //------------------------------------------------------------------------------------
    //      Регистр признаков контрольных символов во входных данных
    always @(posedge rcv_reset, posedge rcv_clk)
        if (rcv_reset)
            rcv_datak_reg <= '0;
        else
            rcv_datak_reg <= rcv_datak;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения искомого шаблона во входных данных
    always @(posedge rcv_reset, posedge rcv_clk)
        if (rcv_reset)
            rcv_patdet_reg <= 1'b0;
        else
            rcv_patdet_reg <= (rcv_data == DPATTERN) & (rcv_datak == KPATTERN);
    
    //------------------------------------------------------------------------------------
    //      Регистр выходных данных
    always @(posedge ref_reset, posedge ref_clk)
        if (ref_reset)
            ref_data_reg <= '0;
        else if (fifo_rdreq)
            ref_data_reg <= ref_data_int;
        else
            ref_data_reg <= ref_data_reg;
    assign ref_data = ref_data_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признаков контрольных символов в выходных данных
    always @(posedge ref_reset, posedge ref_clk)
        if (ref_reset)
            ref_datak_reg <= '0;
        else if (fifo_rdreq)
            ref_datak_reg <= ref_datak_int;
        else
            ref_datak_reg <= ref_datak_reg;
    assign ref_datak = ref_datak_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака обнаружения искомого шаблона в выходных данных
    always @(posedge ref_reset, posedge ref_clk)
        if (ref_reset)
            ref_patdet_reg <= '0;
        else if (fifo_rdreq)
            ref_patdet_reg <= (ref_data_int == DPATTERN) & (ref_datak_int == KPATTERN);
        else
            ref_patdet_reg <= ref_patdet_reg;
    
    //------------------------------------------------------------------------------------
    //      Формирование дополнительного разряда в количестве используемых
    //      слов FIFO при длине равной степени 2-ки
    generate
        if (FIFOLEN == (2**($clog2(FIFOLEN)))) begin: len_is_power_of_two
            assign fifo_wrcnt[$clog2(FIFOLEN + 1) - 2 : 0] = fifo_wrusedw;
            assign fifo_rdcnt[$clog2(FIFOLEN + 1) - 2 : 0] = fifo_rdusedw;
            assign fifo_wrcnt[$clog2(FIFOLEN + 1) - 1] = fifo_wrfull;
            assign fifo_rdcnt[$clog2(FIFOLEN + 1) - 1] = fifo_rdfull;
        end
        else begin: len_isnt_power_of_two
            assign fifo_wrcnt = fifo_wrusedw;
            assign fifo_rdcnt = fifo_rdusedw;
        end
    endgenerate
    
    //------------------------------------------------------------------------------------
    //      Счетчик ожидания при записи
    always @(posedge rcv_reset, posedge rcv_clk)
        if (rcv_reset)
            wr_wait_cnt <= '0;
        else if (wr_wait_inc)
            wr_wait_cnt <= wr_wait_cnt + 1'b1;
        else
            wr_wait_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Счетчик ожидания при чтении
    always @(posedge ref_reset, posedge ref_clk)
        if (ref_reset)
            rd_wait_cnt <= '0;
        else if (rd_wait_inc)
            rd_wait_cnt <= rd_wait_cnt + 1'b1;
        else
            rd_wait_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака удаления шаблона
    always @(posedge rcv_reset, posedge rcv_clk)
        if (rcv_reset)
            rcv_del_reg <= '0;
        else
            rcv_del_reg <= ~fifo_wrreq & rcv_patdet_reg;
    assign stat_rcv_del = rcv_del_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака записи в полное FIFO
    always @(posedge rcv_reset, posedge rcv_clk)
        if (rcv_reset)
            rcv_ovfl_reg <= '0;
        else
            rcv_ovfl_reg <= fifo_wrfull & fifo_wrreq;
    assign stat_rcv_ovfl = rcv_ovfl_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака вставки шаблона
    always @(posedge ref_reset, posedge ref_clk)
        if (ref_reset)
            ref_ins_reg <= '0;
        else
            ref_ins_reg <= ~fifo_rdreq & ref_patdet_reg;
    assign stat_ref_ins = ref_ins_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака чтения из пустого FIFO
    always @(posedge ref_reset, posedge ref_clk)
        if (ref_reset)
            ref_unfl_reg <= '0;
        else
            ref_unfl_reg <= fifo_rdempty & fifo_rdreq;
    assign stat_ref_unfl = ref_unfl_reg;
    
endmodule: pcs_rate_match_fifo