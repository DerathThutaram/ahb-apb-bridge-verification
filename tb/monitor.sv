class monitor;

    virtual bridge_if.MON vif;
    mailbox #(transaction) mbx;
    transaction tr;

    function new(virtual bridge_if.MON vif, mailbox #(transaction) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task main();
        forever begin
            tr = new();

            // Wait for active AHB transfer
            @(vif.mon_cb);
            wait(vif.mon_cb.HSEL && vif.mon_cb.HTRANS[1]);

            // Sample Address Phase
            tr.addr  = vif.mon_cb.HADDR;
            tr.write = vif.mon_cb.HWRITE;
            tr.trans = vif.mon_cb.HTRANS;

            // Wait for Data/Control Phase
            @(vif.mon_cb);
            if (tr.write) begin
                tr.data = vif.mon_cb.HWDATA;
            end else begin
                // Wait for APB enable phase & PREADY to sample read data
                wait(vif.mon_cb.PENABLE && vif.mon_cb.PREADY);
                tr.rdata = vif.mon_cb.PRDATA;
            end

            // Send sampled transaction to Scoreboard
            mbx.put(tr.copy());
            $display("[MON] Captured transaction on bus");
        end
    endtask

endclass