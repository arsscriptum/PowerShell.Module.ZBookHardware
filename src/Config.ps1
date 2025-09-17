#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   config.ps1                                                                   ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-ZBookHardwareUserCredentialID { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Overwrite if present")]
        [String]$Id
    )

    $DefaultUser = Get-ZBookHardwareDefaultUsername
    $Credz = "ZBookHardware_MODULE_USER_$DefaultUser"

    $DevAccount = Get-ZBookHardwareDevAccountOverride
    if($DevAccount){ return "ZBookHardware_MODULE_USER_$DevAccount" }
    
    return $Credz
}

function Get-ZBookHardwareAppCredentialID { 
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $DefaultUser = Get-ZBookHardwareDefaultUsername
    $Credz = "ZBookHardware_MODULE_APP_$DefaultUser"

    $DevAccount = Get-ZBookHardwareDevAccountOverride
    if($DevAccount){ return "ZBookHardware_MODULE_APP_$DevAccount" }
    
    return $Credz
}

function Get-ZBookHardwareDevAccountOverride { 
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegPath = Get-ZBookHardwareModuleRegistryPath
    if( $RegPath -eq "" ) { throw "not in module"; return ;}
    $DevAccount = ''
    $DevAccountOverride = Test-RegistryValue -Path "$RegPath" -Entry 'override_dev_account'
    if($DevAccountOverride){
        $DevAccount = Get-RegistryValue -Path "$RegPath" -Entry 'override_dev_account'
    }
    
    return $DevAccount
}

function Set-ZBookHardwareDevAccountOverride { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Overwrite if present")]
        [String]$Id
    )

    $RegPath = Get-ZBookHardwareModuleRegistryPath
    if( $RegPath -eq "" ) { throw "not in module"; return ;}
    New-RegistryValue -Path "$RegPath" -Entry 'override_dev_account' -Value "$Id" 'String'
    Set-RegistryValue -Path "$RegPath" -Entry 'override_dev_account' -Value "$Id"
    
    return $DevAccount
}

function Get-ZBookHardwareModuleUserAgent { 
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    $ModuleName = ($ExecutionContext.SessionState).Module
    $Agent = "User-Agent $ModuleName. Custom Module."
   
    return $Agent
}


function Set-ZBookHardwareDefaultUsername {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Username")]
        [String]$User      
    )
    $RegPath = Get-ZBookHardwareModuleRegistryPath
    $ok = Set-RegistryValue  "$RegPath" "default_username" "$User"
    [environment]::SetEnvironmentVariable('DEFAULT_ZBookHardware_USERNAME',"$User",'User')
    return $ok
}

<#
    ZBookHardwareDefaultUsername
    New-ItemProperty -Path "$ENV:OrganizationHKCU\ZBookHardware.com" -Name 'default_username' -Value 'codecastor'
 #>
function Get-ZBookHardwareDefaultUsername {
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    $RegPath = Get-ZBookHardwareModuleRegistryPath
    $User = (Get-ItemProperty -Path "$RegPath" -Name 'default_username' -ErrorAction Ignore).default_username
    if( $User -ne $null ) { return $User  }
    if( $Env:DEFAULT_ZBookHardware_USERNAME -ne $null ) { return $Env:DEFAULT_ZBookHardware_USERNAME ; }
    return $null
}


function Set-ZBookHardwareServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Git Server")]
        [String]$Hostname      
    )
    $RegPath = Get-ZBookHardwareModuleRegistryPath
    $ok = Set-RegistryValue  "$RegPath" "hostname" "$Hostname"
    [environment]::SetEnvironmentVariable('DEFAULT_ZBookHardware_SERVER',"$Hostname",'User')
    return $ok
}


function Get-ZBookHardwareServer {      
    [CmdletBinding(SupportsShouldProcess)]
    param ()$Script:MyInvocation.MyCommand.Name
    $RegPath = Get-ZBookHardwareModuleRegistryPath
    $Server = (Get-ItemProperty -Path "$RegPath" -Name 'hostname' -ErrorAction Ignore).hostname
    if( $Server -ne $null ) { return $Server }
     
    if( $Env:DEFAULT_ZBookHardware_SERVER -ne $null ) { return $Env:DEFAULT_ZBookHardware_SERVER  }
    return $null
}


