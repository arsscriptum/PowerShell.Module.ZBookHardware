#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   moduleupdater.ps1                                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-ZBookModuleVersion {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Latest
    )


    if($Latest){
        Write-Verbose "[Get-ZBookModuleVersion] Get Latest (Online) $Latest"

        $ZBookVersionPath = Get-ZBookModuleVersionPath
        $JsonPath = Join-Path $ZBookVersionPath "ZBook.json"

        if (!(Test-Path $JsonPath)) {
            Write-Error "module not initialized! no file $JsonPath"
            return $Null
        }

        [version]$CurrVersion = Get-ZBookModuleVersion
        Write-Verbose "[Get-ZBookModuleVersion] CurrVersion $CurrVersion"
        Write-Verbose "[Get-ZBookModuleVersion] JsonPath $JsonPath"
        $Data = Get-Content $JsonPath | ConvertFrom-Json
        Write-Verbose "[Get-ZBookModuleVersion] JSON DATA`n------`n$Data`n-------`n"
        

        [version]$LatestVersion = Invoke-RestMethod -Uri "$($Data.VersionUrl)"
        Write-Verbose "[Get-ZBookModuleVersion] LatestVersion $($LatestVersion.ToString())"
        return $LatestVersion.ToString()
    }else{
        Write-Verbose "[Get-ZBookModuleVersion] Get Local Version 1.7.176 "
    }

    $Version = "1.7.176"
    return $Version
}

