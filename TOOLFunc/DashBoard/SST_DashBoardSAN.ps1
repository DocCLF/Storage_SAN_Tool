function SST_DashBoardSAN {
    [CmdletBinding()]
    param (
        $STOHWCollection
    )
    
    begin {
        $TD_BTN_SAN_DevOne,$TD_BTN_SAN_DevTwo,$TD_BTN_SAN_DevThree,$TD_BTN_SAN_DevFour,$TD_BTN_SAN_DevFive,$TD_BTN_SAN_DevSix,$TD_BTN_SAN_DevSeven,$TD_BTN_SAN_DevEight |ForEach-Object {$_.Visibility = "Collapsed"}
    }
    
    process {

        #ID, DID, Name, Status, CodeLevel, BrocadeProdName, SerialNumber, TimeStamp FROM IBMSANHWTabl
        $DeviceCounter = 0
        while ($STOHWCollection.Read()) {
            $Name  = $STOHWCollection["Name"]
            $Status    = $STOHWCollection["Status"]
            $CodeLevel  = $STOHWCollection["CodeLevel"]
            $BrocadeProdName = $STOHWCollection["BrocadeProdName"]
            $SerialNumber    = $STOHWCollection["SerialNumber"]
            $TimeStamp = $STOHWCollection["TimeStamp"]

            if($SerialNumber -ne $SerialNumberOld){
                $DeviceCounter++
                $SerialNumberOld = $SerialNumber
            }

            $SST_BTN_Content="Name: $Name`nStatus: $Status`nMTM:  $BrocadeProdName`nSN:      $SerialNumber`nFW:      $CodeLevel"
            $TD_TB_SAN_DevOne,$TD_TB_SAN_DevTwo,$TD_TB_SAN_DevThree,$TD_TB_SAN_DevFour,$TD_TB_SAN_DevFive,$TD_TB_SAN_DevSix,$TD_TB_SAN_DevSeven,$TD_TB_SAN_DevEight |ForEach-Object {
                $SST_CheckBTN_Content = $_.Text
                if((!([string]::IsNullOrWhiteSpace($SST_BTN_Content))) -and ([string]::IsNullOrWhiteSpace($SST_CheckBTN_Content))){
                    $_.Text = $SST_BTN_Content
                    $_.Visibility = "Visible"
                    $SST_BTN_Content = $null
                    $TB_Name = $_.Name.TrimStart('TB_')
                    $TD_TB_Clock_SAN_DevOne,$TD_TB_Clock_SAN_DevTwo,$TD_TB_Clock_SAN_DevThree,$TD_TB_Clock_SAN_DevFour,$TD_TB_Clock_SAN_DevFive,$TD_TB_Clock_SAN_DevSix,$TD_TB_Clock_SAN_DevSeven,$TD_TB_Clock_SAN_DevEight | ForEach-Object {
                        $TB_ClockName = $_.Name.TrimStart('TB_Clock_')
                        if($TB_Name -eq $TB_ClockName){
                            $_.Text = $TimeStamp
                        }
                    }
                    
                    $TD_BTN_SAN_DevOne,$TD_BTN_SAN_DevTwo,$TD_BTN_SAN_DevThree,$TD_BTN_SAN_DevFour,$TD_BTN_SAN_DevFive,$TD_BTN_SAN_DevSix,$TD_BTN_SAN_DevSeven,$TD_BTN_SAN_DevEight |ForEach-Object {
                        if($($_.Name) -like "*$TB_Name"){
                            $_.Visibility = "Visible"
                        }
                    }
                }
            }
        }
        $TD_TB_SANDEVCount.Text = $DeviceCounter
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}