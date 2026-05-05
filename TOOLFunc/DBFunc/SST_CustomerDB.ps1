function SST_CustomerDB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("SaveCustomerSetUp","LoadCustomerSetUp")]
        [string]$SST_InfoType,
        [string]$SST_Customer,
        $SST_NewDBObject
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"

    if (-not [string]::IsNullOrWhiteSpace($SST_Customer)) {
        $Customer = $SST_Customer
    } elseif (-not [string]::IsNullOrWhiteSpace($TD_TB_CustomerInfoName.Text)) {
        $Customer = $TD_TB_CustomerInfoName.Text
    } else {
        $Customer = $SST_NewDBObject.CustomerNumber
    }

    $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
    $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"
    $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
    $SQLiteCommandCreate = $null
    $SQLiteCommand = $null
    $SQLiteReader = $null

    try {
        $SQLiteDBConnection.Open()

        # Table sicherstellen
        $SQLiteCommandCreate = $SQLiteDBConnection.CreateCommand()
        $SQLiteCommandCreate.CommandText = "CREATE TABLE IF NOT EXISTS CustomerToolSetUpDB ( CustomerNumber TEXT PRIMARY KEY, ExportPath TEXT, ExportPathCredential TEXT, TimeStamp TEXT);"
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        switch ($SST_InfoType) {

            "SaveCustomerSetUp" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = " INSERT INTO CustomerToolSetUpDB (CustomerNumber, ExportPath, ExportPathCredential, TimeStamp) VALUES (@CustomerNumber, @ExportPath, @ExportPathCredential, @TimeStamp) ON CONFLICT(CustomerNumber) DO UPDATE SET ExportPath = excluded.ExportPath, ExportPathCredential = excluded.ExportPathCredential, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@CustomerNumber", $Customer) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@ExportPath", $SST_NewDBObject.ExportPath) |Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@ExportPathCredential", $SST_NewDBObject.ExportPathCredential) |Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return
            }

            "LoadCustomerSetUp" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT CustomerNumber, ExportPath, ExportPathCredential, TimeStamp FROM CustomerToolSetUpDB WHERE CustomerNumber = @CustomerNumber;"
                $SQLiteCommand.Parameters.AddWithValue("@CustomerNumber", $Customer) | Out-Null

                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if ($SQLiteReader.Read()) {
                    return [pscustomobject]@{
                        CustomerNumber         = $SQLiteReader["CustomerNumber"]
                        ExportPath           = $SQLiteReader["ExportPath"]
                        ExportPathCredential = $SQLiteReader["ExportPathCredential"]
                        TimeStamp            = $SQLiteReader["TimeStamp"]
                    }
                }

                return $null
            }
        }
    }
    finally {
        if ($SQLiteReader)  { $SQLiteReader.Close(); $SQLiteReader.Dispose() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLiteCommandCreate) { $SQLiteCommandCreate.Dispose() }
        if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }

        # wenn du danach Dateien löschen willst, extra gut:
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}