function Test-ZBookHardwareModuleConfig { 
    $ZBookHardwareModuleInformation    = Get-ZBookHardwareModuleInformation;
    $hash = @{ ZBookHardwareServer               = Get-ZBookHardwareServer;
    ZBookHardwareDefaultUsername      = Get-ZBookHardwareDefaultUsername;
    ZBookHardwareModuleUserAgent      = Get-ZBookHardwareModuleUserAgent;
    ZBookHardwareDevAccountOverride   = Get-ZBookHardwareDevAccountOverride;
    ZBookHardwareUserCredentialID     = Get-ZBookHardwareUserCredentialID;
    ZBookHardwareAppCredentialID      = Get-ZBookHardwareAppCredentialID;
    RegistryRoot               = $ZBookHardwareModuleInformation.RegistryRoot;
    ModuleSystemPath           = $ZBookHardwareModuleInformation.ModuleSystemPath;
    ModuleInstallPath          = $ZBookHardwareModuleInformation.ModuleInstallPath;
    ModuleName                 = $ZBookHardwareModuleInformation.ModuleName;
    ScriptName                 = $ZBookHardwareModuleInformation.ScriptName;
    ModulePath                 = $ZBookHardwareModuleInformation.ModulePath; } 

    Write-Host "---------------------------------------------------------------------" -f DarkRed
    $hash.GetEnumerator() | ForEach-Object {
        $k = $($_.Key) ; $kl = $k.Length ; if($kl -lt 30){ $diff =30 - $kl ; for($i=0;$i -lt $diff ; $i++) { $k += ' '; }}
        Write-Host "$k" -n -f DarkRed
        Write-Host "$($_.Value)" -f DarkYellow
    }
    Write-Host "---------------------------------------------------------------------" -f DarkRed
}

function Get-ZBookHardwareModuleRegistryPath { 
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
    $ModuleName = ($ExecutionContext.SessionState).Module
    if(-not($ModuleName)){$ModuleName = "PowerShell.Module.ZBookHardware"}
    $Path = "$ENV:OrganizationHKCU\$ModuleName"
   
    return $Path
}

function Get-ZBookHardwareModuleInformation {
    [CmdletBinding()]
    param ()
    try{
        if( $ExecutionContext -eq $null ) { throw "not in module"; return "" ; }
        $ModuleName = $ExecutionContext.SessionState.Module
        $ModuleScriptPath = $Script:MyInvocation.MyCommand.Path
        $ModuleInstallPath = (Get-Item "$ModuleScriptPath").DirectoryName
        $CurrentScriptName = $MyInvocation.MyCommand.Name
        $RegistryPath = "$ENV:OrganizationHKCU\$ModuleName"
        $ModuleSystemPath = (Resolve-Path "$ModuleInstallPath\..").Path
        $ModuleInformation = @{
            ModuleName        = $ModuleName
            ModulePath        = $ModuleScriptPath
            ScriptName        = $CurrentScriptName
            RegistryRoot      = $RegistryPath
            ModuleSystemPath  = $ModuleSystemPath
            ModuleInstallPath = $ModuleInstallPath
        }
        return $ModuleInformation        
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

function Invoke-EnsureSharedScriptFolder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = 'C:\ProgramData\arsscriptum\scripts'
    )

    [string]$SharedPath = $Path

    # Create folder if it doesn't exist
    if (-not (Test-Path $SharedPath)) {
        New-Item -Path $SharedPath -ItemType Directory -Force | Out-Null
    }

    # Set access rights to allow all users to read/execute files
    $acl = Get-Acl $SharedPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule (
        "Users", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow"
    )

    if (-not $acl.Access | Where-Object { $_.IdentityReference -eq "Users" -and $_.FileSystemRights -match "ReadAndExecute" }) {
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $SharedPath -AclObject $acl
    }

    return $SharedPath
}


function Get-DirectorySizeFast {
    [OutputType([UInt64])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "LiteralPath")]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath
    )

    process {
        if (-not (Test-Path $LiteralPath -PathType Container)) {
            throw "Directory not found: $LiteralPath"
        }
        $files = Get-ChildItem -LiteralPath $LiteralPath -Recurse -File -Force -ErrorAction SilentlyContinue
        return ($files | Measure-Object -Property Length -Sum).Sum
    }
}



function Wait-ZBookHardwareModuleUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Online,
        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of seconds to wait.")]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 300,

        [Parameter(Mandatory = $false, HelpMessage = "Check interval in seconds.")]
        [ValidateRange(1, 300)]
        [int]$CheckIntervalSeconds = 1
    )

    $Local = $True
    if ($Online) {
        $Local = $false

    }

    $StartTime = Get-Date
    $TimeoutTime = $StartTime.AddSeconds($TimeoutSeconds)

    try {

        if ($Local) {
            [version]$InitialVersion = Get-ZBookHardwareModuleVersion
            [version]$LatestVersion = Get-ZBookHardwareModuleVersion -Latest
            if ($InitialVersion -eq $LatestVersion) {
                Write-Host "🔄 Waiting for version to update from $InitialVersion..." -ForegroundColor Yellow
            } else {

                Write-Host "✅ Already updated: $InitialVersion -> $LatestVersion" -ForegroundColor Green
                return $true
            }
        } else {
            [version]$InitialVersion = Get-ZBookHardwareModuleVersion -Latest
            [version]$LatestVersion = Get-ZBookHardwareModuleVersion -Latest
        }

        while ((Get-Date) -lt $TimeoutTime) {
            Start-Sleep -Seconds $CheckIntervalSeconds
            if ($Local) {
                [version]$CurrentVersion = Get-ZBookHardwareModuleVersion
            } else {
                [version]$CurrentVersion = Get-ZBookHardwareModuleVersion -Latest
            }
            if ($CurrentVersion -gt $InitialVersion) {
                Write-Host "✅ Module updated: $InitialVersion → $CurrentVersion" -ForegroundColor Green
                return $true
            }

            Write-Host "⏳ Still waiting... Current: $CurrentVersion (Latest: $LatestVersion)" -ForegroundColor DarkGray
        }

        Write-Warning "⏰ Timeout reached. Module version is still $InitialVersion"
        return $false
    }
    catch {
        Write-Error "❌ Error during update check: $_"
        return $false
    }
}


