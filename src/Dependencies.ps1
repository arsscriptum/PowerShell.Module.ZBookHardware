
#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   EcRegister.ps1                                                               ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝


function Get-Depdendencies {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory = $true, position = 0)]
        [string]$Path,
        [Parameter(Mandatory = $False)]
        [int]$Depth = 3
    )
    $JsonDepth = 99999
    [System.Collections.ArrayList]$List = [System.Collections.ArrayList]::new()
    #This will self elevate the script so with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
    $deps = & "C:\Programs\Dependencies\x64\Dependencies.exe" "-depth" "$Depth" "-chain" "-json" "$Path" | ConvertFrom-Json -Depth $JsonDepth
    $deps.GetModules.PSObject.Properties.ForEach({ [pscustomobject]$o = [pscustomobject]@{
                Name = "$($_.Value.ModuleName)"
                Path = "$($_.Value.FilePath)"
            }
            [void]$List.Add($o)
        })


    $List | Sort -Property Path
}

function Add-DependenciesContextMenu {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$DependenciesPath = "C:\Programs\Dependencies\x64\DependenciesGui.exe"
    )

    if (-not (Test-Path $DependenciesPath)) {
        Write-Error "DependenciesGui.exe not found at: $DependenciesPath"
        return
    }

    $menuName = "Open with Dependencies"
    $command = "`"$DependenciesPath`" `"%1`""

    # For EXE files
    $exeBase = "Registry::HKEY_CLASSES_ROOT\exefile\shell\$menuName"
    $exeCmd = "$exeBase\command"
    New-Item -Path $exeCmd -Force | Out-Null
    Set-ItemProperty -Path $exeCmd -Name "(default)" -Value $command

    # For DLL files (default class is 'dllfile')
    $dllBase = "Registry::HKEY_CLASSES_ROOT\dllfile\shell\$menuName"
    $dllCmd = "$dllBase\command"
    New-Item -Path $dllCmd -Force | Out-Null
    Set-ItemProperty -Path $dllCmd -Name "(default)" -Value $command

    Write-Host "Context menu option 'Open with Dependencies' added for .exe and .dll files." -ForegroundColor Green
}

# Usage:
# Add-DependenciesContextMenu
