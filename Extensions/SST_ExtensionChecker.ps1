function SST_ExtensionChecker {
    [CmdletBinding()]
    param (
        $SST_UCOBJ,
        [bool]$YNExtension,
        [bool]$CloudDB = $false
    )
    
    begin {
        
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        $Extension = Get-Item -Path "$PSRootPath\Extensions\*" -Exclude *.ps1

        if(($Extension).count -lt 1){ 
            $YNExtension = $false
        }else {
            $YNExtension = $true
        }

        $Extension_PRISMTOOL = @(Get-ChildItem -Path $PSRootPath\Extensions\PRISMTOOL_Customer\PRISMCustomerMainFunc.ps1 -ErrorAction SilentlyContinue)
        if($YNExtension){
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
            $SST_STOHealthCheckWP = $SST_UCOBJ.FindName("DG_KnownDeviceList")
            $TD_Credentials = $SST_STOHealthCheckWP.ItemsSource |ForEach-Object {$_}

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