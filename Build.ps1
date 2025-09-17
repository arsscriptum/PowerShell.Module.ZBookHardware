
#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Build.ps1                                                                    ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $False, position = 0)]
    [ValidateSet('min', 'all')]
    [string]$Type = 'all',
    [Parameter(Mandatory = $false)]
    [switch]$Deploy,
    [Parameter(Mandatory = $false)]
    [switch]$Publish,
    [Parameter(Mandatory = $false)]
    [Alias('r')]
    [switch]$Readme,
    [Parameter(Mandatory = $false)]
    [Alias('doc', 'd')]
    [switch]$Documentation
)



#Requires -Version 5


function Get-Script ([string]$prop) {
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile) | select $prop).$prop
}S

$ScriptPath = split-path $script:MyInvocation.MyCommand.Path
$ScriptFullName = (Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName

#===============================================================================
# Root Path
#===============================================================================
$Global:ConsoleOutEnabled = $true
$Global:CurrentRunningScript = Get-Script basename
$Script:CurrPath = $ScriptPath
$Script:RootPath = (Get-Location).Path
if ($PSBoundParameters.ContainsKey('Path') -eq $True) {
    $Script:RootPath = $Path
}
if ($PSBoundParameters.ContainsKey('ModuleIdentifier') -eq $True) {
    $Global:ModuleIdentifier = $ModuleIdentifier
} else {
    $Global:ModuleIdentifier = (Get-Item $Script:RootPath).Name
}
$Global:MiniModuleIdentifier = $Global:ModuleIdentifier.Replace('PowerShell.Module.', '')

#===============================================================================
# Script Variables
#===============================================================================
$Global:CurrentRunningScript = Get-Script basename
$Script:Time = Get-Date
$Script:Date = $Time.GetDateTimeFormats()[19]
$Script:IncPath = Join-Path $Script:CurrPath "include"
$Script:TplPath = Join-Path $Script:CurrPath "tpl"
$Script:Header = Join-Path $Script:IncPath "Header.ps1"
$Script:VersionFile = Join-Path $Script:RootPath "Version.nfo"
$Script:ReadmeTplFile = Join-Path $Script:TplPath "README.tpl"
$Script:ReadmeMdFile = Join-Path $Script:RootPath "README.md"
$Script:DescriptionFile = Join-Path $Script:RootPath "Description.nfo"
$Script:BuilderConfig = Join-Path $Script:CurrPath "Config.ps1"
$Script:SourcePath = Join-Path $Script:RootPath "src"
$Script:BinariesPath = Join-Path $Script:RootPath "bin"
$Script:OutPath = Join-Path $Script:RootPath "out"
$Script:AssembliesPath = Join-Path $Script:RootPath "assemblies"
$Script:DocPath = Join-Path $Script:RootPath "doc"
$Script:DocumentationBuildFile = Join-Path "$ENV:Temp" "BuildDoc.ps1"
$Script:TemplateFilePath = Join-Path $Script:TplPath 'ModuleVersion.tpl'
$Script:OutputFilePath = Join-Path $Script:SourcePath 'ModuleVersion.ps1'
$Script:VersionFileTmpPath = Join-Path "$ENV:Temp" 'Version.tmp'
$Script:DeployTargetPath = (Resolve-Path "W:\default\powershell\PowerShell.Module.ZBookHardware").Path



#===============================================================================
# Check Folders
#===============================================================================
if (-not (Test-Path -Path $Script:SourcePath -PathType Container)) {
    Write-Host -f DarkRed "[ERROR] " -NoNewline
    Write-Host " + Missing SOURCE '$Script:SourcePath' (are you in a Module directory)" -f DarkGray
    return
}
if (-not (Test-Path -Path $Script:VersionFile -PathType Leaf)) {
    Write-Host -f DarkRed "[ERROR] " -NoNewline
    Write-Host " + Missing Version File '$Script:VersionFile' (are you in a Module directory)" -f DarkGray
    return
}

if (-not (Test-Path -Path $Script:DescriptionFile -PathType Leaf)) {
    Write-Host -f Blue "[ERROR] " -NoNewline
    Write-Host " + Missing Description File '$Script:DescriptionFile', adding the file from template" -f DarkGray
    Set-Content -Path $Script:DescriptionFile -Value $Script:ModuleDescriptionTemplate
}



function Update-VersionNumber {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Which part of the version to increment: Major, Minor, or Patch.")]
        [ValidateSet("Major", "Minor", "Patch")]
        [string]$Part = "Patch"
    )

    if (-not (Test-Path $Script:VersionFile)) {
        throw "Version file not found:$Script:VersionFile"
    }

    $version = Get-Content $Script:VersionFile -ErrorAction Stop | Select-Object -First 1
    if ($version -notmatch '^\d+\.\d+\.\d+$') {
        throw "Invalid version format in $Script:VersionFile. Expected format: Major.Minor.Patch (e.g., 1.0.3)"
    }

    $parts = $version -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    switch ($Part.ToLower()) {
        "major" {
            $major++
            $minor = 0
            $patch = 0
        }
        "minor" {
            $minor++
            $patch = 0
        }
        "patch" {
            $patch++
        }
    }

    $newVersion = [version]::new($major, $minor, $patch)
    $newVersionStr = $newVersion.ToString()
    Set-Content -Path $Script:VersionFile -Value $newVersionStr -Encoding UTF8
    Write-Host "Updated version: $version → $newVersionStr" -ForegroundColor Green
    $newVersionStr
}


