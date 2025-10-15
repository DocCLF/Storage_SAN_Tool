function SST_FOSDBFunc {
    [CmdletBinding()]
    param (
        [string]$SwitchWWN,
        [string]$SwitchPort, 
        [string]$SwitchPortState,
        $SST_SQLiteSTODashBoardQuery = $null,
        $SST_SQLiteDBReader = $null,
        [string]$PSRootPath
    )
    
    begin {
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
        
        # SELECT-Abfrage vorbereiten
        $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
    }
    
    process {
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQliteReadCMD.CommandText = " SELECT State, TimeStamp FROM IBMSANPortInfoTable WHERE SwitchWWN = @SwitchWWN AND Port = @Port ORDER BY TimeStamp DESC LIMIT 1;" 
            # Parameter sicher übergeben (SQL-Injection-Safe)
            $SST_SQliteReadCMD.Parameters.AddWithValue("@SwitchWWN", $SwitchWWN) | Out-Null
            $SST_SQliteReadCMD.Parameters.AddWithValue("@Port", $SwitchPort) | Out-Null

            $SST_SQLReader = $SST_SQliteReadCMD.ExecuteReader()
            while ($SST_SQLReader.Read) {
                $DBSwitchPortState = $SST_SQLReader["State"]
                $DBTimeStamp = $SST_SQLReader["TimeStamp"]
            }
            $SST_SQLReader.Close()
            
            if($SwitchPortState -ne $DBSwitchPortState){
                $PortStateInfo = "State change form $DBSwitchPortState to $SwitchPortState"
            }else {
                $PortStateInfo = $null
            }
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSANPortInfoTable Table" -TD_ToolMSGType Warning -TD_Shown no
        }
    }
    
    end {
        return $PortStateInfo
    }
}