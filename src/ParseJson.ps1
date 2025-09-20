#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   OpenHwdMon.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-FilteredNodeIds {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $true, HelpMessage = "Root JSON node")]
        [PSCustomObject]$Node,
        [Parameter(Position=1,Mandatory = $true)]
        [string]$Pattern
    )
    $result = @()
    if ($Node.PSObject.Properties['Text']) {
        Write-Verbose "Node ID: $($Node.id), Text: $($Node.Text)"
    }
    if ($Node.PSObject.Properties['Text'] -and $Node.Text -eq "$Pattern" -and $Node.PSObject.Properties['id']) {
        Write-Verbose "Found $Pattern Node! ID: $($Node.id)"
        $result += $Node.id
    }
    if ($Node.PSObject.Properties['Children']) {
        Write-Verbose "Node ID: $($Node.id) has $($Node.Children.Count) children"
        foreach ($child in $Node.Children) {
            $result += Get-FilteredNodeIds $child $Pattern
        }
    }
    return $result
}

function Get-NodesById {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $true, HelpMessage = "Root JSON node")]
        [PSCustomObject]$Node,
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


function Get-StatisticsValues {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $true, HelpMessage = "Root JSON node")]
        [PSCustomObject]$Node,
        [Parameter(Position=1,Mandatory = $true)]
        [ValidateSet('Load','Temperatures')]
        [string]$Stats="Temperature"
    )

    # Find all IDs for nodes where Text = 'Temperatures'
    $tempNodeIds = Get-FilteredNodeIds -Node $Node -Pattern "$Stats"
    if ($tempNodeIds -eq $Null) {
        return $Null
    }
    $tempNodes = Get-NodesById -Node $Node -Ids $tempNodeIds
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

   
    return $results
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
    $tempNodeIds = Get-FilteredNodeIds -Node $json -Pattern 'Temperatures'
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

