## ------------------------------------------------------------
## File    : run_cov_marge.ps1
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## ------------------------------------------------------------

Write-Host "=== Coverage merge start ==="

$CovDir      = "result/cov"
$MergeDir    = "result/covmerge"
$MergedUcdb  = "$MergeDir/merged.ucdb"

if (!(Test-Path $MergeDir)) {
    New-Item -ItemType Directory $MergeDir | Out-Null
}

$ucdbList = Get-ChildItem "$CovDir/*.ucdb"

if ($ucdbList.Count -eq 0) {
    Write-Host "No UCDB files found."
    exit 0
}

$vcoverCmd = "vcover merge $MergedUcdb"

foreach ($ucdb in $ucdbList) {
    $vcoverCmd += " $($ucdb.FullName)"
}

Write-Host "CMD: $vcoverCmd"
Invoke-Expression $vcoverCmd

Write-Host "=== Coverage merge end ==="
