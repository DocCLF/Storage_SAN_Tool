function SST_FOSDBFunc {
    [CmdletBinding()]
    param (
        [string]$SwitchWWN,
        [string]$SwitchPort, 
        [string]$SwitchPortState,
        [string]$PSRootPath
    )

    begin {
        $ErrorActionPreference = "SilentlyContinue"
        $PSRootPath = ($PSScriptRoot).Replace('\SAN\Brocade','\')

        $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
    }

    process {
        try {
            $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
            $SST_SQliteReadCMD.CommandText = @"
SELECT State, TimeStamp 
FROM IBMSANPortInfoTable 
WHERE SwitchWWN = @SwitchWWN 
AND Port = @Port 
ORDER BY TimeStamp DESC 
LIMIT 1;
"@

            $SST_SQliteReadCMD.Parameters.AddWithValue("@SwitchWWN", $SwitchWWN) | Out-Null
            $SST_SQliteReadCMD.Parameters.AddWithValue("@Port", $SwitchPort) | Out-Null

            $DBSwitchPortState = $null
            $DBTimeStamp = $null

            # Reader öffnen und Daten auslesen
            $reader = $SST_SQliteReadCMD.ExecuteReader()
            if ($reader.Read()) {
                $DBSwitchPortState = $reader["State"]
                $DBTimeStamp       = $reader["TimeStamp"]
            }
            $reader.Close()

            # Ergebnislogik
            if ($SwitchPortState -ne $DBSwitchPortState) {
                $PortStateInfo = "State change from $DBSwitchPortState to $SwitchPortState (Last update: $DBTimeStamp)"
            } else {
                $PortStateInfo = "no change"
            }

        }
        catch {
            Write-Warning "SQLite query failed: $($_.Exception.Message)"
            return $null
        }
        finally {
            if ($reader -and -not $reader.IsClosed) { $reader.Close() }
            if ($SST_SQLiteCon.State -eq 'Open') { 
                $SST_SQLiteCon.Close()
                $SST_SQLiteCon.Dispose()
            }
        }
    }
    end{
        return $PortStateInfo 
    }
}
