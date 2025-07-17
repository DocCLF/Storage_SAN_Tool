function SST_DashBoardSTO {
    [CmdletBinding()]
    param (
        $STOHWCollection
    )
    
    begin {
        $TD_BTN_STO_DevOne,$TD_BTN_STO_DevTwo,$TD_BTN_STO_DevThree,$TD_BTN_STO_DevFour,$TD_BTN_STO_DevFive,$TD_BTN_STO_DevSix,$TD_BTN_STO_DevSeven,$TD_BTN_STO_DevEight |ForEach-Object {$_.Visibility = "Collapsed"}
    }
    
    process {

        #ID, Name, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, ProdMTM, TimeStamp
        
        while ($STOHWCollection.Read()) {
            $ID    = $STOHWCollection["DID"]
            $Name  = $STOHWCollection["Name"]
            $ClusterName = $STOHWCollection["ClusterName"]
            $WWNN = $STOHWCollection["WWNN"]
            $Status    = $STOHWCollection["Status"]
            $IOgroupid  = $STOHWCollection["IOgroupid"]
            $IOgroupName = $STOHWCollection["IOgroupName"]
            $SerialNumber    = $STOHWCollection["SerialNumber"]
            $CodeLevel  = $STOHWCollection["CodeLevel"]
            $ConfigNode = $STOHWCollection["ConfigNode"]
            $SideID    = $STOHWCollection["SideID"]
            $ProdMTM  = $STOHWCollection["ProdMTM"]
            $TimeStamp = $STOHWCollection["TimeStamp"]

            if(($ProdMTM -like "2145*") -or ($ProdMTM -like "2147*")){
                $SST_BTN_Content="ClusterName: $ClusterName`nName: $Name`nStatus: $Status`nMTM:  $ProdMTM`nSN:      $SerialNumber`nFW:      $CodeLevel"
            }else {
                <# Action when all if and elseif conditions are false #>
                $SST_BTN_Content="ClusterName: $ClusterName`nStatus: $Status`nMTM:  $ProdMTM`nSN:      $SerialNumber`nFW:      $CodeLevel"
            }
            
            $TD_TB_STO_DevOne,$TD_TB_STO_DevTwo,$TD_TB_STO_DevThree,$TD_TB_STO_DevFour,$TD_TB_STO_DevFive,$TD_TB_STO_DevSix,$TD_TB_STO_DevSeven,$TD_TB_STO_DevEight |ForEach-Object {
                $SST_CheckBTN_Content = $_.Text
                if((!([string]::IsNullOrWhiteSpace($SST_BTN_Content))) -and ([string]::IsNullOrWhiteSpace($SST_CheckBTN_Content))){
                    $_.Text = $SST_BTN_Content
                    $_.Visibility = "Visible"
                    $SST_BTN_Content = $null
                    $TB_Name = $_.Name.TrimStart('TB_')
                    $TD_TB_Clock_STO_DevOne,$TD_TB_Clock_STO_DevTwo,$TD_TB_Clock_STO_DevThree,$TD_TB_Clock_STO_DevFour,$TD_TB_Clock_STO_DevFive,$TD_TB_Clock_STO_DevSix,$TD_TB_Clock_STO_DevSeven,$TD_TB_Clock_STO_DevEight | ForEach-Object {
                        $TB_ClockName = $_.Name.TrimStart('TB_Clock_')
                        if($TB_Name -eq $TB_ClockName){
                            $_.Text = $TimeStamp
                        }
                    }
                    
                    $TD_BTN_STO_DevOne,$TD_BTN_STO_DevTwo,$TD_BTN_STO_DevThree,$TD_BTN_STO_DevFour,$TD_BTN_STO_DevFive,$TD_BTN_STO_DevSix,$TD_BTN_STO_DevSeven,$TD_BTN_STO_DevEight |ForEach-Object {
                        if($($_.Name) -like "*$TB_Name"){
                            $_.Visibility = "Visible"
                        }
                    }
                }
            }
        }
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}
