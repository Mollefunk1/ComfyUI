<#
rename_seq.ps1
Sequential file renamer for Windows (PowerShell)

Usage: Run the script and follow prompts.
- Input path
- Input prefix (press Enter for none)
- Input start number (press Enter for 1)
- Preview file-names and confirm or abort namechange.
- Script does a collision-safe two-pass rename and opens the folder on completion

Notes:
- Files are ordered by LastWriteTimeUtc (then CreationTimeUtc, then Name) to match generation order.
- Renames preserve file contents (no re-encoding) so PNG metadata stays intact.
- The script uses a temp-stage (append .tmp.<GUID>) to avoid clobbering.
#>

Set-StrictMode -Version Latest

function Prompt-ForFolder {
    while ($true) {
        $p = Read-Host -Prompt 'Path to folder (or press Enter to cancel)'
        if ([string]::IsNullOrWhiteSpace($p)) {
            Write-Host 'Cancelled by user.' -ForegroundColor Yellow
            exit 1
        }
        # normalize and accept quoted paths like "C:\path\to\folder" or 'C:\path\to\folder'
        $p = $p.Trim()
        $p = $p.Trim('"', "'")
        if (Test-Path -LiteralPath $p -PathType Container) { Write-Host "Using path: $p" -ForegroundColor Cyan; return (Get-Item -LiteralPath $p).FullName }
        Write-Host "Path not found or not a folder: $p" -ForegroundColor Red
    }
}

function Prompt-ForPrefix {
    $pref = Read-Host -Prompt 'Prefix for filenames (press Enter for none)'
    if ($null -eq $pref) { $pref = '' }
    $pref = $pref.Trim()
    Write-Host "Prefix set to: '$pref'" -ForegroundColor Cyan
    return $pref
}

function Prompt-ForStartNumber {
    $input = Read-Host -Prompt 'Start number (default 1)'
    $input = $input.Trim()
    if ([string]::IsNullOrWhiteSpace($input)) { return 1 }
    $val = 0
    if (-not [int]::TryParse($input, [ref]$val)) {
        Write-Warning "Invalid number. Defaulting to 1."
        return 1
    }
    if ($val -lt 0) { Write-Warning "Start must be >= 0. Defaulting to 1."; return 1 }
    return $val
}

function Confirm-YesNo([string]$message) {
    $r = Read-Host -Prompt "$message`nType 'Y' to confirm"
    return ($r -eq 'Y' -or $r -eq 'y')
}

# Main
$folder = Prompt-ForFolder
$prefix = Prompt-ForPrefix
$start = Prompt-ForStartNumber

Write-Host "Scanning files in: $folder (ordering: alphabetical by filename)" -ForegroundColor Cyan
$files = Get-ChildItem -LiteralPath $folder -File |
    Sort-Object @{Expression={ $_.Name.ToLowerInvariant() }}

if ($files.Count -eq 0) {
    Write-Host 'No files found in folder. Exiting.' -ForegroundColor Yellow
    exit 0
}

# Compute padding width
$maxIndex = $start + $files.Count - 1
$width = $maxIndex.ToString().Length

# Build mapping
$mappings = @()
$idx = $start
foreach ($f in $files) {
    $padded = $idx.ToString().PadLeft($width, '0')
    # Ensure we have a safe basename (some providers may not populate BaseName)
    $baseName = if ($f.BaseName) { $f.BaseName } else { [System.IO.Path]::GetFileNameWithoutExtension($f.Name) }
    $finalName = "$prefix$padded$($f.Extension)"
    $tempName  = "$baseName.tmp.$([guid]::NewGuid().ToString())$($f.Extension)"
    $mappings += [PSCustomObject]@{
        OriginalName = $f.Name
        OriginalFullPath = $f.FullName
        TempName = $tempName
        FinalName = $finalName
        OriginalObject = $f
        Index = $idx
    }
    $idx++
}

# Preview
Write-Host "Preview of renames (showing first 100 rows):" -ForegroundColor Green
$mappings | Select-Object Index, OriginalName, FinalName | Format-Table -AutoSize

if (-not (Confirm-YesNo 'Proceed with the above renaming?')) {
    Write-Host 'Aborted by user.' -ForegroundColor Yellow
    exit 0
}

