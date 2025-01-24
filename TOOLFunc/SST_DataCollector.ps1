function SST_DataCollector {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        try {
            $TD_SQLConnection = New-Object System.Data.SqlClient.SqlConnection
            $TD_SQLConnection.ConnectionString = ''
            $TD_SQLConnection.Open()
            return $TD_SQLConnection
        }
        catch {
            Write-Host $_.Exception.Message
        }
    }
    
    process {
        $TD_SQLCommand = $TD_SQLConnection.CreateCommand()
        $TD_SQLCommand.CommandText="Insert into [dbo].[IBMInfo] (ID,PRODUCT_NAME,PRODUCT_MTM,PRODUCT_SN,PRODUCT_FW,PRODUCT_STATUS) values ('2','SVC','2145-SV1','64N052','8.4.0.12','degraded')"
        $TD_SQLCommand.ExecuteNonQuery()
        $TD_SQLConnection.Close()

        $TD_SQLCommand = $TD_SQLConnection.CreateCommand()
        $TD_SQLCommand.CommandText="Delete from [dbo].[IBMInfo] where ID='0'"
        $TD_SQLCommand.ExecuteNonQuery()
        $TD_SQLConnection.Close()

        $TD_SQLCommand = $TD_SQLConnection.CreateCommand()
        $TD_SQLCommand.CommandText="Select * from [dbo].[IBMInfo]"
        $TD_SQLDataAdapter=New-Object System.Data.SqlClient.SqlDataAdapter $TD_SQLCommand
        $TD_SQLData=New-Object System.Data.DataSet
        $TD_SQLDataAdapter.Fill($TD_SQLData)
        $TD_DataRes=$TD_SQLData.Tables[0]
        
        return $TD_DataRes

        $TD_SQLConnection.Close()

    }
    
    end {
        
    }
}