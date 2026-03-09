// ============================================================
// File: tb/fifo_txn.sv
// Description: Transaction class for FIFO operations
// ============================================================

class fifo_txn;

    // Operation fields
    rand logic        wr_en;
    rand logic        rd_en;
    rand logic [7:0]  data_in;

    // Observed output fields (filled by monitor)
    logic [7:0]  data_out;
    logic        full;
    logic        empty;
    logic        overflow;
    logic        underflow;

    // --------------------------------------------------------
    // Constraints: prevent simultaneous overflow+underflow
    // --------------------------------------------------------
    // No constraint on wr_en or rd_en individually —
    // the DUT handles all cases. Constraints added in subclasses
    // if specific scenarios are needed.

    // --------------------------------------------------------
    // Constructor
    // --------------------------------------------------------
    function new();
        wr_en   = 0;
        rd_en   = 0;
        data_in = 0;
    endfunction

    // --------------------------------------------------------
    // Print method for debug
    // --------------------------------------------------------
    function void print(string tag = "TXN");
        $display("[%s] wr_en=%b rd_en=%b data_in=%0h | data_out=%0h full=%b empty=%b overflow=%b underflow=%b",
            tag, wr_en, rd_en, data_in, data_out, full, empty, overflow, underflow);
    endfunction

endclass
