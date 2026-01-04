## ------------------------------------------------------------
## File    : run_cov_report.ps1
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## ------------------------------------------------------------

Write-Host "=== make coverage report  ==="

$vcoverReport = @"
vcover report \
    -html \
    -output result/covmerge/html \
    $MergedUcdb
"@

Write-Host $vcoverReport
Invoke-Expression $vcoverReport
