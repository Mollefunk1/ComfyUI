# ComfyUI Simple Cleanup Script
Write-Host 'Cleaning ComfyUI output folder...' -ForegroundColor Cyan
Remove-Item 'output\*' -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Output folder cleaned!' -ForegroundColor Green
Write-Host 'Starting ComfyUI...' -ForegroundColor Yellow
& 'venv\Scripts\python.exe' main.py
