### OLD UNUSED FUNCTIONS




function Update-ProxyPortStatus {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Specify the timespan (e.g., 3 days)")]
        [timespan]$Since,
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 1000
    )

    Write-Verbose "[Update-ProxyPortStatus] 1) Call Get-ExpiredProxyServers"
    $ExpiredProxyServers = Get-ExpiredProxyServers -Since $Since
    Write-Verbose "$($ExpiredProxyServers.Count) Server Expired"
    $ExpiredCount = $ExpiredProxyServers.Count
    if ($ExpiredCount -eq 0) {
        return 0
    }

    # Load the SQLite assembly
    Add-SqlLiteTypes

    # Create and open the SQLite connection
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()
    #$connection.autocommit = $True

    $UpdateSuccess = 0
    $UpdateFailure = 0
    try {
        [int]$i = 0
        foreach ($proxy in $ExpiredProxyServers) {
            $i++
            $srvHostname = $proxy.Host
            $srvPort = $proxy.Port
            $wasPortOpen = $proxy.PortOpen
            $srvHostnameLen = $srvHostname.Length


            [int]$iPort = $srvPort
            [string]$sPort = $iPort
            if ($iPort -lt 10) {
                $sPort = '    {0}' -f $iPort
            } elseif ($iPort -lt 100) {
                $sPort = '   {0}' -f $iPort
            } elseif ($iPort -lt 100) {
                $sPort = '   {0}' -f $iPort
            } elseif ($iPort -lt 1000) {
                $sPort = '  {0}' -f $iPort
            } elseif ($iPort -lt 10000) {
                $sPort = ' {0}' -f $iPort
            } else {
                $sPort = '{0}' -f $iPort
            }

            $strOPened = " [port $sPort opened]"
            $strClosed = " [port $sPort closed]"
            $strChanged = "  [ value change ]  "
            $strUnChanged = "  [  no changes  ]  "
            $strError = "  [ db add error ]  "
            $checktime = (Get-Date -AsUTC)
            $checktimeStr = $checktime.ToString("yyyy-MM-dd HH:mm:ss")
            $padLen = 19 - $srvHostnameLen
            $pad = [string]::new(' ', $padLen)
            $strLog1 = '[{0:d4}/{1:d4}]{2}{3}   ' -f $i, $ExpiredCount, $pad, $srvHostname
            Write-Host "`n$strLog1" -NoNewline -f DarkCyan
            Write-Host "testing port $sPort" -f DarkYellow -NoNewline
            $isPortOpen = Test-OpenPorts -ServerAddress $srvHostname -Ports @($srvPort) -Timeout $Timeout

            if ($wasPortOpen -ne $isPortOpen) {
                $color = 'Yellow'
                Write-Host "$strChanged" -NoNewline -f Red
                [string]$status = 'closed'
                if ($wasPortOpen) { $status = 'opened'; $color = 'Green' }
                if ($isPortOpen) {
                    Write-Host "$strOPened " -f DarkGreen -NoNewline
                    Write-Host "[was $status] " -f $color -NoNewline
                } else {
                    Write-Host "$strClosed " -f DarkRed -NoNewline
                    Write-Host "[was $status] " -f $color -NoNewline
                }
                Write-Host "[ new time $checktimeStr ] " -NoNewline


                $transaction = $connection.BeginTransaction([System.Data.IsolationLevel]::ReadUncommitted, $True)
                # Prepare update query
                $updateCommand = $connection.CreateCommand()
                $updateCommand.Transaction = $transaction

                $SqlStatement = @"
                BEGIN TRANSACTION;
                    UPDATE Proxy
                    SET PortOpen = @PortOpen, LastCheckedUTC = @LastCheckedUTC
                    WHERE Host = @Host AND Port = @Port;
                    COMMIT;
"@

                $updateCommand.CommandText = $SqlStatement
                $updateCommand.Parameters.AddWithValue("@PortOpen", $isPortOpen) | Out-Null
                $updateCommand.Parameters.AddWithValue("@LastCheckedUTC", $checktimeStr) | Out-Null
                $updateCommand.Parameters.AddWithValue("@Host", $proxyServer) | Out-Null
                $updateCommand.Parameters.AddWithValue("@Port", $proxyPort) | Out-Null


                Write-Sql "$SqlStatement" -h



                try {
                    # Execute update
                    $Updated = $updateCommand.ExecuteNonQuery() | Out-Null
                    $UpdateSuccess++

                    # Commit the transaction
                    $transaction.Commit()
                    Write-Verbose "Transaction committed successfully."

                    $success = $true
                } catch {
                    $UpdateFailure++
                }
            } else {
                $color = 'Yellow'
                [string]$status = 'closed'
                if ($wasPortOpen) { $status = 'opened'; $color = 'Green' }
                if ($isPortOpen) {
                    Write-Host "$strUnChanged " -f DarkGreen -NoNewline
                    Write-Host "[$status] " -f $color -NoNewline
                } else {
                    Write-Host "$strUnChanged " -f DarkRed -NoNewline
                    Write-Host "[$status] " -f $color -NoNewline
                }
            }
        }
        return $UpdateSuccess
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
        return 0
    } finally {
        $connection.Close()
    }
}


