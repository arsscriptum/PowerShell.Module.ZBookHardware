#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   MsgBox.ps1                                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

function Write-TempLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        [Parameter(Position = 1)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [Parameter(Position = 2)]
        [switch]$NoNewline
    )
    $logPath = "C:\tmp\temp.log"
    if (-not (Test-Path "C:\tmp")) { New-Item -Path "C:\tmp" -ItemType Directory -Force | Out-Null }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"

    # Console output with color (optional)
    Write-Host $Message -ForegroundColor $ForegroundColor -NoNewline:$NoNewline

    # Log to file (always new line)
    Add-Content -Path $logPath -Value $line
}


function Set-ZBookMaxTemp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$TempC
    )
    $key = 'HKCU:\SOFTWARE\arsscriptum\PowerShell.Module.ZBookHardware'
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name 'maxtemp' -Value $TempC -Type DWord
}

function Get-ZBookMaxTemp {
    [CmdletBinding()]
    param()
    $key = 'HKCU:\SOFTWARE\arsscriptum\PowerShell.Module.ZBookHardware'
    try {
        $val = Get-ItemProperty -Path $key -Name 'maxtemp' -ErrorAction Stop
        return $val.maxtemp
    } catch {
        Write-Error "maxtemp value not found in $key"
        return $null
    }
}

function New-TempDeamon {
    [CmdletBinding()]
    param()
    Unregister-ScheduledTask -TaskName "CheckZBookTemperature" -Confirm:$false -ErrorAction Ignore
    Unregister-ScheduledTask -TaskName "TestZBookTemperature" -Confirm:$false -ErrorAction Ignore
    Unregister-ScheduledTask -TaskName "TestZBookTemperature2" -Confirm:$false -ErrorAction Ignore
    try {
        $User = "$env:USERDOMAIN\$env:USERNAME" # Or just $env:USERNAME if no domain
        $pwshPath = (Get-Command pwsh.exe).Source
        $encodedCommand = 'SQBtAHAAbwByAHQALQBNAG8AZAB1AGwAZQAgACIAQwA6AFwAVQBzAGUAcgBzAFwAZwBwAFwARABvAGMAdQBtAGUAbgB0AHMAXABQAG8AdwBlAHIAUwBoAGUAbABsAFwATQBvAGQAdQBsAGUAcwBcAFAAbwB3AGUAcgBTAGgAZQBsAGwALgBNAG8AZAB1AGwAZQAuAFoAQgBvAG8AawBIAGEAcgBkAHcAYQByAGUAXABQAG8AdwBlAHIAUwBoAGUAbABsAC4ATQBvAGQAdQBsAGUALgBaAEIAbwBvAGsASABhAHIAZAB3AGEAcgBlAC4AcABzAGQAMQAiACAALQBGAG8AcgBjAGUADQAKAFQAZQBzAHQALQBDAGgAZQBjAGsAVABlAG0AcABlAHIAYQB0AHUAcgBlAFQAaAByAGUAcwBoAG8AbABkAA=='
        #$Action = New-ScheduledTaskAction -Execute $pwshPath -Argument "-ExecutionPolicy Bypass -encodedcommand `"$encodedCommand`""

        [string]$VBSFile = Join-Path "c:\tmp" "hidden_powershell.vbs"
        [string]$VBSContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "pwsh.exe -ExecutionPolicy Bypass -EncodedCommand $encodedCommand", 0, False
"@

        [string]$ArgumentString = "-WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand {0}" -f $encodedCommand
        Write-host "Create Scheduled Task with Base64 Encoded Command"


        New-Item -Path "$VBSFile" -ItemType File -Value "$VBSContent" -Force | Out-Null

        Write-Host "Create a Scheduled Task to Run the VBS Script"
        $WScriptCmd = Get-Command -Name "wscript.exe" -CommandType Application -ErrorAction Stop
        $WScriptBin = $WScriptCmd.Source
        $Action = New-ScheduledTaskAction -Execute "$WScriptBin" -Argument "$VBSFile"

        # 1. Timer trigger (every 5 min, starts after login)
        $TimerTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 9125)

        # 2. Logon trigger
        $LogonTrigger = New-ScheduledTaskTrigger -AtLogOn

        $Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest

        Register-ScheduledTask -TaskName "ZBookTemperature" -Action $Action -Trigger @($TimerTrigger, $LogonTrigger) -Principal $Principal -Description "Checks ZBook temperature every 5 minutes and at logon (interactive, PowerShell Core)"

    } catch {
        Write-Error "$_"
    }
}





