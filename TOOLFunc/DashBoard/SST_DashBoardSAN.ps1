function SST_DashBoardSAN {
    [CmdletBinding()]
    param (
        $SANHWCollection,
        $SQLReader
    )
    
    begin {
        $DeviceCounter = 0
        $SQLReader.CommandText = $SANHWCollection
        $SST_SQLiteDBReader = $SQLReader.ExecuteReader()
    }
    
    process {

        #ID, DID, Name, Status, CodeLevel, BrocadeProdName, SerialNumber, TimeStamp FROM IBMSANHWTabl
        while ($SST_SQLiteDBReader.Read()) {
            $DeviceCounter++
            $DashBoardSANsObj = [PSCustomObject]@{
            Name  = $SST_SQLiteDBReader["Name"]
            Status    = $SST_SQLiteDBReader["Status"]
            CodeLevel  = $SST_SQLiteDBReader["CodeLevel"]
            CodeLevelLV  = $SST_SQLiteDBReader["CodeLevelLV"] -replace '(EOS [\w]{3} [\d]{2}, [\d]{4}, latest version |latest version )','v'
            CodeLevelLVInfo  = $SST_SQLiteDBReader["CodeLevelLV"]
            BrocadeProdName = $SST_SQLiteDBReader["BrocadeProdName"]
            MTM = $SST_SQLiteDBReader["MTM"]
            SerialNumber    = $SST_SQLiteDBReader["SerialNumber"]
            TimeStamp = $SST_SQLiteDBReader["TimeStamp"]
            BrocadeIcon = "$PSRootPath\Resources\Icons\broadcom-96.png"
            ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
            }
            $DashBoardSANDeviceView.Add($DashBoardSANsObj)
        }
        
        $SST_SQLiteDBReader.Close()
        $TD_IC_DashBoardSANDevice.ItemsSource = $DashBoardSANDeviceView

        $TD_TB_SANDEVCount.Text = $DeviceCounter

        foreach ($SAN in $DashBoardSANDeviceView){
            if($SAN.SerialNumber -ne $SerialNumberOld){
                
                if($TD_TB_SANFOSOne.Text -eq ""){
                    $TD_TB_SANFOSOne.Text = "$($SAN.CodeLevel) / $($SAN.CodeLevelLV) / v9.2.x"
                    $TD_TB_SANFOSOne.Visibility = "visible"
                    if($($SAN.CodeLevelLV) -like "*$($SAN.CodeLevel)*"){
                        $TD_TB_SANFOSOne.Foreground = "Green"
                    }else {
                        $TD_TB_SANFOSOne.Foreground = "DarkOrange"
                    }
                }elseif ($TD_TB_SANFOSTwo.Text -eq "") {
                    $TD_TB_SANFOSTwo.Text = "$($SAN.CodeLevel) / $($SAN.CodeLevelLV) / v9.2.x"
                    $TD_TB_SANFOSTwo.Visibility = "visible"
                    if($($SAN.CodeLevelLV) -like "*$($SAN.CodeLevel)*"){
                        $TD_TB_SANFOSTwo.Foreground = "Green"
                    }else {
                        $TD_TB_SANFOSTwo.Foreground = "DarkOrange"
                    }
                }elseif ($TD_TB_SANFOSThree.Text -eq "") {
                    $TD_TB_SANFOSThree.Text = "$($SAN.CodeLevel) / $($SAN.CodeLevelLV) / v9.2.x"
                    $TD_TB_SANFOSThree.Visibility = "visible"
                    if($($SAN.CodeLevelLV) -like "*$($SAN.CodeLevel)*"){
                        $TD_TB_SANFOSThree.Foreground = "Green"
                    }else {
                        $TD_TB_SANFOSThree.Foreground = "DarkOrange"
                    }
                }else{
                    $TD_TB_SANFOSFour.Text = "$($SAN.CodeLevel) / $($SAN.CodeLevelLV) / v9.2.x"
                    $TD_TB_SANFOSFour.Visibility = "visible"
                    if($($SAN.CodeLevelLV) -like "*$($SAN.CodeLevel)*"){
                        $TD_TB_SANFOSFour.Foreground = "Green"
                    }else {
                        $TD_TB_SANFOSFour.Foreground = "DarkOrange"
                    }
                }
                $SerialNumberOld = $SAN.SerialNumber
            }
        }

    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}