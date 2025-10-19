function SST_ExtensionChecker {
    [CmdletBinding()]
    param (
        $SST_UCOBJ,
        $SST_MWOBJ,
        [bool]$YNExtension,
        [bool]$CloudDB = $false,
        $LoadedToolSettings
    )
    
    begin {
        
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        $Extension = Get-Item -Path "$PSRootPath\Extensions\*" -Exclude *.ps1

        if(($Extension).count -ge 1){ 
            $SST_BTN_PowerBoard = $SST_UCOBJ.FindName("BTN_HMCCollector")
            if($SST_BTN_PowerBoard.Visibility -ne "visible"){
                $SST_BTN_PowerBoard.IsEnabled= $true
                $SST_BTN_PowerBoard.Visibility="visible"
            }
            $YNExtension = $true
            SST_ToolMessageCollector -TD_ToolMSGCollector $("IBM_PowerMainFunc: $(($Extension).count) Extension are installed") -TD_ToolMSGType Message -TD_Shown yes
        }

        if($YNExtension){
            $Extension_PRISMTOOL = @(Get-ChildItem -Path $PSRootPath\Extensions\PRISMTOOL_Customer\PRISMCustomerMainFunc.ps1 -ErrorAction Continue)
            foreach($import in @($Extension_PRISMTOOL)) {
                try {
                    . $import.fullname
                }
                catch {
                    SST_ToolMessageCollector -TD_ToolMSGCollector $("Failed to import function $($import.fullname): $_") -TD_ToolMSGType Warning -TD_Shown yes
                }
            }
            <# need your tool Cloud DB the set var to $true, Attation is there no saved *clixml the app will crash #>
        }
    }
    
    process {
            <#PRISMCustomerMainFunc#>
            SST_ToolMessageCollector -TD_ToolMSGCollector $("Extension: $YNExtension ,Cloud: $CloudDB") -TD_ToolMSGType Message -TD_Shown no
            <#Cloud is needed#>
            if($CloudDB){
                <#Cloud is true check if there is a file#>
                $PRISMString = Import-Clixml -Path $PSRootPath\Resources\SavedToolSettings.clixml 
                try {
                    Get-Command PRISMCustomerMainFunc 
                    PRISMCustomerMainFunc -TD_SecDeviceData $LoadedToolSettings -LocalDB $true -CloudDB $true -ConnectionString $PRISMString
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector $("PRISMCustomerMainFunc is not loaded $($_.exception.message)") -TD_ToolMSGType Warning -TD_Shown yes
                }
                
            }
            <#PRISMCustomerMainFunc#>
    }
    end {
        return $YNExtension
    }
}