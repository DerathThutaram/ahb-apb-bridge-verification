`include "tb/transaction.sv"
`include "tb/generator.sv"
`include "tb/driver.sv"
`include "tb/monitor.sv"
`include "tb/scoreboard.sv"
`include "tb/coverage.sv"

class environment;

    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard scb;
    coverage   cov;

    mailbox #(transaction) gen2drv_mbx;
    mailbox #(transaction) mon2scb_mbx;

    virtual bridge_if vif;

    function new(virtual bridge_if vif);
        this.vif = vif;
        gen2drv_mbx = new();
        mon2scb_mbx = new();

        gen = new(gen2drv_mbx);
        drv = new(vif.DRV, gen2drv_mbx);
        mon = new(vif.MON, mon2scb_mbx);
        scb = new(mon2scb_mbx);
        cov = new();
    endfunction

    task test();
        fork
            gen.main();
            drv.main();
            mon.main();
            scb.main();
        join_any
    endtask

    task post_test();
        wait(gen.done.triggered);
        #100;
        $display("\n==================================================");
        $display("   TESTBENCH EXECUTION COMPLETE");
        $display("   Matches: %0d | Mismatches: %0d", scb.match_count, scb.error_count);
        $display("==================================================\n");
        $finish;
    endtask

    task run();
        fork
            test();
            post_test();
        join
    endtask

endclass