#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   EventLogs.ps1                                                                ║
#║   log in events                                                                ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Save-TemperatureEntriesInEventLogs {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        $Node
    )

    $source = "PowerShell-Temperature"
    $logName = "Application"

    # Ensure event source exists
    if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
        New-EventLog -LogName $logName -Source $source
    }

    $entries = Get-TemperaturesValues -Node $Node
    foreach ($e in $entries) {
        $msg = "Sensor: $($e.Sensor)`nLabel: $($e.Label)`nValue: $($e.Value)`nMin: $($e.Min)`nMax: $($e.Max)"
        Write-Verbose "Logging temperature to event log: $msg"
        Write-EventLog -LogName $logName -Source $source -EventId 1001 -EntryType Information -Message $msg
    }
}
