function SST_PRISMLocalDataCheck {
     [CmdletBinding()]
    param (
        $PSRootPath
    )
    $ErrorActionPreference="SilentlyContinue"
    $DBPath = Join-Path $PSRootPath "Resources\DBFolder\ToolDB\ToolDB.db"
    $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"
    $SQLiteConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString

    try {
        $SQLiteConnection.Open()
        $countCmd = $SQLiteConnection.CreateCommand()
        $countCmd.CommandText = "SELECT 1 FROM AdvSettings LIMIT 1;"
        $hasRows = $null -ne $countCmd.ExecuteScalar()

        return $hasRows

    }
    finally {
        if ($countCmd) {$countCmd.Dispose()}
        if ($SQLiteConnection.State -eq 'Open') { $SQLiteConnection.Close() }
        $SQLiteConnection.Dispose()
    }
}