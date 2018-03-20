/*
    //------------------------------------------------------------------------------------
    //      Модуль уровня соединения стека SerialATA
    sata_link_layer
    #(
        .FPGAFAMILY         () // Семейство FPGA ("Arria V" | "Arria 10")
    )
    the_sata_link_layer
    (
        // Сброс и тактирование
        .reset              (), // i
        .clk                (), // i
        
        // Входной потоковый интерфейс передаваемых
        // фреймов от транспортного уровня
        .tx_fis_dat         (), // i  [31 : 0]
        .tx_fis_val         (), // i
        .tx_fis_eop         (), // i
        .tx_fis_rdy         (), // o
        
        // Выходной потоковый интерфейс принимаемых
        // фреймов к транспортному уровню
        .rx_fis_dat         (), // o  [31 : 0]
        .rx_fis_val         (), // o
        .rx_fis_eop         (), // o
        .rx_fis_err         (), // o
        .rx_fis_rdy         (), // i
        
        // Интерфейс запроса статуса ошибки принятого
        // фрейма от транспортного уровня
        .trans_req          (), // o
        .trans_ack          (), // i
        .trans_err          (), // i
        
        // Выходной поток к физическому уровню
        .phy_tx_data        (), // o  [31 : 0]
        .phy_tx_datak       (), // o
        .phy_tx_ready       (), // i
        
        // Входной поток от физического уровня
        .phy_rx_data        (), // i  [31 : 0]
        .phy_rx_datak       (), // i
        
        // Статусные сигналы
        .stat_fsm_code      (), // o  [4 : 0]
        .stat_link_busy     (), // o
        .stat_link_result   (), // o  [2 : 0]
        .stat_rx_fifo_ovfl  ()  // o
    ); // the_sata_link_layer
*/

