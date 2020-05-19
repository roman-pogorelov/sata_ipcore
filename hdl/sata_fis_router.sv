/*
    //------------------------------------------------------------------------------------
    //      Маршрутизатор принимаемых SATA фреймов
    sata_fis_router
    the_sata_fis_router
    (
        // Сброс и тактирование
        .reset          (), // i
        .clk            (), // i

        // Входной потоковый интерфейс принимаемых фреймов
        .rx_dat         (), // i  [31 : 0]
        .rx_val         (), // i
        .rx_eop         (), // i
        .rx_err         (), // i
        .rx_rdy         (), // o

        // Выходной потоковый интерфейс фреймов
        // Register D->H и PIO Setup D->H
        .reg_pio_dat    (), // o  [31 : 0]
        .reg_pio_val    (), // o
        .reg_pio_eop    (), // o
        .reg_pio_err    (), // o
        .reg_pio_rdy    (), // i

        // Выходной потоковый интерфейс фреймов
        // DMA Activate D->H
        .dma_act_dat    (), // o  [31 : 0]
        .dma_act_val    (), // o
        .dma_act_eop    (), // o
        .dma_act_err    (), // o
        .dma_act_rdy    (), // i

        // Выходной потоковый интерфейс фреймов
        // данных D->H (с удаленными заголовками)
        .data_dat       (), // o  [31 : 0]
        .data_val       (), // o
        .data_eop       (), // o
        .data_err       (), // o
        .data_rdy       (), // i

        // Выходной потоковый интерфейс фреймов
        // остальных типов
        .default_dat    (), // o  [31 : 0]
        .default_val    (), // o
        .default_eop    (), // o
        .default_err    (), // o
        .default_rdy    ()  // i
    ); // the_sata_fis_router
*/

