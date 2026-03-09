# Synchronous FIFO Verification Project

![Verified](https://img.shields.io/badge/Verification-Complete-success.svg)
![Language](https://img.shields.io/badge/SystemVerilog-IEEE%201800--2012-blue.svg)
![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog%20%7C%20Questa-orange.svg)

A complete, end-to-end SystemVerilog verification environment for a parameterized Synchronous FIFO (First-In-First-Out) buffer. This project demonstrates industry-standard verification practices including a self-checking testbench architecture, functional coverage, SystemVerilog Assertions (SVA), reference model checking, and randomized stimulus generation.

---

## 📌 Project Architecture & Features

This repository verifies a custom RTL generic Synchronous FIFO module (`sync_fifo.sv`). The verification environment is built from scratch utilizing an object-oriented, UVM-inspired methodology.

### Key Verification Components:
- **DUT**: Parameterized Circular Buffer FIFO (`DATA_WIDTH=8`, `DEPTH=16`) with `full`, `empty`, `overflow`, and `underflow` flags.
- **Reference Model**: A self-checking software queue (`ref_queue`) embedded in the testbench dynamically predicts expected DUT behavior in real-time.
- **Transaction-Level Environment**: Modular verification components including a `fifo_driver`, `fifo_monitor`, `fifo_scoreboard`, and `fifo_txn` transaction class.
- **Behavioral Assertions**: 6 robust concurrent property checkers ensuring RTL temporal safety (iverilog-safe via `always` blocks in `fifo_checker.sv`, and strict SVA via `fifo_assertions_questa.sv`).
- **Functional Coverage**: Comprehensive covergroups tracking critical scenarios like cross-coverage of simultaneous reads/writes, extreme pointer bounds, and corner-case flag triggering (`fifo_coverage.sv`).
- **Constrained Random Testing**: An automated 200-cycle pseudo-random test sequence designed to hammer the DUT interface with back-to-back rapid-fire operations, rigorously validating data integrity.

---

## 📋 Verified Test Scenarios

The testbench executes a full suite of directed tests followed by the random test array. All scenarios result in **0 Scoreboard Mismatches**:

1. **Reset Initialization**: Verifies default states (`empty=1`, `full=0`, pointers reset).
2. **Basic Read/Write Tracking**: Validates data order preservation (First-In, First-Out).
3. **Full Condition Triggering**: Fills FIFO to `DEPTH` and checks `full` assertion.
4. **Empty Sequence Drain**: Empties FIFO and checks `empty` assertion.
5. **Overflow Violations**: Intentionally writes to a full FIFO; checks 1-cycle `overflow` assertion.
6. **Underflow Violations**: Intentionally reads from an empty FIFO; checks 1-cycle `underflow` assertion.
7. **Simultaneous Read/Write**: Asserts `wr_en` and `rd_en` concurrently on a partially full FIFO; ensures count stability and data reliability.
8. **Pointer Wrap-Around**: Executes a double fill/drain cycle to force the read/write discrete pointers to wrap past `DEPTH-1` bounds safely.
9. **200-Cycle Randomized Stress Test**: Completely randomized operational stimulus verified cycle-by-cycle against the software queue reference model.

---

## 🛠️ Repository Structure

```text
fifo_verification/
├── rtl/
│   └── sync_fifo.sv                   ← Synchronous FIFO Design (DUT)
├── tb/
│   ├── tb_top.sv                      ← Testbench Top Module
│   ├── fifo_txn.sv                    ← Transaction Class
│   ├── fifo_driver.sv                 ← BFM Driver component
│   ├── fifo_monitor.sv                ← BFM Monitor component 
│   ├── fifo_scoreboard.sv             ← Reference Model Scoreboard
│   ├── fifo_env.sv                    ← Verification Environment Structure
│   ├── fifo_checker.sv                ← Icarus-compatible assertions
│   ├── fifo_assertions_questa.sv      ← SystemVerilog Assertions (SVA)
│   └── fifo_coverage.sv               ← Functional Covergroups
├── sim/
│   └── fifo_waves.vcd                 ← Value Change Dump waveform output
├── docs/
│   ├── spec.md                        ← Design Specification Sheet
│   ├── interview_prep.md              ← Project Q&A and Engineering writeups
│   └── waveform_*.png                 ← Snapshot Evidence of verified states
└── results/
    ├── test_log.txt                   ← Raw Simulator StdOut log
    └── summary.md                     ← Simulation Results Markdown summary
```

---

## 🚀 How to Run the Simulation

This testbench is strictly hardened for full compatibility across multi-state open-source simulators like **Icarus Verilog**, as well as commercial powerhouses like **Questa/ModelSim**.

### Option A: Using Icarus Verilog (`iverilog`)

```bash
# 1. Compile the DUT, Checker, and Top module into an executable
iverilog -I tb -g2012 -o sim/fifo_sim rtl/sync_fifo.sv tb/fifo_checker.sv tb/tb_top.sv

# 2. Run the executable through the vvp runtime
vvp sim/fifo_sim | tee results/test_log.txt

# 3. View the generated waveforms
gtkwave sim/fifo_waves.vcd
```

### Option B: Using Questa / ModelSim (Includes SVA & Coverage)

```bash
# 1. Compile the full standard SystemVerilog environment
vlog +sv rtl/sync_fifo.sv \
         tb/fifo_if.sv tb/fifo_txn.sv \
         tb/fifo_driver.sv tb/fifo_monitor.sv \
         tb/fifo_scoreboard.sv tb/fifo_env.sv \
         tb/fifo_checker.sv tb/fifo_assertions_questa.sv tb/fifo_coverage.sv \
         tb/tb_top.sv

# 2. Execute and track code coverage
vsim tb_top -do "run -all; quit"
```

---

## 📊 Results Summary

* **Architecture**: RTL successfully synthesized and behaviorally modeled.
* **Test Vectors**: 9 separate architectural tests passed.
* **Property Checkers**: 6 rigorous pipeline checks instantiated & 0 infractions detected.
* **Random Testing**: 200/200 scoreboard queue hits strictly aligned.

*(For detailed execution logs, see `results/summary.md` and `results/test_log.txt`)*
