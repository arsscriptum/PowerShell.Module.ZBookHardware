
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

function Get-ZBookFanSpeed {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param()

    $FanSpeedMap = @{
        "01" = "Max"
        "32" = "VeryHigh"
        "4A" = "High"
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
    $readOut = &$ecprobePath read $regStr
    Write-Verbose "Raw output: $readOut"
    $m = [regex]::Match($readOut, '([0-9]+) \(0x([0-9A-Fa-f]+)\)')
    if ($m.Success) {
        $dec = [int]$m.Groups[1].Value
        $hex = $m.Groups[2].Value.ToUpper().PadLeft(2, '0')
        if ($FanSpeedMap.ContainsKey($hex)) {
            Write-Host "Current fan speed: $($FanSpeedMap[$hex]) ($hex)"
            return $FanSpeedMap[$hex]
        } else {
            Write-Host "Current fan register value: 0x$hex (not in enum map)" -ForegroundColor Yellow
            return $hex
        }
    } else {
        Write-Host "[ERROR] Failed to read current value from register $regStr" -ForegroundColor Red
    }
}




function Set-ZBookFanSpeed {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Max", "VeryHigh", "High", "Medium", "Low", "VeryLow", "Min")]
        [string]$Speed
    )

    $FanSpeedMap = @{
        Max      = "01"
        VeryHigh = "32"
        High     = "4A"
        Medium   = "60"
        Low      = "63"
        VeryLow  = "B5"
        Min      = "C7"
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
    &$ecprobePath write 0x34 0x01 | Out-Null
    &$ecprobePath write 0x38 0x28 | Out-Null
    Start-Sleep -Milliseconds 50

    Write-Verbose "Writing $valStr to register $regStr"
    &$ecprobePath write $regStr $valStr | Out-Null
    Write-Verbose "Fan speed set to $Speed ($valStr) on register $regStr"
}