function Update-ModuleVersionFile {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    # Validate file existence
    foreach ($file in @($Script:VersionFile, $Script:TemplateFilePath)) {
        if (-not (Test-Path $file)) {
            throw "Required file not found: $file"
        }
    }

    # Read version
    [version]$Version = Get-Content -Path $Script:VersionFile -ErrorAction Stop | Select-Object -First 1
    if (-not ($Version)) {
        throw "Version file is empty or invalid: $Script:VersionFile"
    }

    # Read and replace template content
    $Template = Get-Content -Path $Script:TemplateFilePath -Raw -ErrorAction Stop
    $UpdatedContent = $Template -replace '___MODULE_VERSION_STRING____', $Version.ToString()

    # Write to output file
    Set-Content -Path $OutputFilePath -Value $UpdatedContent -Encoding UTF8 -Force
    Write-Host "Updated module version written to: $OutputFilePath" -ForegroundColor Green
    $OutputFilePath
}


function Select-RepositoryId {
    # Get logged-in repos

    $repos = Get-PSRepository

    # Ensure we have repos to display
    if (-not $repos) {
        Write-Host "No ps repos found." -ForegroundColor Red
        return $null
    }

    # Display user list with numbering
    Write-Host "
Please select the repo id:
"
    for ($i = 0; $i -lt $repos.Count; $i++) {
        Write-Host "$($i + 1). $($repos[$i].Name) ($($repos[$i].InstallationPolicy))"
    }

    # Get user input
    $selection = $null
    do {
        $selection = Read-Host "
Answer (Enter a number between 1 and $($repos.Count))"

        # Validate input
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $repos.Count) {
            $selectedRepo = $repos[[int]$selection - 1]
            return $selectedRepo.Name
        } else {
            Write-Host "Invalid selection. Please enter a valid number." -ForegroundColor Red
        }
    } while ($true)
}


function Get-GitExecutablePath {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $GitPath = (get-command "git.exe" -ErrorAction Ignore).Source

    if (($GitPath -ne $null) -and (Test-Path -Path $GitPath)) {
        return $GitPath
    }
    $GitPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\GitForWindows" -Name 'InstallPath' -ErrorAction Ignore).InstallPath
    if ($GitPath -ne $null) { $GitPath = $GitPath + '\bin\git.exe' }
    if (Test-Path -Path $GitPath) {
        return $GitPath
    }
    $GitPath = (Get-ItemProperty -Path "$ENV:OrganizationHKCU\Git" -Name 'InstallPath' -ErrorAction Ignore).InstallPath
    if ($GitPath -ne $null) { $GitPath = $GitPath + '\bin\git.exe' }
    if (($GitPath -ne $null) -and (Test-Path -Path $GitPath)) {
        return $GitPath
    }
}

