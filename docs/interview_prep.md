# Interview Preparation

## Resume Bullets

• Designed and verified a parameterized synchronous FIFO in SystemVerilog using
  a self-checking testbench with directed and 200-cycle randomized stimulus;
  achieved zero scoreboard failures across all 9 test scenarios.

• Built a UVM-style verification environment (driver, monitor, scoreboard,
  coverage collector) with a software reference queue for automated result
  checking; verified reset, full, empty, overflow, underflow, simultaneous
  R/W, and pointer wrap-around corner cases.

• Authored 8 SVA assertions and 6 behavioral property checkers; debugged a
  registered-output sampling race condition by analyzing VCD waveforms in GTKWave.

## Interview Q&A — Key Points

| Question | Answer to give |
|----------|---------------|
| What bug did you find? | A race condition in the testbench: `data_out` is a registered output so it appears one clock cycle after `rd_en`. The original `checked_read` task was sampling `data_out` in the same cycle as `rd_en` instead of waiting one cycle. Found with waveform analysis. Fixed with a two-phase task. |
| What is the difference between `\|->` and `\|=>`? | `\|->` checks in the same clock cycle as the trigger. `\|=>` checks one cycle later. Example: `overflow \|-> (wr_en && full)` means overflow and its cause must be true at the same time. |
| Why do you disable assertions during reset? | During reset, signals are in a known invalid state. The assertion condition might evaluate to a failure not because the DUT is broken but because the design is being reset. `disable iff (!rst_n)` prevents false failures. |
| What is functional coverage? | Manually written coverpoints that track whether specific scenarios were exercised. Unlike code coverage (which is automatic), functional coverage captures design intent. Example: write active, FIFO full, overflow occurred. |
| What is a scoreboard? | A component that maintains a software model of the DUT. On every observed write, it pushes expected data to a queue. On every observed read, it pops from the queue and compares against `data_out`. Any mismatch is reported automatically. |
