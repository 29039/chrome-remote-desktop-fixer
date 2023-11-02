# Fix Chrome Remote Desktop service (chromoting) startup issue
# Version 2

# Instructions:
# - Highlight entire script -> Right-Click on Highlighted area -> Copy
# - Press WINKEY+X keys on keyboard at the same time -> Windows PowerShell (Admin) -> Yes 
# - Right-click on Blue Window (Paste) -> Press ENTER Key

$enableLogging = $false
$logFilePath = "C:\Path\To\Your\Log\CRDFixer_Log.txt"

function Start-Logging {
    if ($enableLogging) {
        Start-Transcript -Path $logFilePath -Append
        Write-Output "Script started at: $(Get-Date)"
    }
}

function Stop-Logging {
    if ($enableLogging) {
        Write-Output "Script stopped at: $(Get-Date)"
        Stop-Transcript
    }
}

function Log-Message {
    param (
        [string]$message,
        [string]$color = "White"
    )

    Write-Host $message -ForegroundColor $color

    if ($enableLogging) {
        $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
        Add-Content -Path $logFilePath -Value $formattedMessage
    }
}

function Check-CRDFixerTask {
    # Check if CRD Fixer task already exists
    $schedule = New-Object -ComObject Schedule.Service
    $schedule.Connect()
    $tasks = $schedule.GetFolder("\").GetTasks(0)

    foreach ($task in ($tasks | Select-Object Name)) {
        if ($task.Name -eq "CRD Fixer") {
            return $true
        }
    }
    return $false
}

function Install-CRDFixerTask {
    # Install the task if it doesn't exist
    $action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-ExecutionPolicy RemoteSigned ""`$crd='chromoting';if((Get-Service `$crd).StartType -ne 'Disabled'){Set-Service `$crd -StartupType Automatic;Start-Service `$crd}""" -WorkingDirectory %SystemRoot%
    $trigger = New-ScheduledTaskTrigger -Daily -At 6pm
    $description = "Sets Chrome Remote Desktop (chromoting service) back to Automatic startup"
    
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "CRD Fixer" -Description $description -User "NT AUTHORITY\SYSTEM"
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
    Set-ScheduledTask -TaskName "CRD Fixer" -Settings $settings 
    Start-ScheduledTask -TaskName "CRD Fixer"

    Log-Message "CRD Fixer task installed."
}

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch as administrator
    Log-Message "Please relaunch as Admin to install" -color "Red"
    Log-Message "Press any key to continue..." -color "Yellow"
    Read-Host
    Exit
}

# Start Logging
Start-Logging

# Check if CRD Fixer task already exists
$doesCRDFixerTaskExist = Check-CRDFixerTask

# Install CRD Fixer task if it doesn't exist
if (-not $doesCRDFixerTaskExist) {
    Install-CRDFixerTask
}

# Provide user feedback
if ($doesCRDFixerTaskExist) {
    Log-Message "CRD Fixer already installed. Delete from Task Scheduler if you want to re-install." -color "Red"
} else {
    Log-Message "CRD Fixer successfully installed." -color "Green"
}

# Stop Logging
Stop-Logging

##
