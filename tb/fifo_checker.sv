// ============================================================
// File: tb/fifo_checker.sv
// Description: Behavioral property checker — iverilog compatible
//              (Replaces SVA for iverilog environments)
// ============================================================

module fifo_checker #(
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

    // Track previous rst_n to detect rising edge
    logic rst_n_prev;
    always @(posedge clk) rst_n_prev <= rst_n;

    // --------------------------------------------------------
    // CHECK 1: One cycle after reset release, FIFO must be empty
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n_prev === 1'b0 && rst_n === 1'b1) begin
            // Wait one cycle to check empty
            @(posedge clk);
            if (empty !== 1'b1)
                $display("CHK FAIL [%0t]: CHECK 1 — empty should be 1 after reset", $time);
        end
    end

    // --------------------------------------------------------
    // CHECK 2: full and empty must never both be 1
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n === 1'b1) begin
            if (full === 1'b1 && empty === 1'b1)
                $display("CHK FAIL [%0t]: CHECK 2 — full and empty both asserted simultaneously",
                          $time);
        end
    end

    // --------------------------------------------------------
    // CHECK 3: overflow must only occur when wr_en=1 AND full=1
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n === 1'b1) begin
            if (overflow === 1'b1 && !(wr_en === 1'b1 && full === 1'b1))
                $display("CHK FAIL [%0t]: CHECK 3 — overflow asserted without wr_en && full",
                          $time);
        end
    end

    // --------------------------------------------------------
    // CHECK 4: underflow must only occur when rd_en=1 AND empty=1
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n === 1'b1) begin
            if (underflow === 1'b1 && !(rd_en === 1'b1 && empty === 1'b1))
                $display("CHK FAIL [%0t]: CHECK 4 — underflow asserted without rd_en && empty",
                          $time);
        end
    end

    // --------------------------------------------------------
    // CHECK 5: writing when full must not reduce count
    //          (checked as: full stays high if only writing)
    // --------------------------------------------------------
    logic full_prev;
    always @(posedge clk) full_prev <= full;

    always @(posedge clk) begin
        if (rst_n === 1'b1) begin
            if (full_prev === 1'b1 && wr_en === 1'b1 && rd_en === 1'b0) begin
                if (full !== 1'b1)
                    $display("CHK FAIL [%0t]: CHECK 5 — full dropped on write-only when full",
                              $time);
            end
        end
    end

    // --------------------------------------------------------
    // CHECK 6: reading when empty must not change empty
    // --------------------------------------------------------
    logic empty_prev;
    always @(posedge clk) empty_prev <= empty;

    always @(posedge clk) begin
        if (rst_n === 1'b1) begin
            if (empty_prev === 1'b1 && rd_en === 1'b1 && wr_en === 1'b0) begin
                if (empty !== 1'b1)
                    $display("CHK FAIL [%0t]: CHECK 6 — empty dropped on read-only when empty",
                              $time);
            end
        end
    end

endmodule
