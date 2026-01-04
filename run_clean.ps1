## ------------------------------------------------------------
## File    : run_clean.ps1
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## ------------------------------------------------------------

Write-Host "=== Questa cleanup start ==="

$root = Get-Location

# ---------------------------------
# 0. Remove modelsim.ini / transcript
# ---------------------------------
$topFiles = @(
    "modelsim.ini",
    "transcript"
)

foreach ($f in $topFiles) {
    $path = Join-Path $root $f
    if (Test-Path $path) {
        Write-Host "Removing file: $path"
        Remove-Item $path -Force
    }
}

# ---------------------------------
# 1. Remove tmp/lib
# ---------------------------------
$tmpLib = Join-Path $root "tmp\lib"
if (Test-Path $tmpLib) {
    Write-Host "Removing directory: $tmpLib"
    Remove-Item $tmpLib -Recurse -Force
}

# ---------------------------------
# 2. Remove files under result
# ---------------------------------
$resultDirs = @(
    "result\cov",
    "result\covmerge",
    "result\log",
    "result\wave"
)

foreach ($dir in $resultDirs) {
    $fullPath = Join-Path $root $dir
    if (Test-Path $fullPath) {
        Write-Host "Cleaning files in: $fullPath"
        Get-ChildItem $fullPath -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                Write-Host "  Removing file: $($_.Name)"
                Remove-Item $_.FullName -Force
            }
    }
}

Write-Host "=== Questa cleanup done ==="
