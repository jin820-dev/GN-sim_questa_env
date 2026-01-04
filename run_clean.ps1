## ------------------------------------------------------------
## File    : run_clean.ps1
## Author  : jin820
## Created : 2026-01-01
## Updated :
## History:
## 2026-01-01  Initial version
## 2026-01-04  Added DryRun function
## ------------------------------------------------------------

param(
    [switch]$Force
)

# DryRun is default unless -Force is specified
$DryRun = -not $Force

Write-Host "=== Questa cleanup start ==="
Write-Host "Mode: " -NoNewline
if ($DryRun) {
    Write-Host "DRY-RUN (no files will be deleted)" -ForegroundColor Yellow
} else {
    Write-Host "FORCE (files will be deleted)" -ForegroundColor Red
}

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
        if ($DryRun) {
            Write-Host "  [DRYRUN] Would remove file: $path"
        } else {
            Write-Host "  Removing file: $path"
            Remove-Item $path -Force
        }
    }
}

# ---------------------------------
# 1. Remove tmp/lib
# ---------------------------------
$tmpLib = Join-Path $root "tmp\lib"
if (Test-Path $tmpLib) {
    if ($DryRun) {
        Write-Host "  [DRYRUN] Would remove directory: $tmpLib"
    } else {
        Write-Host "  Removing directory: $tmpLib"
        Remove-Item $tmpLib -Recurse -Force
    }
}

# ---------------------------------
# 2. Remove files under result (keep .gitkeep)
# ---------------------------------
$resultDirs = @(
    "result\cov",
    "result\covmerge",
    "result\log",
    "result\wave"
)

foreach ($dir in $resultDirs) {
    $fullPath = Join-Path $root $dir
    if (-not (Test-Path $fullPath)) {
        continue
    }

    Write-Host "Cleaning files in: $fullPath"

    $targets = Get-ChildItem $fullPath -Recurse -File -Force -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -ne ".gitkeep" }

    if ($targets.Count -eq 0) {
        Write-Host "  (No files to delete)"
        continue
    }

    foreach ($t in $targets) {
        if ($DryRun) {
            Write-Host "  [DRYRUN] Would remove file: $($t.FullName)"
        } else {
            Write-Host "  Removing file: $($t.FullName)"
            Remove-Item $t.FullName -Force
        }
    }

    # Optional: remove empty subdirectories (except root)
    if (-not $DryRun) {
        Get-ChildItem $fullPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Where-Object {
                $_.FullName -ne $fullPath -and
                (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0
            } |
            Remove-Item -Force
    }
}

Write-Host "=== Questa cleanup done ==="