function Throw-CustomError {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $True, position = 0, HelpMessage = 'Error message')]
        [string]$Message,

        [Parameter(Mandatory = $False, position = 1, HelpMessage = 'Error ID')]
        [string]$ErrorId = 'CustomError',

        [Parameter(Mandatory = $False, position = 2, HelpMessage = 'Error category')]
        [System.Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::InvalidOperation,

        [Parameter(Mandatory = $False, position = 3, HelpMessage = 'Target object')]
        [object]$TargetObject = $null
    )

    $exception = New-Object System.Exception ($Message)

    $errorRecord = New-Object System.Management.Automation.ErrorRecord (
        $exception,
        $ErrorId,
        $Category,
        $TargetObject
    )

    throw $errorRecord
}

function Write-WarningMessage {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(position = 0, Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [switch]$Option
    )

    Write-Host -n "[WARNING]" -f DarkYellow
    write-host -n " ?? "
    write-host "$Message" -f Yellow
}

function Write-ErrorMessage {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(position = 0, Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [switch]$Option
    )

    Write-Host -n "[ ERROR ]" -f DarkRed
    write-host -n " ? "
    write-host "$Message" -f DarkYellow
}

function Write-SuccessMessage {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(position = 0, Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [switch]$Option
    )

    Write-Host -n "[SUCCESS]" -f DarkGreen
    write-host -n " ? "
    write-host "$Message" -f White
}

#===============================================================================
# ExceptionDetails
#===============================================================================
function Show-ExceptionDetails {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$Record,
        [Parameter(Mandatory = $false)]
        [switch]$ShowStack
    )
    $formatstring = "{0}`n{1}"
    $fields = $Record.FullyQualifiedErrorId, $Record.Exception.ToString()
    $ExceptMsg = ($formatstring -f $fields)
    $Stack = $Record.ScriptStackTrace
    Write-Host "`n[ERROR] -> " -NoNewline -ForegroundColor DarkRed;
    Write-Host "$ExceptMsg`n`n" -ForegroundColor DarkYellow
    if ($ShowStack) {
        Write-Host "--stack begin--" -ForegroundColor DarkGreen
        Write-Host "$Stack" -ForegroundColor Gray
        Write-Host "--stack end--`n" -ForegroundColor DarkGreen
    }
}


function Get-BuildModuleScriptPath {
    [OutputType([string])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param()

    $regPath = 'HKCU:\SOFTWARE\arsscriptum\PowerShell.ModuleBuilder'
    $valueName = 'BuildModuleScript'

    try {
        $value = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction Stop).$valueName
        return $value
    }
    catch {
        Write-Error "Failed to retrieve '$valueName' from '$regPath': $_"
        return $null
    }
}

function Get-BuildScriptPath {
    [OutputType([string])]
    [CmdletBinding(SupportsShouldProcess = $false)]
    param()

    $regPath = 'HKCU:\SOFTWARE\arsscriptum\PowerShell.ModuleBuilder'
    $valueName = 'BuildScriptPath'

    try {
        $value = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction Stop).$valueName
        return $value
    }
    catch {
        Write-Error "Failed to retrieve '$valueName' from '$regPath': $_"
        return $null
    }
}


