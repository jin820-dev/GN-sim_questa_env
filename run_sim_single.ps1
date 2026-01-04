## ------------------------------------------------------------
## File    : run_sim_single.ps1
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## ------------------------------------------------------------

# Show
Write-Output ""
Write-Output "=== run.ps1 start ==="
Write-Output "DUT_ROOT : $env:DUT_ROOT"
Write-Output "MDL_ROOT : $env:MDL_ROOTS"
Write-Output "SEED     : $env:SEED"
Write-Output "TESTMODE : $env:TEST_MODE"
Write-Output "TESTLIST : $TEST_LIST"
Write-Output "GUI      : $env:ENABLE_GUI"
Write-Output "Wave     : $env:ENABLE_WAVE"
Write-Output "Coverage : $env:ENABLE_COV"

Write-Output "=== Run scenario: $scn ==="
if ($env:ENABLE_GUI -eq "1") {
    vsim -do "source tcl/default.tcl" 
} else {
    vsim -c -do "source tcl/default.tcl" 
}

Write-Host "=== run_sim_single.ps1 end ==="
Write-Host ""