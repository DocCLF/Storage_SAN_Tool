function SST_CreateButton {
    [CmdletBinding()]
    param (
        $SST_UCOBJ,
        $SST_UCSTYLEOBJ,
        $BTNStyle,
        $DeviceTyp,
        $DeviceID,
        $DeviceIPAddress,
        $OnClickScript
    )
    
    begin {
        
        SST_ToolMessageCollector -TD_ToolMSGCollector "Start to create Button for $DeviceTyp Healthcheck" -TD_ToolMSGType Message -TD_Shown no

        if($DeviceTyp -eq "Storage"){$ButtonIcon = "$PSRootPath\Resources\Icons\IBMFS73Icon.png"}
        if($DeviceTyp -eq "SAN"){$ButtonIcon = "$PSRootPath\Resources\Icons\SAN64B7Icon.png"}
        if($DeviceTyp -eq "PowerHMC"){$ButtonIcon = "$PSRootPath\Resources\Icons\IBMPower11Icon.png"}
    }
    
    process {
        try {
            #$TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
            #SST_ToolMessageCollector -TD_ToolMSGCollector $TD_Credentials.DeviceTyp -TD_ToolMSGType Message -TD_Shown no
            <# Find Warppanel in UC and add Button Stlye #>
            #$SST_STOHealthCheckWP = $SST_UCOBJ.FindName("WP_STOHealthCheck")
            $SST_UCOBJ.Resources.MergedDictionaries.Add( $SST_UCSTYLEOBJ )

            $SST_DummyBTN = New-Object Windows.Controls.Button
            $SST_DummyBTN.Style = $SST_UCOBJ.TryFindResource("HealthBoardBTNStyle")
            $SST_DummyBTN.Name = $DeviceTyp+"_"+$DeviceID
            $SST_BTNSTACKP = New-Object Windows.Controls.StackPanel
            $SST_BTNIMG = New-Object Windows.Controls.Image
            $SST_BTNIMG.Source = $ButtonIcon
            $SST_BTNIMG.Margin = "5"   # Abstand zum Text
            $SST_BTNIMG.Stretch = "Uniform"
            $SST_BTNIMG.VerticalAlignment = "Bottom"
            $SST_BTNIMG.HorizontalAlignment = "Left"
            $SST_BTNIMG.MaxWidth = "160"
            $SST_BTNTB = New-Object Windows.Controls.TextBlock
            $SST_BTNTB.Text = "$DeviceIPAddress"
            $SST_BTNTB.VerticalAlignment = "Center"
            $SST_BTNTB.HorizontalAlignment = "Center"
            $SST_BTNSTACKP.Children.Add($SST_BTNTB) | Out-Null
            $SST_BTNSTACKP.Children.Add($SST_BTNIMG) | Out-Null

            $SST_DummyBTN.Content = $SST_BTNSTACKP
            #$SST_UCOBJ.RegisterName($SST_DummyBTN.Name, $SST_DummyBTN)

            #$SST_STOHealthCheckWP.Children.Add($SST_DummyBTN)

        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes       
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "End to create Button for $DeviceTyp Healthcheck" -TD_ToolMSGType Message -TD_Shown no
        return $SST_DummyBTN
    }
}