function Show-ModuleInstallPaths {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $paths = $env:PSModulePath -split ';'
    $found = @()

    foreach ($base in $paths) {
        if (-not (Test-Path $base)) { continue }

        $matches = Get-ChildItem -Path $base -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ieq $ModuleName }

        foreach ($match in $matches) {
            Write-Host "Found: $($match.FullName)" -ForegroundColor Green
            Start-Process "explorer.exe" -ArgumentList "`"$($match.FullName)`""
            $found += $match.FullName
        }
    }

    if (-not $found) {
        Write-Warning "No directories found for module '$ModuleName' in PSModulePath."
    }
}


function Write-ProgressHelper {
    [CmdletBinding()]
    param()
    try {
        if ($Script:TotalSteps -eq 0) { return }
        Write-Progress -Activity $Script:ProgressTitle -Status $Script:ProgressMessage -PercentComplete (($Script:StepNumber / $Script:TotalSteps) * 100)
    } catch {
        Write-Host "⌛ StepNumber $Script:StepNumber" -f DarkYellow
        Write-Host "⌛ ScriptSteps $Script:TotalSteps" -f DarkYellow
        $val = (($Script:StepNumber / $Script:TotalSteps) * 100)
        Write-Host "⌛ PercentComplete $val" -f DarkYellow
        Show-ExceptionDetails $_ -ShowStack
    }
}

function Write-ZBookHardwareHost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)][Alias('m')]
        [string]$Message
    )
    Write-Host "[PowerShell.Module.ZBookHardware] " -f DarkRed -n
    Write-Host "$Message" -f DarkYellow
}



function Test-Function { ############### NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)][Alias('n')] [string]$Name,
        [Parameter(Mandatory = $true, Position = 1)][Alias('m')] [string]$Module
    )
    $Res = $True
    try {
        Write-Verbose "Test $Name [$Module]"
        if (-not (Get-Command "$Name" -ErrorAction Ignore)) { throw "missing function $Name, from module $Module" }
    } catch {
        Write-Host "[Missing Dependency] " -n -f DarkRed
        Write-Host "$_" -f DarkYellow
        $Res = $False
    }
    return $Res
}

function Test-Dependencies { ############### NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Res = $True
    try {
        $CoreFuncs = @('Set-RegistryValue', 'New-RegistryValue', 'Register-AppCredentials', 'Decrypt-String')
        foreach ($f in $CoreFuncs) {
            if (-not (Test-Function -n "$f" -m "PowerShell.Module.OpenAI")) { $Res = $False; break; }
        }
    } catch {
        Write-Error "$_"
        $Res = $False
    }
    return $Res
}


<#
    .SYNOPSIS
        FROM C-time converter function
    .DESCRIPTION
        Simple function to convert FROM Unix/Ctime into EPOCH / "friendly" time
#>
function ConvertFrom-Ctime {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "ctime")]
        [int64]$Ctime
    )

    [datetime]$epoch = '1970-01-01 00:00:00'
    [datetime]$result = $epoch.AddSeconds($Ctime)
    return $result
}

<#
    .SYNOPSIS
        INTO C-time converter function
    .DESCRIPTION
        Simple function to convert into FROM EPOCH / "friendly" into Unix/Ctime, which the Inventory Service uses.
#>
function ConvertTo-CTime {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "InputEpoch")]
        [datetime]$InputEpoch
    )

    [datetime]$Epoch = '1970-01-01 00:00:00'
    [int64]$Ctime = 0

    $Ctime = (New-TimeSpan -Start $Epoch -End $InputEpoch).TotalSeconds
    return $Ctime
}

function ConvertFrom-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [int64]$UnixTime
    )
    begin {
        $epoch = [datetime]::SpecifyKind('1970-01-01', 'Local')
    }
    process {
        $epoch.AddSeconds($UnixTime)
    }
}

function ConvertTo-UnixTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [datetime]$DateTime
    )
    begin {
        $epoch = [datetime]::SpecifyKind('1970-01-01', 'Local')
    }
    process {
        [int64]($DateTime - $epoch).TotalSeconds
    }
}

function Get-UnixTime {
    $Now = Get-Date
    return ConvertTo-UnixTime $Now
}


function Get-DateString ([switch]$Verbose) {

    if ($Verbose) {
        return ((Get-Date).GetDateTimeFormats()[8]).Replace(' ', '_').ToString()
    }

    $curdate = $(get-date -Format "yyyy-MM-dd_\hhh-\mmmm-\sss")
    return $curdate
}


function Get-DateForFileName ([switch]$Minimal) {
    $sd = (Get-Date).GetDateTimeFormats()[14]
    $sd = $sd.Split('.')[0]
    $sd = $sd.Replace(':', '-');
    if ($Minimal) {
        $sd = $sd.Replace('-', '');
    }
    return $sd
}
