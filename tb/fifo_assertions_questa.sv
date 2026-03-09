// ============================================================
// File: tb/fifo_assertions_questa.sv
// Description: SVA properties for sync_fifo
// QUESTA / VCS ONLY — do NOT compile with iverilog
// To use: add this file to the compile command in Questa/VCS
//         and instantiate in tb_top.sv
// ============================================================

module fifo_assertions_questa #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input logic                  clk,
    input logic                  rst_n,
    input logic                  wr_en,
    input logic                  rd_en,
    input logic [DATA_WIDTH-1:0] data_in,
    input logic [DATA_WIDTH-1:0] data_out,
    input logic                  full,
    input logic                  empty,
    input logic                  overflow,
    input logic                  underflow
);

    // After reset releases, empty must be 1 next cycle
    property p_reset_empty;
        @(posedge clk) $rose(rst_n) |=> empty;
    endproperty
    assert property (p_reset_empty)
        else $error("SVA FAIL: empty not 1 after reset");

    // full and empty never both 1
    property p_no_full_and_empty;
        @(posedge clk) disable iff (!rst_n)
        not (full && empty);
    endproperty
    assert property (p_no_full_and_empty)
        else $error("SVA FAIL: full and empty both 1");

    // overflow only when wr_en AND full
    property p_overflow_cause;
        @(posedge clk) disable iff (!rst_n)
        overflow |-> (wr_en && full);
    endproperty
    assert property (p_overflow_cause)
        else $error("SVA FAIL: overflow without wr_en && full");

    // underflow only when rd_en AND empty
    property p_underflow_cause;
        @(posedge clk) disable iff (!rst_n)
        underflow |-> (rd_en && empty);
    endproperty
    assert property (p_underflow_cause)
        else $error("SVA FAIL: underflow without rd_en && empty");

    // full stays 1 on write-only
    property p_full_stable;
        @(posedge clk) disable iff (!rst_n)
        (full && wr_en && !rd_en) |=> full;
    endproperty
    assert property (p_full_stable)
        else $error("SVA FAIL: full dropped on write-only");

    // empty stays 1 on read-only
    property p_empty_stable;
        @(posedge clk) disable iff (!rst_n)
        (empty && rd_en && !wr_en) |=> empty;
    endproperty
    assert property (p_empty_stable)
        else $error("SVA FAIL: empty dropped on read-only");

    // overflow is a one-cycle pulse
    property p_overflow_pulse;
        @(posedge clk) disable iff (!rst_n)
        overflow |=> !overflow || (wr_en && full);
    endproperty
    assert property (p_overflow_pulse)
        else $error("SVA FAIL: overflow did not clear");

    // underflow is a one-cycle pulse
    property p_underflow_pulse;
        @(posedge clk) disable iff (!rst_n)
        underflow |=> !underflow || (rd_en && empty);
    endproperty
    assert property (p_underflow_pulse)
        else $error("SVA FAIL: underflow did not clear");

endmodule
