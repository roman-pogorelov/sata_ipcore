/*
    //------------------------------------------------------------------------------------
    //      DMA-движок доступа к устройствам интерфейса SATA
    sata_dma_engine
    the_sata_dma_engine
    (
        // Общий асинхронный сброс
        .reset                      (), // i
        
        // Тактирование домена пользователя
        .usr_clk                    (), // i
        
        // Тактирование домена Link-уровня SATA
        .sata_clk                   (), // i
        
        // Интерфейс команд пользователя (домен usr_clk)
        .usr_cmd_valid              (), // i
        .usr_cmd_type               (), // i
        .usr_cmd_address            (), // i  [47 : 0]
        .usr_cmd_size               (), // i  [47 : 0]
        .usr_cmd_ready              (), // o
        .usr_cmd_fault              (), // o
        
        // Интерфейс информационных сигналов пользователя (домен usr_clk)
        .usr_info_valid             (), // o
        .usr_info_max_lba_address   (), // o  [47 : 0]
        .usr_info_sata_supported    (), // o  [2 : 0]
        
        // Потоковый интерфейс записи (домен usr_clk)
        .usr_wr_dat                 (), // i  [31 : 0]
        .usr_wr_val                 (), // i
        .usr_wr_rdy                 (), // o
        
        // Потоковый интерфейс чтения (домен usr_clk)
        .usr_rd_dat                 (), // o  [31 : 0]
        .usr_rd_val                 (), // o
        .usr_rd_eop                 (), // o
        .usr_rd_err                 (), // o
        .usr_rd_rdy                 (), // i
        
        // Потоковый интерфейс передаваемых фреймов SATA (домен sata_clk)
        .sata_tx_dat                (), // o  [31 : 0]
        .sata_tx_val                (), // o
        .sata_tx_eop                (), // o
        .sata_tx_rdy                (), // i
        
        // Потоковый интерфейс принимаемых фреймов SATA (домен sata_clk)
        .sata_rx_dat                (), // i  [31 : 0]
        .sata_rx_val                (), // i
        .sata_rx_eop                (), // i
        .sata_rx_err                (), // i
        .sata_rx_rdy                (), // o
        
        // Интерфейс состояния Link-уровня SATA (домен sata_clk)
        .sata_link_busy             (), // i
        .sata_link_result           ()  // i  [2 : 0]
    ); // the_sata_dma_engine
*/

