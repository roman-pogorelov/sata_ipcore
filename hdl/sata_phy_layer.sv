/*
    //------------------------------------------------------------------------------------
    //      Модуль физического уровня стека SerialATA
    sata_phy_layer
    #(
        .FPGAFAMILY         ()  // Семейство FPGA ("Arria V" | "Arria 10")
    )
    the_sata_phy_layer
    (
        // Сброс и тактирование интерфейса реконфигурации
        .reconfig_reset     (), // i
        .reconfig_clk       (), // i
        
        // Сброс и тактирование высокоскоростных приемопередатчиков
        .gxb_reset          (), // i
        .gxb_refclk         (), // i
        
        // Выходное тактирование интерфейса приемника и передатчика
        .link_clk           (), // o
        
        // Индикатор установки соединения (домен link_clk)
        .linkup             (), // o
        
        // Индикатор поколения SATA (домен link_clk)
        .sata_gen           (), // o  [1 : 0]
        
        // Интерфейс приемника (домен link_clk)
        .rx_data            (), // o  [31 : 0]
        .rx_datak           (), // o
        
        // Интерфейс передатчика (домен link_clk)
        .tx_data            (), // i  [31 : 0]
        .tx_datak           (), // i
        .tx_ready           (), // o
        
        // Высокоскоростные линии
        .gxb_rx             (), // i
        .gxb_tx             ()  // o
    ); // the_sata_phy_layer
*/

