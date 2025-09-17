
#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   AesBinaryEncryption.ps1                                                      ║
#║                                                                                ║
#║   read the current fan speed register value (0x2F) on your HP ZBook and        ║
#║   translate it into the closestsymbolic enum value (Max, High, etc.), matching ║
#║   accepted hex values "0x01", "0x32", "0x4A", "0x60", "0x63", "0xB5", "0xC7"   ║       
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Invoke-LastCommandAsAdmin {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CommandString
    )
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    $TmpFile = (New-TemporaryFile).FullName
    $TmpFilePS1 = (New-TemporaryFile).FullName + '.ps1'
    Move-Item $TmpFile $TmpFilePS1

    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()
    $CommandFileStr = @"

Import-Module `"C:\Users\gp\Documents\PowerShell\Modules\PowerShell.Module.ZBookHardware\PowerShell.Module.ZBookHardware.psd1`" -Force

{0} *> "c:\tmp\pwsh.log"

"@ -f "$CommandString"
    Set-Content -Path "$TmpFilePS1" -Value "$CommandFileStr"



    [System.Collections.ArrayList]$cmdargs = [System.Collections.ArrayList]::new()

    [void]$cmdargs.Add("-NoProfile")
    [void]$cmdargs.Add("-ExecutionPolicy")
    [void]$cmdargs.Add("Bypass")
    [void]$cmdargs.Add("-File")
    [void]$cmdargs.Add("$TmpFilePS1")



    $ProgramArgsSet = @{
        FilePath = "pwsh.exe"
        ArgumentList = $cmdargs
        WorkingDirectory = "$($PWD.Path)"
        Wait = $True
        Verb = "RunAs"
     }
    Write-Host "Launching in Admin mode" -f DarkRed
    $cmdres = Start-Process @ProgramArgsSet
    Get-Content -Path "c:\tmp\pwsh.log"
}

function Get-ZBookFanSpeed {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param()

    #This will self elevate the script so with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        Invoke-LastCommandAsAdmin "$($MyInvocation.Line)"
        return
    }

    $FanSpeedMap = @{
        "01" = "Max"
        "32" = "VeryHigh"
        "4A" = "High"
        "5F" = "Mid-High"
        "60" = "Medium"
        "63" = "Low"
        "B5" = "VeryLow"
        "C7" = "Min"
    }

    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        Write-Host "[ERROR] $ecprobePath not found" -ForegroundColor Red
        return
    }

    $regStr = "0x2F"
    Write-Verbose "Reading register $regStr"
    $readOut = & $ecprobePath read $regStr
    Write-Verbose "Raw output: $readOut"
    $m = [regex]::Match($readOut, '([0-9]+) \(0x([0-9A-Fa-f]+)\)')
    if ($m.Success) {
        $dec = [int]$m.Groups[1].Value
        $hex = $m.Groups[2].Value.ToUpper().PadLeft(2, '0')
        if ($FanSpeedMap.ContainsKey($hex)) {
            Write-Verbose "Current fan speed: $($FanSpeedMap[$hex]) ($hex)"
            return $FanSpeedMap[$hex]
        } else {
            Write-Warning "Current fan register value: 0x$hex (not in enum map)" -ForegroundColor Yellow
            return $hex
        }
    } else {
        Write-Error "[ERROR] Failed to read current value from register $regStr" -ForegroundColor Red
    }
}




function Set-ZBookFanSpeed {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Max", "VeryHigh", "High", "Medium", "Low", "VeryLow", "Min")]
        [string]$Speed,
        [Parameter(Mandatory = $False)]
        [switch]$NoDelay
    )

    #This will self elevate the script so with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        Invoke-LastCommandAsAdmin "$($MyInvocation.Line)"
        return
    }
    $FanSpeedMap = @{
        Max = "01"
        VeryHigh = "32"
        High = "4A"
        MidHigh = "5F"
        Medium = "60"
        Low = "63"
        VeryLow = "B5"
        Min = "C7"
    }
    $Current = Get-ZBookFanSpeed
    if($Current -eq "$Speed"){
        Write-Host "Already at speed $Speed..."
        return $Speed
    }

    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        Write-Host "[ERROR] $ecprobePath not found" -ForegroundColor Red
        return
    }

    $valueHex = $FanSpeedMap[$Speed]
    $regStr = "0x2F"
    $valStr = "0x$valueHex"

    Write-Verbose "Unlock sequence: write 0x01 to 0x34, 0x28 to 0x38"
    & $ecprobePath write 0x34 0x01 | Out-Null
    & $ecprobePath write 0x38 0x28 | Out-Null
    Start-Sleep -Milliseconds 50

    

    Write-Verbose "Writing $valStr to register $regStr"
    & $ecprobePath write $regStr $valStr | Out-Null


    if($NoDelay){
        return $Speed
    }
    Write-Host "Waiting for Fan Speed to sync..." -n
    $Delay = 5
    0..$Delay | % {
        Start-Sleep 1
        $dots = [string]::new('.',($_)*2)
        Write-Host "$dots" -n
    }


    $NewCurrent = Get-ZBookFanSpeed
    # TODO : Read Value to validate change
    Write-Output "`n ✔️ Changed the Fan Speed from $Current --> $NewCurrent"
    Write-Verbose "Fan speed set to $Speed ($valStr) on register $regStr"
    return $NewCurrent
}


