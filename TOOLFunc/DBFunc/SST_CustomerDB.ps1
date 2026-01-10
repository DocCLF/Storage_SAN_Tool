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
        $Customer = $SST_NewDBObject.CustomerName
    }
    Write-Host "Customer $Customer"
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
        $SQLiteCommandCreate.CommandText = "CREATE TABLE IF NOT EXISTS CustomerToolSetUpDB ( CustomerName TEXT PRIMARY KEY, ExportPath TEXT, ExportPathCredential TEXT NOT NULL, TimeStamp TEXT);"
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        switch ($SST_InfoType) {

            "SaveCustomerSetUp" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = " INSERT INTO CustomerToolSetUpDB (CustomerName, ExportPath, ExportPathCredential, TimeStamp) VALUES (@CustomerName, @ExportPath, @ExportPathCredential, @TimeStamp) ON CONFLICT(CustomerName) DO UPDATE SET ExportPath = excluded.ExportPath, ExportPathCredential = excluded.ExportPathCredential, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@CustomerName", $Customer) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@ExportPath", (if ($null -ne $SST_NewDBObject.ExportPath) { $SST_NewDBObject.ExportPath } else { '' })) |Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@ExportPathCredential", (if ($null -ne $SST_NewDBObject.ExportPathCredential) { $SST_NewDBObject.ExportPathCredential } else { '' })) |Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return
            }

            "LoadCustomerSetUp" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT CustomerName, ExportPath, ExportPathCredential, TimeStamp FROM CustomerToolSetUpDB WHERE CustomerName = @CustomerName;"
                $SQLiteCommand.Parameters.AddWithValue("@CustomerName", $Customer) | Out-Null

                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if ($SQLiteReader.Read()) {
                    return [pscustomobject]@{
                        CustomerName         = $SQLiteReader["CustomerName"]
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
