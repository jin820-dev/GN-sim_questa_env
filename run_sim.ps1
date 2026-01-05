## ------------------------------------------------------------
## File    : run_sim.ps1
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## 2026-01-05  Added simulation result summarization feature
## ------------------------------------------------------------

param (
    [string]$DutRoot,   # DUT Root Directory
    [string] $s,        # seed value
    [switch] $t,        # default testlist
    [switch] $a,        # all test mode
    [switch] $g,        # GUI
    [switch] $w,        # wave
    [switch] $c         # coverage
)

# Error Check
if (-not $DutRoot) {
    Write-Error "DutRoot is required"
    exit 1
}

# default value
$env:DUT_ROOT       = $DutRoot
$env:SEED           = 1
$env:TEST_MODE      = "nomral"
$env:ENABLE_GUI     = 0
$env:ENABLE_WAVE    = 0
$env:ENABLE_COV     = 0
$TEST_LIST          = Get-Content "$DutRoot\sim\testlist.txt"

# read model list
$mdlListFile = "$DutRoot/sim/mdllist.txt"
$MdlRootDirs = @()
foreach ($mdl in Get-Content $mdlListFile) {
    $dir = "../$mdl"
    if (Test-Path $dir) {
        $MdlRootDirs += (Resolve-Path $dir).Path
    } else {
        Write-Warning "Model dir not found: $dir"
    }
}
$env:MDL_ROOTS = ($MdlRootDirs -join ";")
Write-Host "Using models: $env:MDL_ROOTS"

# Update
if ($s) { $env:SEED          = $s }
if ($g) { $env:ENABLE_GUI    = 1 }
if ($w) { $env:ENABLE_WAVE   = 1 }
if ($c) { $env:ENABLE_COV    = 1 }
if ($a) {
    $env:TEST_MODE  = "all"
    $TEST_LIST      = Get-Content "$DutRoot\sim\testlist_all.txt"
} else {
    $env:TEST_MODE  = "normal"
    $TEST_LIST      = Get-Content "$DutRoot\sim\testlist.txt"
}

# Log directory
$env:LOG_DIR  = "result\log"

# launch vsim
foreach ($scn in $TEST_LIST) {
    if ($scn.Trim() -eq "") { continue }
    Write-Host "=== Run scenario: $scn ==="
    $env:SCENARIO = $scn

    # run
    .\run_sim_single.ps1 | Tee-Object -FilePath "$env:LOG_DIR\$scn.log"

}

Write-Host "=== run_sim.ps1 end ==="
Write-Host ""

# result summarize
Write-Host "=== Summarizing simulation logs ==="
py -3 .\tcl\summarize_questa_logs.py ".\$env:LOG_DIR\*.log"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Some tests FAILED"
    exit 1
} else {
    Write-Host "All tests PASSED"
    exit 0
}