`include "sata_defs.svh"

module sata_fis_router
(
    // Сброс и тактирование
    input  logic            reset,
    input  logic            clk,

    // Входной потоковый интерфейс принимаемых фреймов
    input  logic [31 : 0]   rx_dat,
    input  logic            rx_val,
    input  logic            rx_eop,
    input  logic            rx_err,
    output logic            rx_rdy,

    // Выходной потоковый интерфейс фреймов
    // Register D->H и PIO Setup D->H
    output logic [31 : 0]   reg_pio_dat,
    output logic            reg_pio_val,
    output logic            reg_pio_eop,
    output logic            reg_pio_err,
    input  logic            reg_pio_rdy,

    // Выходной потоковый интерфейс фреймов
    // DMA Activate D->H
    output logic [31 : 0]   dma_act_dat,
    output logic            dma_act_val,
    output logic            dma_act_eop,
    output logic            dma_act_err,
    input  logic            dma_act_rdy,

    // Выходной потоковый интерфейс фреймов
    // данных D->H с удаленными заголовками
    output logic [31 : 0]   data_dat,
    output logic            data_val,
    output logic            data_eop,
    output logic            data_err,
    input  logic            data_rdy,

    // Выходной потоковый интерфейс фреймов
    // остальных типов
    output logic [31 : 0]   default_dat,
    output logic            default_val,
    output logic            default_eop,
    output logic            default_err,
    input  logic            default_rdy
);
    //------------------------------------------------------------------------------------
    //      Объявление констант
    localparam logic [1 : 0] DEFAULT_ROUTE  = 2'h0;
    localparam logic [1 : 0] REG_PIO_ROUTE  = 2'h1;
    localparam logic [1 : 0] DMA_ACT_ROUTE  = 2'h2;
    localparam logic [1 : 0] DATA_ROUTE     = 2'h3;

    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                   rx_sop_reg;
    logic [1 : 0]           route_num_start;
    logic [1 : 0]           route_num_hold_reg;
    logic [1 : 0]           route_num;
    logic [3 : 0]           route_pos;

    //------------------------------------------------------------------------------------
    //      Регистр признака начала принимаемого фрейма
    initial rx_sop_reg = 1'b1;
    always @(posedge reset, posedge clk) begin
        if (reset)
            rx_sop_reg <= 1'b1;
        else if (rx_val & rx_rdy)
            rx_sop_reg <= rx_eop;
        else
            rx_sop_reg <= rx_sop_reg;
    end

    //------------------------------------------------------------------------------------
    //      Номер маршрута на этапе прохождения первого слова фрейма
    always_comb begin
        case (rx_dat[7 : 0])
            `REG_FIS_D2H:   route_num_start = REG_PIO_ROUTE;
            `PIO_SET_FIS:   route_num_start = REG_PIO_ROUTE;
            `DMA_ACT_FIS:   route_num_start = DMA_ACT_ROUTE;
            `DATA_FIS:      route_num_start = DATA_ROUTE;
            default:        route_num_start = DEFAULT_ROUTE;
        endcase
    end

    //------------------------------------------------------------------------------------
    //      Регистр удержания номера маршрута на время прохождения остальных слов фрейма
    always @(posedge reset, posedge clk) begin
        if (reset)
            route_num_hold_reg <= '0;
        else if (rx_val & rx_rdy & rx_sop_reg)
            route_num_hold_reg <= route_num;
        else
            route_num_hold_reg <= route_num_hold_reg;
    end

    //------------------------------------------------------------------------------------
    //      Номер маршрута для всех слов фрейма
    assign route_num = rx_sop_reg ? route_num_start : route_num_hold_reg;

    //------------------------------------------------------------------------------------
    //      Позиционный код номера маршрута
    always_comb begin
        route_pos = {4{1'b0}};
        route_pos[route_num] = 1'b1;
    end

    //------------------------------------------------------------------------------------
    //      Разветвление данных на все маршруты
    assign reg_pio_dat = rx_dat;
    assign dma_act_dat = rx_dat;
    assign data_dat    = rx_dat;
    assign default_dat = rx_dat;

    //------------------------------------------------------------------------------------
    //      Стробирование признака достоверности по позиции маршрута
    assign reg_pio_val = rx_val & route_pos[REG_PIO_ROUTE];
    assign dma_act_val = rx_val & route_pos[DMA_ACT_ROUTE];
    assign data_val    = rx_val & route_pos[DATA_ROUTE] & ~rx_sop_reg;
    assign default_val = rx_val & route_pos[DEFAULT_ROUTE];

    //------------------------------------------------------------------------------------
    //      Стробирование признака конца фрейма по позиции маршрута
    assign reg_pio_eop = rx_eop & route_pos[REG_PIO_ROUTE];
    assign dma_act_eop = rx_eop & route_pos[DMA_ACT_ROUTE];
    assign data_eop    = rx_eop & route_pos[DATA_ROUTE] & ~rx_sop_reg;
    assign default_eop = rx_eop & route_pos[DEFAULT_ROUTE];

    //------------------------------------------------------------------------------------
    //      Стробирование признака ошибки фрейма по позиции маршрута
    assign reg_pio_err = rx_err & route_pos[REG_PIO_ROUTE];
    assign dma_act_err = rx_err & route_pos[DMA_ACT_ROUTE];
    assign data_err    = rx_err & route_pos[DATA_ROUTE] & ~rx_sop_reg;
    assign default_err = rx_err & route_pos[DEFAULT_ROUTE];

    //------------------------------------------------------------------------------------
    //      Коммутация признака готовности но номеру маршрута
    always_comb begin
        case (route_num)
            REG_PIO_ROUTE:  rx_rdy = reg_pio_rdy;
            DMA_ACT_ROUTE:  rx_rdy = dma_act_rdy;
            DATA_ROUTE:     rx_rdy = data_rdy | rx_sop_reg;
            default:        rx_rdy = default_rdy;
        endcase
    end

endmodule: sata_fis_router