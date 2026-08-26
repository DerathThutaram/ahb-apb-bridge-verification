class coverage;

    transaction tr;

    covergroup bridge_cg;
        option.per_instance = 1;

        // Cover write vs read transfers
        cp_write: coverpoint tr.write {
            bins write_op = {1'b1};
            bins read_op  = {1'b0};
        }

        // Cover transaction types
        cp_trans: coverpoint tr.trans {
            bins nonseq = {2'b10};
            bins seq    = {2'b11};
        }

        // Cross coverage between write/read and transaction types
        cross_write_trans: cross cp_write, cp_trans;
    endgroup

    function new();
        bridge_cg = new();
    endfunction

    function void sample(transaction tr);
        this.tr = tr;
        bridge_cg.sample();
    endfunction

endclass