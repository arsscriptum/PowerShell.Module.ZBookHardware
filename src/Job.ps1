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