`include "sata_defs.svh"

module sata_dma_engine
(
    // Общий асинхронный сброс
    input  logic            reset,
    
    // Тактирование домена пользователя
    input  logic            usr_clk,
    
    // Тактирование домена Link-уровня SATA
    input  logic            sata_clk,
    
    // Интерфейс команд пользователя (домен usr_clk)
    input  logic            usr_cmd_valid,
    input  logic            usr_cmd_type,
    input  logic [47 : 0]   usr_cmd_address,
    input  logic [47 : 0]   usr_cmd_size,
    output logic            usr_cmd_ready,
    output logic            usr_cmd_fault,
    
    // Интерфейс информационных сигналов пользователя (домен usr_clk)
    output logic            usr_info_valid,
    output logic [47 : 0]   usr_info_max_lba_address,
    output logic [2 : 0]    usr_info_sata_supported,
    
    // Потоковый интерфейс записи (домен usr_clk)
    input  logic [31 : 0]   usr_wr_dat,
    input  logic            usr_wr_val,
    output logic            usr_wr_rdy,
    
    // Потоковый интерфейс чтения (домен usr_clk)
    output logic [31 : 0]   usr_rd_dat,
    output logic            usr_rd_val,
    output logic            usr_rd_eop,
    output logic            usr_rd_err,
    input  logic            usr_rd_rdy,
    
    // Потоковый интерфейс передаваемых фреймов SATA (домен sata_clk)
    output logic [31 : 0]   sata_tx_dat,
    output logic            sata_tx_val,
    output logic            sata_tx_eop,
    input  logic            sata_tx_rdy,
    
    // Потоковый интерфейс принимаемых фреймов SATA (домен sata_clk)
    input  logic [31 : 0]   sata_rx_dat,
    input  logic            sata_rx_val,
    input  logic            sata_rx_eop,
    input  logic            sata_rx_err,
    output logic            sata_rx_rdy,
    
    // Интерфейс состояния Link-уровня SATA (домен sata_clk)
    input  logic            sata_link_busy,
    input  logic [2 : 0]    sata_link_result
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam int unsigned     BUFFER_DEPTH = 16;
    //
    localparam logic [1 : 0]    H2D_ID       = 2'h0;
    localparam logic [1 : 0]    H2D_RD       = 2'h1;
    localparam logic [1 : 0]    H2D_WR       = 2'h2;
    //
    localparam logic            RX_DMA_DATA  = 1'b0;
    localparam logic            RX_ID_DATA   = 1'b1;
    //
    localparam logic            RD_TYPE_CODE = 1'b0;
    localparam logic            WR_TYPE_CODE = 1'b1;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                   usr_reset;
    //
    logic                   link_busy;
    logic [2 : 0]           link_result;
    logic                   link_done;
    //
    logic                   rx_select;
    //
    logic [1 : 0]           h2d_select;
    logic [7 : 0]           h2d_dat_command;
    logic [47 : 0]          h2d_dat_address;
    logic [15 : 0]          h2d_dat_scount;
    logic                   h2d_valid;
    logic                   h2d_ready;
    //
    logic [31 : 0]          tx_dat;
    logic                   tx_val;
    logic                   tx_eop;
    logic                   tx_rdy;
    //
    logic [31 : 0]          rx_dat;
    logic                   rx_val;
    logic                   rx_eop;
    logic                   rx_err;
    logic                   rx_rdy;
    //
    logic [31 : 0]          reg_fis_tx_dat;
    logic                   reg_fis_tx_val;
    logic                   reg_fis_tx_eop;
    logic                   reg_fis_tx_rdy;
    //
    logic [31 : 0]          data_fis_tx_dat;
    logic                   data_fis_tx_val;
    logic                   data_fis_tx_eop;
    logic                   data_fis_tx_rdy;
    //
    logic [31 : 0]          reg_fis_rx_dat;
    logic                   reg_fis_rx_val;
    logic                   reg_fis_rx_eop;
    logic                   reg_fis_rx_err;
    logic                   reg_fis_rx_rdy;
    //
    logic [31 : 0]          dma_act_fis_rx_dat;
    logic                   dma_act_fis_rx_val;
    logic                   dma_act_fis_rx_eop;
    logic                   dma_act_fis_rx_err;
    logic                   dma_act_fis_rx_rdy;
    //
    logic [31 : 0]          data_fis_rx_dat;
    logic                   data_fis_rx_val;
    logic                   data_fis_rx_eop;
    logic                   data_fis_rx_err;
    logic                   data_fis_rx_rdy;
    //
    logic [31 : 0]          id_fis_rx_dat;
    logic                   id_fis_rx_val;
    logic                   id_fis_rx_eop;
    logic                   id_fis_rx_err;
    logic                   id_fis_rx_rdy;
    //
    logic                   reg_fis_rcvd_reg;
    logic                   data_fis_rcvd_reg;
    logic                   dma_act_fis_rcvd_reg;
    //
    logic                   cmd_ready;
    logic                   cmd_ready_reg;
    logic                   cmd_fault;
    logic                   cmd_fault_reg;
    //
    logic                   tx_shaper_valid;
    logic                   tx_shaper_ready;
    logic [10 : 0]          tx_shaper_count;
    logic                   tx_shaper_1st_run_reg;
    //
    logic                   type_reg;
    logic [47 : 0]          address_cnt;
    logic [48 : 0]          max_address_reg;
    logic                   zero_size_reg;
    //
    logic                   trans_complete;
    logic [31 : 0]          amount_cnt;
    logic [16 : 0]          scount_reg;
    
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
        .areset         (reset),        // i
        
        // Выходной сброс (синхронный 
        // относительно сигнала тактирования)
        .sreset         (usr_reset)     // o
    ); // usr_reset_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (4),            // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    ({4{1'b0}})     // Значение по умолчанию для ступеней цепи синхронизации
    )
    link_state_synchronizer
    (
        // Сброс и тактирование
        .reset          (usr_reset),    // i
        .clk            (usr_clk),      // i
        
        // Асинхронный входной сигнал
        .async_data     ({
                            sata_link_busy,
                            sata_link_result
                        }),             // i  [WIDTH - 1 : 0]
        
        // Синхронный выходной сигнал
        .sync_data      ({
                            link_busy,
                            link_result
                        })              // o  [WIDTH - 1 : 0]
    ); // link_state_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Буфер синхронизации потоковых интерфейсов фреймов SATA между 
    //      двумя доменами тактирования
    sata_fis_resynchronizer
    #(
        .DWIDTH     (33),           // Разрядность потока
        .DEPTH      (BUFFER_DEPTH), // Глубина FIFO
        .RAMTYPE    ("AUTO")        // Тип блоков встроенной памяти ("MLAB", "M20K", ...)
    )
    tx_resync_buffer
    (
        // Сброс и тактирование
        .reset      (usr_reset),    // i
        .wr_clk     (usr_clk),      // i
        .rd_clk     (sata_clk),     // i
        
        // Входной потоковый интерфейс
        .wr_dat     ({
                        tx_dat,
                        tx_eop
                    }),             // i  [DWIDTH - 1 : 0]
        .wr_val     (tx_val),       // i
        .wr_rdy     (tx_rdy),       // o
        
        // Выходной потоковый интерфейс
        .rd_dat     ({
                        sata_tx_dat,
                        sata_tx_eop
                    }),             // o  [DWIDTH - 1 : 0]
        .rd_val     (sata_tx_val),  // o
        .rd_rdy     (sata_tx_rdy)   // i
    ); // tx_resync_buffer
    
    //------------------------------------------------------------------------------------
    //      Буфер синхронизации потоковых интерфейсов фреймов SATA между 
    //      двумя доменами тактирования
    sata_fis_resynchronizer
    #(
        .DWIDTH     (34),           // Разрядность потока
        .DEPTH      (BUFFER_DEPTH), // Глубина FIFO
        .RAMTYPE    ("AUTO")        // Тип блоков встроенной памяти ("MLAB", "M20K", ...)
    )
    rx_resync_buffer
    (
        // Сброс и тактирование
        .reset      (usr_reset),    // i
        .wr_clk     (sata_clk),     // i
        .rd_clk     (usr_clk),      // i
        
        // Входной потоковый интерфейс
        .wr_dat     ({
                        sata_rx_dat,
                        sata_rx_eop,
                        sata_rx_err
                    }),             // i  [DWIDTH - 1 : 0]
        .wr_val     (sata_rx_val),  // i
        .wr_rdy     (sata_rx_rdy),  // o
        
        // Выходной потоковый интерфейс
        .rd_dat     ({
                        rx_dat,
                        rx_eop,
                        rx_err
                    }),             // o  [DWIDTH - 1 : 0]
        .rd_val     (rx_val),       // o
        .rd_rdy     (rx_rdy)        // i
    ); // rx_resync_buffer
    
    //------------------------------------------------------------------------------------
    //      Модуль формирования фреймов данных SATA из потока данных
    sata_fis_data_shaper
    sata_tx_fis_data_shaper
    (
        // Сброс и тактирование
        .reset      (usr_reset),            // i
        .clk        (usr_clk),              // i
        
        // Интерфейс управления
        .ctl_valid  (tx_shaper_valid),      // i
        .ctl_count  (tx_shaper_count),      // i  [10 : 0]
        .ctl_ready  (tx_shaper_ready),      // o
        
        // Входной потоковый интерфейс
        .i_dat      (usr_wr_dat),           // i  [31 : 0]
        .i_val      (usr_wr_val),           // i
        .i_rdy      (usr_wr_rdy),           // o
        
        // Выходной потоковый интерфейс
        .o_dat      (data_fis_tx_dat),      // o  [31 : 0]
        .o_val      (data_fis_tx_val),      // o
        .o_eop      (data_fis_tx_eop),      // o
        .o_rdy      (data_fis_tx_rdy)       // i
    ); // sata_tx_fis_data_shaper
    
    //------------------------------------------------------------------------------------
    //      Арбитр потоковых интерфейсов фреймов SATA с приоритетом младшего
    sata_fis_arbiter
    the_sata_fis_arbiter
    (
        // Сброс и тактирование
        .reset      (usr_reset),        // i
        .clk        (usr_clk),          // i
        
        // Входной потоковый интерфейс #1 фреймов SATA
        .i1_dat     (reg_fis_tx_dat),   // i  [31 : 0]
        .i1_val     (reg_fis_tx_val),   // i
        .i1_eop     (reg_fis_tx_eop),   // i
        .i1_rdy     (reg_fis_tx_rdy),   // o
        
        // Входной потоковый интерфейс #2 фреймов SATA
        .i2_dat     (data_fis_tx_dat),  // i  [31 : 0]
        .i2_val     (data_fis_tx_val),  // i
        .i2_eop     (data_fis_tx_eop),  // i
        .i2_rdy     (data_fis_tx_rdy),  // o
        
        // Выходной потоковый интерфейс фреймов SATA
        .o_dat      (tx_dat),           // o  [31 : 0]
        .o_val      (tx_val),           // o
        .o_eop      (tx_eop),           // o
        .o_rdy      (tx_rdy)            // i
    ); // the_sata_fis_arbiter
    
    //------------------------------------------------------------------------------------
    //      Маршрутизатор принимаемых SATA фреймов
    sata_fis_router
    rx_fis_router
    (
        // Сброс и тактирование
        .reset          (usr_reset),            // i
        .clk            (usr_clk),              // i
        
        // Входной потоковый интерфейс принимаемых фреймов
        .rx_dat         (rx_dat),               // i  [31 : 0]
        .rx_val         (rx_val),               // i
        .rx_eop         (rx_eop),               // i
        .rx_err         (rx_err),               // i
        .rx_rdy         (rx_rdy),               // o
        
        // Выходной потоковый интерфейс фреймов 
        // Register D->H и PIO Setup D->H
        .reg_pio_dat    (reg_fis_rx_dat),       // o  [31 : 0]
        .reg_pio_val    (reg_fis_rx_val),       // o
        .reg_pio_eop    (reg_fis_rx_eop),       // o
        .reg_pio_err    (reg_fis_rx_err),       // o
        .reg_pio_rdy    (reg_fis_rx_rdy),       // i
        
        // Выходной потоковый интерфейс фреймов
        // DMA Activate D->H
        .dma_act_dat    (dma_act_fis_rx_dat),   // o  [31 : 0]
        .dma_act_val    (dma_act_fis_rx_val),   // o
        .dma_act_eop    (dma_act_fis_rx_eop),   // o
        .dma_act_err    (dma_act_fis_rx_err),   // o
        .dma_act_rdy    (dma_act_fis_rx_rdy),   // i
        
        // Выходной потоковый интерфейс фреймов
        // данных D->H (с удаленными заголовками)
        .data_dat       (data_fis_rx_dat),      // o  [31 : 0]
        .data_val       (data_fis_rx_val),      // o
        .data_eop       (data_fis_rx_eop),      // o
        .data_err       (data_fis_rx_err),      // o
        .data_rdy       (data_fis_rx_rdy),      // i
        
        // Выходной потоковый интерфейс фреймов
        // остальных типов
        .default_dat    (    ),                 // o  [31 : 0]
        .default_val    (    ),                 // o
        .default_eop    (    ),                 // o
        .default_err    (    ),                 // o
        .default_rdy    (1'b1)                  // i
    ); // rx_fis_router
    assign dma_act_fis_rx_rdy = 1'b1;
    
    //------------------------------------------------------------------------------------
    //      Модуль демультиплексирования потоковых интерфейсов фреймов SATA
    sata_fis_demux
    rx_fis_demux
    (
        // Сброс и тактирование
        .reset      (usr_reset),            // i
        .clk        (usr_clk),              // i
        
        // Выбор выходного интерфейса
        .select     (rx_select),            // i
        
        // Входной потоковый интерфейс фреймов SATA
        .i_dat      (data_fis_rx_dat),      // i  [31 : 0]
        .i_val      (data_fis_rx_val),      // i
        .i_eop      (data_fis_rx_eop),      // i
        .i_err      (data_fis_rx_err),      // i
        .i_rdy      (data_fis_rx_rdy),      // o
        
        // Выходной потоковый интерфейс #1 фреймов SATA
        .o1_dat     (usr_rd_dat),           // o  [31 : 0]
        .o1_val     (usr_rd_val),           // o
        .o1_eop     (usr_rd_eop),           // o
        .o1_err     (usr_rd_err),           // o
        .o1_rdy     (usr_rd_rdy),           // i
        
        // Выходной потоковый интерфейс #2 фреймов SATA
        .o2_dat     (id_fis_rx_dat),        // o  [31 : 0]
        .o2_val     (id_fis_rx_val),        // o
        .o2_eop     (id_fis_rx_eop),        // o
        .o2_err     (id_fis_rx_err),        // o
        .o2_rdy     (id_fis_rx_rdy)         // i
    ); // rx_fis_demux
    
    //------------------------------------------------------------------------------------
    //      Модуль отправки фреймов SATA Register FIS
    sata_reg_fis_sender
    the_sata_reg_fis_sender
    (
        // Сброс и тактирование
        .reset          (usr_reset),            // i
        .clk            (usr_clk),              // i
        
        // Входной параллельный интерфейс передаваемого фрейма
        .i_dat_type     (`REG_FIS_H2D),         // i  [7 : 0]
        .i_dat_command  (h2d_dat_command),      // i  [7 : 0]
        .i_dat_address  (h2d_dat_address),      // i  [47 : 0]
        .i_dat_scount   (h2d_dat_scount),       // i  [15 : 0]
        .i_val          (h2d_valid),            // i
        .i_rdy          (h2d_ready),            // o
        
        // Выходной последовательный интерфейс передаваемого фрейма
        .o_dat          (reg_fis_tx_dat),       // o  [31 : 0]
        .o_val          (reg_fis_tx_val),       // o
        .o_eop          (reg_fis_tx_eop),       // o
        .o_rdy          (reg_fis_tx_rdy)        // i
    ); // the_sata_reg_fis_sender
    
    //------------------------------------------------------------------------------------
    //      Модуль приема фреймов SATA Register FIS, Setup PIO FIS
    sata_reg_fis_receiver
    the_sata_reg_fis_receiver
    (
        // Сброс и тактирование
        .reset          (usr_reset),        // i
        .clk            (usr_clk),          // i
        
        // Входной последовательный интерфейс принимаемого фрейма
        .i_dat          (reg_fis_rx_dat),   // i  [31 : 0]
        .i_val          (reg_fis_rx_val),   // i
        .i_eop          (reg_fis_rx_eop),   // i
        .i_err          (reg_fis_rx_err),   // i
        .i_rdy          (reg_fis_rx_rdy),   // o
        
        // Выходной параллельный интерфейс принятого фрейма
        .o_dat_type     (  ),               // o  [7 : 0]
        .o_dat_status   (  ),               // o  [7 : 0]
        .o_dat_error    (  ),               // o  [7 : 0]
        .o_dat_address  (  ),               // o  [47 : 0]
        .o_dat_scount   (  ),               // o  [15 : 0]
        .o_dat_tcount   (  ),               // o  [15 : 0]
        .o_dat_badcrc   (  ),               // o
        .o_val          (  )                // o
    ); // the_sata_reg_fis_receiver
    
    //------------------------------------------------------------------------------------
    //      Модуль разбора фрейма данных с идентификационной информацией
    sata_identify_parser
    the_sata_identify_parser
    (
        // Сброс и тактирование
        .reset              (usr_reset),                    // i
        .clk                (usr_clk),                      // i
        
        // Входной последовательный интерфейс принимаемого фрейма
        .i_dat              (id_fis_rx_dat),                // i  [31 : 0]
        .i_val              (id_fis_rx_val),                // i
        .i_eop              (id_fis_rx_eop),                // i
        .i_err              (id_fis_rx_err),                // i
        .i_rdy              (id_fis_rx_rdy),                // o
        
        // Выходной параллельный интерфейс идентификационной информации
        .identify_done      (usr_info_valid),               // o
        .sata1_supported    (usr_info_sata_supported[0]),   // o
        .sata2_supported    (usr_info_sata_supported[1]),   // o
        .sata3_supported    (usr_info_sata_supported[2]),   // o
        .max_lba_address    (usr_info_max_lba_address),     // o  [47 : 0]
        .bad_checksum       (  )                            // o
    ); // the_sata_identify_parser
    
    //------------------------------------------------------------------------------------
    //      Модуль формирования одиночных импульсов индикаторов фронта входного сигнала
    edgedetector
    #(
        .INIT           (1'b0)      // Исходное значение регистра ('0 | '1)
    )
    link_busy_edgedetector
    (
        // Сброс и тактирование
        .reset          (usr_reset),
        .clk            (usr_clk),
        
        // Входной сигнал
        .i_pulse        (link_busy),
        
        // Выходные импульсы индикаторы фронтов
        .o_rise         (  ),
        .o_fall         (link_done),
        .o_either       (  )
    ); // link_busy_edgedetector
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    (* syn_encoding = "gray" *) enum int unsigned {
        st_rcv_init_d2h,
        st_wait_init_d2h,
        st_trm_id_h2d,
        st_wait_id_h2d,
        st_rcv_pio,
        st_wait_pio,
        st_rcv_id_data,
        st_wait_id_data,
        st_ready,
        st_check_params,
        st_trm_rd_h2d,
        st_wait_rd_h2d,
        st_rcv_rd_data,
        st_wait_rd_data,
        st_rd_trans_complete,
        st_trm_wr_h2d,
        st_wait_wr_h2d,
        st_wr_wait_resp,
        st_wait_dma_act,
        st_run_tx_shaper,
        st_wait_wr_d2h,
        st_wr_trans_complete,
        st_hard_fault
    } cstate, nstate;
    
    //------------------------------------------------------------------------------------
    //      Регистр текущего состояния конечного автомата и его регистровые выходы
    initial cstate = st_rcv_init_d2h;
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset) begin
            cstate <= st_rcv_init_d2h;
            cmd_ready_reg <= 1'b0;
            cmd_fault_reg <= 1'b0;
        end
        else begin
            cstate <= nstate;
            cmd_ready_reg <= cmd_ready;
            cmd_fault_reg <= cmd_fault;
        end
    
    //------------------------------------------------------------------------------------
    //      Логика формирования следующего состояния конечного автомата и его выходов
    always_comb begin
        
        // Установка значений по умолчанию
        rx_select = RX_DMA_DATA;
        h2d_select = H2D_ID;
        h2d_valid = 1'b0;
        cmd_ready = 1'b0;
        cmd_fault = cmd_fault_reg;
        tx_shaper_valid = 1'b0;
        trans_complete = 1'b0;
        
        // Выбор в зависимости от текущего состояния
        case (cstate)
            st_rcv_init_d2h: begin
                if (reg_fis_rcvd_reg)
                    // if (~link_busy)
                        // if (link_result == `LINK_RX_SUCCESS_CODE)
                            // nstate = st_trm_id_h2d;
                        // else if (link_result == `LINK_RX_FAULT_CODE)
                            // nstate = st_rcv_init_d2h;
                        // else
                            // nstate = st_hard_fault;
                    // else
                        nstate = st_wait_init_d2h;
                else
                    nstate = st_rcv_init_d2h;
            end
            
            st_wait_init_d2h: begin
                // if (~link_busy)
                    // if (link_result == `LINK_RX_SUCCESS_CODE)
                        nstate = st_trm_id_h2d;
                    // else if (link_result == `LINK_RX_FAULT_CODE)
                        // nstate = st_rcv_init_d2h;
                    // else
                        // nstate = st_hard_fault;
                // else
                    // nstate = st_wait_init_d2h;
            end
            
            st_trm_id_h2d: begin
                h2d_valid = 1'b1;
                
                if (h2d_ready)
                    nstate = st_wait_id_h2d;
                else
                    nstate = st_trm_id_h2d;
            end
            
            st_wait_id_h2d: begin
                // if (link_done)
                    // if (link_result == `LINK_TX_SUCCESS_CODE)
                        nstate = st_rcv_pio;
                    // else
                        // nstate = st_trm_id_h2d;
                // else
                    // nstate = st_wait_id_h2d;
            end
            
            st_rcv_pio: begin
                if (reg_fis_rcvd_reg)
                    // if (~link_busy)
                        // if (link_result == `LINK_RX_SUCCESS_CODE)
                            // nstate = st_rcv_id_data;
                        // else if (link_result == `LINK_RX_FAULT_CODE)
                            // nstate = st_rcv_pio;
                        // else
                            // nstate = st_hard_fault;
                    // else
                        nstate = st_wait_pio;
                else
                    nstate = st_rcv_pio;
            end
            
            st_wait_pio: begin
                // if (~link_busy)
                    // if (link_result == `LINK_RX_SUCCESS_CODE)
                        nstate = st_rcv_id_data;
                    // else if (link_result == `LINK_RX_FAULT_CODE)
                        // nstate = st_rcv_pio;
                    // else
                        // nstate = st_hard_fault;
                // else
                    // nstate = st_wait_pio;
            end
            
            st_rcv_id_data: begin
                rx_select = RX_ID_DATA;
                
                if (data_fis_rcvd_reg)
                    // if (~link_busy)
                        // if (link_result == `LINK_RX_SUCCESS_CODE) begin
                            // cmd_ready = 1'b1;
                            // nstate = st_ready;
                        // end
                        // else
                            // nstate = st_hard_fault;
                    // else
                        nstate = st_wait_id_data;
                else
                    nstate = st_rcv_id_data;
            end
            
            st_wait_id_data: begin
                // if (~link_busy)
                    // if (link_result == `LINK_RX_SUCCESS_CODE) begin
                        cmd_ready = 1'b1;
                        nstate = st_ready;
                    // end
                    // else
                        // nstate = st_hard_fault;
                // else
                    // nstate = st_wait_id_data;
            end
            
            st_ready: begin
                if (usr_cmd_valid) begin
                    cmd_fault = 1'b0;
                    nstate = st_check_params;
                end
                else begin
                    cmd_ready = 1'b1;
                    nstate = st_ready;
                end
            end
            
            st_check_params: begin
                if (($unsigned(max_address_reg) > $unsigned(usr_info_max_lba_address)) | zero_size_reg) begin
                    cmd_ready = 1'b1;
                    cmd_fault = 1'b1;
                    nstate = st_ready;
                end
                else begin
                    if (type_reg)
                        nstate = st_trm_wr_h2d;
                    else
                        nstate = st_trm_rd_h2d;
                end
            end
            
            st_trm_rd_h2d: begin
                h2d_select = H2D_RD;
                h2d_valid = 1'b1;
                
                if (h2d_ready)
                    nstate = st_wait_rd_h2d;
                else
                    nstate = st_trm_rd_h2d;
            end
            
            st_wait_rd_h2d: begin
                // if (link_done)
                    // if (link_result == `LINK_TX_SUCCESS_CODE)
                        nstate = st_rcv_rd_data;
                    // else
                        // nstate = st_trm_rd_h2d;
                // else
                    // nstate = st_wait_rd_h2d;
            end
            
            st_rcv_rd_data: begin
                if (reg_fis_rcvd_reg)
                    // if (~link_busy)
                        // if (link_result == `LINK_RX_SUCCESS_CODE)
                            // nstate = st_rd_trans_complete;
                        // else if (link_result == `LINK_RX_FAULT_CODE)
                            // nstate = st_rcv_rd_data;
                        // else
                            // nstate = st_hard_fault;
                    // else
                        nstate = st_wait_rd_data;
                else
                    nstate = st_rcv_rd_data;
            end
            
            st_wait_rd_data: begin
                // if (~link_busy)
                    // if (link_result == `LINK_RX_SUCCESS_CODE)
                        nstate = st_rd_trans_complete;
                    // else if (link_result == `LINK_RX_FAULT_CODE)
                        // nstate = st_rcv_rd_data;
                    // else
                        // nstate = st_hard_fault;
                // else
                    // nstate = st_wait_rd_data;
            end
            
            st_rd_trans_complete: begin
                trans_complete = 1'b1;
                
                if (amount_cnt == 1) begin
                    cmd_ready = 1'b1;
                    nstate = st_ready;
                end
                else
                    nstate = st_trm_rd_h2d;
            end
            
            st_trm_wr_h2d: begin
                h2d_select = H2D_WR;
                h2d_valid = 1'b1;
                
                if (h2d_ready)
                    nstate = st_wait_wr_h2d;
                else
                    nstate = st_trm_wr_h2d;
            end
            
            st_wait_wr_h2d: begin
                // if (link_done)
                    // if (link_result == `LINK_TX_SUCCESS_CODE)
                        nstate = st_wr_wait_resp;
                    // else
                        // nstate = st_trm_wr_h2d;
                // else
                    // nstate = st_wait_wr_h2d;
            end
            
            st_wr_wait_resp: begin
                if (dma_act_fis_rcvd_reg)
                    // if (~link_busy)
                        // if (link_result == `LINK_RX_SUCCESS_CODE)
                            // nstate = st_run_tx_shaper;
                        // else
                            // nstate = st_hard_fault;
                    // else
                        nstate = st_wait_dma_act;
                else if (reg_fis_rcvd_reg)
                    // if (~link_busy)
                        // if (link_result == `LINK_RX_SUCCESS_CODE)
                            // nstate = st_wr_trans_complete;
                        // else
                            // nstate = st_hard_fault;
                    // else
                        nstate = st_wait_wr_d2h;
                else
                    nstate = st_wr_wait_resp;
            end
            
            st_wait_dma_act: begin
                // if (~link_busy)
                    // if (link_result == `LINK_RX_SUCCESS_CODE)
                        nstate = st_run_tx_shaper;
                    // else
                        // nstate = st_hard_fault;
                // else
                    // nstate = st_wait_dma_act;
            end
            
            st_run_tx_shaper: begin
                tx_shaper_valid = 1'b1;
                
                if (tx_shaper_ready)
                    nstate = st_wr_wait_resp;
                else
                    nstate = st_run_tx_shaper;
            end
            
            st_wait_wr_d2h: begin
                // if (~link_busy)
                    // if (link_result == `LINK_RX_SUCCESS_CODE)
                        nstate = st_wr_trans_complete;
                    // else
                        // nstate = st_hard_fault;
                // else
                    // nstate = st_wait_wr_d2h;
            end
            
            st_wr_trans_complete: begin
                trans_complete = 1'b1;
                
                if (amount_cnt == 1) begin
                    cmd_ready = 1'b1;
                    nstate = st_ready;
                end
                else
                    nstate = st_trm_wr_h2d;
            end
            
            st_hard_fault: begin
                nstate = st_hard_fault;
            end
            
            default: begin
                nstate = st_hard_fault;
            end
        endcase
        
    end
    
    //------------------------------------------------------------------------------------
    //      Признак готовности к приему очередной команды
    assign usr_cmd_ready = cmd_ready_reg;
    
    //------------------------------------------------------------------------------------
    //      Признак невозможности выполнения команды
    assign usr_cmd_fault = cmd_fault_reg;
    
    //------------------------------------------------------------------------------------
    //      Мультиплексирование передаваемых фреймов Register H2D
    always_comb case (h2d_select)
        H2D_RD: begin
            h2d_dat_command = `READ_DMA_EXT_CMD;
            h2d_dat_address = address_cnt;
            h2d_dat_scount  = scount_reg[15 : 0];
        end
        
        H2D_WR: begin
            h2d_dat_command = `WRITE_DMA_EXT_CMD;
            h2d_dat_address = address_cnt;
            h2d_dat_scount  = scount_reg[15 : 0];
        end
        
        default: begin
            h2d_dat_command = `IDENTIFY_DEVICE_CMD;
            h2d_dat_address = {48{1'b0}};
            h2d_dat_scount  = scount_reg[15 : 0];
        end
    endcase
    
    //------------------------------------------------------------------------------------
    //      Регистр признака приема фрейма типа Reg D2H или PIO Setup
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            reg_fis_rcvd_reg <= '0;
        else
            reg_fis_rcvd_reg <= reg_fis_rx_val & reg_fis_rx_rdy & reg_fis_rx_eop;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака приема фрейма типа Data
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            data_fis_rcvd_reg <= '0;
        else
            data_fis_rcvd_reg <= data_fis_rx_val & data_fis_rx_rdy & data_fis_rx_eop;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака приема фрейма типа DMA Activate
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            dma_act_fis_rcvd_reg <= '0;
        else
            dma_act_fis_rcvd_reg <= dma_act_fis_rx_val & dma_act_fis_rx_rdy & dma_act_fis_rx_eop;
    
    //------------------------------------------------------------------------------------
    //      Регистр индикатор первого запуска модуля формирования фреймов данных SATA
    initial tx_shaper_1st_run_reg <= '1;
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            tx_shaper_1st_run_reg <= '1;
        else if (tx_shaper_1st_run_reg)
            tx_shaper_1st_run_reg <= ~(tx_shaper_valid & tx_shaper_ready);
        else
            tx_shaper_1st_run_reg <= trans_complete;
    
    //------------------------------------------------------------------------------------
    //      Количество слов в передаваемом фрейме данных SATA
    assign tx_shaper_count = {{4{tx_shaper_1st_run_reg}} & scount_reg[3 : 0], {7{1'b0}}};
    
    //------------------------------------------------------------------------------------
    //      Регистр типа операции
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            type_reg <= '0;
        else if (usr_cmd_ready)
            type_reg <= usr_cmd_type;
        else
            type_reg <= type_reg;
    
    //------------------------------------------------------------------------------------
    //      Счетчик адреса доступа
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            address_cnt <= '0;
        else if (usr_cmd_ready)
            address_cnt <= usr_cmd_address;
        else if (trans_complete)
            address_cnt <= address_cnt + scount_reg;
        else
            address_cnt <= address_cnt;
    
    //------------------------------------------------------------------------------------
    //      Регистр адреса последнего сектора доступа
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            max_address_reg <= '0;
        else if (usr_cmd_ready)
            max_address_reg <= {1'b0, usr_cmd_address} + {1'b0, usr_cmd_size};
        else
            max_address_reg <= max_address_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр признака нулевой длины доступа
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            zero_size_reg <= '0;
        else if (usr_cmd_ready)
            zero_size_reg <= (usr_cmd_size == 0);
        else
            zero_size_reg <= zero_size_reg;
    
    //------------------------------------------------------------------------------------
    //      Счетчик количества транзакций доступа
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            amount_cnt <= '0;
        else if (usr_cmd_ready)
            amount_cnt <= usr_cmd_size[47 : 16] + (usr_cmd_size[15 : 0] != 0);
        else if (trans_complete)
            amount_cnt <= amount_cnt - 1'b1;
        else
            amount_cnt <= amount_cnt;
    
    //------------------------------------------------------------------------------------
    //      Регистр размера транзакции доступа в сектора
    always @(posedge usr_reset, posedge usr_clk)
        if (usr_reset)
            scount_reg <= '0;
        else if (usr_cmd_ready)
            scount_reg <= {(usr_cmd_size[15 : 0] == 0), usr_cmd_size[15 : 0]};
        else if (trans_complete)
            scount_reg <= `MAX_DMA_BURST;
        else
            scount_reg <= scount_reg;
    
endmodule: sata_dma_engine