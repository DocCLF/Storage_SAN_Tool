function SST_DashBoardHosts {
    [CmdletBinding()]
 param (
        $STOHWCollection
    )
    
    begin {
        $TD_BTN_STO_HostOne,$TD_BTN_STO_HostTwo,$TD_BTN_STO_HostThree,$TD_BTN_STO_HostFour,$TD_BTN_STO_HostFive,$TD_BTN_STO_HostSix,$TD_BTN_STO_HostSeven,$TD_BTN_STO_HostEight,$TD_BTN_STO_HostNine,$TD_BTN_STO_HostTen,$TD_BTN_STO_HostEleven,$TD_BTN_STO_HostTwelve,$TD_BTN_STO_HostThirteen,$TD_BTN_STO_HostFourteen,$TD_BTN_STO_HostFifteen,$TD_BTN_STO_HostSixteen |ForEach-Object {$_.Visibility = "Collapsed"}
    }
    
    process {

        #ID, HID, Name, Status, HostClusterName, SideName, TimeStamp FROM IBMSTOHostTable

        while ($STOHWCollection.Read()) {
            $HID    = $STOHWCollection["HID"]
            $Name  = $STOHWCollection["Name"]
            $Status = $STOHWCollection["Status"]
            $HostClusterName    = $STOHWCollection["HostClusterName"]
            $SideName  = $STOHWCollection["SideName"]
            $TimeStamp = $STOHWCollection["TimeStamp"]

            $SST_BTN_Content="HostName: $Name`nHostCluster: $HostClusterName`nStatus:  $Status`nSideName: $SideName"
            $TD_TB_STO_HostOne,$TD_TB_STO_HostTwo,$TD_TB_STO_HostThree,$TD_TB_STO_HostFour,$TD_TB_STO_HostFive,$TD_TB_STO_HostSix,$TD_TB_STO_HostSeven,$TD_TB_STO_HostEight,$TD_TB_STO_HostNine,$TD_TB_STO_HostTen,$TD_TB_STO_HostEleven,$TD_TB_STO_HostTwelve,$TD_TB_STO_HostThirteen,$TD_TB_STO_HostFourteen,$TD_TB_STO_HostFifteen,$TD_TB_STO_HostSixteen |ForEach-Object {
                $SST_CheckBTN_Content = $_.Text
                if((!([string]::IsNullOrWhiteSpace($SST_BTN_Content))) -and ([string]::IsNullOrWhiteSpace($SST_CheckBTN_Content))){
                    $_.Text = $SST_BTN_Content
                    $_.Visibility = "Visible"
                    $SST_BTN_Content = $null
                    $TB_Name = $_.Name.TrimStart('TB_')
                    $TD_TB_Clock_STO_HostOne,$TD_TB_Clock_STO_HostTwo,$TD_TB_Clock_STO_HostThree,$TD_TB_Clock_STO_HostFour,$TD_TB_Clock_STO_HostFive,$TD_TB_Clock_STO_HostSix,$TD_TB_Clock_STO_HostSeven,$TD_TB_Clock_STO_HostEight,$TD_TB_Clock_STO_HostNine,$TD_TB_Clock_STO_HostTen,$TD_TB_Clock_STO_HostEleven,$TD_TB_Clock_STO_HostTwelve,$TD_TB_Clock_STO_HostThirteen,$TD_TB_Clock_STO_HostFourteen,$TD_TB_Clock_STO_HostFifteen,$TD_TB_Clock_STO_HostSixteen | ForEach-Object {
                        $TB_ClockName = $_.Name.TrimStart('TB_Clock_')
                        if($TB_Name -eq $TB_ClockName){
                            $_.Text = $TimeStamp
                        }
                    }
                    
                    $TD_BTN_STO_HostOne,$TD_BTN_STO_HostTwo,$TD_BTN_STO_HostThree,$TD_BTN_STO_HostFour,$TD_BTN_STO_HostFive,$TD_BTN_STO_HostSix,$TD_BTN_STO_HostSeven,$TD_BTN_STO_HostEight,$TD_BTN_STO_HostNine,$TD_BTN_STO_HostTen,$TD_BTN_STO_HostEleven,$TD_BTN_STO_HostTwelve,$TD_BTN_STO_HostThirteen,$TD_BTN_STO_HostFourteen,$TD_BTN_STO_HostFifteen,$TD_BTN_STO_HostSixteen |ForEach-Object {
                        if($($_.Name) -like "*$TB_Name"){
                            if($Status -eq "degraded"){$_.Background = "Lightyellow"}else{$_.Background = "#ffdfd4"}
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