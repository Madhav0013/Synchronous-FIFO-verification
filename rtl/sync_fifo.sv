// ============================================================
// File: rtl/sync_fifo.sv
// Description: Parameterized Synchronous FIFO
// Parameters:
//   DATA_WIDTH - width of each data word (default 8)
//   DEPTH      - number of entries in FIFO (default 16)
// ============================================================

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  full,
    output logic                  empty,
    output logic                  overflow,
    output logic                  underflow
);

    // --------------------------------------------------------
    // Internal signals
    // --------------------------------------------------------
    // DEPTH pointer bits need $clog2(DEPTH)+1 bits to detect wrap
    localparam PTR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];  // Memory array
    logic [PTR_WIDTH-1:0]  wr_ptr;           // Write pointer
    logic [PTR_WIDTH-1:0]  rd_ptr;           // Read pointer
    logic [PTR_WIDTH:0]    count;            // Number of valid entries

    // --------------------------------------------------------
    // Status flags
    // --------------------------------------------------------
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // --------------------------------------------------------
    // Write logic
    // --------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr   <= '0;
            overflow <= 1'b0;
        end else begin
            overflow <= 1'b0;  // Default: clear overflow each cycle
            if (wr_en) begin
                if (!full) begin
                    mem[wr_ptr] <= data_in;
                    wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1;
                end else begin
                    overflow    <= 1'b1;  // Write attempted when full
                end
            end
        end
    end

    // --------------------------------------------------------
    // Read logic
    // --------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr    <= '0;
            data_out  <= '0;
            underflow <= 1'b0;
        end else begin
            underflow <= 1'b0;  // Default: clear underflow each cycle
            if (rd_en) begin
                if (!empty) begin
                    data_out <= mem[rd_ptr];
                    rd_ptr   <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1;
                end else begin
                    underflow <= 1'b1;  // Read attempted when empty
                end
            end
        end
    end

    // --------------------------------------------------------
    // Count logic
    // wr_en valid = wr_en AND NOT full
    // rd_en valid = rd_en AND NOT empty
    // Simultaneous valid read and write = count stays same
    // --------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count <= '0;
        end else begin
            case ({(wr_en && !full), (rd_en && !empty)})
                2'b10:   count <= count + 1;  // Write only
                2'b01:   count <= count - 1;  // Read only
                2'b11:   count <= count;      // Simultaneous read and write
                default: count <= count;      // No operation
            endcase
        end
    end

endmodule
