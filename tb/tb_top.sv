`timescale 1ns/1ps

module tb_top;

    // Clock and Reset Signals
    logic        HCLK;
    logic        HRESETn;

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

    // Verification Metrics
    integer match_count = 0;
    integer error_count = 0;

    // Instantiate DUT (AHB to APB Bridge)
    bridge_rtl DUT (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HSEL(HSEL),
        .HADDR(HADDR),
        .HWDATA(HWDATA),
        .HWRITE(HWRITE),
        .HTRANS(HTRANS),
        .HRDATA(HRDATA),
        .HREADYout(HREADYout),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY)
    );

    // Clock Generation (100MHz)
    always #5 HCLK = ~HCLK;

    // Mock APB Peripheral Response
    always @(posedge HCLK) begin
        if (PSEL && PENABLE) begin
            PREADY <= 1'b1;
            if (!PWRITE) begin
                PRDATA <= PADDR + 32'hA5A5_0000;
            end
        end else begin
            PREADY <= 1'b1;
        end
    end

    // AHB Bus Driving Task (Driver Model)
    task ahb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge HCLK);
            HSEL   <= 1'b1;
            HADDR  <= addr;
            HWRITE <= 1'b1;
            HTRANS <= 2'b10; // NONSEQ

            @(posedge HCLK);
            HWDATA <= data;
            
            wait(HREADYout == 1'b1);
            @(posedge HCLK);
            HSEL   <= 1'b0;
            HTRANS <= 2'b00; // IDLE
            $display("[DRV] WRITE Complete -> Addr: 0x%0h | Data: 0x%0h", addr, data);
        end
    endtask

    task ahb_read(input [31:0] addr, input [31:0] expected_data);
        begin
            @(posedge HCLK);
            HSEL   <= 1'b1;
            HADDR  <= addr;
            HWRITE <= 1'b0;
            HTRANS <= 2'b10; // NONSEQ

            @(posedge HCLK);
            wait(HREADYout == 1'b1);
            
            // Scoreboard Check Phase
            if (PRDATA == expected_data) begin
                $display("[SCOREBOARD] PASS! Addr: 0x%0h | Read Data: 0x%0h", addr, PRDATA);
                match_count = match_count + 1;
            end else begin
                $display("[SCOREBOARD] FAIL! Addr: 0x%0h | Exp: 0x%0h | Got: 0x%0h", addr, expected_data, PRDATA);
                error_count = error_count + 1;
            end

            @(posedge HCLK);
            HSEL   <= 1'b0;
            HTRANS <= 2'b00; // IDLE
        end
    endtask

    // VCD Dump Configuration for GTKWave
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_top);
    end

    // Main Test Sequence
    initial begin
        // Initialize Signals
        HCLK    = 0;
        HRESETn = 0;
        HSEL    = 0;
        HADDR   = 0;
        HWDATA  = 0;
        HWRITE  = 0;
        HTRANS  = 0;
        PRDATA  = 0;
        PREADY  = 1;

        #20 HRESETn = 1; // Release Reset
        $display("\n--- STARTING AHB-APB BRIDGE SIMULATION ---");

        // Directed Test Vector Executions
        ahb_write(32'h0000_0010, 32'hDEAD_BEEF);
        ahb_read(32'h0000_0010, 32'h0000_0010 + 32'hA5A5_0000);

        ahb_write(32'h0000_0020, 32'h1234_5678);
        ahb_read(32'h0000_0020, 32'h0000_0020 + 32'hA5A5_0000);

        #100;
        $display("\n==================================================");
        $display("   TESTBENCH EXECUTION COMPLETE");
        $display("   Matches: %0d | Mismatches: %0d", match_count, error_count);
        $display("==================================================\n");
        $finish;
    end

endmodule