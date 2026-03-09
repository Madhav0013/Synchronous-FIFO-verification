// ============================================================
// File: tb/fifo_driver.sv
// Description: Drives transactions onto the fifo_if interface
// ============================================================

`include "fifo_txn.sv"

class fifo_driver;

    virtual fifo_if #(.DATA_WIDTH(8)) vif;  // Virtual interface handle

    // --------------------------------------------------------
    // Constructor
    // --------------------------------------------------------
    function new(virtual fifo_if #(.DATA_WIDTH(8)) _vif);
        vif = _vif;
    endfunction

    // --------------------------------------------------------
    // Task: reset
    // Drives rst_n low for N cycles then releases
    // --------------------------------------------------------
    task reset(int cycles = 4);
        vif.driver_cb.rst_n   <= 1'b0;
        vif.driver_cb.wr_en   <= 1'b0;
        vif.driver_cb.rd_en   <= 1'b0;
        vif.driver_cb.data_in <= '0;
        repeat(cycles) @(vif.driver_cb);
        vif.driver_cb.rst_n <= 1'b1;
        @(vif.driver_cb);
        $display("[DRIVER] Reset complete");
    endtask

    // --------------------------------------------------------
    // Task: drive
    // Drives one transaction on the interface for one cycle
    // --------------------------------------------------------
    task drive(fifo_txn txn);
        @(vif.driver_cb);
        vif.driver_cb.wr_en   <= txn.wr_en;
        vif.driver_cb.rd_en   <= txn.rd_en;
        vif.driver_cb.data_in <= txn.data_in;
        @(vif.driver_cb);  // let signals settle
        // Deassert
        vif.driver_cb.wr_en <= 1'b0;
        vif.driver_cb.rd_en <= 1'b0;
    endtask

endclass
