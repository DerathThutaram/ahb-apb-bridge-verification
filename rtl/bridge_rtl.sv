module bridge_rtl (
    input  logic        HCLK,
    input  logic        HRESETn,
    input  logic        HSEL,
    input  logic [31:0] HADDR,
    input  logic [31:0] HWDATA,
    input  logic        HWRITE,
    input  logic [1:0]  HTRANS,
    output logic [31:0] HRDATA,
    output logic        HREADYout,

    // APB Signals
    output logic        PSEL,
    output logic        PENABLE,
    output logic        PWRITE,
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    input  logic [31:0] PRDATA,
    input  logic        PREADY
);

    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        SETUP  = 2'b01,
        ENABLE = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Internal Registers for Pipeline Phase
    logic [31:0] addr_reg;
    logic        write_reg;

    // State Transition
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            current_state <= IDLE;
            addr_reg      <= '0;
            write_reg     <= '0;
        end else begin
            current_state <= next_state;
            if (HSEL && HTRANS[1] && (current_state == IDLE)) begin
                addr_reg  <= HADDR;
                write_reg <= HWRITE;
            end
        end
    end

    // Next State Logic & Output Control
    always_comb begin
        next_state = current_state;
        PSEL       = 1'b0;
        PENABLE    = 1'b0;
        HREADYout  = 1'b1;

        case (current_state)
            IDLE: begin
                if (HSEL && HTRANS[1]) begin
                    next_state = SETUP;
                end
            end

            SETUP: begin
                PSEL       = 1'b1;
                PENABLE    = 1'b0;
                HREADYout  = 1'b0;
                next_state = ENABLE;
            end

            ENABLE: begin
                PSEL       = 1'b1;
                PENABLE    = 1'b1;
                HREADYout  = PREADY;
                if (PREADY) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    assign PADDR  = addr_reg;
    assign PWRITE = write_reg;
    assign PWDATA = HWDATA;
    assign HRDATA = PRDATA;

endmodule