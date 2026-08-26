interface bridge_if (input logic HCLK, input logic HRESETn);

    // AHB Signals
    logic        HSEL;
    logic [31:0] HADDR;
    logic [31:0] HWDATA;
    logic        HWRITE;
    logic [1:0]  HTRANS;
    logic [31:0] HRDATA;
    logic        HREADYout;

    // APB Signals
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;

    // Clocking Block for Driver (AHB Master view)
    clocking drv_cb @(posedge HCLK);
        default input #1step output #1;
        output HSEL, HADDR, HWDATA, HWRITE, HTRANS;
        input  HRDATA, HREADYout;
    endclocking

    // Clocking Block for Monitor
    clocking mon_cb @(posedge HCLK);
        default input #1step output #1;
        input HSEL, HADDR, HWDATA, HWRITE, HTRANS, HRDATA, HREADYout;
        input PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY;
    endclocking

    // Modports for Environment Components
    modport DRV (clocking drv_cb, input HRESETn);
    modport MON (clocking mon_cb, input HRESETn);

endinterface