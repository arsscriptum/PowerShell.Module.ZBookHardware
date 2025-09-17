#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   EcRegister.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

function Invoke-ValidateRegister {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [Alias("r")]
        [string]$Register
    )

    $Valid = $True

    $Len = $Register.Length
    $Valid = $True
    if (($Len -ne 2) -and ($Len -ne 4)) {
        $Valid = $False
    }

    if ($Len -eq 4) {
        if (!($Register.StartsWith("0x"))) {
            $Valid = $False
        }
        try {
            if ($Register -match '^0x[0-9A-Fa-f]+$') {
                $ByteVal = [int]("$($Register.Trim().ToUpper())")
            } else {
                throw "invalid"
            }
        } catch {
            $Valid = $False
        }
    }
    else {
        try {
            if ($Register -match '^0x[0-9A-Fa-f]+$' -or $Register -match '^[0-9A-Fa-f]+$') {
                $ByteVal = [int]("0x$($Register.Trim().ToUpper())")
            } else {
                throw "invalid"
            }
        } catch {
            $Valid = $False
        }
    }


    return $Valid
}

function Get-EcRegisterValue {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$DumpContent,
        [Parameter(Mandatory = $true)]
        [string]$Register
    )

    # Normalize the register string (e.g., "2E" or "0x2E") to int
    $regNum = if ($Register -match '^0x[0-9A-Fa-f]+$') {
        [int]$Register
    } else {
        [int]("0x" + $Register)
    }

    # Each row begins with an offset (e.g. '20 | ...')
    # Each row contains 16 values, columns 0-15

    # Compute row and column
    $row = $regNum -band 0xF0
    $col = $regNum -band 0x0F

    # Find the row line in the dump
    $rowPattern = "^{0:X2} \|".Replace("{0:X2}", $row.ToString("X2"))
    $line = $DumpContent | Where-Object { $_ -match $rowPattern }

    if (!$line) {
        Write-Warning "Register row not found in dump"
        return $null
    }

    # Remove prefix (e.g. '20 |')
    $vals = $line -replace '^.. \| ', '' -split '\s+'

    # Get the value for the column
    $valHex = $vals[$col]

    # Parse hex to int
    $valInt = [int]("0x$valHex")
    return $valInt
}

# Usage example (assuming $dump is content from the file, $reg = '2E'):
# $val = Get-EcRegisterValue -DumpContent $dump -Register "2E"
# Write-Log "Register 2E value: $val"

function Invoke-EcProbe {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [Alias("r")]
        [string]$Read,
        [Parameter(Mandatory = $false)]
        [Alias("d")]
        [switch]$Dump
    )


    function logErr ([string]$errMsg) {
        Write-Log "[ERROR] " -n -f DarkRed
        Write-Log "$errMsg" -f DarkYellow
    }


    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        logErr "$ecprobePath not valid"
        return
    }
    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()

    $ByteVal = 0


    [System.Collections.ArrayList]$cmdargs = [System.Collections.ArrayList]::new()

    [void]$cmdargs.Add("dump")

    $ProgramArgsSet = @{
        FilePath = $ecprobePath
        ArgumentList = $cmdargs
        WorkingDirectory = "$($PWD.Path)"
        NoNewWindow = $True
        PassThru = $True
        Wait = $True
        RedirectStandardOutput = $stdout
        RedirectStandardError = $stderr
    }
    $cmdres = Start-Process @ProgramArgsSet
    $ecode = $cmdres.ExitCode
    if ($ecode -ne 0) {
        Write-Error "ecprobe error $ecode"
        return $ecode
    }

    # Read the content
    [string[]]$registersDump = Get-Content -Path "$stdout"


    if ($Read) {
        $Valid = Invoke-ValidateRegister $Read
        if (!$Valid) {
            logErr "The register value must be in the format `"0xFF`" or `"FF`""
            return
        }
        $val = Get-EcRegisterValue -DumpContent $registersDump -Register $Read

        Write-Log "Reading Register $Read => $val"
    }
    elseif ($Dump) {
        $registersDump
    }


}

