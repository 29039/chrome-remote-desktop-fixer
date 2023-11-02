# Fix Chrome Remote Desktop service (chromoting) startup issue
# Version 2

# Instructions:
# - Highlight entire script -> Right-Click on Highlighted area -> Copy
# - Press WINKEY+X keys on keyboard at the same time -> Windows PowerShell (Admin) -> Yes 
# - Right-click on Blue Window (Paste) -> Press ENTER Key

$enableLogging = $false
$logFilePath = "C:\Path\To\Your\Log\CRDFixer_Log.txt"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Please relaunch as Admin to install" -ForegroundColor "Red"
    Write-Host "Press any key to continue..." -ForegroundColor "Yellow"
    Read-Host
    Exit
}

# Start Logging
if ($enableLogging) {
    Start-Transcript -Path $logFilePath -Append
    Write-Output "Script started at: $(Get-Date)"
}

# Check if CRD Fixer task already exists
$schedule = New-Object -ComObject Schedule.Service
$schedule.Connect()
$tasks = $schedule.GetFolder("\").GetTasks(0)
$doesCRDFixerTaskExist = $tasks.Name -contains "CRD Fixer"

# Install CRD Fixer task if it doesn't exist
if (-not $doesCRDFixerTaskExist) {
    $action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-ExecutionPolicy RemoteSigned ""`$crd='chromoting';if((Get-Service `$crd).StartType -ne 'Disabled'){Set-Service `$crd -StartupType Automatic;Start-Service `$crd}""" -WorkingDirectory %SystemRoot%
    $trigger = New-ScheduledTaskTrigger -Daily -At 6pm
    $description = "Sets Chrome Remote Desktop (chromoting service) back to Automatic startup"
    
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "CRD Fixer" -Description $description -User "NT AUTHORITY\SYSTEM"
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
    Set-ScheduledTask -TaskName "CRD Fixer" -Settings $settings 
    Start-ScheduledTask -TaskName "CRD Fixer"

    Write-Host "CRD Fixer task installed."
}

# Provide user feedback
if ($doesCRDFixerTaskExist) {
    Write-Host "CRD Fixer already installed. Delete from Task Scheduler if you want to re-install." -ForegroundColor "Red"
} else {
    Write-Host "CRD Fixer successfully installed." -ForegroundColor "Green"
}

# Stop Logging
if ($enableLogging) {
    Write-Output "Script stopped at: $(Get-Date)"
    Stop-Transcript
}
##