function Get-Forever {
    param()
    $Since = [timespan]::new([int64]::MaxValue)
    return $Since
}


function Update-Proxy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CountryCode,

        [Parameter(Mandatory = $true)]
        [string]$Hostname,

        [Parameter(Mandatory = $true)]
        [string]$City,

        [Parameter(Mandatory = $true)]
        [string]$Region,

        [Parameter(Mandatory = $true)]
        [string]$Coordinates,

        [Parameter(Mandatory = $true)]
        [string]$Org,

        [Parameter(Mandatory = $true)]
        [string]$Postal,

        [Parameter(Mandatory = $true)]
        [string]$Timezone,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 5)]
        [int]$Score
    )

    # Load SQLite assembly
    Add-SqlLiteTypes
    $Res = 0
    # Connect to the SQLite database
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()

    try {
        # Lookup the CountryId from the Countries table
        $lookupCommand = $connection.CreateCommand()
        $lookupCommand.CommandText = "SELECT Id FROM Countries WHERE CountryCode = @CountryCode"
        $lookupCommand.Parameters.AddWithValue("@CountryCode", $CountryCode) | Out-Null
        $countryId = $lookupCommand.ExecuteScalar()

        if (-not $countryId) {
            Write-Host "CountryCode '$CountryCode' not found in the Countries table." -ForegroundColor Yellow
            return
        }

        # Update the Proxy table
        $updateCommand = $connection.CreateCommand()
        $updateCommand.CommandText = @"
            UPDATE Proxy
            SET
                CountryId = @CountryId,
                City = @City,
                Region = @Region,
                Coordinates = @Coordinates,
                Org = @Org,
                Postal = @Postal,
                Timezone = @Timezone,
                Score = @Score
            WHERE Host = @Host
"@
        $updateCommand.Parameters.AddWithValue("@CountryId", $countryId) | Out-Null
        $updateCommand.Parameters.AddWithValue("@City", $City) | Out-Null
        $updateCommand.Parameters.AddWithValue("@Region", $Region) | Out-Null
        $updateCommand.Parameters.AddWithValue("@Coordinates", $Coordinates) | Out-Null
        $updateCommand.Parameters.AddWithValue("@Org", $Org) | Out-Null
        $updateCommand.Parameters.AddWithValue("@Postal", $Postal) | Out-Null
        $updateCommand.Parameters.AddWithValue("@Timezone", $Timezone) | Out-Null
        $updateCommand.Parameters.AddWithValue("@Score", $Score) | Out-Null
        $updateCommand.Parameters.AddWithValue("@Host", $Hostname) | Out-Null

        $rowsAffected = $updateCommand.ExecuteNonQuery()
        if ($rowsAffected -gt 0) {
            Write-Host "Proxy '$Hostname' updated successfully. Effects $rowsAffected" -ForegroundColor Green
        } else {
            Write-Host "No proxy found with Hostname '$Hostname' to update." -ForegroundColor Yellow
        }
        $connection.Close()
        $Res = $rowsAffected;
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    }
    return $Res
}


