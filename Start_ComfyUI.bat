@echo off
REM ComfyUI Quick Start - Double-click to run ComfyUI
REM This batch file starts ComfyUI with CUDA acceleration

echo.
echo ===============================================
echo          Starting ComfyUI with GPU
echo ===============================================
echo.

REM Change to the ComfyUI directory
cd /d "%~dp0"

REM Check if virtual environment exists
if not exist "venv\Scripts\python.exe" (
    echo ❌ Error: Virtual environment not found!
    echo Please make sure the venv folder exists in the ComfyUI directory.
    pause
    exit /b 1
)

REM Display system info
echo 🚀 Starting ComfyUI...
echo 📁 Directory: %CD%
echo 🐍 Python: venv\Scripts\python.exe
echo.

REM Start ComfyUI
echo ⚡ Launching ComfyUI with GPU acceleration...
echo 🌐 Web interface will be available at: http://127.0.0.1:8188
echo.
echo 💡 To stop ComfyUI, close this window or press Ctrl+C
echo.

REM Run ComfyUI with Manager enabled
venv\Scripts\python.exe main.py --enable-manager

REM If ComfyUI exits, pause to show any error messages
echo.
echo ComfyUI has stopped.
pause