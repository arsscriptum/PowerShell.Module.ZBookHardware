

function Get-RootPath {
    return (Get-ZBookHardwareModuleInformation).ModuleInstallPath
}

function Get-ExportsPath {
    return Join-Path -Path (Get-RootPath) -ChildPath "exports"
}

function Get-ProxyScriptsPath {
    return Join-Path -Path (Get-RootPath) -ChildPath "scripts"
}

function Get-ProxyDbPath {
    return Join-Path -Path (Get-ExportsPath) -ChildPath "db"
}

function Get-ProxyDataPath {
    return Join-Path -Path (Get-ExportsPath) -ChildPath "data"
}

function Get-ProxyLibPath {
    return Join-Path -Path (Get-ExportsPath) -ChildPath "lib"
}

function Get-SqlPath {
    return Join-Path -Path (Get-RootPath) -ChildPath "sql"
}


function Get-ZBookHardwareModuleExportsPath {
    $ModPath = (Get-ZBookHardwareModuleInformation).ModuleInstallPath
    $ExportsPath = Join-Path $ModPath 'exports'
    return $ExportsPath
}

function Get-ZBookHardwareModuleLibPath {
    $ExportsPath = Get-ZBookHardwareModuleExportsPath
    $libPath = Join-Path $ModPath 'lib'
    return $libPath
}


function Get-ZBookHardwareModuleDatabasePath {
    $ExportsPath = Get-ZBookHardwareModuleExportsPath
    $DatabasePath = Join-Path $ModPath 'db'
    return $DatabasePath
}

function Get-ZBookStatsSqlDbPath {
    $dbPath = Get-ZBookHardwareModuleDatabasePath
    $DatabasePath = Join-Path $dbPath 'stats.db'
    return $DatabasePath
}



function Get-Forever {
    param()
    $Since = [timespan]::new([int64]::MaxValue)
    return $Since
}


function Add-SqlLiteTypes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False, HelpMessage = "Force Reload")]
        [switch]$Force
    )
    $IsLoaded = $False
    $assemblyPath = Join-Path -Path (Get-ZBookHardwareModuleLibPath) -ChildPath "System.Data.SQLite.dll"
    try {
        if ([System.Data.SQLite.SQLiteModule] -as [type]) {
            $IsLoaded = $True
        } else {
            $IsLoaded = $False
        }
    } catch {
        $IsLoaded = $False
    }

    $ShouldLoadAssembly = $False
    if ($Force) {
        Write-Verbose "[Add-SqlLiteTypes] Force Reload"
        $ShouldLoadAssembly = $True
    } elseif ($IsLoaded -eq $False) {
        Write-Verbose "[Add-SqlLiteTypes] Not Loaded. Will load."
        $ShouldLoadAssembly = $True
    } else {
        Write-Verbose "[Add-SqlLiteTypes] alrady loaded"
        $ShouldLoadAssembly = $False
    }

    if ($ShouldLoadAssembly) {
        try {
            Add-Type -Path "$assemblyPath" -ErrorAction Stop
        } catch {
            Write-Warning "Failed to load SQLite assembly $assembly : $_"
        }
    }

}