`include "sata_defs.svh"

module sata_phy_layer
#(
    parameter               FPGAFAMILY  = "Arria V"     // Семейство FPGA ("Arria V" | "Arria 10")
)
(
    // Сброс и тактирование интерфейса реконфигурации
    input  logic            reconfig_reset,
    input  logic            reconfig_clk,
    
    // Сброс и тактирование высокоскоростных приемопередатчиков
    input  logic            gxb_reset,
    input  logic            gxb_refclk,
    
    // Выходное тактирование интерфейса приемника и передатчика
    output logic            link_clk,
        
    // Индикатор установки соединения (домен link_clk)
    output logic            linkup,
    
    // Индикатор поколения SATA (домен link_clk)
    output logic [1 : 0]    sata_gen,
    
    // Интерфейс приемника (домен link_clk)
    output logic [31 : 0]   rx_data,
    output logic            rx_datak,
    
    // Интерфейс передатчика (домен link_clk)
    input  logic [31 : 0]   tx_data,
    input  logic            tx_datak,
    output logic            tx_ready,
    
    // Высокоскоростные линии
    input  logic            gxb_rx,
    output logic            gxb_tx
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned         CLKFREQ = 150_000;
    localparam int unsigned         TIMEOUT = (880 * CLKFREQ) / 1000;
    localparam int unsigned         TCWIDTH = $clog2(TIMEOUT + 1);
    localparam int unsigned         FIFOLEN = 10;
    localparam int unsigned         MAXUSED = 7;
    localparam int unsigned         MINUSED = 3;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                           rx_reset;
    logic                           rx_clk;
    logic                           tx_reset;
    logic                           tx_clk;
    //
    logic                           rx_is_lockedtodata;
    logic                           rx_is_lockedtoref;
    logic                           rx_is_lockedtoref_resync;
    logic [3 : 0]                   rx_patterndetect;
    logic                           tx_elecidle;
    logic                           rx_signaldetect;
    logic                           rx_signaldetect_resync;
    logic [3 : 0]                   rx_syncstatus;
    logic [3 : 0]                   rx_syncstatus_resync;
    logic [3 : 0]                   rx_datak_resync;
    logic [31 : 0]                  rx_data_resync;
    logic [3 : 0]                   rx_datak_unalign;
    logic [31 : 0]                  rx_data_unalign;
    logic [3 : 0]                   rx_datak_align;
    logic [31 : 0]                  rx_data_align;
    //
    logic                           tx_cominit;
    logic                           tx_comwake;
    logic                           tx_oobfinish;
    logic                           tx_select;
    logic                           tx_select_resync;
    logic                           tx_obb_ready;
    //
    logic                           rx_cominit;
    logic                           rx_comwake;
    logic                           rx_oobfinish;
    //
    logic                           link_ready;
    logic                           link_ready_resync;
    logic                           timeout_inc;
    logic [TCWIDTH - 1 : 0]         timeout_cnt;
    logic [7 : 0]                   align_cnt;
    logic                           align_reg;
    //
    logic [31 : 0]                  tx_data_reg;
    logic                           tx_datak_reg;
    //
    logic [$clog2(FIFOLEN) - 1 : 0] linkup_cnt;
    logic                           linkup_reg;
    //
    logic                           reset_rmfifo_reg;
    //
    logic                           recfg_request;
    logic                           recfg_request_resync;
    logic                           recfg_ready;
    logic                           recfg_ready_resync;
    logic [1 : 0]                   recfg_sata_gen_reg;
    logic [1 : 0]                   recfg_sata_gen_resync;
    logic [1 : 0]                   sata_gen_reg;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    enum logic [8 : 0] {
        st_idle             = 9'b00_0_0_0_0_0_0_0,
        st_send_comreset    = 9'b00_0_0_0_0_0_1_0,
        st_suspend_comreset = 9'b01_0_0_0_0_0_0_0,
        st_wait_cominit     = 9'b00_0_1_0_0_0_0_0,
        st_send_comwake     = 9'b00_0_0_0_0_1_0_0,
        st_suspend_comwake  = 9'b10_0_0_0_0_0_0_0,
        st_wait_comwake     = 9'b01_0_1_0_0_0_0_0,
        st_wait_oobfinish   = 9'b10_0_1_0_0_0_0_0,
        st_send_dial        = 9'b11_0_1_1_1_0_0_0,
        st_request_recfg    = 9'b11_1_0_0_0_0_0_0,
        st_wait_recfg       = 9'b11_0_1_0_0_0_0_0,
        st_send_align       = 9'b11_0_1_0_1_0_0_0,
        st_link_ready       = 9'b11_0_0_0_1_0_0_1
    } state;
    wire [8 : 0] st;
    assign st = state;
    
    //------------------------------------------------------------------------------------
    //      Управляющие сигналы конечного автомата
    assign link_ready    = st[0];
    assign tx_cominit    = st[1];
    assign tx_comwake    = st[2];
    assign tx_oobfinish  = st[3];
    assign tx_select     = st[4];
    assign timeout_inc   = st[5];
    assign recfg_request = st[6];
    
    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            state <= st_idle;
        else case (state)
            st_idle:
                if (rx_is_lockedtoref_resync)
                    state <= st_send_comreset;
                else
                    state <= st_idle;
                
            st_send_comreset:
                state <= st_suspend_comreset;
                
            st_suspend_comreset:
                if (tx_obb_ready)
                    state <= st_wait_cominit;
                else
                    state <= st_suspend_comreset;
                
            st_wait_cominit:
                if (rx_cominit)
                    state <= st_send_comwake;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_wait_cominit;
                
            st_send_comwake:
                state <= st_suspend_comwake;
                
            st_suspend_comwake:
                if (tx_obb_ready)
                    state <= st_wait_comwake;
                else
                    state <= st_suspend_comwake;
                
            st_wait_comwake:
                if (rx_comwake)
                    state <= st_wait_oobfinish;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_wait_comwake;
                
            st_wait_oobfinish:
                if (rx_oobfinish)
                    state <= st_send_dial;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_wait_oobfinish;
            
            st_send_dial:
                if ((rx_data_resync == `ALIGN_PRIM) & (rx_datak_resync == {{3{1'b0}}, `DWORD_IS_PRIM}) & (&rx_syncstatus_resync))
                    state <= st_send_align;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_request_recfg;
                else
                    state <= st_send_dial;
            
            st_request_recfg:
                if (recfg_ready)
                    state <= st_wait_recfg;
                else
                    state <= st_request_recfg;
                
            st_wait_recfg:
                if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_wait_recfg;
            
            st_send_align:
                if ((rx_data_resync == `SYNC_PRIM) & (rx_datak_resync == {{3{1'b0}}, `DWORD_IS_PRIM}))
                    state <= st_link_ready;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_send_align;
            
            st_link_ready:
                if (rx_signaldetect_resync & (&rx_syncstatus_resync))
                    state <= st_link_ready;
                else
                    state <= st_idle;
            
            default:
                state <= st_idle;
        endcase
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)          // Активный уровень сигнала сброса
    )
    rx_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (rx_clk),       // i
        
        // Входной сброс (асинхронный 
        // относительно сигнала тактирования)
        .areset         (gxb_reset),    // i
        
        // Выходной сброс (синхронный 
        // относительно сигнала тактирования)
        .sreset         (rx_reset)      // o
    ); // rx_reset_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)          // Активный уровень сигнала сброса
    )
    tx_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (tx_clk),       // i
        
        // Входной сброс (асинхронный 
        // относительно сигнала тактирования)
        .areset         (gxb_reset),    // i
        
        // Выходной сброс (синхронный 
        // относительно сигнала тактирования)
        .sreset         (tx_reset)      // o
    ); // tx_reset_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (42),           // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ({42{1'b0}})    // Значение по умолчанию для ступеней цепи синхронизации
    )
    rx2ref_ff_synchronizer
    (
        // Сброс и тактирование
        .reset          (gxb_reset),    // i
        .clk            (gxb_refclk),   // i
        
        // Асинхронный входной сигнал
        .async_data     ({              // i  [WIDTH - 1 : 0]
                            rx_signaldetect,
                            rx_is_lockedtoref,
                            rx_syncstatus,
                            rx_datak_align,
                            rx_data_align
                        }),
        
        // Синхронный выходной сигнал
        .sync_data      ({              // o  [WIDTH - 1 : 0]
                            rx_signaldetect_resync,
                            rx_is_lockedtoref_resync,
                            rx_syncstatus_resync,
                            rx_datak_resync,
                            rx_data_resync
                        })
    ); // rx2ref_ff_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (4),            // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ({2{1'b0}})     // Значение по умолчанию для ступеней цепи синхронизации
    )
    ref2tx_ff_synchronizer
    (
        // Сброс и тактирование
        .reset          (tx_reset),     // i
        .clk            (tx_clk),       // i
        
        // Асинхронный входной сигнал
        .async_data     ({              // i  [WIDTH - 1 : 0]
                            tx_select,
                            link_ready,
                            sata_gen_reg & {2{link_ready}}
                        }),
        
        // Синхронный выходной сигнал
        .sync_data      ({              // o  [WIDTH - 1 : 0]
                            tx_select_resync,
                            link_ready_resync,
                            sata_gen
                        })
    ); // ref2tx_ff_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации интерфейса DataStream между двумя доменами
    //      тактирования на основе механизма взаимного подтверждения
    ds_hs_synchronizer
    #(
        .WIDTH      (2),                        // Разрядность потока
        .ESTAGES    (1),                        // Количество дополнительных ступеней цепи синхронизации
        .HSTYPE     (2)                         // Схема взаимного подтверждения (2 - с двумя фазами 4 - с четырьмя фазами)
    )
    reconfig_synchronizer
    (
        // Сброс и тактирование входного потокового интерфейса
        .i_reset    (gxb_reset),                // i
        .i_clk      (gxb_refclk),               // i
        
        // Входной потоковый интерфейс
        .i_dat      (recfg_sata_gen_reg),       // i  [WIDTH - 1 : 0]
        .i_val      (recfg_request),            // i
        .i_rdy      (recfg_ready),              // o
        
        // Сброс и тактирование выходного потокового интерфейса
        .o_reset    (reconfig_reset),           // i
        .o_clk      (reconfig_clk),             // i
        
        // Выходной потоковый интерфейс
        .o_dat      (recfg_sata_gen_resync),    // o  [WIDTH - 1 : 0]
        .o_val      (recfg_request_resync),     // o
        .o_rdy      (recfg_ready_resync)        // i
    ); // reconfig_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Кодер OOB-последовательностей Serial ATA
    sata_oob_coder
    the_sata_oob_coder
    (
        // Сброс и тактирование
        .reset          (gxb_reset),            // i
        .clk            (gxb_refclk),           // i
        
        // Индикатор готовности к приему команды
        .ready          (tx_obb_ready),         // o
        
        // Окончание фазы генерации последовательностей
        .oobfinish      (tx_oobfinish),         // i
        
        // Команды генерируемых  последовательностей
        .cominit        (tx_cominit),           // i
        .comwake        (tx_comwake),           // i
        
        // Управление переводом передатчика в неактивное состояние
        .txelecidle     (tx_elecidle)           // o
    ); // the_sata_oob_coder
    
    //------------------------------------------------------------------------------------
    //      Декодер OOB-последовательностей Serial ATA
    sata_oob_decoder
    the_sata_oob_decoder
    (
        // Сброс и тактирование
        .reset          (gxb_reset),        // i
        .clk            (gxb_refclk),       // i
        
        // Индикатор активности на линии приема
        .rxsignaldetect (rx_signaldetect),  // i
        
        // Импульсы обнаруженных последовательностей
        .cominit        (rx_cominit),       // o
        .comwake        (rx_comwake),       // o
        
        // Признак окончания фазы отправки последовательностей
        .oobfinish      (rx_oobfinish)      // o
    ); // the_sata_oob_decoder
    
    //------------------------------------------------------------------------------------
    //      Модуль выравнивания порядка следования байт, приходящих от PCS-уровня
    //      высокоскоростного трансивера
    pcs_byte_aligner
    #(
        .BYTES      (4)                 // Количество байт (BYTES > 1)
    )
    sata_pcs_byte_aligner
    (
        // Сброс и тактирование
        .reset      (rx_reset),         // i
        .clk        (rx_clk),           // i
        
        // Входной интерфейс
        .i_data     (rx_data_unalign),  // i  [8 * BYTES - 1 : 0]
        .i_datak    (rx_datak_unalign), // i  [BYTES - 1 : 0]
        .i_patdet   (rx_patterndetect), // i  [BYTES - 1 : 0]
        
        // Выходной интерфейс
        .o_data     (rx_data_align),    // o  [8 * BYTES - 1 : 0]
        .o_datak    (rx_datak_align)    // o  [BYTES - 1 : 0]
    ); // sata_pcs_byte_aligner
    
    //------------------------------------------------------------------------------------
    //      Модуль компенсации разности между восстановленной и опорной частотами
    //      PCS-уровня
    pcs_rate_match_fifo
    #(
        .BYTES          (4),                // Количество байт
        .DPATTERN       (`ALIGN_PRIM),      // Шаблон удаляемых/вставляемых данных
        .KPATTERN       (`DWORD_IS_PRIM),   // Шаблон удаляемых/вставляемых признаков контрольных символов
        .FIFOLEN        (FIFOLEN),          // Длина FIFO
        .MAXUSED        (MAXUSED),          // Максимальное количество слов в FIFO
        .MINUSED        (MINUSED),          // Минимальное количество слов в FIFO
        .RAMTYPE        ("AUTO")            // Тип блоков встроенной памяти ("MLAB" "M20K" ...)
    )
    the_pcs_rate_match_fifo
    (
        // Общий асинхронный сброс
        .reset          (reset_rmfifo_reg), // i
        
        // Восстановленная частота тактирования
        .rcv_clk        (rx_clk),           // i
        
        // Опорная частота тактирования
        .ref_clk        (tx_clk),           // i
        
        // Входной поток данных на восстановленной частоте
        .rcv_data       (rx_data_align),    // i  [8 * BYTES - 1 : 0]
        .rcv_datak      (rx_datak_align),   // i  [BYTES - 1 : 0]
        
        // Выходной поток данных на опорной частоте
        .ref_data       (rx_data),          // o  [8 * BYTES - 1 : 0]
        .ref_datak      (rx_datak),         // o  [BYTES - 1 : 0]
        
        // Статусные сигналы на восстановленной частоте
        .stat_rcv_del   (  ),               // o
        .stat_rcv_ovfl  (  ),               // o
        
        // Статусные сигналы на опорной частоте
        .stat_ref_ins   (  ),               // o
        .stat_ref_unfl  (  )                // o
    ); // the_pcs_rate_match_fifo
    
    //------------------------------------------------------------------------------------
    //      Генерация высокоскоростного приемопередатчика для конкретного семейства
    generate
        if (FPGAFAMILY == "Arria 10") begin: arria10_xcvr
            //------------------------------------------------------------------------------------
            //      Модуль высокоскоростного приемопередатчика Arria10, настроенного для
            //      работы с интерфейсом SerialATA
            a10_sata_xcvr
            #(
                .PLLTYPE            ("fPLL")                        // Тип используемой PLL ("fPLL" | "CMUPLL" | "ATXPLL")
            )
            the_a10_sata_xcvr
            (
                // Сброс и тактирование интерфейса реконфигурации
                .reconfig_reset     (reconfig_reset),               // i
                .reconfig_clk       (reconfig_clk),                 // i
                
                // Сброс и тактирование высокоскоростных приемопередатчиков
                .gxb_reset          (gxb_reset),                    // i
                .gxb_refclk         (gxb_refclk),                   // i
                
                // Интерфейсные сигналы приемника
                .rx_clock           (rx_clk),                       // o
                .rx_data            (rx_data_unalign),              // o  [31 : 0]
                .rx_datak           (rx_datak_unalign),             // o  [3 : 0]
                .rx_is_lockedtodata (rx_is_lockedtodata),           // o
                .rx_is_lockedtoref  (rx_is_lockedtoref),            // o
                .rx_patterndetect   (rx_patterndetect),             // o  [3 : 0]
                .rx_signaldetect    (rx_signaldetect),              // o
                .rx_syncstatus      (rx_syncstatus),                // o  [3 : 0]
                
                // Интерфейсные сигналы передатчика
                .tx_clock           (tx_clk),                       // o
                .tx_data            (tx_data_reg),                  // i  [31 : 0]
                .tx_datak           ({{3{1'b0}}, tx_datak_reg}),    // i  [3 : 0]
                .tx_elecidle        (tx_elecidle),                  // i
                
                // Высокоскоростные линии
                .gxb_rx             (gxb_rx),                       // i
                .gxb_tx             (gxb_tx)                        // o
            ); // the_a10_sata_xcvr
        end
        else begin: arriav_xcvr
            //------------------------------------------------------------------------------------
            //      Модуль высокоскоростного приемопередатчика ArriaV, настроенного для
            //      работы с интерфейсом SerialATA
            av_sata_xcvr
            the_av_sata_xcvr
            (
                // Сброс и тактирование интерфейса реконфигурации
                .reconfig_reset     (reconfig_reset),               // i
                .reconfig_clk       (reconfig_clk),                 // i
                
                // Сброс и тактирование высокоскоростных приемопередатчиков
                .gxb_reset          (gxb_reset),                    // i
                .gxb_refclk         (gxb_refclk),                   // i
                
                // Интерфейс реконфигурации между поколениями SATA
                // (домен reconfig_clk)
                .recfg_request      (recfg_request_resync),         // i
                .recfg_sata_gen     (recfg_sata_gen_resync),        // i  [1 : 0]
                .recfg_ready        (recfg_ready_resync),           // o
                
                // Интерфейсные сигналы приемника
                .rx_clock           (rx_clk),                       // o
                .rx_data            (rx_data_unalign),              // o  [31 : 0]
                .rx_datak           (rx_datak_unalign),             // o  [3 : 0]
                .rx_is_lockedtodata (rx_is_lockedtodata),           // o
                .rx_is_lockedtoref  (rx_is_lockedtoref),            // o
                .rx_patterndetect   (rx_patterndetect),             // o  [3 : 0]
                .rx_signaldetect    (rx_signaldetect),              // o
                .rx_syncstatus      (rx_syncstatus),                // o  [3 : 0]
                
                // Интерфейсные сигналы передатчика
                .tx_clock           (tx_clk),                       // o
                .tx_data            (tx_data_reg),                  // i  [31 : 0]
                .tx_datak           ({{3{1'b0}}, tx_datak_reg}),    // i  [3 : 0]
                .tx_elecidle        (tx_elecidle),                  // i
                
                // Высокоскоростные линии
                .gxb_rx             (gxb_rx),                       // i
                .gxb_tx             (gxb_tx)                        // o
            ); // the_av_sata_xcvr
        end
    endgenerate
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов таймаута для прерывания операции
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            timeout_cnt <= '0;
        else if (timeout_inc)
            timeout_cnt <= timeout_cnt + 1'b1;
        else
            timeout_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов между примитивами выравнивания
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            align_cnt <= '0;
        else if (link_ready_resync)
            align_cnt <= align_cnt + 1'b1;
        else
            align_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Регист управления вставкой примитивов выравнивания
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            align_reg <= '0;
        else
            align_reg <= link_ready_resync & ((align_cnt == 0) | (align_cnt == 1));
    
    //------------------------------------------------------------------------------------
    //      Регист данных для передачи
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            tx_data_reg <= '0;
        else if (tx_select_resync)
            tx_data_reg <= `DIAL_DATA;
        else if (link_ready_resync & ~align_reg)
            tx_data_reg <= tx_data;
        else
            tx_data_reg <= `ALIGN_PRIM;
    
    //------------------------------------------------------------------------------------
    //      Регистр признаков контрольных символов для передачи
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            tx_datak_reg <= '0;
        else if (tx_select_resync)
            tx_datak_reg <= `DWORD_IS_DATA;
        else if (link_ready_resync & ~align_reg)
            tx_datak_reg <= tx_datak;
        else
            tx_datak_reg <= `DWORD_IS_PRIM;
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов установленного соединения
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            linkup_cnt <= '0;
        else if (link_ready_resync)
            linkup_cnt <= linkup_cnt + (linkup_cnt != (FIFOLEN - 1));
        else
            linkup_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака установки соединения
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            linkup_reg <= '0;
        else
            linkup_reg <= link_ready_resync & (linkup_cnt == (FIFOLEN - 1));
    
    //------------------------------------------------------------------------------------
    //      Регистр сброса Rate-Match FIFO
    initial reset_rmfifo_reg = '1;
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            reset_rmfifo_reg <= '1;
        else
            reset_rmfifo_reg <= ~link_ready_resync;
    
    //------------------------------------------------------------------------------------
    //      Регист текущей конфигурации SATA
    initial sata_gen_reg = `SATA_GEN3;
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            sata_gen_reg <= `SATA_GEN3;
        else if (recfg_request & recfg_ready)
            if (sata_gen_reg == `SATA_GEN1)
                sata_gen_reg <= `SATA_GEN3;
            else
                sata_gen_reg <= sata_gen_reg - 1'b1;
        else
            sata_gen_reg <= sata_gen_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр следующей конфигурации SATA
    initial recfg_sata_gen_reg = `SATA_GEN2;
    always @(posedge gxb_reset, posedge gxb_refclk)
        if (gxb_reset)
            recfg_sata_gen_reg <= `SATA_GEN2;
        else if (recfg_request & recfg_ready)
            if (recfg_sata_gen_reg == `SATA_GEN1)
                recfg_sata_gen_reg <= `SATA_GEN3;
            else
                recfg_sata_gen_reg <= recfg_sata_gen_reg - 1'b1;
        else
            recfg_sata_gen_reg <= recfg_sata_gen_reg;
    
    //------------------------------------------------------------------------------------
    //      Признак готовности интерфейса передатчика (не готов во время передачи
    //      примитивов выравнивания)
    assign tx_ready = ~align_reg;
    
    //------------------------------------------------------------------------------------
    //      Выходное тактирование интерфейса приемника и передатчика
    assign link_clk = tx_clk;
    
    //------------------------------------------------------------------------------------
    //      Индикатор установки соединения
    assign linkup = linkup_reg;
    
endmodule: sata_phy_layer