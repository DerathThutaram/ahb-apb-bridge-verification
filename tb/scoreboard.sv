class scoreboard;

    mailbox #(transaction) mbx;
    transaction tr;

    // Reference Model: Associative Array acting as Ideal Peripheral Memory
    logic [31:0] ref_mem [logic [31:0]];

    int match_count = 0;
    int error_count = 0;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction

    task main();
        forever begin
            mbx.get(tr);

            if (tr.write) begin
                // Store expected data into reference memory
                ref_mem[tr.addr] = tr.data;
                $display("[SCOREBOARD] WRITE CHECK: Stored 0x%0h at Address 0x%0h", tr.data, tr.addr);
            end else begin
                // Read Phase: Check if address exists in reference memory
                if (ref_mem.exists(tr.addr)) begin
                    if (ref_mem[tr.addr] == tr.rdata) begin
                        $display("[SCOREBOARD] PASS! Read Data Match: Expected 0x%0h | Actual 0x%0h at Addr 0x%0h", 
                                  ref_mem[tr.addr], tr.rdata, tr.addr);
                        match_count++;
                    end else begin
                        $error("[SCOREBOARD] FAIL! Read Mismatch: Expected 0x%0h | Actual 0x%0h at Addr 0x%0h", 
                               ref_mem[tr.addr], tr.rdata, tr.addr);
                        error_count++;
                    end
                end else begin
                    $display("[SCOREBOARD] READ NOTICE: Reading unwritten address 0x%0h", tr.addr);
                end
            end
        end
    endtask

endclass