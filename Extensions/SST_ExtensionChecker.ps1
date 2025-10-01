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
        $SST_BTN_PowerBoard = $SST_MWOBJ.FindName("BTN_PowerBoard")
        $SST_BTN_PowerBoardTooltip = $SST_MWOBJ.FindName("BTN_PowerBoardTooltip")
        $SST_STODeviceCred = $SST_UCOBJ.FindName("DG_KnownDeviceList")

        if((($Extension).count -lt 1) -and ((($SST_STODeviceCred.ItemsSource).count -lt 1))-or(($LoadedToolSettings).count -lt 1)){ 
            $YNExtension = $false
            $SST_BTN_PowerBoard.Background = "Coral"
            $SST_BTN_PowerBoardTooltip.Text = "No Extension are installed or Credentials are loaded!"
            $SST_BTN_PowerBoard.IsEnabled= $false
        }else {
            $YNExtension = $true
        }

        if($YNExtension){
            $Extension_PRISMTOOL = @(Get-ChildItem -Path $PSRootPath\Extensions\PRISMTOOL_Customer\PRISMCustomerMainFunc.ps1 -ErrorAction SilentlyContinue)
            
            foreach($import in @($Extension_PRISMTOOL)) {
                try {
                    . $import.fullname
                }
                catch {
                    Write-Error -Message "Failed to import function $($import.fullname): $_"
                }
            }

            <# need your tool Cloud DB the set var to $true, Attation is there no saved *clixml the app will crash #>
            $CloudDB = $true
        }
    }
    
    process {
        if($YNExtension){
            
            $TD_Credentials = $SST_STODeviceCred.ItemsSource |ForEach-Object {$_}

            <#PRISMCustomerMainFunc#>
            <#Cloud is needed#>
            if($CloudDB){
                <#Cloud is true check if there is a file#>
                if((Get-ChildItem -Path $PSRootPath\Resources\SavedToolSettings.clixml)){
                    $PRISMString = Import-Clixml -Path $PSRootPath\Resources\SavedToolSettings.clixml 
                    PRISMCustomerMainFunc -TD_SecDeviceData $TD_Credentials -LocalDB $true -CloudDB $true -ConnectionString $PRISMString
                }
            }
            <#PRISMCustomerMainFunc#>






            
        }
    }
    end {
        
    }
}