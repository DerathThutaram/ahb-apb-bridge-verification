class driver;

    virtual bridge_if.DRV vif;
    mailbox #(transaction) mbx;
    transaction tr;

    function new(virtual bridge_if.DRV vif, mailbox #(transaction) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    // Reset Task
    task reset();
        $display("[DRV] Resetting AHB Interface...");
        vif.drv_cb.HSEL    <= 1'b0;
        vif.drv_cb.HADDR   <= '0;
        vif.drv_cb.HWDATA  <= '0;
        vif.drv_cb.HWRITE  <= 1'b0;
        vif.drv_cb.HTRANS  <= 2'b00; // IDLE
    endtask

    // Main Drive Loop
    task main();
        forever begin
            mbx.get(tr);
            
            // Wait for positive edge of HCLK via clocking block
            @(vif.drv_cb);
            vif.drv_cb.HSEL   <= 1'b1;
            vif.drv_cb.HADDR  <= tr.addr;
            vif.drv_cb.HWRITE <= tr.write;
            vif.drv_cb.HTRANS <= tr.trans;

            // Data phase
            @(vif.drv_cb);
            if (tr.write) begin
                vif.drv_cb.HWDATA <= tr.data;
            end

            // Wait for HREADYout from DUT
            wait(vif.drv_cb.HREADYout == 1'b1);
            
            // Return interface to IDLE state
            vif.drv_cb.HSEL   <= 1'b0;
            vif.drv_cb.HTRANS <= 2'b00;
            $display("[DRV] Driven transaction to AHB bus complete");
        end
    endtask

endclass