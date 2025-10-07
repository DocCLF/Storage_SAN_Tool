Add-Type -AssemblyName PresentationFramework
function IBM_PowerMainFunc {
    [CmdletBinding()]
    param (
        $PSRootPath,
        $SST_UCOBJ,
        $SST_MWOBJ,
        $SST_UCSTYLEOBJ,
        [bool]$SST_Extension
    )
    
    begin {
        <# check at first is there any extension #>
        $SST_Extension = SST_ExtensionChecker -SST_UCOBJ $SST_UCOBJ
        if(!($SST_Extension)){
            $SST_BTN_PowerBoard = $SST_UCOBJ.FindName("BTN_HMCCollector")
            #$TD_BTN_HMCInfoView = $SST_UCOBJ.FindName("BTN_HMCInfoView")
            $SST_BTN_PowerBoardTooltip = $SST_UCOBJ.FindName("BTN_HMCCollectorTooltip")
            $SST_BTN_PowerBoard.Background = "Coral"
            $SST_BTN_PowerBoardTooltip.Text = "No Extension are installed or Credentials are loaded!"
            SST_ToolMessageCollector -TD_ToolMSGCollector "IBM_PowerMainFunc: No Extension are installed or Credentials are loaded!" -TD_ToolMSGType Warning -TD_Shown yes
        }
        if(((SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "CountHMCTabelleEntrys") -ge 1)){

            SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "HMCGUIInfo" -UCOBJ $SST_UCOBJ

        }
        if(((SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "CountPowerSysTabelleEntrys") -ge 1)){
            
            SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "PWRSysGUIInfo" -UCOBJ $SST_UCOBJ
            
        }
        if(((SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "CountLPARSTabelleEntrys") -ge 1)){
            
            SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "LPARGUIInfo" -UCOBJ $SST_UCOBJ
         
        }
    }
    
    process {
        #if(($TD_BTN_HMCCollector.IsEnabled) -eq $false ){$TD_BTN_HMCCollector.IsEnabled= $true}
    }
    
    end {
        
    }
}