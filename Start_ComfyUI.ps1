# ComfyUI PowerShell Launcher
# Alternative PowerShell script to start ComfyUI

param(
    [switch]$CPU,
    [switch]$Verbose,
    [int]$Port = 8188,
    [string]$Listen = "127.0.0.1"
)

Write-Host "🎨 ComfyUI PowerShell Launcher" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Get the ComfyUI directory (where this script is located)
$ComfyUIPath = $PSScriptRoot
$VenvPython = Join-Path $ComfyUIPath "venv\Scripts\python.exe"
$MainScript = Join-Path $ComfyUIPath "main.py"

# Check if required files exist
if (-not (Test-Path $VenvPython)) {
    Write-Host "❌ Error: Virtual environment not found!" -ForegroundColor Red
    Write-Host "Expected: $VenvPython" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path $MainScript)) {
    Write-Host "❌ Error: main.py not found!" -ForegroundColor Red
    Write-Host "Expected: $MainScript" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 1
}

# Display startup information
Write-Host "📁 ComfyUI Directory: $ComfyUIPath" -ForegroundColor Blue
Write-Host "🐍 Python: $VenvPython" -ForegroundColor Blue
Write-Host "🌐 Web Interface: http://$Listen`:$Port" -ForegroundColor Green

# Build command arguments
$Arguments = @($MainScript)

if ($CPU) {
    $Arguments += "--cpu"
    Write-Host "⚠️  CPU Mode: GPU acceleration disabled" -ForegroundColor Yellow
} else {
    Write-Host "⚡ GPU Mode: CUDA acceleration enabled" -ForegroundColor Green
}

if ($Port -ne 8188) {
    $Arguments += "--port", $Port
}

if ($Listen -ne "127.0.0.1") {
    $Arguments += "--listen", $Listen
}

if ($Verbose) {
    $Arguments += "--verbose"
}

# Enable ComfyUI Manager by default
$Arguments += "--enable-manager"

Write-Host ""
Write-Host "🚀 Starting ComfyUI..." -ForegroundColor Green
Write-Host "💡 To stop: Press Ctrl+C or close this window" -ForegroundColor Blue
Write-Host ""

# Start ComfyUI
try {
    & $VenvPython @Arguments
} catch {
    Write-Host "❌ Error starting ComfyUI: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "ComfyUI has stopped." -ForegroundColor Yellow
Read-Host "Press Enter to exit"