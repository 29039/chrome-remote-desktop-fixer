#Fix Chrome Remote Desktop service (chromoting) which mysteriously gets set to 'manual' startup sometimes, breaking it's main function
#Instructions: Highlight entire script -> Right-Click on Highlighted area -> Copy
#Press WINKEY+X keys on keyboard at the same time -> Windows PowerShell (Admin) -> Yes 
#Right click on Blue Window (Paste) -> Press ENTER Key

#Check if already installed
$doesCRDFixerTaskExist = 0
$schedule = new-object -com Schedule.Service 
$schedule.connect() 
$tasks = $schedule.getfolder("\").gettasks(0)
foreach ($task in ($tasks | select Name)) {
   if($task.name -eq "CRD Fixer") {
      $script:doesCRDFixerTaskExist = 1
      break
   }
}
#Install it if it's not
 if($doesCRDFixerTaskExist -eq 0){
   $action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-ExecutionPolicy RemoteSigned ""Set-Service -Name chromoting -StartupType Automatic; Start-Service chromoting""" -WorkingDirectory %SystemRoot%
   $trigger =  New-ScheduledTaskTrigger -Daily -At 6pm
   $description = "Sets Chrome Remote Desktop (chromoting service) back to Automatic startup"
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "CRD Fixer" -Description $description -User "NT AUTHORITY\SYSTEM"
   $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
   Set-ScheduledTask -TaskName "CRD Fixer" -Settings $settings 
   Start-ScheduledTask -TaskName "CRD Fixer"
}
#Tell the user what happened
if($doesCRDFixerTaskExist -eq 1){
   write-host "
   CRD Fixer already installed, delete from Task Scheduler if you want to re-install" -ForegroundColor Red
} else {
   write-host "
   CRD Fixer successfully installed" -ForegroundColor Green
}
#