function Add-QosServers {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[PSCustomObject]]$Servers
    )

    # Load SQLite assembly
    Add-SqlLiteTypes

    # Connect to the SQLite database
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()

    try {
        foreach ($srv in $Servers) {
            # Lookup CountryId from the Countries table using the country name
            $lookupCommand = $connection.CreateCommand()
            $lookupCommand.CommandText = "SELECT Id FROM Countries WHERE CountryName = @CountryName"
            $lookupCommand.Parameters.AddWithValue("@CountryName", $srv.country) | Out-Null
            $countryId = $lookupCommand.ExecuteScalar()

            if (-not $countryId) {
                Write-Host "Country '$($srv.country)' not found in the Countries table. Skipping entry." -ForegroundColor Yellow
                continue
            }

            # Insert server into QosServer table
            $insertCommand = $connection.CreateCommand()
            $insertCommand.CommandText = @"
                INSERT INTO QosServer (NetworkId, Hostname, Port, Name, Location, CountryId, IpAddress, LastTestOn)
                VALUES (@NetworkId, @Hostname, @Port, @Name, @Location, @CountryId, @IpAddress, NULL)
"@
            $insertCommand.Parameters.AddWithValue("@NetworkId", $srv.id) | Out-Null
            $insertCommand.Parameters.AddWithValue("@Hostname", $srv.Host) | Out-Null
            $insertCommand.Parameters.AddWithValue("@Port", $srv.Port) | Out-Null
            $insertCommand.Parameters.AddWithValue("@Name", $srv.Name) | Out-Null
            $insertCommand.Parameters.AddWithValue("@Location", $srv.location) | Out-Null
            $insertCommand.Parameters.AddWithValue("@CountryId", $countryId) | Out-Null
            $insertCommand.Parameters.AddWithValue("@IpAddress", "") | Out-Null # Placeholder for IP Address

            $insertCommand.ExecuteNonQuery() | Out-Null
            #Write-Host "Server added: $($srv.name) ($($srv.host))" -ForegroundColor Green
            Write-Verbose "Proxy added successfully"
        }
        return $True
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
        return $False
    } finally {
        $connection.Close()
    }
}


function Add-CountriesFromJson {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path -Path "$_" -PathType Leaf })]
        [string]$Path
    )

    # Load SQLite assembly
    Add-SqlLiteTypes

    # Read and parse the JSON file
    if (-not (Test-Path $Path)) {
        Write-Host "File not found: $JsonFilePath" -ForegroundColor Red
        return
    }

    $countries = Get-Content -Path $Path | ConvertFrom-Json

    # Connect to the SQLite database
    $databasePath = Get-DatabaseFilePath
    $connectionString = "Data Source=$databasePath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection ($connectionString)
    $connection.Open()

    try {
        $NumInserts = 0
        # Insert each country into the Countries table
        foreach ($country in $countries) {
            $command = $connection.CreateCommand()
            $command.CommandText = @"
                INSERT INTO Countries (CountryName, CountryCode)
                VALUES (@CountryName, @CountryCode)
"@
            $command.Parameters.AddWithValue("@CountryName", $country.country) | Out-Null
            $command.Parameters.AddWithValue("@CountryCode", $country.Code) | Out-Null

            try {
                $command.ExecuteNonQuery() | Out-Null
                Write-Host "Inserted: $($country.Country) ($($country.Code)), " -ForegroundColor DarkGray -NoNewline
                $NumInserts++
            } catch {
                Write-Host "Failed to insert $($country.Country) ($($country.Code)). Error: $_" -ForegroundColor Yellow
            }
        }
    } catch {
        Show-ExceptionDetails ($_) -ShowStack
    } finally {
        $connection.Close()
        Write-Host "DOne`n"
    }
}
