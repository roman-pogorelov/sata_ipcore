/*
    //------------------------------------------------------------------------------------
    //      Стек Serial ATA, реализующий DMA-доступ записи и чтения
    sata_dma_stack
    #(
        .FPGAFAMILY             ()  // Семейство FPGA ("Arria V" | "Stratix V" | "Arria 10")
    )
    the_sata_dma_stack
    (
        // Общий сброс
        .reset                  (), // i

        // Тактирование высокоскоростного приемопередатчика (150 МГц)
        .gxb_refclk             (), // i

        // Тактирование интерфейса реконфигурации
        .reconfig_clk           (), // i

        // Высокоскоростные линии
        .gxb_rx                 (), // i
        .gxb_tx                 (), // o

        // Тактирование Link-уровня SerialATA (37.5 МГц, 75.0 МГц, 150.0 МГц)
        .sata_clkout            (), // o

        // Тактирование интерфейса пользователя
        .usr_clk                (), // i

        // Интерфейс команд пользователя (домен usr_clk)
        .cmd_valid              (), // i
        .cmd_type               (), // i
        .cmd_address            (), // i  [47 : 0]
        .cmd_size               (), // i  [47 : 0]
        .cmd_ready              (), // o
        .cmd_fault              (), // o

        // Потоковый интерфейс записи (домен usr_clk)
        .wr_dat                 (), // i  [31 : 0]
        .wr_val                 (), // i
        .wr_rdy                 (), // o

        // Потоковый интерфейс чтения (домен usr_clk)
        .rd_dat                 (), // o  [31 : 0]
        .rd_val                 (), // o
        .rd_rdy                 (), // i

        // Сигналы статуса соединения (домен usr_clk)
        .stat_linkup            (), // o
        .stat_generation        (), // o  [1 : 0]

        // Сигналы информации об устройстве (домен usr_clk)
        .info_valid             (), // o
        .info_max_lba_address   (), // o  [47 : 0]
        .info_sata_supported    ()  // o  [2 : 0]
    ); // the_sata_dma_stack
*/

