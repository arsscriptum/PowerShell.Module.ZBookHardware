
Import-Module "C:\Users\gp\Documents\PowerShell\Modules\PowerShell.Module.ZBookHardware\PowerShell.Module.ZBookHardware.psd1" -Force

Check-TemperatureThreshold *> "c:\tmp\pwsh.log"

