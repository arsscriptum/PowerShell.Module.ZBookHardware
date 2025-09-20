#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   Miscellaneous.ps1                                                            ║
#║   vaious helper funcs                                                          ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



# Sample Code For Example Only 


function Get-HardwareMonitorQueryModuleInformation{
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

function Get-HardwareMonitorQueryModuleExportsPath{   
    $ModPath = (Get-HardwareMonitorQueryModuleInformation).ModuleScriptPath
    $ExportsPath = Join-Path $ModPath 'exports'
    return $ExportsPath
}

function Get-HardwareMonitorQueryModuleLibsPath{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $ExportsPath = Get-HardwareMonitorQueryModuleExportsPath
    $LibsPath = (Join-Path $ExportsPath "lib")  
    return $LibsPath
    
}