function Test-EcRegisterWritableValues {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Register to test (hex, e.g., 46 or 0x46)")]
        [string]$Register,
        [Parameter(Mandatory = $false, HelpMessage = "Send HP ZBook unlock sequence before each write")]
        [switch]$Unlock
    )

    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        Write-Log "[ERROR] $ecprobePath not found" -ForegroundColor Red
        return
    }

    $regStr = if ($Register.StartsWith("0x")) { $Register } else { "0x$Register" }
    $results = @()

    Write-Log "Testing writable values for EC register $regStr ..."
    for ($i = 0; $i -le 255; $i++) {
        $hexVal = "{0:X2}" -f $i
        $valStr = "0x$hexVal"
        
        # Unlock sequence if requested
        if ($Unlock) {
            &$ecprobePath write 0x34 0x01 | Out-Null
            &$ecprobePath write 0x38 0x28 | Out-Null
            Start-Sleep -Milliseconds 30 # Give EC a moment to latch
        }

        # Write the value
        &$ecprobePath write $regStr $valStr | Out-Null
        # Read back
        $readOut = &$ecprobePath read $regStr
        $m = [regex]::Match($readOut, '([0-9]+) \(0x([0-9A-Fa-f]+)\)')
        if ($m.Success) {
            $dec = [int]$m.Groups[1].Value
            $hex = $m.Groups[2].Value.ToUpper()
            if ($dec -eq $i) {
                $results += $hexVal
                Write-Log "$regStr Write $valStr SUCCESS"
            }
        }
        Start-Sleep -Milliseconds 30 # Short pause, don't overload EC
    }
    Write-Log "`nAccepted values for register $regStr`n$($results -join ', ')"
}

# Usage example with unlock:
# Test-EcRegisterWritableValues -Register "2E" -Unlock


function Set-EcAllRegistersValue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Value to write (e.g., 0xFF or FF or 255)")]
        [string]$Value,
        [Parameter(Mandatory = $false, HelpMessage = "Send HP ZBook unlock sequence before each write")]
        [switch]$Unlock
    )

    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        Write-Log "[ERROR] $ecprobePath not found" -ForegroundColor Red
        return
    }

    # Normalize value to hex string
    $valStr = if ($Value.StartsWith("0x")) { $Value } else { "0x$Value" }

    Write-Log "Writing $valStr to all EC registers 0x00–0xFF..."
    for ($i = 0; $i -le 255; $i++) {
        $regStr = "0x{0:X2}" -f $i

        if ($Unlock) {
            &$ecprobePath write 0x34 0x01 | Out-Null
            &$ecprobePath write 0x38 0x28 | Out-Null
            Start-Sleep -Milliseconds 30
        }

        try {
            &$ecprobePath write $regStr $valStr | Out-Null
            Write-Log "Register $regStr <- $valStr"
        } catch {
            Write-Log "[WARN] Failed to write $valStr to $regStr"
        }

        Start-Sleep -Milliseconds 30
    }
    Write-Log "Completed writing $valStr to all EC registers."
}


function Test-EcRegisterRangeValue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Value to write (e.g., 40 or 0x40)")]
        [string]$Value,
        [Parameter(Mandatory = $false, HelpMessage = "Delay (ms) between operations, default 30")]
        [int]$DelayMs = 30,
        [Parameter(Mandatory = $false, HelpMessage = "Send unlock sequence before each write")]
        [switch]$Unlock
    )

    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        Write-Log "[ERROR] $ecprobePath not found" -ForegroundColor Red
        return
    }

    $valStr = if ($Value.StartsWith("0x")) { $Value } else { "0x$Value" }

    Write-Log "Testing EC register range 0x2A–0x30 with value $valStr ..."

    for ($i = 0x21; $i -le 0x30; $i++) {
        $regStr = "0x{0:X2}" -f $i

        if ($Unlock) {
            &$ecprobePath write 0x34 0x01 | Out-Null
            &$ecprobePath write 0x38 0x28 | Out-Null
            Start-Sleep -Milliseconds $DelayMs
        }

        # Write value
        &$ecprobePath write $regStr $valStr | Out-Null

        # Read value
        $readOut = &$ecprobePath read $regStr
        $m = [regex]::Match($readOut, '([0-9]+) \(0x([0-9A-Fa-f]+)\)')
        if ($m.Success) {
            $dec = [int]$m.Groups[1].Value
            $hex = $m.Groups[2].Value.ToUpper()
            if ($dec -eq [int]$valStr) {
                Write-Log "Register $regStr  Set to $valStr [OK]" -ForegroundColor Green
            } else {
                Write-Log "Register $regStr  Set to $valStr [FAILED, now 0x$hex]" -ForegroundColor Yellow
            }
        } else {
            Write-Log "Register $regStr  Error reading back value" -ForegroundColor Red
        }

        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Log "Test complete."
}

