Add-Type -AssemblyName PresentationFramework
function IBM_PowerMainFunc {
    [CmdletBinding()]
    param (
        $PSRootPath,
        $SST_UCOBJ,
        $SecureData
    )
    
    begin {
        <# check at first is there any extension #>
        $SST_BTN_PowerBoard = $SST_UCOBJ.FindName("BTN_HMCCollector")
    }
    
    process {

        if($SecureData.count -ge 1){
            
            $SST_BTN_PowerBoard.IsEnabled= $true
            $SST_BTN_PowerBoard.Visibility="visible"
            $SecureData | ForEach-Object {
                if($_.DeviceTyp -match "PowerHMC"){
                    IBM_PowerHMCScanner -HMCIP $_.IPAddress -HMCUser $_.UserName -HMCPass $([Net.NetworkCredential]::new('', $_.Password).Password) -Debug
                }
            }
            
            $CustomerHMCData = Import-Csv -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCData.csv -ErrorAction Continue
            SST_ToolMessageCollector -TD_ToolMSGCollector "CustomerHMCData - $($CustomerHMCData.count)" -TD_ToolMSGType Message -TD_Shown no
            if(($CustomerHMCData).count -gt 0){
                try {
                    SST_LiteDBControl -SST_InfoType "PowerHMC" -SST_CollectedInformations $CustomerHMCData
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }

            $CustomerHMCScannerLPARSummary = Import-Csv -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCScannerLPARSummary.csv -ErrorAction Continue
            SST_ToolMessageCollector -TD_ToolMSGCollector "CustomerHMCScannerLPARSummary - $($CustomerHMCScannerLPARSummary.count)" -TD_ToolMSGType Message -TD_Shown no
            if(($CustomerHMCScannerLPARSummary).count -gt 0){
                try {
                    SST_LiteDBControl -SST_InfoType "LPARSummary" -SST_CollectedInformations $CustomerHMCScannerLPARSummary
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }

            $CustomerHMCScannerSysSummary = Import-Csv -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCScannerSysSummary.csv -ErrorAction Continue
            SST_ToolMessageCollector -TD_ToolMSGCollector "CustomerHMCScannerSysSummary - $($CustomerHMCScannerSysSummary.count)" -TD_ToolMSGType Message -TD_Shown no
            if(($CustomerHMCScannerSysSummary).count -gt 0){
                try {
                    SST_LiteDBControl -SST_InfoType "PowerSysSummary" -SST_CollectedInformations $CustomerHMCScannerSysSummary
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
            try {
                Remove-Item -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCData.csv -Confirm:$false
                Remove-Item -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCScannerLPARSummary.csv -Confirm:$false
                Remove-Item -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCScannerSysSummary.csv -Confirm:$false
                 SST_ToolMessageCollector -TD_ToolMSGCollector "Remove CustomerHMCData, CustomerHMCScannerLPARSummary, CustomerHMCScannerSysSummary " -TD_ToolMSGType Message -TD_Shown yes
            }
            catch {
                <#Do this if a terminating exception happens#>
                SST_ToolMessageCollector -TD_ToolMSGCollector "Remove HMCScanerTEMP $($_.exception.message)" -TD_ToolMSGType Warning -TD_Shown yes

            }
        }else{
            if($SST_BTN_PowerBoard.Visibility -eq "Collapsed"){
                $SST_BTN_PowerBoard.IsEnabled= $true
                $SST_BTN_PowerBoard.Visibility="visible"
            }
        }
        <# Display Data on GUI #>
        if(((SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "CountHMCTabelleEntrys") -ge 1)){
            SST_ToolMessageCollector -TD_ToolMSGCollector "SST_PowerDBFunc HMCGUIInfo" -TD_ToolMSGType Message -TD_Shown yes

            SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "HMCGUIInfo" -UCOBJ $SST_UCOBJ

        }
        if(((SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "CountPowerSysTabelleEntrys") -ge 1)){
            SST_ToolMessageCollector -TD_ToolMSGCollector "SST_PowerDBFunc PWRSysGUIInfo" -TD_ToolMSGType Message -TD_Shown yes

            SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "PWRSysGUIInfo" -UCOBJ $SST_UCOBJ
            
        }
        if(((SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "CountLPARSTabelleEntrys") -ge 1)){
            SST_ToolMessageCollector -TD_ToolMSGCollector "SST_PowerDBFunc LPARGUIInfo" -TD_ToolMSGType Message -TD_Shown yes

            SST_PowerDBFunc -MainPath $PSRootPath -IBMPowerOperatorDB "LPARGUIInfo" -UCOBJ $SST_UCOBJ
         
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "IBM_PowerMainFunc End" -TD_ToolMSGType Message -TD_Shown no
    }
}