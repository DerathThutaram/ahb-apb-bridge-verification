class generator;

    transaction tr;
    mailbox #(transaction) mbx;
    int count = 10; // Number of transactions to generate
    event done;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    task main();
        for (int i = 0; i < count; i++) begin
            tr = new();
            if (!tr.randomize()) begin
                $fatal("Generator: Randomization failed!");
            end
            mbx.put(tr.copy());
            $display("[GEN] Transaction %0d generated and sent to Driver", i + 1);
        end
        -> done;
    endtask

endclass