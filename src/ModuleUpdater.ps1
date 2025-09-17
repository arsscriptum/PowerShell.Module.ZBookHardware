#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   moduleupdater.ps1                                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


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


function Get-ZBookHardwareModuleVersionPath {
    $ModPath = (Get-ZBookHardwareModuleInformation).ModuleInstallPath
    $VersionPath = Join-Path $ModPath 'version'
    return $VersionPath
}


function New-ZBookHardwareModuleVersionFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$AutoUpdateFlag,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $JsonPath = (Join-Path (Get-ZBookHardwareModuleVersionPath) "ZBookHardware.json")
    Write-Verbose "[Get-ZBookHardwareModuleVersionPath] JsonPath $JsonPath"
    $ZBookHardwareVersionPath = Get-ZBookHardwareModuleVersionPath

    $CurrDate = Get-Date -UFormat "%s"
    $ModuleName = (Get-ZBookHardwareModuleInformation).ModuleName.Name
    $ModuleInstallPath = (Get-ZBookHardwareModuleInformation).ModuleInstallPath
    $ModulePath = (Get-ZBookHardwareModuleInformation).ModulePath

    $psm1path = (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psm1'
    $psd1path = (Join-Path "$ModuleInstallPath" "$ModuleName") + '.psd1'

    Write-Verbose "[Get-ZBookHardwareModuleVersionPath]`n - CurrDate $CurrDate`n - ModuleName $ModuleName`n - ModuleInstallPath $ModuleInstallPath`n - ModulePath $ModulePath`n - psm1path $psm1path`n - psd1path $psd1path"

    $ValidFiles = ((Test-Path "$psm1path") -and (Test-Path "$psd1path"))
    if (!$ValidFiles) {
        Write-Error "Missing Module File"
    }

    $GetUpdateUrlCmd = Get-Command -Name "Get-PowerShellModulesUpdateUrl" -CommandType Function -Module "PowerShell.Module.Core" -ErrorAction Ignore

    $UpdateBaseUrl = "https://arsscriptum.github.io"

    if ($GetUpdateUrlCmd -ne $Null) {
        $UpdateBaseUrl = Get-PowerShellModulesUpdateUrl
    }
    if ($GetUpdateUrlCmd -ne $Null) {
        $UpdateBaseUrl = Get-PowerShellModulesUpdateUrl
        Write-Verbose "[Get-ZBookHardwareModuleVersionPath] Command Get-PowerShellModulesUpdateUrl found in Core. Overriding UpdateURL with $UpdateBaseUrl"
    }else{
        Write-Verbose "[Get-ZBookHardwareModuleVersionPath] UpdateURL defaults to $UpdateBaseUrl"
    }
    $UpdateUrl = "{0}/{1}" -f $UpdateBaseUrl, $ModuleName
    $VersionUrl = "{0}/{1}/Version.nfo" -f $UpdateBaseUrl, $ModuleName
    $CurrVersion = Get-ZBookHardwareModuleVersion
    Write-Verbose "[Get-ZBookHardwareModuleVersionPath]`n - UpdateUrl $UpdateUrl`n - VersionUrl $VersionUrl`n - CurrVersion $CurrVersion`n"

    $ShouldOverwrite = $False
    $FileExists = (Test-Path "$JsonPath" -PathType Leaf)
    if ($Force) {
        $ShouldOverwrite = $True
    }

    Write-Verbose "[Get-ZBookHardwareModuleVersionPath] Force $Force . File $JsonPath Exists? $FileExists. ShouldOverwrite $ShouldOverwrite"

    if ((!($FileExists)) -or ($ShouldOverwrite)) {
        [pscustomobject]$o = [pscustomobject]@{
            CurrentVersion = "$CurrVersion"
            LastUpdate = "$CurrDate"
            UpdateUrl = "$UpdateUrl"
            VersionUrl = "$VersionUrl"
            ModuleName = "$ModuleName"
            AutoUpdate = $AutoUpdateFlag
            LocalPSM1 = "$psm1path"
            LocalPSD1 = "$psd1path"
        }
        $NewFileJsonData = $o | ConvertTo-Json
        New-Item -Path "$JsonPath" -ItemType File -Force -EA Stop -Value $NewFileJsonData | Out-Null
        Write-Host "[Get-ZBookHardwareModuleVersionPath] Wrote $JsonPath"
    }
}

function Set-ZBookHardwareAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $true)]
        [bool]$Enable
    )


    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ZBookHardware\ZBookHardwareAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        New-Item -Path $RegKeyRoot -Force | Out-Null
    }
    $Val = if($Enable){1}else{0}

    # Set the registry key as REG_MULTI_SZ (array of strings)
    Set-ItemProperty -Path $RegKeyRoot -Name "override" -Value $Val -Type DWORD
}


