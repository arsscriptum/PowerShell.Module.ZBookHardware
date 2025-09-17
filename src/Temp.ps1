#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   MsgBox.ps1                                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

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

function Check-TemperatureThreshold {
    [CmdletBinding()]
    param(
        # Function to get the current temp (default: Get-SystemTemperatureC, returns max if multiple)
        [Parameter(Mandatory=$false)]
        [scriptblock]$GetCurrentTemp = { 
            $temps = Get-SystemTemperatureC
            if ($temps) { ($temps | Sort-Object TempC -Descending | Select-Object -First 1).TempC }
            else { $null }
        }
    )
    #This will self elevate the script so with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
        Invoke-LastCommandAsAdmin "$($MyInvocation.Line)"
        return
    }
    # Read max temp from registry
    $maxTemp = Get-ZBookMaxTemp
    if ($null -eq $maxTemp) {
        Write-Host "[ERROR] Could not read threshold (maxtemp) from registry." -ForegroundColor Red
        return
    }

    # Get the current temperature
    $Temp = & $GetCurrentTemp
    if ($null -eq $Temp) {
        Write-Host "[ERROR] Could not determine current temperature." -ForegroundColor Red
        return
    }

    Write-Host "Current temperature: $Temp°C, threshold: $maxTemp°C"

    if ($Temp -ge $maxTemp) {
        Show-TemperatureWarning $Temp
    }
}