# Phase 1: rename to temp names
$renamedTemps = @()
$phase1Errors = @()
foreach ($m in $mappings) {
    try {
        Rename-Item -LiteralPath $m.OriginalFullPath -NewName $m.TempName -ErrorAction Stop
        $renamedTemps += $m
    } catch {
        $phase1Errors += [PSCustomObject]@{ Mapping = $m; Error = $_.Exception.Message }
        Write-Host "Failed to rename $($m.OriginalName) -> temp: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($phase1Errors.Count -gt 0) {
    Write-Host "Errors occurred during temp renames. Attempting rollback for successful renames..." -ForegroundColor Yellow
    foreach ($m in $renamedTemps) {
        $tempFull = Join-Path $folder $m.TempName
        if (Test-Path -LiteralPath $tempFull) {
            try { Rename-Item -LiteralPath $tempFull -NewName $m.OriginalName -ErrorAction Stop }
            catch { Write-Host "Rollback failed for $($m.TempName): $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
    Write-Host 'Aborting due to phase1 errors.' -ForegroundColor Red
    exit 1
}

# Safety check: ensure no conflicts for final names (e.g., a file exists already that is not in our mapping)
$existingConflicts = @()
foreach ($m in $mappings) {
    $finalFull = Join-Path $folder $m.FinalName
    # If a file with this final name exists and it is NOT one of our temp names, it's a conflict
    if (Test-Path -LiteralPath $finalFull) {
        # if it's one of the temps, ignore
        $isTemp = $false
        foreach ($t in $mappings) { if ($t.TempName -eq $m.FinalName) { $isTemp = $true; break } }
        if (-not $isTemp) { $existingConflicts += $m.FinalName }
    }
}

if ($existingConflicts.Count -gt 0) {
    Write-Host 'Detected existing files that would conflict with final names:' -ForegroundColor Red
    $existingConflicts | ForEach-Object { Write-Host " - $_" }
    Write-Host 'Attempting rollback...' -ForegroundColor Yellow
    foreach ($m in $mappings) {
        $tempFull = Join-Path $folder $m.TempName
        if (Test-Path -LiteralPath $tempFull) {
            try { Rename-Item -LiteralPath $tempFull -NewName $m.OriginalName -ErrorAction Stop }
            catch { Write-Host "Rollback failed for $($m.TempName): $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
    Write-Host 'Aborted due to final-name conflicts.' -ForegroundColor Red
    exit 1
}

# Phase 2: rename temps to final names
$phase2Errors = @()
$phase2Success = @()
foreach ($m in $mappings) {
    $tempFull = Join-Path $folder $m.TempName
    $finalName = $m.FinalName
    try {
        if (-not (Test-Path -LiteralPath $tempFull)) {
            throw "Temp file missing: $tempFull"
        }
        Rename-Item -LiteralPath $tempFull -NewName $finalName -ErrorAction Stop
        $phase2Success += $m
    } catch {
        $phase2Errors += [PSCustomObject]@{ Mapping = $m; Error = $_.Exception.Message }
        Write-Host "Failed to rename temp $($m.TempName) -> $($finalName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
$total = $mappings.Count
$successCount = $phase2Success.Count
Write-Host "\nRenaming complete. Success: $successCount / $total" -ForegroundColor Green
if ($phase2Errors.Count -gt 0) {
    Write-Host "Failures: $($phase2Errors.Count). See details below:" -ForegroundColor Red
    $phase2Errors | ForEach-Object { Write-Host "- $($_.Mapping.OriginalName) -> $($_.Mapping.FinalName): $($_.Error)" }
}

# Write log
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$logPath = Join-Path $folder "rename_seq_log_$timestamp.txt"
"Renamer run on $(Get-Date)`nFolder: $folder`nPrefix: $prefix`nStart: $start`nTotal: $total`nSuccess: $successCount`nFailures: $($phase2Errors.Count)`n`nMappings:`n" | Out-File -FilePath $logPath -Encoding UTF8
foreach ($m in $mappings) {
    "$($m.OriginalName) -> $($m.FinalName)" | Out-File -FilePath $logPath -Encoding UTF8 -Append
}
if ($phase2Errors.Count -gt 0) {
    "`nErrors:`n" | Out-File -FilePath $logPath -Encoding UTF8 -Append
    foreach ($e in $phase2Errors) { "- $($e.Mapping.OriginalName) -> $($e.Mapping.FinalName): $($e.Error)" | Out-File -FilePath $logPath -Encoding UTF8 -Append }
}

Write-Host "Log written to: $logPath" -ForegroundColor Cyan

# Open folder
try { Start-Process explorer.exe -ArgumentList $folder } catch { Invoke-Item $folder }

Write-Host 'Done.' -ForegroundColor Green