function Set-EcRegisterValueWithUnlock {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Register to write (hex, e.g., 2E or 0x2E)")]
        [string]$Register,
        [Parameter(Mandatory = $true, HelpMessage = "Value to write (e.g., 40 or 0x40)")]
        [string]$Value,
        [Parameter(Mandatory = $false, HelpMessage = "Send unlock sequence before write")]
        [switch]$Unlock
    )

    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        Write-Log "[ERROR] $ecprobePath not found" -ForegroundColor Red
        return
    }

    $regStr = if ($Register.StartsWith("0x")) { $Register } else { "0x$Register" }
    $valStr = if ($Value.StartsWith("0x")) { $Value } else { "0x$Value" }

    if ($Unlock) {
        &$ecprobePath write 0x34 0x01 | Out-Null
        &$ecprobePath write 0x38 0x28 | Out-Null
        Start-Sleep -Milliseconds 30
    }

    Write-Log "Writing $valStr to register $regStr..."
    &$ecprobePath write $regStr $valStr | Out-Null
    Write-Log "Done."
}


function Test-EcRegisterAllValues {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Register to test (hex, e.g., 2F or 0x2F)")]
        [string]$Register,
        [Parameter(Mandatory = $false, HelpMessage = "Delay (ms) between ops, default 50")]
        [int]$DelayMs = 50
    )

    $nbfcPath = Join-Path "${ENV:ProgramFiles(x86)}" "NoteBook FanControl"
    $ecprobePath = Join-Path "$nbfcPath" "ec-probe.exe"
    if (-not (Test-Path "$ecprobePath")) {
        Write-Log "[ERROR] $ecprobePath not found" -ForegroundColor Red
        return
    }

    $regStr = if ($Register.StartsWith("0x")) { $Register } else { "0x$Register" }
    $results = @()

    Write-Log "Testing all values for EC register $regStr ..."
    for ($i = 0; $i -le 255; $i++) {
        $hexVal = "{0:X2}" -f $i
        $valStr = "0x$hexVal"

        # Unlock sequence (always needed for your ZBook)
        Write-Verbose "Testing Value $valStr => Unlock Sequence"
        &$ecprobePath write 0x34 0x01 | Out-Null
        &$ecprobePath write 0x38 0x28 | Out-Null
        Start-Sleep -Milliseconds $DelayMs

        # Write test value
        Write-Verbose "Testing Value $valStr => Write test value"
        &$ecprobePath write $regStr $valStr | Out-Null

        # Read-back
        Write-Verbose "Testing Value $valStr => Read-back"
        $readOut = &$ecprobePath read $regStr
        $m = [regex]::Match($readOut, '([0-9]+) \(0x([0-9A-Fa-f]+)\)')
        if ($m.Success) {
            $dec = [int]$m.Groups[1].Value
            $hex = $m.Groups[2].Value.ToUpper()
            Write-Verbose "Testing Value $valStr => Read-back GOT $dec $hex"
            if ($dec -eq $i) {
                $results += $hexVal
                Write-Host "Register $regStr $valStr [OK]" -ForegroundColor Green
            }
            else{
                Write-Host "$dec -eq $i" -f Red
            }
        } else {
            Write-HOst "Register $regStr  $valStr [Read error]" -ForegroundColor Red
        }

        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Log "`nAccepted values for register $regStr `n$($results -join ', ')"
}
