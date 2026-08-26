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
// SVA 1: PENABLE must go HIGH 1 cycle after PSEL goes HIGH
    property p_enable_timing;
        @(posedge HCLK) disable iff (!HRESETn)
        $rose(PSEL) |==> PENABLE;
    endproperty
    assert_enable_timing: assert property (p_enable_timing)
        else $error("SVA ERROR: PENABLE failed to go HIGH after PSEL!");

    // SVA 2: PSEL must remain active while waiting for PREADY
    property p_psel_stable;
        @(posedge HCLK) disable iff (!HRESETn)
        (PSEL && !PREADY) |=> PSEL;
    endproperty
    assert_psel_stable: assert property (p_psel_stable)
        else $error("SVA ERROR: PSEL dropped before PREADY was asserted!");
endinterface