module sata_dma_stack
#(
    parameter               FPGAFAMILY  = "Arria V"     // Семейство FPGA ("Arria V" | "Stratix V" | "Arria 10")
)
(
    // Общий сброс
    input  logic            reset,

    // Тактирование высокоскоростного приемопередатчика (150 МГц)
    input  logic            gxb_refclk,

    // Тактирование интерфейса реконфигурации
    input  logic            reconfig_clk,

    // Высокоскоростные линии
    input  logic            gxb_rx,
    output logic            gxb_tx,

    // Тактирование Link-уровня SerialATA (37.5 МГц, 75.0 МГц, 150.0 МГц)
    output logic            sata_clkout,

    // Тактирование интерфейса пользователя
    input  logic            usr_clk,

    // Интерфейс команд пользователя (домен usr_clk)
    input  logic            cmd_valid,
    input  logic            cmd_type,
    input  logic [47 : 0]   cmd_address,
    input  logic [47 : 0]   cmd_size,
    output logic            cmd_ready,
    output logic            cmd_fault,

    // Потоковый интерфейс записи (домен usr_clk)
    input  logic [31 : 0]   wr_dat,
    input  logic            wr_val,
    output logic            wr_rdy,

    // Потоковый интерфейс чтения (домен usr_clk)
    output logic [31 : 0]   rd_dat,
    output logic            rd_val,
    input  logic            rd_rdy,

    // Сигналы статуса соединения (домен usr_clk)
    output logic            stat_linkup,
    output logic [1 : 0]    stat_generation,

    // Сигналы информации об устройстве (домен usr_clk)
    output logic            info_valid,
    output logic [47 : 0]   info_max_lba_address,
    output logic [2 : 0]    info_sata_supported
);
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                   sata_reset;
    logic                   usr_reset;
    //
    logic                   sata_linkup;
    logic [1 : 0]           sata_generation;
    //
    logic [31 : 0]          phy_tx_data;
    logic                   phy_tx_datak;
    logic                   phy_tx_ready;
    //
    logic [31 : 0]          phy_rx_data;
    logic                   phy_rx_datak;
    //
    logic                   link_layer_busy;
    logic [2 : 0]           link_layer_result;
    //
    logic [31 : 0]          tx_fis_dat;
    logic                   tx_fis_val;
    logic                   tx_fis_eop;
    logic                   tx_fis_rdy;
    //
    logic [31 : 0]          rx_fis_dat;
    logic                   rx_fis_val;
    logic                   rx_fis_eop;
    logic                   rx_fis_err;
    logic                   rx_fis_rdy;

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)          // Активный уровень сигнала сброса
    )
    sata_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (sata_clkout),  // i

        // Входной сброс (асинхронный
        // относительно сигнала тактирования)
        .areset         (
                            reset |
                            ~sata_linkup
                        ), // i

        // Выходной сброс (синхронный
        // относительно сигнала тактирования)
        .sreset         (sata_reset)    // o
    ); // sata_reset_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)          // Активный уровень сигнала сброса
    )
    usr_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (usr_clk),      // i

        // Входной сброс (асинхронный
        // относительно сигнала тактирования)
        .areset         (
                            reset |
                            ~sata_linkup
                        ), // i

        // Выходной сброс (синхронный
        // относительно сигнала тактирования)
        .sreset         (usr_reset)     // o
    ); // usr_reset_synchronizer

    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (3),            // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ({3{1'b0}})     // Значение по умолчанию для ступеней цепи синхронизации
    )
    sata2usr_synchronizer
    (
        // Сброс и тактирование
        .reset          (usr_reset),    // i
        .clk            (usr_clk),      // i

        // Асинхронный входной сигнал
        .async_data     ({
                            sata_generation,
                            sata_linkup
                        }), // i  [WIDTH - 1 : 0]

        // Синхронный выходной сигнал
        .sync_data      ({
                            stat_generation,
                            stat_linkup
                        })  // o  [WIDTH - 1 : 0]
    ); // sata2usr_synchronizer

    //------------------------------------------------------------------------------------
    //      DMA-движок доступа к устройствам интерфейса SATA
    sata_dma_engine
    the_sata_dma_engine
    (
        // Общий асинхронный сброс
        .reset                      (usr_reset),            // i

        // Тактирование домена пользователя
        .usr_clk                    (usr_clk),              // i

        // Тактирование домена Link-уровня SATA
        .sata_clk                   (sata_clkout),          // i

        // Интерфейс команд пользователя (домен usr_clk)
        .usr_cmd_valid              (cmd_valid),            // i
        .usr_cmd_type               (cmd_type),             // i
        .usr_cmd_address            (cmd_address),          // i  [47 : 0]
        .usr_cmd_size               (cmd_size),             // i  [47 : 0]
        .usr_cmd_ready              (cmd_ready),            // o
        .usr_cmd_fault              (cmd_fault),            // o

        // Интерфейс информационных сигналов пользователя (домен usr_clk)
        .usr_info_valid             (info_valid),           // o
        .usr_info_max_lba_address   (info_max_lba_address), // o  [47 : 0]
        .usr_info_sata_supported    (info_sata_supported),  // o  [2 : 0]

        // Потоковый интерфейс записи (домен usr_clk)
        .usr_wr_dat                 (wr_dat),               // i  [31 : 0]
        .usr_wr_val                 (wr_val),               // i
        .usr_wr_rdy                 (wr_rdy),               // o

        // Потоковый интерфейс чтения (домен usr_clk)
        .usr_rd_dat                 (rd_dat),               // o  [31 : 0]
        .usr_rd_val                 (rd_val),               // o
        .usr_rd_eop                 (  ),                   // o
        .usr_rd_err                 (  ),                   // o
        .usr_rd_rdy                 (rd_rdy),               // i

        // Потоковый интерфейс передаваемых фреймов SATA (домен sata_clk)
        .sata_tx_dat                (tx_fis_dat),           // o  [31 : 0]
        .sata_tx_val                (tx_fis_val),           // o
        .sata_tx_eop                (tx_fis_eop),           // o
        .sata_tx_rdy                (tx_fis_rdy),           // i

        // Потоковый интерфейс принимаемых фреймов SATA (домен sata_clk)
        .sata_rx_dat                (rx_fis_dat),           // i  [31 : 0]
        .sata_rx_val                (rx_fis_val),           // i
        .sata_rx_eop                (rx_fis_eop),           // i
        .sata_rx_err                (rx_fis_err),           // i
        .sata_rx_rdy                (rx_fis_rdy),           // o

        // Интерфейс состояния Link-уровня SATA (домен sata_clk)
        .sata_link_busy             (link_layer_busy),      // i
        .sata_link_result           (link_layer_result)     // i  [2 : 0]
    ); // the_sata_dma_engine

    //------------------------------------------------------------------------------------
    //      Модуль уровня соединения стека SerialATA
    sata_link_layer
    #(
        .FPGAFAMILY         (FPGAFAMILY)            // Семейство FPGA ("Arria V" | "Arria 10")
    )
    the_sata_link_layer
    (
        // Сброс и тактирование
        .reset              (sata_reset),           // i
        .clk                (sata_clkout),          // i

        // Входной потоковый интерфейс передаваемых
        // фреймов от транспортного уровня
        .tx_fis_dat         (tx_fis_dat),           // i  [31 : 0]
        .tx_fis_val         (tx_fis_val),           // i
        .tx_fis_eop         (tx_fis_eop),           // i
        .tx_fis_rdy         (tx_fis_rdy),           // o

        // Выходной потоковый интерфейс принимаемых
        // фреймов к транспортному уровню
        .rx_fis_dat         (rx_fis_dat),           // o  [31 : 0]
        .rx_fis_val         (rx_fis_val),           // o
        .rx_fis_eop         (rx_fis_eop),           // o
        .rx_fis_err         (rx_fis_err),           // o
        .rx_fis_rdy         (rx_fis_rdy),           // i

        // Интерфейс запроса статуса ошибки принятого
        // фрейма от транспортного уровня
        .trans_req          (  ),                   // o
        .trans_ack          (1'b1),                 // i
        .trans_err          (1'b0),                 // i

        // Выходной поток к физическому уровню
        .phy_tx_data        (phy_tx_data),          // o  [31 : 0]
        .phy_tx_datak       (phy_tx_datak),         // o
        .phy_tx_ready       (phy_tx_ready),         // i

        // Входной поток от физического уровня
        .phy_rx_data        (phy_rx_data),          // i  [31 : 0]
        .phy_rx_datak       (phy_rx_datak),         // i

        // Статусные сигналы
        .stat_fsm_code      (  ),                   // o  [4 : 0]
        .stat_link_busy     (link_layer_busy),      // o
        .stat_link_result   (link_layer_result),    // o  [2 : 0]
        .stat_rx_fifo_ovfl  (  )                    // o
    ); // the_sata_link_layer

    //------------------------------------------------------------------------------------
    //      Модуль физического уровня стека SerialATA
    sata_phy_layer
    #(
        .FPGAFAMILY         (FPGAFAMILY)        // Семейство FPGA ("Arria V" | "Stratix V" | "Arria 10")
    )
    the_sata_phy_layer
    (
        // Общий сброс
        .reset              (reset),            // i

        // Тактирование интерфейса реконфигурации
        .reconfig_clk       (reconfig_clk),     // i

        // Тактирование высокоскоростных приемопередатчиков
        .gxb_refclk         (gxb_refclk),       // i

        // Выходное тактирование интерфейса приемника и передатчика
        .link_clk           (sata_clkout),      // o

        // Индикатор установки соединения (домен link_clk)
        .linkup             (sata_linkup),      // o

        // Индикатор поколения SATA (домен link_clk)
        .sata_gen           (sata_generation),  // o  [1 : 0]

        // Интерфейс приемника (домен link_clk)
        .rx_data            (phy_rx_data),      // o  [31 : 0]
        .rx_datak           (phy_rx_datak),     // o

        // Интерфейс передатчика (домен link_clk)
        .tx_data            (phy_tx_data),      // i  [31 : 0]
        .tx_datak           (phy_tx_datak),     // i
        .tx_ready           (phy_tx_ready),     // o

        // Высокоскоростные линии
        .gxb_rx             (gxb_rx),           // i
        .gxb_tx             (gxb_tx)            // o
    ); // the_sata_phy_layer

endmodule: sata_dma_stack