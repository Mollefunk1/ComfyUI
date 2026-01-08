@echo off
REM ComfyUI Desktop Shortcut Creator
REM Run this to create a desktop shortcut for easy access

echo.
echo ===============================================
echo       Creating ComfyUI Desktop Shortcut
echo ===============================================
echo.

set "ComfyUIPath=%~dp0"
set "BatchFile=%ComfyUIPath%Start_ComfyUI.bat"
set "DesktopPath=%USERPROFILE%\Desktop"
set "ShortcutName=ComfyUI - AI Image Generator.lnk"

REM Check if the batch file exists
if not exist "%BatchFile%" (
    echo ❌ Error: Start_ComfyUI.bat not found!
    echo Please make sure this script is in the ComfyUI directory.
    pause
    exit /b 1
)

REM Create the shortcut using PowerShell
echo 🔧 Creating desktop shortcut...

powershell -Command ^
"$WshShell = New-Object -comObject WScript.Shell; ^
$Shortcut = $WshShell.CreateShortcut('%DesktopPath%\%ShortcutName%'); ^
$Shortcut.TargetPath = '%BatchFile%'; ^
$Shortcut.WorkingDirectory = '%ComfyUIPath%'; ^
$Shortcut.Description = 'Start ComfyUI AI Image Generator with GPU acceleration'; ^
$Shortcut.Save()"

if exist "%DesktopPath%\%ShortcutName%" (
    echo ✅ Desktop shortcut created successfully!
    echo 📁 Location: %DesktopPath%\%ShortcutName%
    echo.
    echo 🎉 You can now double-click the shortcut on your desktop to start ComfyUI!
) else (
    echo ❌ Failed to create desktop shortcut.
)

echo.
pause