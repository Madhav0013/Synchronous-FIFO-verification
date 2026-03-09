// ============================================================
// File: tb/fifo_env.sv
// Description: Environment that wires all TB components together
// ============================================================

`include "fifo_driver.sv"
`include "fifo_monitor.sv"
`include "fifo_scoreboard.sv"

class fifo_env;

    fifo_driver    driver;
    fifo_monitor   monitor;
    fifo_scoreboard scoreboard;

    mailbox #(fifo_txn) mon2scb;

    virtual fifo_if #(.DATA_WIDTH(8)) vif;

    // --------------------------------------------------------
    // Constructor
    // --------------------------------------------------------
    function new(virtual fifo_if #(.DATA_WIDTH(8)) _vif);
        vif    = _vif;
        mon2scb = new();
    endfunction

    // --------------------------------------------------------
    // Function: build
    // Constructs all components with correct connections
    // --------------------------------------------------------
    function void build();
        driver     = new(vif);
        monitor    = new(vif, mon2scb);
        scoreboard = new(mon2scb);
    endfunction

    // --------------------------------------------------------
    // Task: run
    // Starts monitor and scoreboard in parallel threads
    // --------------------------------------------------------
    task run();
        fork
            monitor.run();
            scoreboard.run();
        join_none
    endtask

    // --------------------------------------------------------
    // Function: report
    // --------------------------------------------------------
    function void report();
        scoreboard.report();
    endfunction

endclass
