

function Save-TemperatureEntriesToFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Node,
        [string]$Path = "$PSScriptRoot\TemperatureLog.txt"
    )

    $entries = Get-TemperaturesValues -Node $Node
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    foreach ($e in $entries) {
        $line = "$timestamp`t$($e.Sensor)`t$($e.Label)`t$($e.Value)`tMin: $($e.Min)`tMax: $($e.Max)"
        Add-Content -Path $Path -Value $line
    }
}
