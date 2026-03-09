# Synchronous FIFO Specification

## Parameters
- DATA_WIDTH: 8 bits
- DEPTH: 16 entries

## Interface Signals

### Inputs
| Signal       | Width | Description                        |
|--------------|-------|------------------------------------|
| clk          | 1     | System clock (rising edge active)  |
| rst_n        | 1     | Active-low synchronous reset       |
| wr_en        | 1     | Write enable                       |
| rd_en        | 1     | Read enable                        |
| data_in      | 8     | Data to write into FIFO            |

### Outputs
| Signal       | Width | Description                        |
|--------------|-------|------------------------------------|
| data_out     | 8     | Data read from FIFO                |
| full         | 1     | FIFO is full, no more writes       |
| empty        | 1     | FIFO is empty, no valid reads      |
| overflow     | 1     | Write attempted when full          |
| underflow    | 1     | Read attempted when empty          |

## Functional Requirements

1. After reset, FIFO must be empty (empty=1, full=0, count=0).
2. A write is accepted only when wr_en=1 AND full=0.
3. A read is accepted only when rd_en=1 AND empty=0.
4. Writing when full must assert overflow=1 for one clock cycle.
5. Reading when empty must assert underflow=1 for one clock cycle.
6. Data must come out in the same order it was written (FIFO order).
7. Simultaneous read and write when neither full nor empty must keep count stable.
8. Write and read pointers must wrap around correctly after reaching DEPTH-1.
9. The count register must never exceed DEPTH or go below 0.

## Corner Cases to Verify
- Reset
- Write-only until full
- Read-only until empty
- Overflow (write when full)
- Underflow (read when empty)
- Simultaneous read and write
- Pointer wrap-around
- Back-to-back writes and reads
