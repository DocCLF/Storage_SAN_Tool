function SST_DashBoardEvents {
    [CmdletBinding()]
    param (
        $STOEVCollection
    )
    
    begin {
        
    }
    
    process {
        # SeqID,LastTime,ObjectType,ObjectID,ObjectName,CopyID,Status,Fixed,ErrorCode,Description,WWNN,SerialNumber
        [int]$EventCounter = 0
        while ($STOEVCollection.Read()) {

            $EventCounter++

            
        }
        #Write-Host $EventCounter
        $TD_TB_STOEventsCount.Text = $EventCounter
        if($EventCounter -ge 1){
            $TD_TB_HealthStatus.Text = "Attention"
            $TD_TB_HealthStatus.Foreground = "Orange"
            $TD_TB_STOEventsCount.Foreground = "Orange"
        }
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}