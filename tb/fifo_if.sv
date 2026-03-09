// ============================================================
// File: tb/fifo_if.sv
// Description: SystemVerilog interface for sync_fifo signals
// ============================================================

interface fifo_if #(
    parameter DATA_WIDTH = 8
)(
    input logic clk
);
    logic                  rst_n;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;
    logic                  full;
    logic                  empty;
    logic                  overflow;
    logic                  underflow;

    // Clocking block for driver: signals driven synchronously
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output rst_n, wr_en, rd_en, data_in;
        input  data_out, full, empty, overflow, underflow;
    endclocking

    // Clocking block for monitor: observes all signals
    clocking monitor_cb @(posedge clk);
        default input #1;
        input rst_n, wr_en, rd_en, data_in;
        input data_out, full, empty, overflow, underflow;
    endclocking

endinterface