`include "sata_defs.svh"

module sata_link_layer
#(
    parameter               FPGAFAMILY  = "Arria V"     // Семейство FPGA ("Arria V" | "Arria 10")
)
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,
    
    // Входной потоковый интерфейс передаваемых
    // фреймов от транспортного уровня
    input  logic [31 : 0]   tx_fis_dat,
    input  logic            tx_fis_val,
    input  logic            tx_fis_eop,
    output logic            tx_fis_rdy,
    
    // Выходной потоковый интерфейс принимаемых
    // фреймов к транспортному уровню
    output logic [31 : 0]   rx_fis_dat,
    output logic            rx_fis_val,
    output logic            rx_fis_eop,
    output logic            rx_fis_err,
    input  logic            rx_fis_rdy,
    
    // Интерфейс запроса статуса ошибки принятого
    // фрейма от транспортного уровня
    output logic            trans_req,
    input  logic            trans_ack,
    input  logic            trans_err,
    
    // Выходной поток к физическому уровню
    output logic [31 : 0]   phy_tx_data,
    output logic            phy_tx_datak,
    input  logic            phy_tx_ready,
    
    // Входной поток от физического уровня
    input  logic [31 : 0]   phy_rx_data,
    input  logic            phy_rx_datak,
    
    // Статусные сигналы
    output logic [4 : 0]    stat_fsm_code,
    output logic            stat_link_busy,
    output logic [2 : 0]    stat_link_result,
    output logic            stat_rx_fifo_ovfl
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam logic [4 : 0]    IDLE_CODE           = 5'h00;
    localparam logic [4 : 0]    SEND_CHK_RDY_CODE   = 5'h01;
    localparam logic [4 : 0]    SEND_SOF_CODE       = 5'h02;
    localparam logic [4 : 0]    SEND_DATA_CODE      = 5'h03;
    localparam logic [4 : 0]    SEND_EOF_CODE       = 5'h04;
    localparam logic [4 : 0]    SEND_HOLD_CODE      = 5'h05;
    localparam logic [4 : 0]    RCVR_HOLD_CODE      = 5'h06;
    localparam logic [4 : 0]    WAIT_CODE           = 5'h07;
    localparam logic [4 : 0]    RCV_WAIT_FIFO_CODE  = 5'h08;
    localparam logic [4 : 0]    RCV_CHK_RDY_CODE    = 5'h09;
    localparam logic [4 : 0]    RCV_DATA_CODE       = 5'h0a;
    localparam logic [4 : 0]    HOLD_CODE           = 5'h0b;
    localparam logic [4 : 0]    RCV_HOLD_CODE       = 5'h0c;
    localparam logic [4 : 0]    RCV_EOF_CODE        = 5'h0d;
    localparam logic [4 : 0]    GOOD_CRC_CODE       = 5'h0e;
    localparam logic [4 : 0]    BAD_END_CODE        = 5'h0f;
    localparam logic [4 : 0]    GOOD_END_CODE       = 5'h10;
    //
    localparam logic [2 : 0]    NOTHING_CODE        = 3'h0;
    localparam logic [2 : 0]    TX_SUCCESS_CODE     = 3'h1;
    localparam logic [2 : 0]    TX_ABORT_CODE       = 3'h2;
    localparam logic [2 : 0]    TX_FAULT_CODE       = 3'h3;
    localparam logic [2 : 0]    RX_SUCCESS_CODE     = 3'h4;
    localparam logic [2 : 0]    RX_ABORT_CODE       = 3'h5;
    localparam logic [2 : 0]    RX_FAULT_CODE       = 3'h6;
    localparam logic [2 : 0]    UNKNOWN_FAULT_CODE  = 3'h7;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic [31 : 0]          cont_extr_data;
    logic                   cont_extr_datak;
    //
    logic [31 : 0]          fis_extr_dat;
    logic                   fis_extr_val;
    logic                   fis_extr_eop;
    //
    logic                   rx_fifo_empty;
    logic                   rx_fifo_almostfull;
    logic                   rx_good_crc;
    logic                   rx_bad_crc;
    //
    logic [31 : 0]          tx_fifo_data;
    logic                   tx_fifo_eop;
    logic                   tx_fifo_rdreq;
    logic                   tx_fifo_empty;
    logic                   tx_fifo_almostempty;
    //
    logic [3 : 0]           tx_sel_code;
    logic [4 : 0]           fsm_code;
    logic [2 : 0]           link_result_reg;
    //
    logic                   prim_det;
    logic                   align_det;
    logic                   sync_det;
    logic                   sof_det;
    logic                   eof_det;
    logic                   r_rdy_det;
    logic                   r_ip_det;
    logic                   r_ok_det;
    logic                   r_err_det;
    logic                   x_rdy_det;
    logic                   wtrm_det;
    logic                   hold_det;
    logic                   holda_det;
    //
    logic [31 : 0]          tx_data_reg;
    logic                   tx_datak_reg;
    logic                   tx_ready;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    enum logic [11 : 0] {
        st_idle          = {IDLE_CODE         , 1'b0, 1'b0, `SYNC_TX_CODE,  1'b0},
        st_send_chk_rdy  = {SEND_CHK_RDY_CODE , 1'b0, 1'b0, `X_RDY_TX_CODE, 1'b1},
        st_send_sof      = {SEND_SOF_CODE     , 1'b0, 1'b0, `SOF_TX_CODE,   1'b1},
        st_send_data     = {SEND_DATA_CODE    , 1'b0, 1'b1, `DATA_TX_CODE,  1'b1},
        st_send_eof      = {SEND_EOF_CODE     , 1'b0, 1'b0, `EOF_TX_CODE,   1'b1},
        st_send_hold     = {SEND_HOLD_CODE    , 1'b0, 1'b0, `HOLD_TX_CODE,  1'b1},
        st_rcvr_hold     = {RCVR_HOLD_CODE    , 1'b0, 1'b0, `HOLDA_TX_CODE, 1'b1},
        st_wait          = {WAIT_CODE         , 1'b0, 1'b0, `WTRM_TX_CODE,  1'b1},
        st_rcv_wait_fifo = {RCV_WAIT_FIFO_CODE, 1'b0, 1'b0, `SYNC_TX_CODE,  1'b1},
        st_rcv_chk_rdy   = {RCV_CHK_RDY_CODE  , 1'b0, 1'b0, `R_RDY_TX_CODE, 1'b1},
        st_rcv_data      = {RCV_DATA_CODE     , 1'b0, 1'b0, `R_IP_TX_CODE,  1'b1},
        st_hold          = {HOLD_CODE         , 1'b0, 1'b0, `HOLD_TX_CODE,  1'b1},
        st_rcv_hold      = {RCV_HOLD_CODE     , 1'b0, 1'b0, `HOLDA_TX_CODE, 1'b1},
        st_rcv_eof       = {RCV_EOF_CODE      , 1'b0, 1'b0, `R_IP_TX_CODE,  1'b1},
        st_good_crc      = {GOOD_CRC_CODE     , 1'b1, 1'b0, `R_IP_TX_CODE,  1'b1},
        st_bad_end       = {BAD_END_CODE      , 1'b0, 1'b0, `R_ERR_TX_CODE, 1'b1},
        st_good_end      = {GOOD_END_CODE     , 1'b0, 1'b0, `R_OK_TX_CODE,  1'b1}
    } state;
    wire [11 : 0] st;
    assign st = state;
    
    //------------------------------------------------------------------------------------
    //      Управляющие сигналы конечного автомата
    assign stat_link_busy = st[0];
    assign tx_sel_code    = st[4 : 1];
    assign tx_fifo_rdreq  = st[5] & tx_ready;
    assign trans_req      = st[6];
    assign stat_fsm_code  = st[11 : 7];
    
    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата
    always @(posedge reset, posedge clk)
        if (reset)
            state <= st_idle;
        else case (state)
            st_idle:
                if (x_rdy_det)
                    state <= st_rcv_wait_fifo;
                else if (tx_fifo_empty)
                    state <= st_idle;
                else
                    state <= st_send_chk_rdy;
            
            st_send_chk_rdy:
                if (x_rdy_det)
                    state <= st_rcv_wait_fifo;
                else if (r_rdy_det)
                    state <= st_send_sof;
                else
                    state <= st_send_chk_rdy;
            
            st_send_sof:
                if (sync_det)
                    state <= st_idle;
                else if (tx_ready)
                    state <= st_send_data;
                else
                    state <= st_send_sof;
            
            st_send_data:
                if (sync_det)
                    state <= st_idle;
                else if (tx_ready)
                    if (tx_fifo_eop)
                        state <= st_send_eof;
                    else if (tx_fifo_almostempty)
                        state <= st_send_hold;
                    else if (hold_det)
                        state <= st_rcvr_hold;
                    else
                        state <= st_send_data;
                else
                    state <= st_send_data;
            
            st_send_eof:
                if (sync_det)
                    state <= st_idle;
                else if (tx_ready)
                    state <= st_wait;
                else
                    state <= st_send_eof;
            
            st_send_hold:
                if (sync_det)
                    state <= st_idle;
                else if (tx_fifo_empty)
                    state <= st_send_hold;
                else if (hold_det)
                    state <= st_rcvr_hold;
                else
                    state <= st_send_data;
            
            st_rcvr_hold:
                if (sync_det)
                    state <= st_idle;
                else if (hold_det)
                    state <= st_rcvr_hold;
                else
                    state <= st_send_data;
            
            st_wait:
                if (sync_det | r_err_det | r_ok_det)
                    state <= st_idle;
                else
                    state <= st_wait;
            
            st_rcv_wait_fifo:
                if (x_rdy_det)
                    if (rx_fifo_almostfull)
                        state <= st_rcv_wait_fifo;
                    else
                        state <= st_rcv_chk_rdy;
                else if (align_det)
                    state <= st_rcv_wait_fifo;
                else
                    state <= st_idle;
            
            st_rcv_chk_rdy:
                if (x_rdy_det | align_det)
                    state <= st_rcv_chk_rdy;
                else if (sof_det)
                    state <= st_rcv_data;
                else
                    state <= st_idle;
            
            st_rcv_data:
                if (prim_det)
                    if (sync_det)
                        state <= st_idle;
                    else if (wtrm_det)
                        state <= st_bad_end;
                    else if (eof_det)
                        state <= st_rcv_eof;
                    else if (hold_det)
                        state <= st_rcv_hold;
                    else
                        state <= st_rcv_data;
                else if (rx_fifo_almostfull)
                    state <= st_hold;
                else
                    state <= st_rcv_data;
            
            st_hold:
                if (sync_det)
                    state <= st_idle;
                else if (eof_det)
                    state <= st_rcv_eof;
                else if (rx_fifo_almostfull)
                    state <= st_hold;
                else if (hold_det)
                    state <= st_rcv_hold;
                else
                    state <= st_rcv_data;
            
            st_rcv_hold:
                if (sync_det)
                    state <= st_idle;
                else if (eof_det)
                    state <= st_rcv_eof;
                else if (hold_det)
                    state <= st_rcv_hold;
                else
                    state <= st_rcv_data;
            
            st_rcv_eof:
                if (rx_bad_crc)
                    state <= st_bad_end;
                else if (rx_good_crc)
                    state <= st_good_crc;
                else
                    state <= st_rcv_eof;
            
            st_good_crc:
                if (trans_ack)
                    if (trans_err)
                        state <= st_bad_end;
                    else
                        state <= st_good_end;
                else
                    state <= st_good_crc;
            
            st_bad_end:
                if (sync_det)
                    state <= st_idle;
                else
                    state <= st_bad_end;
            
            st_good_end:
                if (sync_det)
                    state <= st_idle;
                else
                    state <= st_good_end;
            
            default:
                state <= st_idle;
        endcase
    
    //------------------------------------------------------------------------------------
    //      Регистр результата последнего обмена
    initial link_result_reg = NOTHING_CODE;
    always @(posedge reset, posedge clk)
        if (reset)
            link_result_reg <= NOTHING_CODE;
        else case (state)
            st_idle:
                if (x_rdy_det | ~tx_fifo_empty)
                    link_result_reg <= NOTHING_CODE;
                else
                    link_result_reg <= link_result_reg;
            
            st_send_chk_rdy:
                link_result_reg <= NOTHING_CODE;
            
            st_send_sof:
                if (sync_det)
                    link_result_reg <= TX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_send_data:
                if (sync_det)
                    link_result_reg <= TX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_send_eof:
                if (sync_det)
                    link_result_reg <= TX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_send_hold:
                if (sync_det)
                    link_result_reg <= TX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_rcvr_hold:
                if (sync_det)
                    link_result_reg <= TX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_wait:
                if (sync_det)
                    link_result_reg <= TX_ABORT_CODE;
                else if (r_err_det)
                    link_result_reg <= TX_FAULT_CODE;
                else if (r_ok_det)
                    link_result_reg <= TX_SUCCESS_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_rcv_wait_fifo:
                if (~(x_rdy_det | align_det))
                    link_result_reg <= RX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_rcv_chk_rdy:
                if (~(x_rdy_det | align_det | sof_det))
                    link_result_reg <= RX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_rcv_data:
                if (sync_det)
                    link_result_reg <= RX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_hold:
                if (sync_det)
                    link_result_reg <= RX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_rcv_hold:
                if (sync_det)
                    link_result_reg <= RX_ABORT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_rcv_eof:
                link_result_reg <= NOTHING_CODE;
            
            st_good_crc:
                link_result_reg <= NOTHING_CODE;
            
            st_bad_end:
                if (sync_det)
                    link_result_reg <= RX_FAULT_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            st_good_end:
                if (sync_det)
                    link_result_reg <= RX_SUCCESS_CODE;
                else
                    link_result_reg <= NOTHING_CODE;
            
            default:
                link_result_reg <= UNKNOWN_FAULT_CODE;
        endcase
    assign stat_link_result = link_result_reg;
    
    //------------------------------------------------------------------------------------
    //      Модуль извлечения из потока принимаемых данных примитива CONT и следующей
    //      за ним псевдослучайной последовательности данных
    sata_cont_extractor
    the_sata_cont_extractor
    (
        // Сброс и тактирование
        .reset      (reset),            // i
        .clk        (clk),              // i
        
        // Входной поток
        .i_data     (phy_rx_data),      // i  [31 : 0]
        .i_datak    (phy_rx_datak),     // i
        
        // Выходной поток
        .o_data     (cont_extr_data),   // o  [31 : 0]
        .o_datak    (cont_extr_datak)   // o
    ); // the_sata_cont_extractor
    
    //------------------------------------------------------------------------------------
    //      Модуль выделения фрейма SerialATA из непрерывного потока принимаемых данных
    sata_fis_extractor
    the_sata_fis_extractor
    (
        // Сброс и тактирование
        .reset      (reset),            // i
        .clk        (clk),              // i
        
        // Входной поток принимаемых данных
        .rx_data    (cont_extr_data),   // i  [31 : 0]
        .rx_datak   (cont_extr_datak),  // i
        
        // Выходной поток фреймов
        .fis_dat    (fis_extr_dat),     // o  [31 : 0]
        .fis_val    (fis_extr_val),     // o
        .fis_eop    (fis_extr_eop)      // o
    ); // the_sata_fis_extractor
    
    //------------------------------------------------------------------------------------
    //      Признаки обнаружения различных примитивов
    assign prim_det  = (cont_extr_datak == `DWORD_IS_PRIM);
    assign align_det = prim_det & (cont_extr_data == `ALIGN_PRIM);
    assign sync_det  = prim_det & (cont_extr_data == `SYNC_PRIM);
    assign sof_det   = prim_det & (cont_extr_data == `SOF_PRIM);
    assign eof_det   = prim_det & (cont_extr_data == `EOF_PRIM);
    assign r_rdy_det = prim_det & (cont_extr_data == `R_RDY_PRIM);
    assign r_ip_det  = prim_det & (cont_extr_data == `R_IP_PRIM);
    assign r_ok_det  = prim_det & (cont_extr_data == `R_OK_PRIM);
    assign r_err_det = prim_det & (cont_extr_data == `R_ERR_PRIM);
    assign x_rdy_det = prim_det & (cont_extr_data == `X_RDY_PRIM);
    assign wtrm_det  = prim_det & (cont_extr_data == `WTRM_PRIM);
    assign hold_det  = prim_det & (cont_extr_data == `HOLD_PRIM);
    assign holda_det = prim_det & (cont_extr_data == `HOLDA_PRIM);
    
    //------------------------------------------------------------------------------------
    //      Тракт прохождения принимаемых данных Link-уровня SerialATA
    sata_link_rx_path
    #(
        .FPGAFAMILY         (FPGAFAMILY)            // Семейство FPGA ("Arria V" | "Arria 10")
    )
    the_sata_link_rx_path
    (
        // Сброс и тактирование
        .reset              (reset),                // i
        .clk                (clk),                  // i
        
        // Входной потоковый интерфейс
        .rx_dat             (fis_extr_dat),         // i  [31 : 0]
        .rx_val             (fis_extr_val),         // i
        .rx_eop             (fis_extr_eop),         // i
        
        // Интерфейс FIFO
        .fifo_data          (rx_fis_dat),           // o  [31 : 0]
        .fifo_eop           (rx_fis_eop),           // o
        .fifo_err           (rx_fis_err),           // o
        .fifo_rdreq         (rx_fis_rdy),           // i
        .fifo_empty         (rx_fifo_empty),        // o
        .fifo_almostfull    (rx_fifo_almostfull),   // o
        
        // Интерфейс статусных сигналов
        .stat_good_crc      (rx_good_crc),          // o
        .stat_bad_crc       (rx_bad_crc),           // o
        .stat_fifo_ovfl     (stat_rx_fifo_ovfl)     // o
    ); // the_sata_link_rx_path
    assign rx_fis_val = ~rx_fifo_empty;
    
    //------------------------------------------------------------------------------------
    //      Тракт прохождения передаваемых данных Link-уровня SerialATA
    sata_link_tx_path
    #(
        .FPGAFAMILY         (FPGAFAMILY)            // Семейство FPGA ("Arria V" | "Arria 10")
    )
    the_sata_link_tx_path
    (
        // Сброс и тактирование
        .reset              (reset),                // i
        .clk                (clk),                  // i
        
        // Входной потоковый интерфейс
        .tx_dat             (tx_fis_dat),           // i  [31 : 0]
        .tx_val             (tx_fis_val),           // i
        .tx_eop             (tx_fis_eop),           // i
        .tx_rdy             (tx_fis_rdy),           // o
        
        // Интерфейс FIFO
        .fifo_data          (tx_fifo_data),         // o  [31 : 0]
        .fifo_eop           (tx_fifo_eop),          // o
        .fifo_rdreq         (tx_fifo_rdreq),        // i
        .fifo_empty         (tx_fifo_empty),        // o
        .fifo_almostempty   (tx_fifo_almostempty)   // o
    ); // the_sata_link_tx_path
    
    //------------------------------------------------------------------------------------
    //      Регистр передаваемого слова данных/примитива
    initial tx_data_reg = `SYNC_PRIM;
    always @(posedge reset, posedge clk)
        if (reset)
            tx_data_reg <= `SYNC_PRIM;
        else if (tx_ready)
            case (tx_sel_code)
                `SYNC_TX_CODE:  tx_data_reg <= `SYNC_PRIM;
                `SOF_TX_CODE:   tx_data_reg <= `SOF_PRIM;
                `EOF_TX_CODE:   tx_data_reg <= `EOF_PRIM;
                `R_RDY_TX_CODE: tx_data_reg <= `R_RDY_PRIM;
                `R_IP_TX_CODE:  tx_data_reg <= `R_IP_PRIM;
                `R_OK_TX_CODE:  tx_data_reg <= `R_OK_PRIM;
                `R_ERR_TX_CODE: tx_data_reg <= `R_ERR_PRIM;
                `X_RDY_TX_CODE: tx_data_reg <= `X_RDY_PRIM;
                `WTRM_TX_CODE:  tx_data_reg <= `WTRM_PRIM;
                `HOLD_TX_CODE:  tx_data_reg <= `HOLD_PRIM;
                `HOLDA_TX_CODE: tx_data_reg <= `HOLDA_PRIM;
                `DATA_TX_CODE:  tx_data_reg <= tx_fifo_data;
                default:        tx_data_reg <= `SYNC_PRIM;
            endcase
        else
            tx_data_reg <= tx_data_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр передаваемого признака примитива
    initial tx_datak_reg = `DWORD_IS_PRIM;
    always @(posedge reset, posedge clk)
        if (reset)
            tx_datak_reg <= `DWORD_IS_PRIM;
        else if (tx_ready)
            if (tx_sel_code == `DATA_TX_CODE)
                tx_datak_reg <= `DWORD_IS_DATA;
            else
                tx_datak_reg <= `DWORD_IS_PRIM;
        else
            tx_datak_reg <= tx_datak_reg;
    
    //------------------------------------------------------------------------------------
    //      Модуль вставки в поток передаваемых данных примитива CONT и следующей
    //      за ним псевдослучайной последовательности данных
    sata_cont_inserter
    the_sata_cont_inserter
    (
        // Сброс и тактирование
        .reset      (reset),        // i
        .clk        (clk),          // i
        
        // Входной поток
        .i_data     (tx_data_reg),  // i  [31 : 0]
        .i_datak    (tx_datak_reg), // i
        .i_ready    (tx_ready),     // o
        
        // Выходной поток
        .o_data     (phy_tx_data),  // o  [31 : 0]
        .o_datak    (phy_tx_datak), // o
        .o_ready    (phy_tx_ready)  // i
    ); // the_sata_cont_inserter
    /*
    assign phy_tx_data  = tx_data_reg;
    assign phy_tx_datak = tx_datak_reg;
    assign tx_ready     = phy_tx_ready;
    */
endmodule: sata_link_layer