





function New-SmallLoadTest {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [ValidateRange(1, 32)]
        [int]$NumProcesses = 10
    )
    $Testlimit64Exe = "C:\ProgramData\chocolatey\bin\Testlimit64.exe"
    [System.Collections.ArrayList]$cmdargs = [System.Collections.ArrayList]::new()
    [void]$cmdargs.Add("-t")
    [void]$cmdargs.Add("1024")
    [void]$cmdargs.Add("-c")
    [void]$cmdargs.Add("1024")
    [void]$cmdargs.Add("-r")
    [void]$cmdargs.Add("10")


    [void]$cmdargs.Add("$NumProcesses")

    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()
    $ProgramArgsSet = @{
        FilePath = $Testlimit64Exe
        ArgumentList = $cmdargs
        WorkingDirectory = "$($PWD.Path)"
        NoNewWindow = $True
        PassThru = $True
        Wait = $False
        RedirectStandardOutput = $stdout
        RedirectStandardError = $stderr
    }
    $cmdres = Start-Process @ProgramArgsSet
    $cmdres
}

function New-LoadTest {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Number of processes")]
        [ValidateRange(1, 32)]
        [int]$NumProcesses = 10,

        [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Memory (MB) per process")]
        [ValidateRange(1, 32768)]
        [int]$MemoryMB = 200,

        [Parameter(Position = 2, Mandatory = $false, HelpMessage = "Duration in seconds before killing the load processes")]
        [ValidateRange(0, 86400)]
        [int]$DurationSec = 0
    )
    $LogFile = "C:\tmp\testlimits.log"
    if (-not (Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }
    $Testlimit64Exe = "C:\ProgramData\chocolatey\bin\Testlimit64.exe"
    $procList = @()
    for ($i = 1; $i -le $NumProcesses; $i++) {
        $args = "-m $MemoryMB"
        [System.Collections.ArrayList]$cmdargs = [System.Collections.ArrayList]::new()
        [void]$cmdargs.Add("-t")
        [void]$cmdargs.Add("1024")
        [void]$cmdargs.Add("-c")
        [void]$cmdargs.Add("1024")
        [void]$cmdargs.Add("-r")
        [void]$cmdargs.Add("10")
        [void]$cmdargs.Add("-m")
        [void]$cmdargs.Add("$MemoryMB")

        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()
        $proc = Start-Process -FilePath $Testlimit64Exe -ArgumentList $cmdargs `
             -WorkingDirectory $PWD.Path `
             -NoNewWindow `
             -Passthru `
             -Wait:$false `
             -RedirectStandardOutput $stdout `
             -RedirectStandardError $stderr
        $procList += $proc

        $logMsg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') STARTED: PID $($proc.Id), $MemoryMB MB"
        Add-Content -Path $LogFile -Value $logMsg
    }

    if ($DurationSec -gt 0) {
        # Use background job for delayed kill and log
        $pids = $procList | Select-Object -ExpandProperty Id
        $logPath = $LogFile
        Start-Job -ScriptBlock {
            param($PIDs, $WaitSec, $LogPath)
            Start-Sleep -Seconds $WaitSec
            foreach ($pid in $PIDs) {
                try {
                    Stop-Process -Id $pid -Force
                    $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') STOPPED: PID $pid"
                } catch {
                    $msg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ALREADY EXITED: PID $pid"
                }
                Add-Content -Path $LogPath -Value $msg
            }
        } -ArgumentList ($pids, $DurationSec, $logPath) | Out-Null
    }

    return $procList
}
function Show-CPULoadView {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Number of processes to display")]
        [ValidateRange(1, 50)]
        [int]$Count = 10
    )

    $cpuCount = [Environment]::ProcessorCount
    $window = @{}

    function Get-ColorForValue ($v) {
        switch ($v) {
            { $_ -ge 50 } { return 'Red' }
            { $_ -ge 20 } { return 'Yellow' }
            { $_ -ge 10 } { return 'Blue' }
            { $_ -ge 5 } { return 'Cyan' }
            default { return 'White' }
        }
    }

    while ($true) {
        $procs1 = Get-Process | Select-Object Id, Name, CPU
        Start-Sleep -Milliseconds 1000
        $procs2 = Get-Process | Select-Object Id, Name, CPU

        $usage = foreach ($p1 in $procs1) {
            $p2 = $procs2 | Where-Object { $_.Id -eq $p1.Id }
            if ($p2) {
                $cpuDelta = $p2.CPU - $p1.CPU
                [pscustomobject]@{
                    Name = $p2.Name
                    CPUPercent = [math]::Round(($cpuDelta / 1) / $cpuCount * 100, 1)
                }
            }
        }

        $grouped = $usage | Group-Object Name | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                TotalCPUPercent = ($_.Group | Measure-Object -Property CPUPercent -Sum).Sum
                Count = $_.Count
            }
        }

        foreach ($entry in $grouped) {
            $name = $entry.Name
            $val = $entry.TotalCPUPercent
            if (-not $window.ContainsKey($name)) { $window[$name] = @() }
            $window[$name] += $val
            if ($window[$name].Count -gt 10) { $window[$name] = $window[$name][-10..-1] }
        }

        Clear-Host
        "{0,3} {1,-20} {2}" -f "#", "Name", "Last 10 %CPU"
        "-" * 80
        $i = 1
        $window.GetEnumerator() |
        Sort-Object { $_.Value[-1] } -Descending |
        Select-Object -First $Count |
        ForEach-Object {
            $name = $_.Key
            $values = $_.Value
            Write-Host ("{0,3} {1,-20} " -f $i, $name) -NoNewline
            foreach ($v in $values) {
                $color = Get-ColorForValue $v
                Write-Host ("{0,8:N1}" -f $v) -NoNewline -ForegroundColor $color
            }
            Write-Host ""
            $i++
        }
        Start-Sleep -Seconds 1
    }
}


