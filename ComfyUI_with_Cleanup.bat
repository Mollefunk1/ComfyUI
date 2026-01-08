@echo off
REM Quick ComfyUI with Auto-Cleanup
REM This starts ComfyUI and includes a cleanup option when you're done

echo.
echo ===============================================
echo     ComfyUI with Smart Cleanup Option
echo ===============================================
echo.

REM Start ComfyUI
echo 🚀 Starting ComfyUI...
echo 🌐 Web interface: http://127.0.0.1:8188
echo.
call "%~dp0Start_ComfyUI.bat"

echo.
echo ===============================================
echo              ComfyUI Cleanup
echo ===============================================
echo.

REM Ask if user wants to cleanup
set /p cleanup="🧹 Do you want to clean up generated images? (y/N): "

if /i "%cleanup%"=="y" (
    echo.
    echo 🗑️  Running cleanup...
    call "%~dp0cleanup_output.bat"
) else (
    echo ✅ Cleanup skipped. Generated images preserved.
)

echo.
echo 👋 Goodbye!
pause