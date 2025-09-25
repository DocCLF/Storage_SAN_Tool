Add-Type -AssemblyName PresentationFramework
function SST_MainHealthCheckFunc {
    [CmdletBinding()]
    param (
       $SST_UCOBJ,
       $SST_UCSTYLEOBJ
    )
    
    begin {
        $ErrorActionPreference="Continue"
        SST_ToolMessageCollector -TD_ToolMSGCollector "Start SST_MainHealthCheckFunc " -TD_ToolMSGType Message -TD_Shown no
    }
    
    process {
        try {
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
            SST_ToolMessageCollector -TD_ToolMSGCollector $TD_Credentials.DeviceTyp -TD_ToolMSGType Message -TD_Shown no
            <# Find Warppanel in UC and add Button Stlye #>
            $SST_STOHealthCheckWP = $SST_UCOBJ.FindName("WP_STOHealthCheck")
            
            foreach ($TD_Credential in $TD_Credentials) {

                $SST_DummyBTN = SST_CreateButton -SST_UCOBJ $SST_UCOBJ -SST_UCSTYLEOBJ $SST_UCSTYLEOBJ -DeviceTyp $TD_Credential.DeviceTyp -DeviceID $TD_Credential.ID -DeviceIPAddress $TD_Credential.IPAddress
                #$win = $SST_UCOBJ.FindName($SST_DummyBTN)

                $SST_UCOBJ.RegisterName($SST_DummyBTN.Name, $SST_DummyBTN)
                
                $SST_STOHealthCheckWP.Children.Add($SST_DummyBTN)

                $SST_DummyBTN.Add_Click({ 
                    param($sender,$e)

                    $FoundUSControl = Get-ParentUserControl -control $sender
                    $TD_Credential = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {($_.DeviceTyp -eq "Storage")-and($this.Name -like "*_$($_.ID)")}   

                    IBM_StorageHealthCheck -SST_DeviceLoggingInfo $TD_Credential -UCOBJ $FoundUSControl
                })
            }

        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes       
        }
       
        try {
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}
            SST_ToolMessageCollector -TD_ToolMSGCollector $TD_Credentials.DeviceTyp -TD_ToolMSGType Message -TD_Shown no
            <# Find Warppanel in UC and add Button Stlye #>
            $SST_STOHealthCheckWP = $SST_UCOBJ.FindName("WP_SANHealthCheck")

            foreach ($TD_Credential in $TD_Credentials) {

                $SST_DummyBTN = SST_CreateButton -SST_UCOBJ $SST_UCOBJ -SST_UCSTYLEOBJ $SST_UCSTYLEOBJ -DeviceTyp $TD_Credential.DeviceTyp -DeviceID $TD_Credential.ID -DeviceIPAddress $TD_Credential.IPAddress
                #$win = $SST_UCOBJ.FindName($SST_DummyBTN)

                $SST_UCOBJ.RegisterName($SST_DummyBTN.Name, $SST_DummyBTN)

                $SST_STOHealthCheckWP.Children.Add($SST_DummyBTN)

                $SST_DummyBTN.Add_Click({ 
                    param($sender,$e)
                    $FoundUSControl = Get-ParentUserControl -control $sender
                    $TD_Credential = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {($_.DeviceTyp -eq "SAN")-and($this.Name -like "*_$($_.ID)")}   

                    IBM_SANHealthCheck -SST_DeviceLoggingInfo $TD_Credential -UCOBJ $FoundUSControl
                })

            }
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes       
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_MainHealthCheckFunc End" -TD_ToolMSGType Debug -TD_Shown no
    }
}