function Get-ZBookHardwareAutoUpdateOverride {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $RegKeyRoot = "HKCU:\Software\arsscriptum\PowerShell.Module.ZBookHardware\ZBookHardwareAutoUpdate"

    # Ensure the registry path exists
    if (-not (Test-Path $RegKeyRoot)) {
        return $False
    }

    # Set the registry key as REG_MULTI_SZ (array of strings)
    $RegVal = Get-ItemProperty -Path $RegKeyRoot -Name "override" -ErrorAction Ignore
    if (-not ($RegVal)) {
        return $False
    }
    if($RegVal.override){
        return $True
    }
    return $False
}

function Invoke-ZBookHardwareAutoUpdate {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        [Parameter(Mandatory = $false)]
        [switch]$Import
    )

    $ShouldBypass = Get-ZBookHardwareAutoUpdateOverride
    if($ShouldBypass){
        Write-Host "[Invoke-ZBookHardwareAutoUpdate] Bypass OVerride" -f DarkRed
        return
    }

    $ZBookHardwareVersionPath = Get-ZBookHardwareModuleVersionPath
    $JsonPath = Join-Path $ZBookHardwareVersionPath "ZBookHardware.json"

    if (!(Test-Path $JsonPath)) {
        Write-Verbose "No such file $JsonPath... creating default version file."
        New-ZBookHardwareModuleVersionFile
    }

    [version]$CurrVersion = Get-ZBookHardwareModuleVersion

    $Data = Get-Content $JsonPath | ConvertFrom-Json
    if ($Data.AutoUpdate) {
        try {
            [version]$LatestVersionStruct = Invoke-RestMethod -Uri "$($Data.VersionUrl)"
            [string]$LatestVersion = $LatestVersionStruct.ToString()
        } catch {
            Write-Warning "Cannot Update -> No Version found at $($Data.VersionUrl)"
            return
        }

        Write-Host "Current Version    $CurrVersion"
        Write-Host "Latest  Version    $LatestVersion"
        $UpdateRequired = (($LatestVersion -gt $CurrVersion) -or $Force)

        if ($UpdateRequired) {
            Write-Host "[Invoke-ZBookHardwareAutoUpdate] UpdateRequired" -f DarkRed

            $ModuleInstallPath = (Get-ZBookHardwareModuleInformation).ModuleInstallPath
            $ModuleInstallPathRoot = (Split-Path -Parent $ModuleInstallPath) 
            Write-Host "[Invoke-ZBookHardwareAutoUpdate] ModuleInstallPath     $ModuleInstallPath" -f DarkRed
            Write-Host "[Invoke-ZBookHardwareAutoUpdate] ModuleInstallPathRoot $ModuleInstallPathRoot" -f DarkRed
            $VersionFolder = Join-Path -Path "$ModuleInstallPathRoot" -ChildPath "$LatestVersion"
            if (!(Test-Path $VersionFolder)) {
                Write-Host "[Invoke-ZBookHardwareAutoUpdate] New Version Folder $VersionFolder" -f DarkRed
                New-Item -ItemType Directory -Path $VersionFolder -Force | Out-Null
            }

            $psd1path = Join-Path $VersionFolder "$($Data.ModuleName).psd1"
            $psm1path = Join-Path $VersionFolder "$($Data.ModuleName).psm1"

            $Psd1Url = "$($Data.UpdateUrl)/$($Data.ModuleName).psd1"
            $Psm1Url = "$($Data.UpdateUrl)/$($Data.ModuleName).psm1"

            Write-Host "Updating Manifest from URL $Psd1Url -> $psd1path" -f Magenta
            Invoke-WebRequest -Uri $Psd1Url -OutFile $psd1path -UseBasicParsing -ErrorAction Stop

            Write-Host "Updating Module from URL $Psm1Url -> $psm1path" -f Blue
            Invoke-WebRequest -Uri $Psm1Url -OutFile $psm1path -UseBasicParsing -ErrorAction Stop

            # Update the json
            $Data.CurrentVersion = $LatestVersion.ToString()
            $Data.LocalPSD1 = $psd1path
            $Data.LocalPSM1 = $psm1path
            $Data | ConvertTo-Json -Depth 4 | Set-Content -Path $JsonPath -Encoding UTF8

            Write-ZBookHardwareHost "✅ Module successfully updated to version $LatestVersion"
            if($Import){
             import-module "PowerShell.Module.ZBookHardware" -MinimumVersion "$LatestVersion" -Force
            }
        }
        else {
            Write-Verbose "Should Update -> No"
            Write-ZBookHardwareHost "No Update Required. Current Version is $CurrVersion"
            if ($NoUpdate) {
                return $false
            }
        }
    }
}
