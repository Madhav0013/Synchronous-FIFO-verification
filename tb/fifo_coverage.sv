// ============================================================
// File: tb/fifo_coverage.sv
// Description: Functional coverage for sync_fifo
// ============================================================

class fifo_coverage;

    // Covergroup: samples key scenarios on every transaction
    covergroup fifo_cg;

        // Was write enabled?
        cp_wr_en: coverpoint wr_en_v {
            bins write_active   = {1};
            bins write_inactive = {0};
        }

        // Was read enabled?
        cp_rd_en: coverpoint rd_en_v {
            bins read_active   = {1};
            bins read_inactive = {0};
        }

        // Was FIFO full when a write occurred?
        cp_full: coverpoint full_v {
            bins fifo_full     = {1};
            bins fifo_not_full = {0};
        }

        // Was FIFO empty when a read occurred?
        cp_empty: coverpoint empty_v {
            bins fifo_empty     = {1};
            bins fifo_not_empty = {0};
        }

        // Did overflow occur?
        cp_overflow: coverpoint overflow_v {
            bins overflow_occurred  = {1};
            bins no_overflow        = {0};
        }

        // Did underflow occur?
        cp_underflow: coverpoint underflow_v {
            bins underflow_occurred = {1};
            bins no_underflow       = {0};
        }

        // Cross coverage: simultaneous read and write
        cp_rw_cross: cross cp_wr_en, cp_rd_en;

    endgroup

    // Signal variables (sampled from interface each cycle)
    logic wr_en_v, rd_en_v, full_v, empty_v, overflow_v, underflow_v;

    // --------------------------------------------------------
    // Constructor — create the covergroup
    // --------------------------------------------------------
    function new();
        fifo_cg = new();
    endfunction

    // --------------------------------------------------------
    // Task: sample
    // Call this every clock cycle with current signal values
    // --------------------------------------------------------
    task sample(
        input logic wr_en,
        input logic rd_en,
        input logic full,
        input logic empty,
        input logic overflow,
        input logic underflow
    );
        wr_en_v    = wr_en;
        rd_en_v    = rd_en;
        full_v     = full;
        empty_v    = empty;
        overflow_v = overflow;
        underflow_v = underflow;
        fifo_cg.sample();
    endtask

    // --------------------------------------------------------
    // Function: report
    // Prints coverage percentage at end of simulation
    // --------------------------------------------------------
    function void report();
        $display("==============================================");
        $display("  FUNCTIONAL COVERAGE REPORT");
        $display("  fifo_cg coverage: %0.2f%%", fifo_cg.get_coverage());
        $display("==============================================");
    endfunction

endclass
