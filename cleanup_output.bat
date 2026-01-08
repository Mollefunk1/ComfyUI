@echo off
REM Quick ComfyUI Output Cleanup
REM This batch file runs the PowerShell cleanup script

echo.
echo ===============================================
echo    ComfyUI Output Folder Quick Cleanup
echo ===============================================
echo.

REM Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0cleanup_output.ps1" %*

pause