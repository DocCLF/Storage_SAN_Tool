Add-Type -AssemblyName PresentationFramework
function IBM_PowerMainFunc {
    [CmdletBinding()]
    param (
        $PSRootPath,
        $SST_UCOBJ,
        $SST_MWOBJ,
        $SST_UCSTYLEOBJ,
        $SecureData,
        $CloudString,
        [bool]$SST_Extension
    )
    
    begin {
        <# check at first is there any extension #>
        if($SecureData.count -lt 1){
            $SST_Extension = SST_ExtensionChecker -SST_UCOBJ $SST_UCOBJ
        }else{
            SST_ExtensionChecker -SST_UCOBJ $SST_UCOBJ -LoadedToolSettings $SecureData -CloudDB $true
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