Write-Host "`n`n===============================================================================" -f DarkRed
Write-Host "BUILDING  MODULE `t" -NoNewline -f DarkYellow; Write-Host "$Global:ModuleIdentifier" -f Gray
Write-Host "MODULE DEVELOPER `t" -NoNewline -f DarkYellow; Write-Host "$ENV:Username" -f Gray
Write-Host "BUILD DATE       `t" -NoNewline -f DarkYellow; Write-Host "$Script:Date" -f Gray
if ($Script:DebugMode) {
    Write-Host "`t`t`t`t>>>>>> DEBUG MODE <<<<<<" -f DarkRed;
}
Write-Host "===============================================================================" -f DarkRed

try {

    $BuildModuleScriptPath = Get-BuildModuleScriptPath
    $BuildScriptPath = Get-BuildScriptPath

    if ($Readme) {
        Write-Host "`n`n===============================================================================" -f DarkRed
        Write-Host "BUILDING  README FILE`n" -NoNewline -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed
        Remove-Item -Path "$Script:DocumentationBuildFile" -Force -ErrorAction Ignore | Out-Null
        New-Item -Path "$Script:DocumentationBuildFile" -Force -ErrorAction Ignore -ItemType File | Out-Null
        $AllBases = Get-FunctionList "$Script:SourcePath" | Select -ExpandProperty Base -Unique


        $Content_01 = @"

function Get-FunctionDocUrl(`$Name){{
    `$Url = `"https://github.com/arsscriptum/PowerShell.Module.ZBook/blob/master/doc/{{0}}.md`" -f `$Name
    [string]`$res = `"`t- [{{0}}]({{1}})``n`" -f `$Name, `$Url
    `$res
}}

"@

        $Content = $Content_01.Replace('{{', '{').Replace('}}', '}')
        Set-Content -Path "$Script:DocumentationBuildFile" -Value "$Content"

        $Content_03 = @"
`$Functions{0}Text = ForEach(`$fn in `$Functions{0}){{
    `$DocUrl= Get-FunctionDocUrl `$fn
    `$DocUrl
}}
"@


        $Content_04 = @"
## Functions - {0}
`$Functions{0}Text
"@


        $Content_05 = @"
[string]`$LastUpdate = (Get-Date).GetDateTimeFormats()[5]

`$Text = @`"
{0}
## Last Update

`$LastUpdate
`"@
"@

        $Content_06 = "(Get-Content `"{0}`" -Raw).Replace('__FUNCTIONS_DOCUMENTATION__',`$Text) | Set-Content `"{1}`""

        foreach ($b in $AllBases) {
            $Content_02 = "`$Functions{0,-30}= Get-FunctionList .\src\ | Where Base -match `"\b(?:{0})\b`""
            $v = $Content_02 -f $b
            $Diff = 130 - $v.Length
            $sp = [string]::new(' ', $Diff)
            $Content_02 = "`$Functions{0,-30}= Get-FunctionList .\src\ | Where Base -match `"\b(?:{0})\b`"{1}| Select -ExpandProperty Name"
            $v = $Content_02 -f $b, "$sp"
            Add-Content -Path "$Script:DocumentationBuildFile" -Value "$v"
        }
        foreach ($b in $AllBases) {
            $v = $Content_03 -f $b
            Add-Content -Path "$Script:DocumentationBuildFile" -Value "$v"
        }
        [string]$Funcs = ''
        foreach ($b in $AllBases) {
            $v = $Content_04 -f $b
            $Funcs += "$v`n"
        }
        $v = $Content_05 -f $Funcs
        Add-Content -Path "$Script:DocumentationBuildFile" -Value "$v"
        $v = $Content_06 -f $Script:ReadmeTplFile, $Script:ReadmeMdFile
        Add-Content -Path "$Script:DocumentationBuildFile" -Value "$v"
        . "$Script:DocumentationBuildFile"
    }

    if ($Documentation) {
        Write-Host "`n`n===============================================================================" -f DarkRed
        Write-Host "BUILDING DOCUMENTATION`n" -NoNewline -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed

        . "$BuildScriptPath" -Documentation -NoUpdateVersion
    }



    $newVersion = Update-VersionNumber
    Copy-Item $Script:VersionFile $Script:VersionFileTmpPath -Force
    $OutputFilePath = Update-ModuleVersionFile
    . "$OutputFilePath"

    $ModuleVersion = Get-ZBookModuleVersion

    Set-ZBookAutoUpdateOverride -Enable $True

    if ($Type -eq 'min') {
        . "$BuildScriptPath" -NoUpdateVersion -SkipImport
    } elseif ($Type -eq 'all') {
        makeall -NoUpdateVersion
    } else {
        Write-Host "Error" -f DarkRed
    }

    if ($Publish) {
        Write-Host "`n`n===============================================================================" -f DarkRed
        Write-Host "PUBLISH`n" -NoNewline -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed

        make -SkipImport -Deploy -Publish -NoUpdateVersion
    }

    Set-ZBookAutoUpdateOverride -Enable $False



    Write-Host "Updated module version $newVersion" -ForegroundColor Green

    Copy-Item $Script:VersionFileTmpPath $Script:VersionFile -Force
    Remove-Item $Script:VersionFileTmpPath -Force



    if ($Deploy) {
        Write-Host "`n`n===============================================================================" -f DarkRed
        Write-Host "DEPLOY`n" -NoNewline -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed

        Write-Host "Current Path : $Script:CurrPath" -f Blue
        Write-Host "Out Path     : $Script:OutPath" -f Blue
        Write-Host "Target Path  : $Script:DeployTargetPath" -f Blue

        [version]$CurrVersionStruct = Get-ZBookModuleVersion
        [string]$CurrVersion = $CurrVersionStruct.ToString()

        $srcpsd1path = Join-Path $Script:OutPath "PowerShell.Module.ZBook.psd1"
        $srcpsm1path = Join-Path $Script:OutPath "PowerShell.Module.ZBook.psm1"


        $dstpsd1path = Join-Path $Script:DeployTargetPath "PowerShell.Module.ZBook.psd1"
        $dstpsm1path = Join-Path $Script:DeployTargetPath "PowerShell.Module.ZBook.psm1"

        $psd1VersionBefore = get-content $dstpsd1path | Select-String "ModuleVersion " -Raw
        if ([string]::IsNullOrEmpty($psd1VersionBefore)) {
            write-warning "NoVersion in PSd1"
        } else {
            $psd1VersionBefore = $psd1VersionBefore.Split('=')[1].Replace("'", '').Trim()
        }


        $newVersionFile = Join-Path $Script:DeployTargetPath "Version.nfo"
        Write-Host "Current  Version : $CurrVersion" -f Blue
        Write-Host "Updating Version File : $newVersionFile" -f Blue
        Set-Content -Path "$newVersionFile" -Value "$CurrVersion" -Force

        Write-Host "Updating Module File : $dstpsm1path" -f Blue
        Copy-Item -Path "$srcpsm1path" -Destination "$dstpsm1path" -Force
        Write-Host "Updating Manifest File : $dstpsd1path" -f Blue
        Copy-Item -Path "$srcpsd1path" -Destination "$dstpsd1path" -Force

        $psd1VersionAfter = get-content $dstpsd1path | Select-String "ModuleVersion " -Raw
        if ([string]::IsNullOrEmpty($psd1VersionAfter)) {
            write-warning "NoVersion in PSd1"
        } else {
            $psd1VersionAfter = $psd1VersionAfter.Split('=')[1].Replace("'", '').Trim()
        }

        Write-Host "Original Manifest Version : $psd1VersionBefore" -f Blue
        Write-Host "Updated  Manifest Version : $psd1VersionAfter" -f Blue

        # Run gpush in ../CTLive
        Push-Location $Script:DeployTargetPath
        try {
            Write-Host "Running gpush in $Script:DeployTargetPath..." -f Blue
            gpush
        }
        finally {
            Pop-Location
        }


    }

} catch {
    Write-Error -Message "Build Failure"
    Show-ExceptionDetails ($_) -ShowStack
}


