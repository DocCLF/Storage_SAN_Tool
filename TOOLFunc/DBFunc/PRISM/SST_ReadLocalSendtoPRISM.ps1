function SST_ReadLocalSendtoPRISM {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("StorageDrive","StorageBase","StorageEventLog","SANBase","PowerHMC","PowerSysSummary","LPARSummary","LibraryBaseInfo","LibraryDrive","LibraryEvents","LibraryReports")]
        [string]$SST_InfoType,
        $SST_Customer,
        [int]$Top = 1,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"

        $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$SST_Customer.db"
        $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"
        $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
        $SQLiteCommand = $null
    }
    
    process {
        try {
            $SQLiteDBConnection.Open()
            $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
            
            switch ($SST_InfoType) {

                "StorageBase" {
                    $SQLiteCommand.CommandText = "SELECT * FROM IBMSTOHWTable WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "StorageDrive" {
                    $SQLiteCommand.CommandText = "SELECT * FROM IBMSTODriveTable WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "StorageEventLog" {
                    $SQLiteCommand.CommandText = "SELECT * FROM IBMSTOEventsTable WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "SANBase" {
                    $SQLiteCommand.CommandText = "SELECT * FROM IBMSANHWTable WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "PowerHMC" {
                    $SQLiteCommand.CommandText = "SELECT * FROM PowerHMC WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "PowerSysSummary" {
                    $SQLiteCommand.CommandText = "SELECT * FROM PowerSysSummary WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "LPARSummary" {
                    $SQLiteCommand.CommandText = "SELECT * FROM LPARSummary WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC"
                }

                "LibraryBaseInfo" { 
                    $SQLiteCommand.CommandText = "SELECT * FROM LibraryBaseInfo WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }
                "LibraryDrive" {
                    $SQLiteCommand.CommandText = "SELECT * FROM LibraryDrive WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "LibraryEvents" {
                    $SQLiteCommand.CommandText = "SELECT * FROM LibraryEvents WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC;"
                }

                "LibraryReports" {
                    $SQLiteCommand.CommandText = "SELECT * FROM LibraryReports WHERE CustomerNbr = @CustomerNbr ORDER BY TimeStamp DESC"
                }
            }

            # Parameter
            $SQLiteCommand.Parameters.Clear()
            $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $SST_Customer) | Out-Null
            #$SQLiteCommand.Parameters.AddWithValue("@Top", $Top) | Out-Null # wenn man die Ausgabe beschränken möchte!

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
        finally {
            if ($reader) { $reader.Dispose() }
            if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
            if ($SQLiteDBConnection.State -eq 'Open') { $SQLiteDBConnection.Close() }
            $SQLiteDBConnection.Dispose()
        }
    }
    
    end {
        
    }
}