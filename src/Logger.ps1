#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Logger.ps1                                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

function Write-Sql {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$SqlStatement,
        [Parameter(Mandatory = $False)]
        [Alias('h')]
        [switch]$Headers
    )
    try {
        [string]$fcolorNormal = 'White'
        [string]$fcolorHighlight = 'DarkGray'
        if ($Headers) {
            [string]$fcolorNormal = 'Magenta'
            [string]$fcolorHighlight = 'Blue'
        }
        if (($ENV:SQL_LOGS_ENABLED -eq $Null) -or ($ENV:SQL_LOGS_ENABLED -eq $False)) {
            return
        }

        if ($Headers) {
            Write-host "`n======================================" -f $fcolorNormal
            Write-host "             sql statement            " -f $fcolorHighlight
            Write-host "======================================" -f $fcolorNormal
        }

        Write-host "$SqlStatement"

        if ($Headers) {
            Write-host "======================================`n" -f $fcolorNormal
        }

    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
}

New-Alias -Name logsql -Value Write-Sql -Force -ErrorAction Ignore | Out-Null

function Write-ProxyLog {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$Message,
        [Parameter(Mandatory = $False)]
        [Alias('t')]
        [ValidateSet('Error', 'Success', 'Normal', 'Warning')]
        [string]$Type = 'Normal'
    )
    try {

        if (($ENV:PROXY_LOGS_ENABLED -eq $Null) -or ($ENV:PROXY_LOGS_ENABLED -eq $False)) {
            return
        }

        switch ($Type)
        {
            'Error' {
                Write-Host "[Error] " -f DarkRed -NoNewline
                Write-Host "$Message" -f DarkYellow
            }
            'Success' {
                Write-Host "[Success] " -f DarkGreen -NoNewline
                Write-Host "$Message" -f White
            }
            'Normal' {
                Write-Host "[Proxy] " -f DarkCyan -NoNewline
                Write-Host "$Message" -f DarkGray
            }
            'Warning' {
                Write-Host "[Warning] " -f DarkYellow -NoNewline
                Write-Host "$Message" -f Gray
            }
        }

    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
}



New-Alias -Name proxylog -Value Write-ProxyLog -Force -ErrorAction Ignore | Out-Null

function Disable-SqlLogs {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        if ($ENV:EnableSqlLogs -eq $Null) {
            [System.Environment]::SetEnvironmentVariable('SQL_LOGS_ENABLED', $False, [System.EnvironmentVariableTarget]::Process)
        }
        elseif ($ENV:EnableSqlLogs -eq $True) {
            [System.Environment]::SetEnvironmentVariable('SQL_LOGS_ENABLED', $False, [System.EnvironmentVariableTarget]::Process)
        } else {
            Write-Warning "[Disable-SqlLogs] Already Disabled"
        }
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
}

function Enable-SqlLogs {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        if ($ENV:EnableSqlLogs -eq $Null) {
            [System.Environment]::SetEnvironmentVariable('SQL_LOGS_ENABLED', $True, [System.EnvironmentVariableTarget]::Process)
        }
        elseif ($ENV:EnableSqlLogs -eq $True) {
            Write-Warning "[Enable-SqlLogs] Already Enabled"
        } else {
            [System.Environment]::SetEnvironmentVariable('SQL_LOGS_ENABLED', $True, [System.EnvironmentVariableTarget]::Process)
        }
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
}


function Disable-ProxyLogs {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        if ($ENV:EnableSqlLogs -eq $Null) {
            [System.Environment]::SetEnvironmentVariable('PROXY_LOGS_ENABLED', $False, [System.EnvironmentVariableTarget]::Process)
        }
        elseif ($ENV:EnableSqlLogs -eq $True) {
            [System.Environment]::SetEnvironmentVariable('PROXY_LOGS_ENABLED', $False, [System.EnvironmentVariableTarget]::Process)
        } else {
            Write-Warning "[Disable-SqlLogs] Already Disabled"
        }
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
}

function Enable-ProxyLogs {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        if ($ENV:EnableSqlLogs -eq $Null) {
            [System.Environment]::SetEnvironmentVariable('PROXY_LOGS_ENABLED', $True, [System.EnvironmentVariableTarget]::Process)
        }
        elseif ($ENV:EnableSqlLogs -eq $True) {
            Write-Warning "[Enable-SqlLogs] Already Enabled"
        } else {
            [System.Environment]::SetEnvironmentVariable('PROXY_LOGS_ENABLED', $True, [System.EnvironmentVariableTarget]::Process)
        }
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
}



