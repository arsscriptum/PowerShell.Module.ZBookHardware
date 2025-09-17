$duration = [TimeSpan]::FromDays(9999)   # ≈ 27 years
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File 'C:\Users\gp\Documents\PowerShell\Module-Development\PowerShell.Module.ZBookHardware\scripts\CheckTemp.ps1'"
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration $duration  
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "CheckZBookTemperature" -Action $Action -Trigger $Trigger -Principal $Principal -Description "Checks ZBook temperature every 5 minutes and warns if over threshold."
