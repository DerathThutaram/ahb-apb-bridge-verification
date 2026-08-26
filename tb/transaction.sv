class transaction;

    // Randomizable Fields
    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic        write;
    rand logic [1:0]  trans;

    // Output Signal Storage (for Scoreboard Sampling)
    logic [31:0] rdata;
    logic        error;

    // Protocol Constraints
    constraint c_addr  { addr inside {[32'h0000_0000 : 32'h0000_00FF]}; } // Restrict to valid memory region
    constraint c_trans { trans inside {2'b10, 2'b11}; }                 // NONSEQ (2'b10) or SEQ (2'b11)

    // Function to Print Transaction Details
    function void display(string tag = "");
        $display("[%0s] ADDR: 0x%0h | DATA: 0x%0h | WRITE: %0b | TRANS: %0b | RDATA: 0x%0h", 
                  tag, addr, data, write, trans, rdata);
    endfunction

    // Deep Copy Method
    function transaction copy();
        transaction copy_tr = new();
        copy_tr.addr  = this.addr;
        copy_tr.data  = this.data;
        copy_tr.write = this.write;
        copy_tr.trans = this.trans;
        copy_tr.rdata = this.rdata;
        return copy_tr;
    endfunction

endclass