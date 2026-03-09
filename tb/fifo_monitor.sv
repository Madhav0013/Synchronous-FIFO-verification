// ============================================================
// File: tb/fifo_monitor.sv
// Description: Observes DUT interface and captures transactions
// ============================================================

`include "fifo_txn.sv"

class fifo_monitor;

    virtual fifo_if #(.DATA_WIDTH(8)) vif;

    // Mailbox to send observed transactions to scoreboard
    mailbox #(fifo_txn) mon2scb;

    // --------------------------------------------------------
    // Constructor
    // --------------------------------------------------------
    function new(virtual fifo_if #(.DATA_WIDTH(8)) _vif,
                 mailbox #(fifo_txn) _mon2scb);
        vif     = _vif;
        mon2scb = _mon2scb;
    endfunction

    // --------------------------------------------------------
    // Task: run
    // Continuously monitors the interface and captures
    // any transaction where wr_en or rd_en is active
    // --------------------------------------------------------
    task run();
        fifo_txn txn;
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.wr_en || vif.monitor_cb.rd_en) begin
                txn           = new();
                txn.wr_en     = vif.monitor_cb.wr_en;
                txn.rd_en     = vif.monitor_cb.rd_en;
                txn.data_in   = vif.monitor_cb.data_in;
                txn.data_out  = vif.monitor_cb.data_out;
                txn.full      = vif.monitor_cb.full;
                txn.empty     = vif.monitor_cb.empty;
                txn.overflow  = vif.monitor_cb.overflow;
                txn.underflow = vif.monitor_cb.underflow;
                mon2scb.put(txn);  // Send to scoreboard
            end
        end
    endtask

endclass