function Show-MemoryLoadView {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Number of processes to display")]
        [ValidateRange(1, 50)]
        [int]$Count = 10
    )

    $window = @{} # Hashtable: process name → array of last 10 values

    function Get-ColorForValue ($v) {
        switch ($v) {
            { $_ -ge 2048 } { return 'Red' }
            { $_ -ge 1024 } { return 'Yellow' }
            { $_ -ge 512 } { return 'Blue' }
            { $_ -ge 256 } { return 'Cyan' }
            default { return 'White' }
        }
    }

    while ($true) {
        $usage = Get-Process | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                WorkingSetMB = [math]::Round($_.WorkingSet64 / 1MB, 1)
            }
        }

        $grouped = $usage | Group-Object Name | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                TotalWorkingSetMB = ($_.Group | Measure-Object -Property WorkingSetMB -Sum).Sum
                Count = $_.Count
            }
        }

        foreach ($entry in $grouped) {
            $name = $entry.Name
            $val = $entry.TotalWorkingSetMB
            if (-not $window.ContainsKey($name)) { $window[$name] = @() }
            $window[$name] += $val
            if ($window[$name].Count -gt 10) { $window[$name] = $window[$name][-10..-1] }
        }

        Clear-Host
        "{0,-20} {1}" -f "Name", "Last 10 WorkingSet MB"
        "-" * 75
        $window.GetEnumerator() |
        Sort-Object { $_.Value[-1] } -Descending |
        Select-Object -First $Count |
        ForEach-Object {
            $name = $_.Key
            $values = $_.Value
            Write-Host ("{0,-20} " -f $name) -NoNewline
            foreach ($v in $values) {
                $color = Get-ColorForValue $v
                Write-Host ("{0,8:N1}" -f $v) -NoNewline -ForegroundColor $color
            }
            Write-Host ""
        }
        Start-Sleep -Seconds 1
    }
}

