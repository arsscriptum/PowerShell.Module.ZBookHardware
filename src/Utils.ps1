function Get-ProxyLogPath {
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [int]$ProcessId
    )

    if ($ProcessId) {
        return "$ENV:TEMP\Proxy_$ProcessId.log"
    } else {
        $latestLog = Get-ChildItem -Path "$ENV:TEMP" -File -Filter "Proxy_*.log" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

        return $latestLog?.FullName
    }
}

function Invoke-TailFile {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "File not found: $FilePath"
        return
    }

    $fs = [System.IO.File]::Open($FilePath, 'Open', 'Read', 'ReadWrite')
    $sr = New-Object System.IO.StreamReader ($fs)
    $fs.Seek(0, [System.IO.SeekOrigin]::End) | Out-Null

    try {
        while ($true) {
            if ($sr.EndOfStream) {
                Start-Sleep -Milliseconds 500
            } else {
                Write-Host $sr.ReadLine()
            }
        }
    } finally {
        $sr.Close()
        $fs.Close()
    }
}