function Invoke-StartWarningTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 120)]
        [int]$Temperature = 100

    )
    try {
        [int]$Delay = 30
        $UseVbs = $True

        $ScriptWarning = @"

&"C:\Dev\MessageBox-Ctrl\test\bin\Debug\net472\TestWarningDll.exe" "{0}"

"@
        $LogFile = "$ENV:Temp\task_warning.log"
        [string]$ScriptString = $ScriptWarning -f $Temperature

        [string]$ScriptBase64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptString))
        $now = [datetime]::Now.AddSeconds(10)
        # Example Usage
        $selectedUser = "DESKTOP-6K3G95V\gp"

        [string]$TaskName = "WarningDelayedRemote"

        try {
            Write-Host "Unregister task $TaskName" -NoNewline -f DarkYellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Remove-SchedTasks -TaskName $TaskName
            Write-Host "Success" -f DarkGreen
        } catch {
            Write-Host "Failed" -f DarkRed
        }
        [string]$folder = Invoke-EnsureSharedScriptFolder
        [string]$VBSFile = Join-Path "$folder" "hidden_powershell.vbs"
        [string]$VBSContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -EncodedCommand $ScriptBase64", 0, False
"@

        [string]$ArgumentString = "-WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand {0}" -f $ScriptBase64
        Write-host "Create Scheduled Task with Base64 Encoded Command"

        if ($UseVbs) {
            New-Item -Path "$VBSFile" -ItemType File -Value "$VBSContent" -Force | Out-Null

            Write-Host "Create a Scheduled Task to Run the VBS Script"
            $WScriptCmd = Get-Command -Name "wscript.exe" -CommandType Application -ErrorAction Stop
            $WScriptBin = $WScriptCmd.Source
            $Action = New-ScheduledTaskAction -Execute "$WScriptBin" -Argument "$VBSFile"

        } else {
            $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $ScriptBase64"
        }


        $Trigger = New-ScheduledTaskTrigger -At $now -Once:$false
        $Principal = New-ScheduledTaskPrincipal -UserId "$selectedUser" -LogonType Interactive -RunLevel Highest
        $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal

        write-host "Register and Run Task"
        Register-ScheduledTask -TaskName $TaskName -InputObject $Task | Out-Null
        Add-SchedTasks -TaskName $TaskName
        Start-ScheduledTask -TaskName $TaskName

        Write-Host "In 10 seconds... $LogFile"

    } catch {
        write-error "$_"
    }

}

function Invoke-StopWarningTask {
    [CmdletBinding()]
    param()
    try {
        [string]$TaskName = "WarningDelayedRemote"
        [int]$NumPowershell = (tasklist | Select-String "powershell" -Raw | measure).Count
        try {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-Host "Unregister task $TaskName" -NoNewline -f DarkYellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Remove-SchedTasks -TaskName $TaskName
            Write-Host "Success" -f DarkGreen
        } catch {
            Write-Host "Failed" -f DarkRed
        }
        [string[]]$Res = & "C:\Windows\system32\taskkill.exe" "/IM" "powershell.exe" "/F" 2> "$ENV:Temp\killres.txt"
        $Killed = $Res.Count
        Write-Host "NumPowershell $NumPowershell Killed $Killed"

    } catch {
        write-error "$_"
    }

}


function Test-CheckTemperatureThreshold {
    [CmdletBinding()]
    param()

    $SystemTemperatureC = (Get-SystemTemperatureC | Sort-Object TempC -Descending | Select-Object -First 1).TempC
    Write-TempLog "[Test-CheckTemperatureThreshold] SystemTemperatureC $SystemTemperatureC"
    $SSDTemperature = Get-SSDTemperature
    Write-TempLog "[Test-CheckTemperatureThreshold] SSDTemperature $SSDTemperature"
    # Read max temp from registry
    $ZBookMaxTemp = Get-ZBookMaxTemp
    Write-TempLog "[Test-CheckTemperatureThreshold] ZBookMaxTemp $ZBookMaxTemp"

    $HigherTemp = if ($SystemTemperatureC -gt $SSDTemperature) { $SystemTemperatureC } else { $SSDTemperature }
    Write-TempLog "[Test-CheckTemperatureThreshold] HigherTemp $HigherTemp"
    # Get the current temperature

    Write-TempLog "Current temperature: $Temp°C, threshold: $ZBookMaxTemp"

    if ($HigherTemp -ge $ZBookMaxTemp) {
        Write-TempLog "Invoke-StartWarningTask $HigherTemp"
        Invoke-StartWarningTask $HigherTemp

    }
}