function Show-CPULoadViewWithKill {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Number of processes to display")]
        [ValidateRange(1, 50)]
        [int]$Count = 10
    )

    $cpuCount = [Environment]::ProcessorCount
    $window = @{}

    function Get-ColorForValue ($v) {
        switch ($v) {
            { $_ -ge 50 } { return 'Red' }
            { $_ -ge 20 } { return 'Yellow' }
            { $_ -ge 10 } { return 'Blue' }
            { $_ -ge 5 } { return 'Cyan' }
            default { return 'White' }
        }
    }

    while ($true) {
        $procs1 = Get-Process | Select-Object Id, Name, CPU
        Start-Sleep -Milliseconds 1000
        $procs2 = Get-Process | Select-Object Id, Name, CPU

        $usage = foreach ($p1 in $procs1) {
            $p2 = $procs2 | Where-Object { $_.Id -eq $p1.Id }
            if ($p2) {
                $cpuDelta = $p2.CPU - $p1.CPU
                [pscustomobject]@{
                    Name = $p2.Name
                    CPUPercent = [math]::Round(($cpuDelta / 1) / $cpuCount * 100, 1)
                }
            }
        }

        $grouped = $usage | Group-Object Name | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                TotalCPUPercent = ($_.Group | Measure-Object -Property CPUPercent -Sum).Sum
                Count = $_.Count
            }
        }

        foreach ($entry in $grouped) {
            $name = $entry.Name
            $val = $entry.TotalCPUPercent
            if (-not $window.ContainsKey($name)) { $window[$name] = @() }
            $window[$name] += $val
            if ($window[$name].Count -gt 10) { $window[$name] = $window[$name][-10..-1] }
        }

        Clear-Host
        "{0,3} {1,-20} {2}" -f "#", "Name", "Last 10 %CPU"
        "-" * 80
        $i = 1
        $indexMap = @{}
        $window.GetEnumerator() |
        Sort-Object { $_.Value[-1] } -Descending |
        Select-Object -First $Count |
        ForEach-Object {
            $name = $_.Key
            $values = $_.Value
            $indexMap[$i] = $name
            Write-Host ("{0,3} {1,-20} " -f $i, $name) -NoNewline
            foreach ($v in $values) {
                $color = Get-ColorForValue $v
                Write-Host ("{0,8:N1}" -f $v) -NoNewline -ForegroundColor $color
            }
            Write-Host ""
            $i++
        }

        Write-Host ""
        Write-Host "Press 'k' to kill a process by index, any other key to refresh..."

        $waitTimeMs = 1000 # Wait up to 1 second for key
        $keyPressed = $null
        $timeout = [datetime]::Now.AddMilliseconds($waitTimeMs)
        while ([console]::KeyAvailable -eq $false -and [datetime]::Now -lt $timeout) {
            Start-Sleep -Milliseconds 100
        }
        if ([console]::KeyAvailable) {
            $keyPressed = [console]::ReadKey($true)
        }

        if ($keyPressed -and $keyPressed.KeyChar -eq 'k') {
            Write-Host "Enter process index to kill: " -NoNewline
            $userIndex = [console]::ReadLine()
            if ($userIndex -match '^\d+$' -and $indexMap.ContainsKey([int]$userIndex)) {
                $procName = $indexMap[[int]$userIndex]
                Write-Host "Killing all processes named '$procName'..."
                # If you want to use pskill.exe, swap the next line for:
                # Start-Process -FilePath "pskill.exe" -ArgumentList $procName -Wait
                Get-Process -Name $procName -ErrorAction SilentlyContinue | Stop-Process -Force
                Start-Sleep -Seconds 1
            }
        }
    }
}



function Show-MemoryLoadViewWithKill {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $window = @{} # Hashtable: process name → array of last 10 values

    function Get-ColorForValue ($v) {
        switch ($v) {
            { $_ -ge 2048 } { return 'Red' } # >2GB
            { $_ -ge 1024 } { return 'Yellow' } # >1GB
            { $_ -ge 512 } { return 'Blue' } # >512MB
            { $_ -ge 256 } { return 'Cyan' } # >256MB
            default { return 'White' }
        }
    }

    while ($true) {
        $usage = Get-Process | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                WorkingSetMB = [math]::Round($_.WorkingSet64 / 1MB, 1)
            }
        }

        $grouped = $usage | Group-Object Name | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                TotalWorkingSetMB = ($_.Group | Measure-Object -Property WorkingSetMB -Sum).Sum
                Count = $_.Count
            }
        }

        foreach ($entry in $grouped) {
            $name = $entry.Name
            $val = $entry.TotalWorkingSetMB
            if (-not $window.ContainsKey($name)) { $window[$name] = @() }
            $window[$name] += $val
            if ($window[$name].Count -gt 10) { $window[$name] = $window[$name][-10..-1] }
        }

        Clear-Host
        "{0,-20} {1}" -f "Name", "Last 10 WorkingSet MB"
        "-" * 75
        $window.GetEnumerator() |
        Sort-Object { $_.Value[-1] } -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            $name = $_.Key
            $values = $_.Value
            Write-Host ("{0,-20} " -f $name) -NoNewline
            foreach ($v in $values) {
                $color = Get-ColorForValue $v
                Write-Host ("{0,8:N1}" -f $v) -NoNewline -ForegroundColor $color
            }
            Write-Host ""
        }
        Start-Sleep -Seconds 1
    }
}

