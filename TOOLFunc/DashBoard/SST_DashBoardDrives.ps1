function SST_DashBoardDrives {
    [CmdletBinding()]
    param (
        $STODriveCollection
    )
    
    begin {
        
    }
    
    process {

        #DriveID, Slot, ProductID, DriveStatus, FWlev, LatestDriveFW, DriveCap, PhyDriveCap, PhyUsedDriveCap, EffeUsedDriveCap, DeviceSN, DeviceWWNN, TimeStamp
        while ($STODriveCollection.Read()) {
            $DeviceSN = $STODriveCollection["DeviceSN"] 
            $FWlev = $STODriveCollection["FWlev"]
            $LatestDriveFW = $STODriveCollection["LatestDriveFW"]
            $Name = $STODriveCollection["Name"]
            $ProductID = $STODriveCollection["ProductID"]

            if($ProductID -ne $ProductIDOld){
                Write-Host $FWlev / $LatestDriveFW
                if($TD_TB_NKNResOne.Text -eq ""){
                    $TD_TB_NKNDescrOne.Text = "$Name Drive FW:"
                    $TD_TB_NKNResOne.Text = "$FWlev / $LatestDriveFW"
                    $TD_TB_NKNDescrOne.Visibility = "visible"
                    $TD_TB_NKNResOne.Visibility = "visible"
                    #if("$FWlev" -like "*$LatestDriveFW*"){
                    #    $TD_TB_NKNResOne.Foreground = "Green"
                    #}else {
                    #    $TD_TB_NKNResOne.Foreground = "Orange"
                    #}
                }elseif ($TD_TB_NKNResTwo.Text -eq "") {
                    $TD_TB_NKNDescrTwo.Text = "$Name Drive FW:"
                    $TD_TB_NKNResTwo.Text = "$FWlev / $LatestDriveFW"
                    $TD_TB_NKNDescrTwo.Visibility = "visible"
                    $TD_TB_NKNResTwo.Visibility = "visible"
                    #if($FWlev -eq $LatestDriveFW){
                    #    $TD_TB_NKNResTwo.Foreground = "Green"
                    #}else {
                    #    $TD_TB_NKNResTwo.Foreground = "Orange"
                    #}
                }else{
                    $TD_TB_NKNDescrThree.Text = "$Name Drive FW:"
                    $TD_TB_NKNResThree.Text = "$FWlev / $LatestDriveFW"
                    $TD_TB_NKNDescrThree.Visibility = "visible"
                    $TD_TB_NKNResThree.Visibility = "visible"
                    #if($FWlev -eq $LatestDriveFW){
                    #    $TD_TB_NKNResThree.Foreground = "Green"
                    #}else {
                    #    $TD_TB_NKNResThree.Foreground = "Orange"
                    #}
                }
                $ProductIDOld = $ProductID
            }

        }
        
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}
<#
        DriveID       = $reader["DriveID"]
        Slot          = $reader["Slot"]
        ProductID     = $reader["ProductID"]
        DriveStatus   = $reader["DriveStatus"]
        FWlev         = $reader["FWlev"]
        LatestDriveFW = $reader["LatestDriveFW"]
        DriveCap      = $reader["DriveCap"]
        DeviceSN      = $reader["DeviceSN"]
        TimeStamp     = $reader["TimeStamp"]
        NodeName      = $reader["Name"]
        ClusterName   = $reader["ClusterName"]
        CodeLevel     = $reader["CodeLevel"]
        ProdMTM       = $reader["ProdMTM"]
#>