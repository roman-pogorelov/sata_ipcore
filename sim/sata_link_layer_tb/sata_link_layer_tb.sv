`timescale  1ns / 1ps

`include "sata_defs.svh"

module sata_link_layer_tb ();
    
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam int unsigned     DELAY = 8;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                           reset;
    logic                           clk;
    //
    logic [31 : 0]                  tx_fis_dat;
    logic                           tx_fis_val;
    logic                           tx_fis_eop;
    logic                           tx_fis_rdy;
    //
    logic [31 : 0]                  rx_fis_dat;
    logic                           rx_fis_val;
    logic                           rx_fis_eop;
    logic                           rx_fis_err;
    logic                           rx_fis_rdy;
    //
    logic [31 : 0]                  trm_phy_data;
    logic                           trm_phy_datak;
    //
    logic [DELAY - 1 : 0][31 : 0]   trm_phy_data_dly_reg;
    logic [DELAY - 1 : 0]           trm_phy_datak_dly_reg;
    logic [31 : 0]                  trm_phy_data_dly;
    logic                           trm_phy_datak_dly;
    //
    logic [31 : 0]                  rcv_phy_data;
    logic                           rcv_phy_datak;
    //
    logic [DELAY - 1 : 0][31 : 0]   rcv_phy_data_dly_reg;
    logic [DELAY - 1 : 0]           rcv_phy_datak_dly_reg;
    logic [31 : 0]                  rcv_phy_data_dly;
    logic                           rcv_phy_datak_dly;
    //
    logic [4 : 0]                   trm_fsm_code;
    logic                           trm_link_busy;
    logic [2 : 0]                   trm_link_result;
    logic                           trm_rx_fifo_ovfl;
    //
    logic [4 : 0]                   rcv_fsm_code;
    logic                           rcv_link_busy;
    logic [2 : 0]                   rcv_link_result;
    logic                           rcv_rx_fifo_ovfl;
    //
    logic [7 : 0]                   trm_cycle_cnt;
    logic                           trm_ready;
    //
    logic [7 : 0]                   rcv_cycle_cnt;
    logic                           rcv_ready;
    
    //------------------------------------------------------------------------------------
    //      Инициализация
    initial begin
        tx_fis_dat = 0;
        tx_fis_val = 0;
        tx_fis_eop = 0;
        rx_fis_rdy = 1;
    end
    
    //------------------------------------------------------------------------------------
    //      Сброс
    initial begin
        #00 reset = 1;
        #15 reset = 0;
    end
    
    //------------------------------------------------------------------------------------
    //      Тактирование
    initial clk = 1;
    always  clk = #05 ~clk;
    
    //------------------------------------------------------------------------------------
    //      Модуль уровня соединения стека SerialATA
    sata_link_layer
    sata_link_layer_tx
    (
        // Сброс и тактирование
        .reset              (reset),            // i
        .clk                (clk),              // i
        
        // Входной потоковый интерфейс передаваемых
        // фреймов от транспортного уровня
        .tx_fis_dat         (tx_fis_dat),       // i  [31 : 0]
        .tx_fis_val         (tx_fis_val),       // i
        .tx_fis_eop         (tx_fis_eop),       // i
        .tx_fis_rdy         (tx_fis_rdy),       // o
        
        // Выходной потоковый интерфейс принимаемых
        // фреймов к транспортному уровню
        .rx_fis_dat         (    ),             // o  [31 : 0]
        .rx_fis_val         (    ),             // o
        .rx_fis_eop         (    ),             // o
        .rx_fis_err         (    ),             // o
        .rx_fis_rdy         (1'b1),             // i
        
        // Интерфейс запроса статуса ошибки принятого
        // фрейма от транспортного уровня
        .trans_req          (    ),             // o
        .trans_ack          (1'b1),             // i
        .trans_err          (1'b0),             // i
        
        // Выходной поток к физическому уровню
        .phy_tx_data        (trm_phy_data),     // o  [31 : 0]
        .phy_tx_datak       (trm_phy_datak),    // o
        .phy_tx_ready       (trm_ready),        // i
        
        // Входной поток от физического уровня
        .phy_rx_data        (rcv_phy_data_dly), // i  [31 : 0]
        .phy_rx_datak       (rcv_phy_datak_dly),// i
        
        // Статусные сигналы
        .stat_fsm_code      (trm_fsm_code),     // o  [4 : 0]
        .stat_link_busy     (trm_link_busy),    // o
        .stat_link_result   (trm_link_result),  // o  [2 : 0]
        .stat_rx_fifo_ovfl  (trm_rx_fifo_ovfl)  // o
    ); // sata_link_layer_tx
    
    //------------------------------------------------------------------------------------
    //      Модуль уровня соединения стека SerialATA
    sata_link_layer
    sata_link_layer_rx
    (
        // Сброс и тактирование
        .reset              (reset),            // i
        .clk                (clk),              // i
        
        // Входной потоковый интерфейс передаваемых
        // фреймов от транспортного уровня
        .tx_fis_dat         ({32{1'b0}}),       // i  [31 : 0]
        .tx_fis_val         (1'b0),             // i
        .tx_fis_eop         (1'b0),             // i
        .tx_fis_rdy         (    ),             // o
        
        // Выходной потоковый интерфейс принимаемых
        // фреймов к транспортному уровню
        .rx_fis_dat         (rx_fis_dat),       // o  [31 : 0]
        .rx_fis_val         (rx_fis_val),       // o
        .rx_fis_eop         (rx_fis_eop),       // o
        .rx_fis_err         (rx_fis_err),       // o
        .rx_fis_rdy         (rx_fis_rdy),       // i
        
        // Интерфейс запроса статуса ошибки принятого
        // фрейма от транспортного уровня
        .trans_req          (    ),             // o
        .trans_ack          (1'b1),             // i
        .trans_err          (1'b0),             // i
        
        // Выходной поток к физическому уровню
        .phy_tx_data        (rcv_phy_data),     // o  [31 : 0]
        .phy_tx_datak       (rcv_phy_datak),    // o
        .phy_tx_ready       (rcv_ready),        // i
        
        // Входной поток от физического уровня
        .phy_rx_data        (trm_phy_data_dly), // i  [31 : 0]
        .phy_rx_datak       (trm_phy_datak_dly),// i
        
        // Статусные сигналы
        .stat_fsm_code      (rcv_fsm_code),     // o  [4 : 0]
        .stat_link_busy     (rcv_link_busy),    // o
        .stat_link_result   (rcv_link_result),  // o  [2 : 0]
        .stat_rx_fifo_ovfl  (rcv_rx_fifo_ovfl)  // o
    ); // sata_link_layer_rx
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов передатчика
    always @(posedge reset, posedge clk)
        if (reset)
            trm_cycle_cnt <= $random;
        else
            trm_cycle_cnt <= trm_cycle_cnt + 1'b1;
    assign trm_ready = (trm_cycle_cnt != 0) & (trm_cycle_cnt != 1);
    
    //------------------------------------------------------------------------------------
    //      Счетчик тактов приемника
    always @(posedge reset, posedge clk)
        if (reset)
            rcv_cycle_cnt <= $random;
        else
            rcv_cycle_cnt <= rcv_cycle_cnt + 1'b1;
    assign rcv_ready = (rcv_cycle_cnt != 0) & (rcv_cycle_cnt != 1);
    
    //------------------------------------------------------------------------------------
    //      Линия задержки от передатчика к приемнику
    always @(posedge reset, posedge clk)
        if (reset) begin
            trm_phy_data_dly_reg <= '0;
            trm_phy_datak_dly_reg <= '0;
        end
        else if (DELAY > 1) begin
            trm_phy_data_dly_reg <= {trm_phy_data_dly_reg[DELAY - 2 : 0], trm_ready ? trm_phy_data : `ALIGN_PRIM};
            trm_phy_datak_dly_reg <= {trm_phy_datak_dly_reg[DELAY - 2 : 0], trm_ready ? trm_phy_datak : `DWORD_IS_PRIM};
        end
        else begin
            trm_phy_data_dly_reg <= trm_ready ? trm_phy_data : `ALIGN_PRIM;
            trm_phy_datak_dly_reg <= trm_ready ? trm_phy_datak : `DWORD_IS_PRIM;
        end
    assign trm_phy_data_dly = trm_phy_data_dly_reg[DELAY - 1];
    assign trm_phy_datak_dly = trm_phy_datak_dly_reg[DELAY - 1];
    
    //------------------------------------------------------------------------------------
    //      Линия задержки от приемнику к передатчика
    always @(posedge reset, posedge clk)
        if (reset) begin
            rcv_phy_data_dly_reg <= '0;
            rcv_phy_datak_dly_reg <= '0;
        end
        else if (DELAY > 1) begin
            rcv_phy_data_dly_reg <= {rcv_phy_data_dly_reg[DELAY - 2 : 0], rcv_ready ? rcv_phy_data : `ALIGN_PRIM};
            rcv_phy_datak_dly_reg <= {rcv_phy_datak_dly_reg[DELAY - 2 : 0], rcv_ready ? rcv_phy_datak : `DWORD_IS_PRIM};
        end
        else begin
            rcv_phy_data_dly_reg <= rcv_ready ? rcv_phy_data : `ALIGN_PRIM;
            rcv_phy_datak_dly_reg <= rcv_ready ? rcv_phy_datak : `DWORD_IS_PRIM;
        end
    assign rcv_phy_data_dly = rcv_phy_data_dly_reg[DELAY - 1];
    assign rcv_phy_datak_dly = rcv_phy_datak_dly_reg[DELAY - 1];
    
endmodule: sata_link_layer_tb