function Show-MemoryLoadViewWithKill {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Number of processes to display")]
        [ValidateRange(1, 50)]
        [int]$Count = 10
    )

    $window = @{} # process name → array of last 10 values

    function Get-ColorForValue ($v) {
        switch ($v) {
            { $_ -ge 2048 } { return 'Red' }
            { $_ -ge 1024 } { return 'Yellow' }
            { $_ -ge 512 } { return 'Blue' }
            { $_ -ge 256 } { return 'Cyan' }
            default { return 'White' }
        }
    }

    while ($true) {
        $usage = Get-Process | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                WorkingSetMB = [math]::Round($_.WorkingSet64 / 1MB, 1)
            }
        }

        $grouped = $usage | Group-Object Name | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                TotalWorkingSetMB = ($_.Group | Measure-Object -Property WorkingSetMB -Sum).Sum
                Count = $_.Count
            }
        }

        foreach ($entry in $grouped) {
            $name = $entry.Name
            $val = $entry.TotalWorkingSetMB
            if (-not $window.ContainsKey($name)) { $window[$name] = @() }
            $window[$name] += $val
            if ($window[$name].Count -gt 10) { $window[$name] = $window[$name][-10..-1] }
        }

        Clear-Host
        "{0,3} {1,-20} {2}" -f "#", "Name", "Last 10 WorkingSet MB"
        "-" * 80
        $i = 1
        $indexMap = @{}
        $window.GetEnumerator() |
        Sort-Object { $_.Value[-1] } -Descending |
        Select-Object -First $Count |
        ForEach-Object {
            $name = $_.Key
            $values = $_.Value
            $indexMap[$i] = $name
            Write-Host ("{0,3} {1,-20} " -f $i, $name) -NoNewline
            foreach ($v in $values) {
                $color = Get-ColorForValue $v
                Write-Host ("{0,8:N1}" -f $v) -NoNewline -ForegroundColor $color
            }
            Write-Host ""
            $i++
        }

        Write-Host ""
        Write-Host "Press 'k' to kill a process by index, any other key to refresh..."

        $waitTimeMs = 1000 # Wait up to 1 second for key
        $keyPressed = $null
        $timeout = [datetime]::Now.AddMilliseconds($waitTimeMs)
        while ([console]::KeyAvailable -eq $false -and [datetime]::Now -lt $timeout) {
            Start-Sleep -Milliseconds 100
        }
        if ([console]::KeyAvailable) {
            $keyPressed = [console]::ReadKey($true)
        }

        if ($keyPressed -and $keyPressed.KeyChar -eq 'k') {
            Write-Host "Enter process index to kill: " -NoNewline
            $userIndex = [console]::ReadLine()
            if ($userIndex -match '^\d+$' -and $indexMap.ContainsKey([int]$userIndex)) {
                $procName = $indexMap[[int]$userIndex]
                Write-Host "Killing all processes named '$procName'..."
                # To use pskill: Start-Process -FilePath "pskill.exe" -ArgumentList $procName -Wait
                Get-Process -Name $procName -ErrorAction SilentlyContinue | Stop-Process -Force
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Show-TempHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Delay in seconds between samples")]
        [int]$Delay = 5
    )

    $history = @{}
    $ssdKey = "SSD"

    function Get-TempColor ($val) {
        switch ($val) {
            { $_ -lt 60 } { "Cyan"; break }
            { $_ -lt 70 } { "Yellow"; break }
            { $_ -lt 75 } { "Yellow"; break }
            { $_ -lt 80 } { "DarkYellow"; break }
            { $_ -lt 85 } { "Red"; break }
            { $_ -lt 90 } { "DarkRed"; break }
            default { "Magenta" }
        }
    }

    while ($true) {
        $sysTemps = Get-SystemTemperatureC
        $ssdTemp = Get-SSDTemperature

        foreach ($row in $sysTemps) {
            $name = $row.Sensor
            $val = [math]::Round($row.TempC, 1)
            if (-not $history.ContainsKey($name)) { $history[$name] = @() }
            $history[$name] += $val
            if ($history[$name].Count -gt 10) { $history[$name] = $history[$name][-10..-1] }
        }

        if (-not $history.ContainsKey($ssdKey)) { $history[$ssdKey] = @() }
        $history[$ssdKey] += [int]$ssdTemp
        if ($history[$ssdKey].Count -gt 10) { $history[$ssdKey] = $history[$ssdKey][-10..-1] }

        Clear-Host
        Write-Host ("Name".PadRight(16) + "Last 10".PadRight(34))
        Write-Host ("-" * 50)
        foreach ($name in $history.Keys) {
            Write-Host ($name.Replace('ACPI\ThermalZone\','').PadRight(14)) -NoNewline
            $arr = $history[$name]
            foreach ($v in $arr) {
                $col = Get-TempColor $v
                Write-Host ($v.ToString("0.0").PadLeft(6)) -NoNewline -ForegroundColor $col
            }
            Write-Host
        }

        Start-Sleep -Seconds $Delay
    }
}
