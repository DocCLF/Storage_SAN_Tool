function SST_CustomerLibraryDBReadTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("GetLibrarySerialNumberMTM")]
        [string]$SST_InfoType,
        $SST_NeededInformations,
        $SST_Customer,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"

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
        try {
            $SQLiteDBConnection.Open()
            $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
            switch ($SST_InfoType) {
                "GetLibrarySerialNumberMTM" { 
                    $SQLiteCommand.CommandText = "SELECT SerialNumberMTM FROM LibraryBaseInfo WHERE CustomerNbr = @CustomerNbr AND WWNN = @WWNN;"

                    # Set parameters (important for preventing SQL injection!)
                    $SQLiteCommand.Parameters.Clear()
                    $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                    $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_NeededInformations) | Out-Null

                    #Run query
                    $result = $SQLiteCommand.ExecuteScalar()
                    return $result
                }
                Default {}
            }

        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host "SQL Read Error: $($_.Exception.Message)"
        }
        finally {
            <#Do this after the try block regardless of whether an exception occurred or not#>
            if ($reader) { $reader.Dispose() }
            if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
            if ($SQLiteDBConnection.State -eq 'Open') { $SQLiteDBConnection.Close() }
            $SQLiteDBConnection.Dispose()
        }
    }
    
    end {
        
    }
}