/*
    //------------------------------------------------------------------------------------
    //      Модуль физического уровня стека SerialATA
    sata_phy_layer
    #(
        .GENERATION         ()  // Поколение ("SATA1" | "SATA2" | "SATA3")
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
        
        // Индикатор установки соединения
        .linkup             (), // o
        
        // Интерфейс приемника
        .rx_data            (), // o  [31 : 0]
        .rx_datak           (), // o  [3 : 0]
        
        // Интерфейс передатчика
        .tx_data            (), // i  [31 : 0]
        .tx_datak           (), // i  [3 : 0]
        .tx_ready           (), // o
        
        // Высокоскоростные линии
        .gxb_rx             (), // i
        .gxb_tx             ()  // o
    ); // the_sata_phy_layer
*/

`include "sata_defs.svh"

module sata_phy_layer
#(
    parameter               GENERATION  = "SATA1"   // Поколение ("SATA1" | "SATA2" | "SATA3")
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
        
    // Индикатор установки соединения
    output logic            linkup,
    
    // Интерфейс приемника
    output logic [31 : 0]   rx_data,
    output logic [3 : 0]    rx_datak,
    
    // Интерфейс передатчика
    input  logic [31 : 0]   tx_data,
    input  logic [3 : 0]    tx_datak,
    output logic            tx_ready,
    
    // Высокоскоростные линии
    input  logic            gxb_rx,
    output logic            gxb_tx
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned         CLKFREQ = (GENERATION == "SATA1") ? 37_500 : (GENERATION == "SATA2") ? 75_000 : 150_000;
    localparam int unsigned         TIMEOUT = (880 * CLKFREQ) / 1000;
    localparam int unsigned         TCWIDTH = $clog2(TIMEOUT + 1);
    localparam int unsigned         FIFOLEN = 32;
    localparam int unsigned         MAXUSED = 24;
    localparam int unsigned         MINUSED = 8;
    
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
    logic                           tx_obb_ready;
    //
    logic                           rx_cominit;
    logic                           rx_cominit_resync;
    logic                           rx_comwake;
    logic                           rx_comwake_resync;
    logic                           rx_oobfinish;
    logic                           rx_oobfinish_resync;
    //
    logic                           link_ready;
    logic                           timeout_inc;
    logic [TCWIDTH - 1 : 0]         timeout_cnt;
    logic [7 : 0]                   align_cnt;
    logic                           align_reg;
    //
    logic [31 : 0]                  tx_data_reg;
    logic [3 : 0]                   tx_datak_reg;
    //
    logic [$clog2(FIFOLEN) - 1 : 0] linkup_cnt;
    logic                           linkup_reg;
    //
    logic                           reset_rmfifo_reg;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    enum logic [7 : 0] {
        st_idle             = 8'b00_0_0_0_0_0_0,
        st_send_comreset    = 8'b00_0_0_0_0_1_0,
        st_suspend_comreset = 8'b01_0_0_0_0_0_0,
        st_wait_cominit     = 8'b00_1_0_0_0_0_0,
        st_send_comwake     = 8'b00_0_0_0_1_0_0,
        st_suspend_comwake  = 8'b10_0_0_0_0_0_0,
        st_wait_comwake     = 8'b01_1_0_0_0_0_0,
        st_wait_oobfinish   = 8'b10_1_0_0_0_0_0,
        st_send_dial        = 8'b11_1_1_1_0_0_0,
        st_send_align       = 8'b11_1_0_1_0_0_0,
        st_link_ready       = 8'b11_0_0_1_0_0_1
    } state;
    wire [7 : 0] st;
    assign st = state;
    
    //------------------------------------------------------------------------------------
    //      Управляющие сигналы конечного автомата
    assign link_ready   = st[0];
    assign tx_cominit   = st[1];
    assign tx_comwake   = st[2];
    assign tx_oobfinish = st[3];
    assign tx_select    = st[4];
    assign timeout_inc  = st[5];
    
    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
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
                if (rx_cominit_resync)
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
                if (rx_comwake_resync)
                    state <= st_wait_oobfinish;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_wait_comwake;
                
            st_wait_oobfinish:
                if (rx_oobfinish_resync)
                    state <= st_send_dial;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_wait_oobfinish;
            
            st_send_dial:
                if ((rx_data_resync == `ALIGN_PRIM) & (rx_datak_resync == `DWORD_IS_PRIM) & (&rx_syncstatus_resync))
                    state <= st_send_align;
                else if (timeout_cnt == TIMEOUT)
                    state <= st_idle;
                else
                    state <= st_send_dial;
            
            st_send_align:
                if ((rx_data_resync == `SYNC_PRIM) & (rx_datak_resync == `DWORD_IS_PRIM))
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
        .WIDTH          (43),           // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ({43{1'b0}})    // Значение по умолчанию для ступеней цепи синхронизации
    )
    rx2tx_ff_synchronizer
    (
        // Сброс и тактирование
        .reset          (tx_reset),     // i
        .clk            (tx_clk),       // i
        
        // Асинхронный входной сигнал
        .async_data     ({              // i  [WIDTH - 1 : 0]
                            rx_signaldetect,
                            rx_is_lockedtoref,
                            rx_syncstatus,
                            rx_datak_align,
                            rx_data_align,
                            rx_oobfinish
                        }),
        
        // Синхронный выходной сигнал
        .sync_data      ({              // o  [WIDTH - 1 : 0]
                            rx_signaldetect_resync,
                            rx_is_lockedtoref_resync,
                            rx_syncstatus_resync,
                            rx_datak_resync,
                            rx_data_resync,
                            rx_oobfinish_resync
                        })
    ); // rx2tx_ff_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации передачи одиночных (длительностью 1 такт) импульсов
    //      между двумя асинхронными доменами. Работоспособность обеспечивается
    //      только для импульсов длительностью в один такт частоты источника и периодом
    //      следования не менее двух тактов частоты приемника
    single_pulse_synchronizer
    #(
        .EXTRA_STAGES   (1)                 // Количество дополнительных ступеней цепи синхронизации
    )
    rx2tx_cominit_synchronizer
    (
        // Сброс и тактирование домена источника
        .src_reset      (rx_reset),         // i
        .src_clk        (rx_clk),           // i
        
        // Сброс и тактирование домена приемника
        .dst_reset      (tx_reset),         // i
        .dst_clk        (tx_clk),           // i
        
        // Одиночный импульс домена источника
        .src_pulse      (rx_cominit),       // i
        
        // Одиночный импульс домена приемника
        .dst_pulse      (rx_cominit_resync) // o
    ); // rx2tx_cominit_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации передачи одиночных (длительностью 1 такт) импульсов
    //      между двумя асинхронными доменами. Работоспособность обеспечивается
    //      только для импульсов длительностью в один такт частоты источника и периодом
    //      следования не менее двух тактов частоты приемника
    single_pulse_synchronizer
    #(
        .EXTRA_STAGES   (1)                 // Количество дополнительных ступеней цепи синхронизации
    )
    rx2tx_comwake_synchronizer
    (
        // Сброс и тактирование домена источника
        .src_reset      (rx_reset),         // i
        .src_clk        (rx_clk),           // i
        
        // Сброс и тактирование домена приемника
        .dst_reset      (tx_reset),         // i
        .dst_clk        (tx_clk),           // i
        
        // Одиночный импульс домена источника
        .src_pulse      (rx_comwake),       // i
        
        // Одиночный импульс домена приемника
        .dst_pulse      (rx_comwake_resync) // o
    ); // rx2tx_comwake_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Кодер OOB-последовательностей Serial ATA
    sata_oob_coder
    #(
        .CLKFREQ        (CLKFREQ)               // Частота тактирования clk, кГц
    )
    the_sata_oob_coder
    (
        // Сброс и тактирование
        .reset          (tx_reset),             // i
        .clk            (tx_clk),               // i
        
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
    #(
        .CLKFREQ        (CLKFREQ)           // Частота тактирования clk, кГц
    )
    the_sata_oob_decoder
    (
        // Сброс и тактирование
        .reset          (rx_reset),         // i
        .clk            (rx_clk),           // i
        
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
    //      Модуль высокоскоростного приемопередатчика Arria10, настроенного для
    //      работы с интерфейсом SerialATA
    a10_sata_xcvr
    #(
        .PLLTYPE            ("fPLL")                // Тип используемой PLL ("fPLL" | "CMUPLL" | "ATXPLL")
    )
    the_a10_sata_xcvr
    (
        // Сброс и тактирование интерфейса реконфигурации
        .reconfig_reset     (reconfig_reset),       // i
        .reconfig_clk       (reconfig_clk),         // i
        
        // Сброс и тактирование высокоскоростных приемопередатчиков
        .gxb_reset          (gxb_reset),            // i
        .gxb_refclk         (gxb_refclk),           // i
        
        // Интерфейсные сигналы приемника
        .rx_clock           (rx_clk),               // o
        .rx_data            (rx_data_unalign),      // o  [31 : 0]
        .rx_datak           (rx_datak_unalign),     // o  [3 : 0]
        .rx_is_lockedtodata (rx_is_lockedtodata),   // o
        .rx_is_lockedtoref  (rx_is_lockedtoref),    // o
        .rx_patterndetect   (rx_patterndetect),     // o  [3 : 0]
        .rx_signaldetect    (rx_signaldetect),      // o
        .rx_syncstatus      (rx_syncstatus),        // o  [3 : 0]
        
        // Интерфейсные сигналы передатчика
        .tx_clock           (tx_clk),               // o
        .tx_data            (tx_data_reg),          // i  [31 : 0]
        .tx_datak           (tx_datak_reg),         // i  [3 : 0]
        .tx_elecidle        (tx_elecidle),          // i
        
        // Высокоскоростные линии
        .gxb_rx             (gxb_rx),               // i
        .gxb_tx             (gxb_tx)                // o
    ); // the_a10_sata_xcvr
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов таймаута для прерывания операции
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
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
        else if (link_ready)
            align_cnt <= align_cnt + 1'b1;
        else
            align_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Регист управления вставкой примитивов выравнивания
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            align_reg <= '0;
        else
            align_reg <= link_ready & ((align_cnt == 0) | (align_cnt == 1));
    
    //------------------------------------------------------------------------------------
    //      Регист данных для передачи
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            tx_data_reg <= '0;
        else if (tx_select)
            tx_data_reg <= `DIAL_DATA;
        else if (link_ready & ~align_reg)
            tx_data_reg <= tx_data;
        else
            tx_data_reg <= `ALIGN_PRIM;
    
    //------------------------------------------------------------------------------------
    //      Регистр признаков контрольных символов для передачи
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            tx_datak_reg <= '0;
        else if (tx_select)
            tx_datak_reg <= `DWORD_IS_DATA;
        else if (link_ready & ~align_reg)
            tx_datak_reg <= tx_datak;
        else
            tx_datak_reg <= `DWORD_IS_PRIM;
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов установленного соединения
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            linkup_cnt <= '0;
        else if (link_ready)
            linkup_cnt <= linkup_cnt + (linkup_cnt != (FIFOLEN - 1));
        else
            linkup_cnt <= '0;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака установки соединения
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            linkup_reg <= '0;
        else
            linkup_reg <= link_ready & (linkup_cnt == (FIFOLEN - 1));
    
    //------------------------------------------------------------------------------------
    //      Регистр сброса Rate-Match FIFO
    initial reset_rmfifo_reg = '1;
    always @(posedge tx_reset, posedge tx_clk)
        if (tx_reset)
            reset_rmfifo_reg <= '1;
        else
            reset_rmfifo_reg <= ~link_ready;
    
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