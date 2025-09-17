#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   SSDTemperatur.ps1                                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

function Get-SSDTemperature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Device = "/dev/sda",
        [Parameter(Mandatory=$false)]
        [string]$SmartctlPath = "C:\Programs\smartmontools\bin\smartctl.exe"
    )

    if (-not (Test-Path $SmartctlPath)) {
        Write-Host "[ERROR] smartctl not found at $SmartctlPath" -ForegroundColor Red
        return
    }

    $output = & $SmartctlPath -a $Device 2>&1

    # Look for 'Temperature_Celsius' line
    $tempLine = $output | Select-String -Pattern "Temperature_Celsius"
    if ($tempLine) {
        # Extract the temp from '... RAW_VALUE'
        if ($tempLine -match 'Temperature_Celsius\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+)') {
            $tempC = $Matches[1]
            Write-Output $tempC
        } else {
            Write-Host "[WARN] Could not extract temperature from line: $tempLine" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARN] Temperature_Celsius attribute not found." -ForegroundColor Yellow
    }
}

# Usage:
# Get-SSDTemperature
function Get-SystemTemperatureC {
    [CmdletBinding()]
    param()
    $temps = @()
    try {
        # Use Get-WmiObject for PS 5.x, Get-CimInstance for Core/7+ if available
        if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
            $objs = Get-CimInstance -Namespace "root/wmi" -ClassName "MSAcpi_ThermalZoneTemperature"
        } else {
            $objs = Get-WmiObject -Namespace "root/wmi" -Class "MSAcpi_ThermalZoneTemperature"
        }
        foreach ($obj in $objs) {
            if ($obj.CurrentTemperature -gt 0) {
                $tempC = ($obj.CurrentTemperature / 10) - 273.15
                $temps += [PSCustomObject]@{
                    Sensor = $obj.InstanceName
                    TempC  = [math]::Round($tempC, 1)
                }
            }
        }
        return $temps
    }
    catch {
        Write-Error "Could not read temperature sensors: $_"
    }
}

# Usage example:
# Get-SystemTemperatureC
