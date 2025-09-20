


[CmdletBinding(SupportsShouldProcess)]
param()


function Register-HtmlAgilityPack {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Path
    )
    begin {
        $libsPath = Get-HardwareMonitorQueryModuleLibsPath
        if ([string]::IsNullOrEmpty($Path)) {
            $Path = "{0}\lib\{1}\HtmlAgilityPack.dll" -f "$libsPath", "$($PSVersionTable.PSEdition)"
        }
    }
    process {
        try {
            if (-not (Test-Path -Path "$Path" -PathType Leaf)) { throw "no such file `"$Path`"" }
            if (!("HtmlAgilityPack.HtmlDocument" -as [type])) {
                Write-Verbose "Registering HtmlAgilityPack... "
                add-type -Path "$Path"
            } else {
                Write-Verbose "HtmlAgilityPack already registered "
            }
        } catch {
            throw $_
        }
    }
}


function Get-MassoList {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [int]$Page = 1
    )

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        
        $HtmlContent = Get-StatisticsPageSource

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)


    } catch {
        Write-Verbose "$_"
        Write-Host "Error Occured. Probably Invalid Page Id" -f DarkRed
    }
    return $Null
}



function Search-Masso {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$Name
    )

    process {
        try {
            $AllResults = @{}
            $PageId = 1
            $Succeeded = $True
            while ($Succeeded) {
                $r = Get-MassoList -Page $PageId
                $PageId++
                if ($r -eq $Null) {
                    $Succeeded = $False
                } else {
                    $AllResults += $r
                }
            }

            $AllResults

            foreach ($info in $AllResults.Keys) {
                $PersonName = $info
                $WebSite = $($AllResults["$info"])
                if ($PersonName -match "$Name") {
                    Write-Host "Found!"
                    Write-Host "$Name"
                    Write-Host "$WebSite"
                    & (Get-ChromePath) "$WebSite"
                    continue;
                }
            }
        } catch {
            throw $_
        }
    }
}



function Get-StatisticsPageSource {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Uri = "http://172.17.32.1:8085"
    )
    try {
        $headers = @{
            "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
            "Accept-Encoding" = "gzip, deflate"
            "Accept-Language" = "en-US,en;q=0.8"
            "Sec-GPC" = "1"
            "Upgrade-Insecure-Requests" = "1"
        }
        $Res = Invoke-WebRequest -UseBasicParsing -Uri $Uri -Headers $headers -ErrorAction Stop
        if ($Res.StatusCode -ne 200) {
            throw "$_"
        }
        return $Res.Content
    } catch {
        Write-Error "$_"
    }
}
