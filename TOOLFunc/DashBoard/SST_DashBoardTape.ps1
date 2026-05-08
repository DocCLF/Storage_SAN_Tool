function SST_DashBoardTape {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Query,
        [Parameter(Mandatory)]
        $SQLConnection
    )

    try {
        $SQLConnection.Open()
        $SQLiteCommand = $SQLConnection.CreateCommand()

        $SQLiteCommand.CommandText = $Query
        $SST_SQLiteDBReader = $SQLiteCommand.ExecuteReader()

        $DashBoardTapeView = while ($SST_SQLiteDBReader.Read()) {
            $row = [ordered]@{}
            for ($i = 0; $i -lt $SST_SQLiteDBReader.FieldCount; $i++) {
                $columnName = $SST_SQLiteDBReader.GetName($i)
                if ($SST_SQLiteDBReader.IsDBNull($i)) {
                    $row[$columnName] = $null
                }
                else {
                    $row[$columnName] = $SST_SQLiteDBReader.GetValue($i)
                }
            }
            [PSCustomObject]$row
        }

        $TD_IC_DashBoardTapeDevice.ItemsSource = @($DashBoardTapeView)
        
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    finally {
        <#Do this after the try block regardless of whether an exception occurred or not#>
        if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLConnection.State -eq 'Open') { $SQLConnection.Close() }

    }

}