# Automated ComfyUI Cleanup - Scheduled Task Setup
# Run this script to set up automatic cleanup

Write-Host "⚙️  ComfyUI Automatic Cleanup Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$ComfyUIPath = $PSScriptRoot
$CleanupScript = Join-Path $ComfyUIPath "cleanup_output.ps1"

# Check if cleanup script exists
if (-not (Test-Path $CleanupScript)) {
    Write-Host "❌ Cleanup script not found: $CleanupScript" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Available automation options:" -ForegroundColor White
Write-Host ""
Write-Host "1. 🕐 Daily cleanup (keeps last 10 images)" -ForegroundColor Green
Write-Host "2. 🕑 Weekly cleanup (keeps last 20 images)" -ForegroundColor Green  
Write-Host "3. 🕒 Manual setup (custom schedule)" -ForegroundColor Yellow
Write-Host "4. ❌ Remove existing scheduled task" -ForegroundColor Red
Write-Host ""

$Choice = Read-Host "Select option (1-4)"

$TaskName = "ComfyUI_Output_Cleanup"

# Remove existing task if it exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Write-Host "🗑️  Removing existing scheduled task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

switch ($Choice) {
    "1" {
        # Daily cleanup
        Write-Host "⏰ Setting up daily cleanup..." -ForegroundColor Green
        
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$CleanupScript`" -KeepLast -KeepCount 10 -Force -NoRestart"
        $Trigger = New-ScheduledTaskTrigger -Daily -At "03:00"
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Daily ComfyUI output folder cleanup"
        
        Write-Host "✅ Daily cleanup scheduled for 3:00 AM (keeps last 10 images)" -ForegroundColor Green
    }
    
    "2" {
        # Weekly cleanup
        Write-Host "⏰ Setting up weekly cleanup..." -ForegroundColor Green
        
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$CleanupScript`" -KeepLast -KeepCount 20 -Force -NoRestart"
        $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Weekly ComfyUI output folder cleanup"
        
        Write-Host "✅ Weekly cleanup scheduled for Sundays at 3:00 AM (keeps last 20 images)" -ForegroundColor Green
    }
    
    "3" {
        Write-Host "📖 Manual setup instructions:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Use Windows Task Scheduler to create a custom task:" -ForegroundColor White
        Write-Host "Action: PowerShell.exe" -ForegroundColor Gray
        Write-Host "Arguments: -ExecutionPolicy Bypass -File `"$CleanupScript`" [options]" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Available options:" -ForegroundColor White
        Write-Host "  -KeepLast -KeepCount 5   : Keep last 5 images" -ForegroundColor Gray
        Write-Host "  -Force                   : No confirmation prompt" -ForegroundColor Gray
        Write-Host "  -NoRestart              : Don't restart ComfyUI" -ForegroundColor Gray
    }
    
    "4" {
        Write-Host "✅ Scheduled task removed (if it existed)" -ForegroundColor Green
    }
    
    default {
        Write-Host "❌ Invalid option selected" -ForegroundColor Red
        exit 1
    }
}

if ($Choice -in @("1", "2")) {
    Write-Host ""
    Write-Host "🎉 Automation setup complete!" -ForegroundColor Green
    Write-Host "💡 You can view/modify the task in Windows Task Scheduler" -ForegroundColor Blue
    Write-Host "🗑️  To remove: Run this script again and select option 4" -ForegroundColor Blue
}