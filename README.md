# GN-sim_questa_env
Simulation environment for **Questa Prime Lite** (PowerShell based)

- Simulator: Questa Prime Lite
- Language: PowerShell / Tcl / Python
- License: MIT

## Overview
This repository provides a **script-driven simulation environment**
for running SystemVerilog-based verification on **Questa Prime Lite**
under Windows.

The environment is designed with the following principles:
- One simulation run per test scenario
- One log file per scenario
- Final Pass / Fail decision based on log analysis

This approach emphasizes **repeatability, debuggability, and simplicity**
over monolithic batch simulation.

## Requirements
- Questa Prime Lite
- PowerShell (Windows)
- Python 3.x (for result summarization)

## Features
- Script-based simulation control (PowerShell)
- Support for multiple test scenarios
- Batch and single-scenario execution
- Optional GUI execution
- Waveform dump control
- Clean-up utilities for simulation artifacts
- Coverage collection (limited in Questa Prime Lite)
- **Log-based Pass / Fail summarization**

> Note:
> Coverage merge and report scripts are included,
> but they are not verified on Questa Prime Lite.
> Full coverage features may require the commercial version.

## Directory Structure
```
.
├─ run_sim.ps1            # Run simulations using test lists
├─ run_sim_single.ps1     # Run a single test scenario
├─ run_clean.ps1          # Remove temporary and result files
├─ run_cov_merge.ps1      # Merge coverage databases (not verified)
├─ run_cov_report.ps1     # Generate coverage reports (not verified)
│
├─ tcl/
│   ├─ compile.tcl        # Compilation flow
│   ├─ sim.tcl            # Simulation control
│   ├─ default.tcl        # Default simulation sequence
│   └─ dumpmisc.tcl       # Wave / signal dump settings
│   └─ summarize_questa_logs.py  # Simulation result summarizer
│
├─ result/
│   ├─ log/               # Simulation logs
│   ├─ wave/              # Waveform files
│   ├─ cov/               # Coverage databases
│   └─ covmerge/          # Merged coverage results
│
├─ tmp/                   # Temporary simulation files
│
├─ LICENSE
└─ README.md
```

## Usage

### Run specified test list
```powershell
.\run_sim.ps1 <DUT_ROOT> -t
```

### Run all tests with waveform and coverage enabled
```powershell
.\run_sim.ps1 <DUT_ROOT> -a -w -c
```

### Run simulation in GUI mode
```powershell
.\run_sim.ps1 <DUT_ROOT> -g
```

Each test scenario is executed independently, and its output
is stored as a dedicated log file under result/log/.

## Result Summarization

After all simulations are completed, test results can be summarized
by parsing the generated log files:

``` powershell
py -3 tcl/summarize_questa_logs.py result/log/*.log
```

This generates:
- A console summary table
- result/summary.csv for further analysis

## Pass / Fail Criteria
A test scenario is judged as FAILED if any of the following is detected
in its log file:
- [TEST] RESULT=FAIL tag
- [SCB] TEST FAILED reported by a scoreboard
- Simulator-reported runtime errors (Errors > 0), including SVA violations

## Notes
- This environment is optimized for Questa Prime Lite limitations.
- Each test scenario is isolated to simplify failure analysis.
- Python is used only for post-processing and does not affect simulation.
- The environment is intended for functional and protocol verification.

## License
This project is licensed under the MIT License.


