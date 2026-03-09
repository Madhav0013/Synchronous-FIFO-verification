// ============================================================
// File: tb/tb_top.sv
// Description: Self-checking testbench for sync_fifo
// iverilog-compatible (no SVA, no inline variable declarations)
// ============================================================

`timescale 1ns/1ps

module tb_top;

    // --------------------------------------------------------
    // Parameters
    // --------------------------------------------------------
    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;
    localparam CLK_PERIOD = 10;

    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    logic                  clk;
    logic                  rst_n;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;
    logic                  full;
    logic                  empty;
    logic                  overflow;
    logic                  underflow;

    // --------------------------------------------------------
    // All variables declared here — NOT inside begin blocks
    // This is required for iverilog compatibility
    // --------------------------------------------------------
    logic [DATA_WIDTH-1:0] ref_queue [$];    // Reference model queue
    logic [DATA_WIDTH-1:0] rd_expected;      // Expected read value
    integer                pass_count;
    integer                fail_count;
    integer                i;                // General loop variable
    integer                wr_val;           // Write value in loops

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_en     (wr_en),
        .rd_en     (rd_en),
        .data_in   (data_in),
        .data_out  (data_out),
        .full      (full),
        .empty     (empty),
        .overflow  (overflow),
        .underflow (underflow)
    );

    // --------------------------------------------------------
    // Plain-always checker (iverilog-safe replacement for SVA)
    // --------------------------------------------------------
    fifo_checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) checker_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_en     (wr_en),
        .rd_en     (rd_en),
        .data_in   (data_in),
        .data_out  (data_out),
        .full      (full),
        .empty     (empty),
        .overflow  (overflow),
        .underflow (underflow)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // --------------------------------------------------------
    // VCD waveform dump
    // --------------------------------------------------------
    initial begin
        $dumpfile("sim/fifo_waves.vcd");
        $dumpvars(0, tb_top);
    end

    // --------------------------------------------------------
    // Task: reset_dut
    // --------------------------------------------------------
    task reset_dut;
        begin
            rst_n   = 1'b0;
            wr_en   = 1'b0;
            rd_en   = 1'b0;
            data_in = 8'h00;
            ref_queue = {};   // clear reference queue on reset
            repeat(4) @(posedge clk);
            #1;
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    // --------------------------------------------------------
    // Task: do_write
    // Drives wr_en for one cycle.
    // If write is accepted (not full), also pushes to ref queue.
    // --------------------------------------------------------
    task do_write;
        input [7:0] data;
        begin
            @(posedge clk); #1;
            wr_en   = 1'b1;
            data_in = data;
            @(posedge clk); #1;
            // Capture full BEFORE deasserting (full is sampled this cycle)
            if (!full) begin
                ref_queue.push_back(data);
            end
            wr_en = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // Task: checked_read
    // FIX v2: Two-phase read.
    //   Phase 1 — drive rd_en=1 for one clock
    //   Phase 2 — on the NEXT posedge, sample data_out
    //             (data_out is a registered output, 1-cycle latency)
    // --------------------------------------------------------
    task checked_read;
        begin
            @(posedge clk); #1;
            rd_en = 1'b1;
            @(posedge clk); #1;
            // data_out is now valid — sample it
            rd_en = 1'b0;

            if (ref_queue.size() > 0) begin
                rd_expected = ref_queue.pop_front();
                if (data_out === rd_expected) begin
                    $display("PASS: data_out=0x%02h  expected=0x%02h", data_out, rd_expected);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: data_out=0x%02h  expected=0x%02h  *** MISMATCH ***",
                              data_out, rd_expected);
                    fail_count = fail_count + 1;
                end
            end else begin
                // queue empty — underflow expected
                if (underflow === 1'b1) begin
                    $display("PASS: underflow correctly asserted on empty read");
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: read on empty — underflow expected but not seen");
                    fail_count = fail_count + 1;
                end
            end
        end
    endtask

    // --------------------------------------------------------
    // Task: print_summary
    // --------------------------------------------------------
    task print_summary;
        begin
            $display("==============================================");
            $display("  FINAL RESULTS: %0d PASS  |  %0d FAIL",
                      pass_count, fail_count);
            if (fail_count == 0)
                $display("  STATUS: ALL TESTS PASSED");
            else
                $display("  STATUS: *** FAILURES — CHECK LOG ***");
            $display("==============================================");
        end
    endtask

    // --------------------------------------------------------
    // Timeout watchdog
    // --------------------------------------------------------
    initial begin
        #100000;
        $display("ERROR: Simulation timeout at %0t", $time);
        $finish;
    end

    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==============================================");
        $display("  Sync FIFO Full Test Suite");
        $display("==============================================");

        // --------------------------------------------------
        // TEST 1: Reset
        // --------------------------------------------------
        $display("\n--- TEST 1: Reset ---");
        reset_dut();
        @(posedge clk); #1;
        if (empty === 1'b1 && full === 1'b0 &&
            overflow === 1'b0 && underflow === 1'b0) begin
            $display("PASS: Reset flags correct (empty=1 full=0 overflow=0 underflow=0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Reset flags wrong — empty=%b full=%b overflow=%b underflow=%b",
                      empty, full, overflow, underflow);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // TEST 2: Basic write/read (order preservation)
        // --------------------------------------------------
        $display("\n--- TEST 2: Basic Write/Read ---");
        reset_dut();
        do_write(8'hAA);
        do_write(8'hBB);
        do_write(8'hCC);
        do_write(8'hDD);
        checked_read();  // expect AA
        checked_read();  // expect BB
        checked_read();  // expect CC
        checked_read();  // expect DD

        // --------------------------------------------------
        // TEST 3: Full condition
        // --------------------------------------------------
        $display("\n--- TEST 3: Full Condition ---");
        reset_dut();
        for (i = 0; i < DEPTH; i = i + 1) begin
            do_write(i[7:0]);
        end
        @(posedge clk); #1;
        if (full === 1'b1) begin
            $display("PASS: full=1 after %0d writes", DEPTH);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: full=%b after %0d writes", full, DEPTH);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // TEST 4: Empty condition
        // --------------------------------------------------
        $display("\n--- TEST 4: Empty Condition ---");
        reset_dut();
        do_write(8'h01);
        do_write(8'h02);
        do_write(8'h03);
        checked_read();
        checked_read();
        checked_read();
        @(posedge clk); #1;
        if (empty === 1'b1) begin
            $display("PASS: empty=1 after draining all entries");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: empty=%b after draining", empty);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // TEST 5: Overflow
        // --------------------------------------------------
        $display("\n--- TEST 5: Overflow ---");
        reset_dut();
        for (i = 0; i < DEPTH; i = i + 1) begin
            do_write(i[7:0]);
        end
        // Now write one more — must trigger overflow
        @(posedge clk); #1;
        wr_en   = 1'b1;
        data_in = 8'hFF;
        @(posedge clk); #1;
        wr_en = 1'b0;
        if (overflow === 1'b1) begin
            $display("PASS: overflow=1 on write when full");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: overflow=%b — expected 1", overflow);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // TEST 6: Underflow
        // --------------------------------------------------
        $display("\n--- TEST 6: Underflow ---");
        reset_dut();
        // Read from empty FIFO
        @(posedge clk); #1;
        rd_en = 1'b1;
        @(posedge clk); #1;
        rd_en = 1'b0;
        if (underflow === 1'b1) begin
            $display("PASS: underflow=1 on read when empty");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: underflow=%b — expected 1", underflow);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // TEST 7: Simultaneous read and write
        // --------------------------------------------------
        $display("\n--- TEST 7: Simultaneous Read/Write ---");
        reset_dut();
        do_write(8'h11);
        do_write(8'h22);
        do_write(8'h33);
        // Drive wr_en and rd_en in the same cycle
        @(posedge clk); #1;
        wr_en   = 1'b1;
        rd_en   = 1'b1;
        data_in = 8'h44;
        // Track: one read (pops 0x11), one write (pushes 0x44)
        rd_expected = ref_queue.pop_front(); // consume 0x11 from ref model
        ref_queue.push_back(8'h44);   // add 0x44 to ref model
        @(posedge clk); #1;
        wr_en = 1'b0;
        rd_en = 1'b0;
        // data_out should be 0x11 (sampled one cycle after rd_en)
        if (data_out === 8'h11) begin
            $display("PASS: Simultaneous R/W — data_out=0x11 correct");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Simultaneous R/W — data_out=0x%02h, expected=0x11", data_out);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // TEST 8: Pointer wrap-around
        // --------------------------------------------------
        $display("\n--- TEST 8: Pointer Wrap-Around ---");
        reset_dut();
        // First fill and drain — advances pointers to wrap zone
        for (i = 0; i < DEPTH; i = i + 1) do_write(8'hA0 + i[7:0]);
        for (i = 0; i < DEPTH; i = i + 1) checked_read();
        // Second fill and drain — pointers must wrap correctly
        for (i = 0; i < DEPTH; i = i + 1) do_write(8'hB0 + i[7:0]);
        for (i = 0; i < DEPTH; i = i + 1) checked_read();
        @(posedge clk); #1;
        if (empty === 1'b1) begin
            $display("PASS: Wrap-around — FIFO empty after double fill/drain");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Wrap-around — empty=%b after double fill/drain", empty);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // TEST 9: Random test (200 cycles)
        // FIX v2: ref_queue tracking happens BEFORE clock edge
        //         data_out sampled on the cycle AFTER rd_en
        // --------------------------------------------------
        $display("\n--- TEST 9: Random Test (200 cycles) ---");
        reset_dut();

        for (i = 0; i < 200; i = i + 1) begin
            // Generate pseudo-random stimulus
            wr_val  = ($urandom % 2);
            rd_en   = ($urandom % 2);
            wr_en   = wr_val[0];
            data_in = $urandom % 256;

            // Update reference model BEFORE clock edge
            // Write is accepted when wr_en=1 AND not full
            if (wr_en === 1'b1 && full === 1'b0)
                ref_queue.push_back(data_in);

            // Check for overflow (wr_en when full)
            if (wr_en === 1'b1 && full === 1'b1) begin
                // overflow will be checked on next clock
            end

            // Flag whether a valid read is expected this cycle
            // (rd_en=1 AND not empty AND queue has data)

            @(posedge clk); #1;

            // Now check results that landed on this posedge
            if (rd_en === 1'b1 && empty === 1'b0) begin
                // data_out is now updated — compare
                if (ref_queue.size() > 0) begin
                    rd_expected = ref_queue.pop_front();
                    if (data_out === rd_expected) begin
                        pass_count = pass_count + 1;
                    end else begin
                        $display("RAND FAIL [cycle %0d]: data_out=0x%02h expected=0x%02h",
                                  i, data_out, rd_expected);
                        fail_count = fail_count + 1;
                    end
                end
            end

            // Deassert for next iteration
            wr_en = 1'b0;
            rd_en = 1'b0;
        end
        $display("Random test complete.");

        // --------------------------------------------------
        // Final summary
        // --------------------------------------------------
        print_summary();
        #50;
        $finish;
    end

endmodule
