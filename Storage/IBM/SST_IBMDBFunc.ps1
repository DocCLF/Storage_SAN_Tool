function SST_IBMDBFunc {
    [CmdletBinding()]
    param (
        [string]$STOWWN,
        [string]$STOHostID, 
        [string]$STOHostState,
        [string]$STOHostName,
        [string]$PSRootPath
    )

    begin {
        $ErrorActionPreference = "SilentlyContinue"
        $PSRootPath = ($PSScriptRoot).Replace('\Storage\IBM','\')

        $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
    }

    process {
        try {
            $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
            $SST_SQliteReadCMD.CommandText = @"
SELECT Status, TimeStamp 
FROM IBMSTOHostTable 
WHERE WWNN = @WWNN 
AND HID = @HID 
ORDER BY TimeStamp DESC 
LIMIT 1;
"@

            $SST_SQliteReadCMD.Parameters.AddWithValue("@WWNN", $STOWWN) | Out-Null
            $SST_SQliteReadCMD.Parameters.AddWithValue("@HID", $STOHostID) | Out-Null

            $DBSTOHostState = $null
            $DBTimeStamp = $null

            # Reader öffnen und Daten auslesen
            $reader = $SST_SQliteReadCMD.ExecuteReader()
            if ($reader.Read()) {
                $DBSTOHostState = $reader["Status"]
                $DBTimeStamp       = $reader["TimeStamp"]
            }
            $reader.Close()

            # Ergebnislogik
            if ($STOHostState -ne $DBSTOHostState) {
                $HostStateInfo = "Status change from $DBSTOHostState to $STOHostState (Last update: $DBTimeStamp)"
                $TD_TB_STOHostStatusChangedOne.Text = "Status change from $DBSTOHostState to $STOHostState for $STOHostName (Last update: $DBTimeStamp)"
                $TD_TB_STOHostStatusChangedOne.Foreground = "OrangeRed"
                
                if($TD_TB_STOHostStatusChangedTwo.Text -eq ""){
                    $TD_TB_STOHostStatusChangedTwo.Text = "Status change from $DBSTOHostState to $STOHostState for $STOHostName (Last update: $DBTimeStamp)"
                    $TD_TB_STOHostStatusChangedTwo.Foreground = "OrangeRed"
                    $TD_TB_STOHostStatusChangedTwo.Visibility = "visible"

                }elseif ($TD_TB_STOHostStatusChangedThree.Text -eq "") {
                    $TD_TB_STOHostStatusChangedThree.Text = "Status change from $DBSTOHostState to $STOHostState for $STOHostName (Last update: $DBTimeStamp)"
                    $TD_TB_STOHostStatusChangedThree.Foreground = "OrangeRed"
                    $TD_TB_STOHostStatusChangedThree.Visibility = "visible"
 
                }elseif ($TD_TB_STOHostStatusChangedFour.Text -eq "") {
                    $TD_TB_STOHostStatusChangedFour.Text = "Status change from $DBSTOHostState to $STOHostState for $STOHostName (Last update: $DBTimeStamp)"
                    $TD_TB_STOHostStatusChangedFour.Foreground = "OrangeRed"
                    $TD_TB_STOHostStatusChangedFour.Visibility = "visible"

                }else{
                    $TD_TB_STOHostStatusChangedFive.Text = "Several hosts other than those listed here are affected. Please check your systems. (Last update: $DBTimeStamp)"
                    $TD_TB_STOHostStatusChangedFive.Foreground = "OrangeRed"
                    $TD_TB_STOHostStatusChangedFive.Visibility = "visible"
                }
                
            } else {
                $HostStateInfo = "no change"
                $TD_TB_STOHostStatusChangedOne.Text = "No changes since the last check on: $DBTimeStamp, Please Click the refresh Button to Update the DashBoard"
                $TD_TB_STOHostStatusChangedOne.Foreground = "Green"
                $TD_TB_STOHostStatusChangedOne.Visibility = "visible"
                
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
        return $HostStateInfo 
    }
}
