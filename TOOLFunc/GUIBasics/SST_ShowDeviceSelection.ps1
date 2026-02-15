Add-Type -AssemblyName PresentationFramework
function SST_ShowDeviceSelection {
    [CmdletBinding()]
    param (
       $SST_UCOBJ,
       $STP_PlaceinUC =$null
    )
    
    begin {
        $ErrorActionPreference="Continue"
        #SST_ToolMessageCollector -TD_ToolMSGCollector "Start SST_MainHealthCheckFunc " -TD_ToolMSGType Message -TD_Shown no
    }
    
    process {
        <# Cred Part #>
        switch ($SST_UCOBJ.Name) {
            "IBMSTO" { 
                $STP_PlaceinUC = $SST_UCOBJ.FindName("STP_STODeviceVisibility")
                $CB_SelectAll = $SST_UCOBJ.FindName("CB_SelectAllSTOCB")
                #$TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
            }
            "PWR" { 
                $STP_PlaceinUC = $SST_UCOBJ.FindName("STP_PWRDeviceVisibility")
                $CB_SelectAll = $SST_UCOBJ.FindName("CB_SelectAllPWRCB")
                #$TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
            }
            "IBMTape" { 
                $STP_PlaceinUC = $SST_UCOBJ.FindName("STP_TapeDeviceVisibility")
                $CB_SelectAll = $SST_UCOBJ.FindName("CB_SelectAllTapeCB")
                #$TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
            }
            "BRSAN" { 
                $STP_PlaceinUC = $SST_UCOBJ.FindName("STP_SANDeviceVisibility")
                $CB_SelectAll = $SST_UCOBJ.FindName("CB_SelectAllSANCB")
                #$TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
            }
            Default {}
        }
        <# Sicher stellen das alle Checkboxen die dynamisch erstellt wurden gelöscht werden um doppelte Namen zu verhindern #>
        $CBtoRemove = $STP_PlaceinUC.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "*test*" }
        if ($CBtoRemove) {
            $STP_PlaceinUC.Children.Remove($CBtoRemove) | Out-Null
            try { $SST_UCOBJ.UnregisterName($CBtoRemove.Name) } catch {}
        }
        <# wenn das STP nicht leer ist Checkboxen erstellen und einen Eventhandler anhängen #>
        if($null -ne $STP_PlaceinUC){
            $CB_SelectDevice = SST_CreateCheckBox -SST_UCOBJ $SST_UCOBJ
            try { $SST_UCOBJ.RegisterName($CB_SelectDevice.Name, $CB_SelectDevice) } catch {}
            $STP_PlaceinUC.Children.Add($CB_SelectDevice)

            if ($CB_SelectAll.Tag -ne 'SelectAllHandlersAttached') {
                $CB_SelectAll.Tag = 'SelectAllHandlersAttached'
                $CB_SelectAll.Add_Checked({
                    param($sender, $e)
                    $FoundUSControl = Get-ParentUserControl -control $sender
                    $SST_UCOBJTemp = Get-VisualDescendants -Root $FoundUSControl | Where-Object { $_ -is [System.Windows.Controls.StackPanel] } | Where-Object { $_.Name -like "STP_*DeviceVisibility" }
                    foreach ($SST_UCOBJChild in $SST_UCOBJTemp.Children) {
                        if ($SST_UCOBJChild -is [System.Windows.Controls.CheckBox] -and $SST_UCOBJChild.Name -ne $sender.Name) {
                            $SST_UCOBJChild.IsChecked = $true
                        }
                    }
                })
                $CB_SelectAll.Add_Unchecked({
                    param($sender, $e)
                    $FoundUSControl = Get-ParentUserControl -control $sender
                    $SST_UCOBJTemp = Get-VisualDescendants -Root $FoundUSControl | Where-Object { $_ -is [System.Windows.Controls.StackPanel] } | Where-Object { $_.Name -like "STP_*DeviceVisibility" }
                    foreach ($SST_UCOBJChild in $SST_UCOBJTemp.Children) {
                        if ($SST_UCOBJChild -is [System.Windows.Controls.CheckBox] -and $SST_UCOBJChild.Name -ne $sender.Name) {
                            $SST_UCOBJChild.IsChecked = $false
                        }
                    }
                })
            }
        }
        
    }
    
    end {
        #SST_ToolMessageCollector -TD_ToolMSGCollector "SST_MainHealthCheckFunc End" -TD_ToolMSGType Debug -TD_Shown no
    }
}