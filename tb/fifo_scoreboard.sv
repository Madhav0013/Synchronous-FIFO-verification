// ============================================================
// File: tb/fifo_scoreboard.sv
// Description: Compares DUT output against reference model
// ============================================================

`include "fifo_txn.sv"

class fifo_scoreboard;

    mailbox #(fifo_txn) mon2scb;

    // Reference queue (software FIFO model)
    logic [7:0] ref_queue [$];

    // Counters
    int pass_count = 0;
    int fail_count = 0;

    // --------------------------------------------------------
    // Constructor
    // --------------------------------------------------------
    function new(mailbox #(fifo_txn) _mon2scb);
        mon2scb = _mon2scb;
    endfunction

    // --------------------------------------------------------
    // Task: run
    // Gets transactions from monitor and checks them
    // --------------------------------------------------------
    task run();
        fifo_txn txn;
        forever begin
            mon2scb.get(txn);
            check(txn);
        end
    endtask

    // --------------------------------------------------------
    // Task: check
    // --------------------------------------------------------
    task check(fifo_txn txn);
        // Handle write
        if (txn.wr_en && !txn.full) begin
            ref_queue.push_back(txn.data_in);
        end

        // Handle overflow
        if (txn.wr_en && txn.full) begin
            if (txn.overflow) begin
                $display("SCB PASS: overflow correctly set");
                pass_count++;
            end else begin
                $display("SCB FAIL: expected overflow=1, got overflow=%b", txn.overflow);
                fail_count++;
            end
        end

        // Handle read
        if (txn.rd_en && !txn.empty) begin
            if (ref_queue.size() > 0) begin
                logic [7:0] expected = ref_queue.pop_front();
                if (txn.data_out === expected) begin
                    $display("SCB PASS: data_out=%0h matches expected=%0h",
                              txn.data_out, expected);
                    pass_count++;
                end else begin
                    $display("SCB FAIL: data_out=%0h MISMATCH expected=%0h",
                              txn.data_out, expected);
                    fail_count++;
                end
            end
        end

        // Handle underflow
        if (txn.rd_en && txn.empty) begin
            if (txn.underflow) begin
                $display("SCB PASS: underflow correctly set");
                pass_count++;
            end else begin
                $display("SCB FAIL: expected underflow=1, got underflow=%b", txn.underflow);
                fail_count++;
            end
        end
    endtask

    // --------------------------------------------------------
    // Function: report
    // Call at end of simulation to print summary
    // --------------------------------------------------------
    function void report();
        $display("==============================================");
        $display("  SCOREBOARD RESULTS");
        $display("  PASS: %0d  |  FAIL: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("  STATUS: ALL CHECKS PASSED");
        else
            $display("  STATUS: *** FAILURES DETECTED ***");
        $display("==============================================");
    endfunction

endclass
