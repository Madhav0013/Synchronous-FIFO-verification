# Synchronous FIFO Verification Project

Complete SystemVerilog verification environment for a parameterized
synchronous FIFO. Demonstrates RTL design, self-checking testbench,
scoreboard-based checking, behavioral assertions, functional coverage,
and randomized testing.

## Parameters
DATA_WIDTH=8, DEPTH=16

## How to Run (iverilog)

```bash
iverilog -I tb -g2012 -o sim/fifo_sim rtl/sync_fifo.sv tb/tb_top.sv
vvp sim/fifo_sim | tee results/test_log.txt
gtkwave sim/fifo_waves.vcd
```

## Tests
Reset, Write/Read, Full, Empty, Overflow, Underflow,
Simultaneous R/W, Pointer Wrap-Around, Random (200 cycles)

## Verification Components
- Self-checking testbench with software reference queue
- fifo_checker.sv — 6 behavioral property checks (iverilog safe)
- fifo_assertions_questa.sv — 8 SVA properties (Questa/VCS)
- fifo_coverage.sv — Functional coverpoints for all key scenarios
- Driver, Monitor, Scoreboard, Environment (UVM-style structure)

## Results
47 checks — 0 failures. 100% functional coverage (Questa).
