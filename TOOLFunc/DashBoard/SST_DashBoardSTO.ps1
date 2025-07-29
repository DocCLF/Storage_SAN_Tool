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
        $DeviceCounter = 0
        while ($STOHWCollection.Read()) {
            # $ID    = $STOHWCollection["DID"]
            $Name  = $STOHWCollection["Name"]
            $ClusterName = $STOHWCollection["ClusterName"]
            # $WWNN = $STOHWCollection["WWNN"]
            $Status    = $STOHWCollection["Status"]
            # $IOgroupid  = $STOHWCollection["IOgroupid"]
            # $IOgroupName = $STOHWCollection["IOgroupName"]
            $SerialNumber    = $STOHWCollection["SerialNumber"]
            $CodeLevel  = $STOHWCollection["CodeLevel"]
            # $ConfigNode = $STOHWCollection["ConfigNode"]
            # $SideID    = $STOHWCollection["SideID"]
            $ProdMTM  = $STOHWCollection["ProdMTM"]
            $RecommendedPTF = $STOHWCollection["RecommendedPTF"]
            $MDiskTotalCapacity = $STOHWCollection["MDiskTC"]
            #$MDiskFreeCapacity = $STOHWCollection["MDiskFC"]
            $MDiskUsedCapacity = $STOHWCollection["MDiskUC"]
            $TimeStamp = $STOHWCollection["TimeStamp"]

            if(($ProdMTM -like "2145*") -or ($ProdMTM -like "2147*")){
                $SST_BTN_Content="ClusterName: $ClusterName`nName:   $Name`nStatus:   $Status`nMTM:    $ProdMTM`nSN:        $SerialNumber`nFW:        $CodeLevel`nFW Rec: $RecommendedPTF"
            }else {
                <# Action when all if and elseif conditions are false #>
                If([string]::IsNullOrWhiteSpace($RecommendedPTF)){$RecommendedPTF = "none"}
                $SST_BTN_Content="ClusterName: $ClusterName`nStatus:   $Status`nMTM:    $ProdMTM`nSN:        $SerialNumber`nFW:        $CodeLevel`nFW Rec: $RecommendedPTF"
            }
            if($SerialNumber -ne $SerialNumberOld){
                $DeviceCounter++
                $SerialNumberOld = $SerialNumber
            }
            <# Device Details push to the TB and BTN #>
            $TD_TB_STO_DevOne,$TD_TB_STO_DevTwo,$TD_TB_STO_DevThree,$TD_TB_STO_DevFour,$TD_TB_STO_DevFive,$TD_TB_STO_DevSix,$TD_TB_STO_DevSeven,$TD_TB_STO_DevEight |ForEach-Object {
                $SST_CheckBTN_Content = $_.Text
                if((!([string]::IsNullOrWhiteSpace($SST_BTN_Content))) -and ([string]::IsNullOrWhiteSpace($SST_CheckBTN_Content))){
                    $_.Text = $SST_BTN_Content
                    $_.Visibility = "Visible"
                    $TB_Name = $_.Name.TrimStart('TB_')
                    <# Creation Time of Report #>
                    $TD_TB_Clock_STO_DevOne,$TD_TB_Clock_STO_DevTwo,$TD_TB_Clock_STO_DevThree,$TD_TB_Clock_STO_DevFour,$TD_TB_Clock_STO_DevFive,$TD_TB_Clock_STO_DevSix,$TD_TB_Clock_STO_DevSeven,$TD_TB_Clock_STO_DevEight | ForEach-Object {
                        $TB_ClockName = $_.Name.TrimStart('TB_Clock_')
                        if($TB_Name -eq $TB_ClockName){
                            $_.Text = $TimeStamp
                        }
                    }
                    <# Capacity #>
                    $TD_PB_STO_DevOneUsed,$TD_PB_STO_DevTwoUsed,$TD_PB_STO_DevThreeUsed,$TD_PB_STO_DevFourUsed,$TD_PB_STO_DevFiveUsed,$TD_PB_STO_DevSixUsed,$TD_PB_STO_DevSevenUsed,$TD_PB_STO_DevEightUsed | ForEach-Object {
                        
                        if($($_.Name) -like "*$TB_Name*"){
                            $_.Value = $MDiskUsedCapacity.TrimEnd('TB')
                            $PercentFillGrad = ($MDiskUsedCapacity/$MDiskTotalCapacity)*100
                            if([math]::Round($PercentFillGrad) -gt 90){
                                $_.Foreground = "red"
                            }
                        }
                        
                    }
                    $TD_TB_STO_DevOneTotal,$TD_TB_STO_DevTwoTotal,$TD_TB_STO_DevThreeTotal,$TD_TB_STO_DevFourTotal,$TD_TB_STO_DevFiveTotal,$TD_TB_STO_DevSixTotal,$TD_TB_STO_DevSevenTotal,$TD_TB_STO_DevEightTotal | ForEach-Object {
                        if($($_.Name) -like "*$TB_Name*"){
                            $_.Text = $MDiskTotalCapacity
                        }
                    }
                    <# Visibility of Button where the Datas in #>
                    $TD_BTN_STO_DevOne,$TD_BTN_STO_DevTwo,$TD_BTN_STO_DevThree,$TD_BTN_STO_DevFour,$TD_BTN_STO_DevFive,$TD_BTN_STO_DevSix,$TD_BTN_STO_DevSeven,$TD_BTN_STO_DevEight |ForEach-Object {
                        if($($_.Name) -like "*$TB_Name"){
                            $_.Visibility = "Visible"
                        }
                    }
                    $SST_BTN_Content = $null
                }
            }
        }
        $TD_TB_STODEVCount.Text = $DeviceCounter
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}
