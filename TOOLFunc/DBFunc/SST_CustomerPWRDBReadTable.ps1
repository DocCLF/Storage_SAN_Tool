function SST_CustomerPWRDBReadTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("PowerHMC","PowerSysSummary","LPARSummary")]
        [string]$SST_InfoType,
        [string]$SST_Customer,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        if (-not [string]::IsNullOrWhiteSpace($SST_Customer)) {
            $Customer = $SST_Customer
        } elseif (-not [string]::IsNullOrWhiteSpace($TD_TB_CustomerInfoName.Text)) {
            $Customer = $TD_TB_CustomerInfoName.Text
        } else {
            $Customer = $SST_NewDBObject.CustomerNumber
        }
        #Write-Host "Customer $Customer"
        $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
        $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
        $SQLiteCommand = $null
    }
    
    process {

        switch ($SST_InfoType) {
            "PowerHMC" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.CommandText = "SELECT * FROM PowerHMC WHERE datetime(TimeStamp) >= datetime('now', 'localtime', 'localtime', '-5 minutes');"

                    $reader = $SQLiteCommand.ExecuteReader()
                    $result = while ($reader.Read()) {
                        $row = [ordered]@{}
                        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                            $columnName = $reader.GetName($i)
                            if ($reader.IsDBNull($i)) {
                                $row[$columnName] = $null
                            }
                            else {
                                $row[$columnName] = $reader.GetValue($i)
                            }
                        }
                        [PSCustomObject]$row
                    }
                    $reader.Close()
                    return $result
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    if ($reader) { $reader.Dispose() }
                    if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                    if ($SQLiteDBConnection.State -eq 'Open') { $SQLiteDBConnection.Close() }
                    $SQLiteDBConnection.Dispose()
                }

            }
            "PowerSysSummary" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.CommandText = "SELECT * FROM PowerSysSummary WHERE datetime(TimeStamp) >= datetime('now', 'localtime', '-5 minutes');"

                    $reader = $SQLiteCommand.ExecuteReader()
                    $result = while ($reader.Read()) {
                        $row = [ordered]@{}
                        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                            $columnName = $reader.GetName($i)
                            if ($reader.IsDBNull($i)) {
                                $row[$columnName] = $null
                            }
                            else {
                                $row[$columnName] = $reader.GetValue($i)
                            }
                        }
                        [PSCustomObject]$row
                    }
                    $reader.Close()
                    return $result
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    if ($reader) { $reader.Dispose() }
                    if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                    if ($SQLiteDBConnection.State -eq 'Open') { $SQLiteDBConnection.Close() }
                    $SQLiteDBConnection.Dispose()
                }

            }
            "LPARSummary" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.CommandText = "SELECT * FROM LPARSummary WHERE datetime(TimeStamp) >= datetime('now', 'localtime', '-5 minutes');"

                    $reader = $SQLiteCommand.ExecuteReader()
                    $result = while ($reader.Read()) {
                        $row = [ordered]@{}
                        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                            $columnName = $reader.GetName($i)
                            if ($reader.IsDBNull($i)) {
                                $row[$columnName] = $null
                            }
                            else {
                                $row[$columnName] = $reader.GetValue($i)
                            }
                        }
                        [PSCustomObject]$row
                    }
                    $reader.Close()
                    return $result
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    if ($reader) { $reader.Dispose() }
                    if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                    if ($SQLiteDBConnection.State -eq 'Open') { $SQLiteDBConnection.Close() }
                    $SQLiteDBConnection.Dispose()
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong during saving the $SST_InfoType data in the local db.") -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {

    }
}