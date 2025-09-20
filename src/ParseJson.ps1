function Find-TemperaturesNodeIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Root JSON node")]
        $Node
    )
    $result = @()
    if ($Node.PSObject.Properties['Text']) {
        Write-Verbose "Node ID: $($Node.id), Text: $($Node.Text)"
    }
    if ($Node.PSObject.Properties['Text'] -and $Node.Text -eq 'Temperatures' -and $Node.PSObject.Properties['id']) {
        Write-Verbose "Found Temperatures Node! ID: $($Node.id)"
        $result += $Node.id
    }
    if ($Node.PSObject.Properties['Children']) {
        Write-Verbose "Node ID: $($Node.id) has $($Node.Children.Count) children"
        foreach ($child in $Node.Children) {
            $result += Find-TemperaturesNodeIds -Node $child
        }
    }
    return $result
}

function Get-NodesById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Root JSON node")]
        $Node,
        [Parameter(Mandatory = $true, HelpMessage = "Array of IDs to match")]
        [int[]]$Ids
    )
    $result = @()
    if ($Node.PSObject.Properties['id'] -and $Ids -contains $Node.id) {
        Write-Verbose "Matched node by ID: $($Node.id)"
        $result += $Node
    }
    if ($Node.PSObject.Properties['Children']) {
        foreach ($child in $Node.Children) {
            $result += Get-NodesById -Node $child -Ids $Ids
        }
    }
    return $result
}

function Get-TemperaturesValues {
    [CmdletBinding()]
    param()
    Write-Verbose "Starting Get-TemperaturesValues"
    $Uri = "http://172.17.32.1:8085/data.json"
    Write-Verbose "Load your JSON from $Uri"
    $json = Invoke-RestMethod -Uri "$Uri"
    $Node = $json.Children
    $jsonString = $json | ConvertTo-Json -Depth 99
    Write-Verbose "JSON $jsonString"
    $ids = Find-TemperaturesNodeIds -Node $Node
    Write-Verbose "Total Temperatures nodes found: $($ids.Count) -> $($ids -join ', ')"
    $nodes = Get-NodesById -Node $Node -Ids $ids

    foreach ($node in $nodes) {
        Write-Host "`n=== $($node.Text) (ID: $($node.id)) ===" -ForegroundColor Cyan
        foreach ($c in $node.Children) {
            $label = $c.Text
            $value = $c.Value
            # Parse number from value (handle " °C")
            if ($value -match '([\d\.]+) ?°C') {
                $temp = [double]$matches[1]
                # Choose color
                if ($temp -lt 60) { $color = 'Cyan' }
                elseif ($temp -lt 70) { $color = 'Green' }
                elseif ($temp -lt 75) { $color = 'Yellow' }
                elseif ($temp -lt 80) { $color = 'DarkYellow' }
                elseif ($temp -lt 85) { $color = 'Red' }
                elseif ($temp -lt 90) { $color = 'DarkRed' }
                else { $color = 'Magenta' }
            } else {
                $color = 'Gray'
            }
            Write-Host ("{0,-18} : {1,8}" -f $label, $value) -ForegroundColor $color
            Write-Verbose ("Details: Text={0}, Value={1}, Min={2}, Max={3}, ImageURL={4}" -f $c.Text, $c.Value, $c.Min, $c.Max, $c.ImageURL)
        }
    }
}


function Test-OpenHardwareMonitorWebServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ServerAddress = "127.0.0.1",
        [Parameter(Mandatory = $false)]
        [int]$Port = 8085,
        [Parameter(Mandatory = $false, HelpMessage = "Timeout in milliseconds")]
        [int]$Timeout = 500 # im on the LAN
    )

    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
        $connectTask = $tcpClient.ConnectAsync($ServerAddress, $Port)
        $completed = $connectTask.Wait($Timeout)

        if ($completed -and $tcpClient.Connected) {
            $tcpClient.Close()
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

function Get-TemperaturesValues {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "The server address")]
        [uri]$Uri = "http://172.17.32.1:8085/data.json",
        [Parameter(Mandatory = $False)]
        [switch]$AsString
    )
    $ServerUp = Test-OpenHardwareMonitorWebServer -Port $($Uri.Port)
    [string]$AbsUrl = $Uri.AbsoluteUri

    if ($False -eq $ServerUp) {
        Write-Warning "No server at $AbsUrl"
        return
    }

    $json = Invoke-RestMethod -Uri "$AbsUrl"
    if ($Null -eq $json) {
        Write-Warning "no data from $AbsUrl"
        return
    }
    # Find all IDs for nodes where Text = 'Temperatures'
    $tempNodeIds = Find-TemperaturesNodeIds -Node $json
    if ($tempNodeIds -eq $Null) {
        Write-Host "Find all IDs for nodes where Text = 'Temperatures'" -DarkYellow -n
        Write-Host "RETURN NOTHING" -f DarkRed
        return
    }
    $tempNodes = Get-NodesById -Node $json -Ids $tempNodeIds
    # (Save these somewhere: e.g. a text file, DB, or keep in memory)

    $results = @()

    foreach ($t in $tempNodes) {
        foreach ($child in $t.Children) {
            $obj = [PSCustomObject]@{
                Sensor = $t.Text
                Label  = $child.Text
                Value  = $child.Value
                Min    = $child.Min
                Max    = $child.Max
            }
            $results += $obj
        }
    }

    if ($AsString) {
        foreach ($t in $tempNodes) {
            Write-Host "Found: $($t.Text)  (id=$($t.id))" -ForegroundColor DarkMagenta
            foreach ($child in $t.Children) {
                Write-Host ("  {0,-18}: {1,-10}  (min: {2}, max: {3})" -f $child.Text, $child.Value, $child.Min, $child.Max)
            }
        }
    }

    return $results
}


function Get-TemperatureEventLogStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Hours to look back")]
        [int]$Hours = 24
    )

    $source = "PowerShell-Temperature"
    $logName = "Application"
    $since = (Get-Date).AddHours(-$Hours)

    $events = Get-EventLog -LogName $logName -Source $source | Where-Object { $_.TimeGenerated -ge $since }
    if (!$events) {
        Write-Host "No events found from source '$source' in the last $Hours hours." -ForegroundColor Yellow
        return
    }

    $tempEntries = @()
    foreach ($ev in $events) {
        if ($ev.Message -match "Label: (.+?)`nValue: ([\d\.]+) °C") {
            $label = $matches[1].Trim()
            $value = [double]$matches[2]
            $tempEntries += [PSCustomObject]@{ Label = $label; Value = $value }
        }
    }

    if (!$tempEntries) {
        Write-Host "No temperature entries parsed from events." -ForegroundColor Yellow
        return
    }

    $labels = $tempEntries | Select-Object -ExpandProperty Label -Unique

    foreach ($label in $labels) {
        $temps = $tempEntries | Where-Object { $_.Label -eq $label } | Select-Object -ExpandProperty Value
        $min = ($temps | Measure-Object -Minimum).Minimum
        $max = ($temps | Measure-Object -Maximum).Maximum
        $avg = ($temps | Measure-Object -Average).Average
        Write-Host "`n$label" -ForegroundColor Cyan
        Write-Host ("   Min:  {0:N1} °C" -f $min) -ForegroundColor Green
        Write-Host ("   Max:  {0:N1} °C" -f $max) -ForegroundColor Red
        Write-Host ("   Avg:  {0:N1} °C" -f $avg) -ForegroundColor Yellow
    }
}


function Start-TemperatureLoggingJob {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 5
    )

    $scriptBlock = {
        param($node, $interval)
        while ($true) {
            try {
                Save-TemperatureEntriesInEventLogs
            } catch {
                Write-Host "Temperature logging failed: $_" -ForegroundColor Red
            }
            Start-Sleep -Seconds ($interval * 60)
        }
    }

    Start-Job -Name "TemperatureLogger" -ScriptBlock $scriptBlock -ArgumentList $Node, $IntervalMinutes | Out-Null
    Write-Host "Temperature logging job started. Logging every $IntervalMinutes minute(s)." -ForegroundColor Green
}


function Save-TemperatureEntriesInEventLogs {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $source = "PowerShell-Temperature"
    $logName = "Application"

    # Ensure event source exists
    if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
        New-EventLog -LogName $logName -Source $source
    }

    $entries = Get-TemperaturesValues 
    foreach ($e in $entries) {
        $msg = "Sensor: $($e.Sensor)`nLabel: $($e.Label)`nValue: $($e.Value)`nMin: $($e.Min)`nMax: $($e.Max)"
        Write-Verbose "Logging temperature to event log: $msg"
        Write-EventLog -LogName $logName -Source $source -EventId 1001 -EntryType Information -Message $msg
    }
}
