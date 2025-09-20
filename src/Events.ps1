


function Get-RecentShutdownReasons {
<#
.SYNOPSIS
    Retrieves the last N Windows shutdown or unexpected restart events, showing reason, user, process, and time.
.PARAMETER Count
    Number of events to return (default: 5)
.EXAMPLE
    Get-RecentShutdownReasons -Count 7
.NOTES
    Works on PowerShell Core and Windows PowerShell.
#>
    [CmdletBinding()]
    param(
        [int]$Count = 5
    )

    $events = Get-WinEvent -LogName System -MaxEvents 100 |
        Where-Object {
            $_.Id -in 1074, 6006, 6008
        } | 
        Select-Object -First ($Count * 3)

    $results = foreach ($event in $events) {
        $obj = [PSCustomObject]@{
            TimeCreated = $event.TimeCreated
            EventID     = $event.Id
            User        = $null
            Process     = $null
            Reason      = $null
        }
        if ($event.Id -eq 1074) {
            if ($event.Properties.Count -ge 4) {
                $obj.User    = $event.Properties[1].Value
                $obj.Process = $event.Properties[0].Value
                $obj.Reason  = $event.Properties[3].Value
            }
        }
        elseif ($event.Id -eq 6006) {
            $obj.Reason = "Clean shutdown (Event Log service stopped)"
        }
        elseif ($event.Id -eq 6008) {
            $obj.Reason = "Unexpected shutdown (crash, forced power off, or similar)"
        }
        $obj
    }

    $results | Select-Object -First $Count | Format-Table -AutoSize -Wrap
}
