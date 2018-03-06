/*
    //------------------------------------------------------------------------------------
    //      Модуль калибровки и сброса PLL тактирования высокоскоростных трансиверов
    a10_xcvr_pll_resetter
    #(
        .PLL_TYPE               (), // Тип PLL ("fPLL" | "CMUPLL" | "ATXPLL")
        .RST_DELAY              ()  // Длительность сброса PLL (в тактах clk)
    )
    the_a10_xcvr_pll_resetter
    (
        // Сброс и тактирование
        .reset                  (), // i
        .clk                    (), // i
        
        // Интерфейс калибровки PLL
        .reconfig_address       (), // o  [9 : 0]
        .reconfig_write         (), // o
        .reconfig_writedata     (), // o  [31 : 0]
        .reconfig_read          (), // o
        .reconfig_readdata      (), // i  [31 : 0]
        .reconfig_waitrequest   (), // i
        
        // Интерфейс управления PLL
        .pll_powerdown          (), // o
        .pll_cal_busy           ()  // i
    ); // the_a10_xcvr_pll_resetter
*/

module a10_xcvr_pll_resetter
#(
    parameter                   PLL_TYPE    = "fPLL",   // Тип PLL ("fPLL" | "CMUPLL" | "ATXPLL")
    parameter int unsigned      RST_DELAY   = 10        // Длительность сброса PLL (в тактах clk)
)
(
    // Сброс и тактирование
    input  logic                reset,
    input  logic                clk,
    
    // Интерфейс калибровки PLL
    output logic [9 : 0]        reconfig_address,
    output logic                reconfig_write,
    output logic [31 : 0]       reconfig_writedata,
    output logic                reconfig_read,
    input  logic [31 : 0]       reconfig_readdata,
    input  logic                reconfig_waitrequest,
    
    // Интерфейс управления PLL
    output logic                pll_powerdown,
    input  logic                pll_cal_busy
);
    //------------------------------------------------------------------------------------
    //      Описание констант
    localparam int unsigned     CWIDTH              = $clog2(RST_DELAY);
    localparam logic [31 : 0]   ATXPLL_CAL_ENA_BIT  = 32'h00000001;
    localparam logic [31 : 0]   FPLL_CAL_ENA_BIT    = 32'h00000002;
    localparam logic [31 : 0]   CMUPLL_CAL_ENA_BIT  = 32'h00000020;
    
    //------------------------------------------------------------------------------------
    //      Объявление сигналов
    logic                       sreset;
    logic                       cal_busy;
    logic [CWIDTH - 1 : 0]      powerdown_cnt;
    logic                       powerdown_reg;
    logic [31 : 0]              data_reg;
    
    //------------------------------------------------------------------------------------
    //      Кодирование состояний конечного автомата
    enum logic [5 : 0] {
        st_wait_init_cal    = 6'b000000,
        st_set_user_access  = 6'b000011,
        st_get_cal_register = 6'b001101,
        st_set_cal_register = 6'b001011,
        st_run_calibration  = 6'b010011,
        st_wait_busy_rise   = 6'b000001,
        st_wait_busy_fall   = 6'b010001,
        st_set_powerdown    = 6'b100001,
        st_idle             = 6'b010000
    } state;
    wire [5 : 0] st;
    assign st = state;
    
    //------------------------------------------------------------------------------------
    //      Управляющие сигналы конечного автомата
    assign       reconfig_write   = st[1];
    assign       reconfig_read    = st[2];
    assign       reconfig_address = {1'b0, st[3], 8'b0};
    wire         powerdown        = st[5];
    wire [1 : 0] wdata_select     = st[4 : 3];
    
    //------------------------------------------------------------------------------------
    //      Логика переходов конечного автомата
    initial state = st_wait_init_cal;
    always @(posedge sreset, posedge clk)
        if (sreset)
            state <= st_wait_init_cal;
        else case (state)
            st_wait_init_cal:
                if (cal_busy)
                    state <= st_wait_init_cal;
                else
                    state <= st_set_user_access;
            
            st_set_user_access:
                if (reconfig_waitrequest)
                    state <= st_set_user_access;
                else
                    state <= st_get_cal_register;
            
            st_get_cal_register:
                if (reconfig_waitrequest)
                    state <= st_get_cal_register;
                else
                    state <= st_set_cal_register;
            
            st_set_cal_register:
                if (reconfig_waitrequest)
                    state <= st_set_cal_register;
                else
                    state <= st_run_calibration;
            
            st_run_calibration:
                if (reconfig_waitrequest)
                    state <= st_run_calibration;
                else
                    state <= st_wait_busy_rise;
            
            st_wait_busy_rise:
                if (cal_busy)
                    state <= st_wait_busy_fall;
                else
                    state <= st_wait_busy_rise;
            
            st_wait_busy_fall:
                if (cal_busy)
                    state <= st_wait_busy_fall;
                else
                    state <= st_set_powerdown;
            
            st_set_powerdown:
                if (powerdown_cnt == 0)
                    state <= st_idle;
                else
                    state <= st_set_powerdown;
            
            st_idle:
                state <= st_idle;
            
            default:
                state <= st_idle;
        endcase
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигналов асинхронного сброса (предустановки)
    areset_synchronizer
    #(
        .EXTRA_STAGES   (1),        // Количество дополнительных ступеней цепи синхронизации
        .ACTIVE_LEVEL   (1'b1)      // Активный уровень сигнала сброса
    )
    input_reset_synchronizer
    (
        // Сигнал тактирования
        .clk            (clk),      // i
        
        // Входной сброс (асинхронный 
        // относительно сигнала тактирования)
        .areset         (reset),    // i
        
        // Выходной сброс (синхронный 
        // относительно сигнала тактирования)
        .sreset         (sreset)    // o
    ); // input_reset_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Модуль синхронизации сигнала на последовательной триггерной цепочке
    ff_synchronizer
    #(
        .WIDTH          (1),            // Разрядность синхронизируемой шины
        .EXTRA_STAGES   (1),            // Количество дополнительных ступеней цепи синхронизации
        .RESET_VALUE    (1'b1)          // Значение по умолчанию для ступеней цепи синхронизации
    )
    pll_cal_busy_synchronizer
    (
        // Сброс и тактирование
        .reset          (sreset),       // i
        .clk            (clk),          // i
        
        // Асинхронный входной сигнал
        .async_data     (pll_cal_busy), // i  [WIDTH - 1 : 0]
        
        // Синхронный выходной сигнал
        .sync_data      (cal_busy)      // o  [WIDTH - 1 : 0]
    ); // pll_cal_busy_synchronizer
    
    //------------------------------------------------------------------------------------
    //      Счетчик длительности сброса PLL
    initial powerdown_cnt = RST_DELAY[CWIDTH - 1 : 0] - 1'b1;
    always @(posedge sreset, posedge clk)
        if (sreset)
            powerdown_cnt <= RST_DELAY[CWIDTH - 1 : 0] - 1'b1;
        else if (powerdown)
            powerdown_cnt <= powerdown_cnt - 1'b1;
        else
            powerdown_cnt <= RST_DELAY[CWIDTH - 1 : 0] - 1'b1;
    
    //------------------------------------------------------------------------------------
    //      Регистр сброса PLL
    initial powerdown_reg = 1'b0;
    always @(posedge sreset, posedge clk)
        if (sreset)
            powerdown_reg <= 1'b0;
        else
            powerdown_reg <= powerdown;
    assign pll_powerdown = powerdown_reg;
    
    //------------------------------------------------------------------------------------
    //      Регистр данных, сохраняемых при чтении
    initial data_reg = '0;
    always @(posedge sreset, posedge clk)
        if (sreset)
            data_reg <= '0;
        else if (reconfig_read & ~reconfig_waitrequest)
            if (PLL_TYPE == "ATXPLL")
                data_reg <= reconfig_readdata | ATXPLL_CAL_ENA_BIT;
            else if (PLL_TYPE == "fPLL")
                data_reg <= reconfig_readdata | FPLL_CAL_ENA_BIT;
            else
                data_reg <= reconfig_readdata | CMUPLL_CAL_ENA_BIT;
        else
            data_reg <= data_reg;
    
    //------------------------------------------------------------------------------------
    //      Мультиплексирование записываемых данных
    always_comb begin
        case (wdata_select)
            2'b01:   reconfig_writedata = data_reg;
            2'b10:   reconfig_writedata = 32'h00000001;
            default: reconfig_writedata = 32'h00000002;
        endcase
    end
    
endmodule: a10_xcvr_pll_resetter