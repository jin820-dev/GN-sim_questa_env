# GN-sim_questa_env
Simulation environment for Questa Prime Lite (PowerShell based)

- Simulator: Questa Prime Lite
- Language: ps1 / tcl
- License: MIT

## Overview
This repository provides a simulation environment for
**Questa Prime Lite**.

It is designed to run SystemVerilog-based verification
using a script-driven flow on Windows, focusing on
repeatability and simplicity.

## Requirements
- Questa Prime Lite
- PowerShell (Windows)

## Features
- Script-based simulation control (PowerShell)
- Support for multiple test scenarios
- Batch and single-scenario execution
- Optional GUI execution
- Waveform dump control
- Clean-up utilities for simulation artifacts
- Coverage collection (limited in Questa Prime Lite)

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

The simulation environment supports multiple DUTs and
verification models by specifying their root directories
via script arguments or environment variables.

## License
This project is licensed under the MIT License.


