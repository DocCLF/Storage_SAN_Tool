Add-Type -AssemblyName PresentationCore,PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

<# Create the xaml Files / Base of GUI Mainwindow #>
function Storage_SAN_Tool {
[CmdletBinding()]
#$ErrorActionPreference="SilentlyContinue"

$MainxamlFile ="$PSScriptRoot\MainWindow.xaml"
$inputXAML=Get-Content -Path $MainxamlFile -raw
$inputXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
[xml]$MainXAML=$inputXAML
$Mainreader = New-Object System.Xml.XmlNodeReader $MainXAML
$Mainform=[Windows.Markup.XamlReader]::Load($Mainreader)
$MainXAML.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $Mainform.FindName($_.Name)}

$PSRootPath = Split-Path -Path $PSScriptRoot -Parent

<# Create UserControls as basis of Content for MainWindow #>
$UserCxamlFile = Get-ChildItem "$PSScriptRoot\UserControl*.xaml"
foreach($file in $UserCxamlFile){
    $fileName = ($file.Name).trim(".xaml")
    Set-Variable -Name "TD_$($fileName)"
    <# if you want more UserControls then add them here #>
    switch -wildcard ($fileName) {
        "*l1" { 
            $UserC1=Get-Content -Path $file -raw
            $UserC1=$UserC1 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML1=$UserC1
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML1
            $TD_UserControl1=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML1.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl1.FindName($_.Name) }
         }
        "*l2" { 
            $UserC2=Get-Content -Path $file -raw
            $UserC2=$UserC2 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML2=$UserC2
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML2
            $TD_UserControl2=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML2.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl2.FindName($_.Name) }
         }
        "*l3" { 
            $UserC3=Get-Content -Path $file -raw
            $UserC3=$UserC3 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML3=$UserC3
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML3
            $TD_UserControl3=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML3.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl3.FindName($_.Name) }
         }
        "*l3_1" { 
            $UserC3_1=Get-Content -Path $file -raw
            $UserC3_1=$UserC3_1 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML3_1=$UserC3_1
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML3_1
            $TD_UserControl3_1=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML3_1.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl3_1.FindName($_.Name) }
         }
        "*l3_2" { 
            $UserC3_2=Get-Content -Path $file -raw
            $UserC3_2=$UserC3_2 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML3_2=$UserC3_2
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML3_2
            $TD_UserControl3_2=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML3_2.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl3_2.FindName($_.Name) }
         }
        "*l4" { 
            $UserC4=Get-Content -Path $file -raw
            $UserC4=$UserC4 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML4=$UserC4
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML4
            $TD_UserControl4=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML4.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl4.FindName($_.Name) }
         }
        Default { Write-Host "Something did not work, start the application in debug mod and/or check the log file." -ForegroundColor Red; Start-Sleep -Seconds 5; exit }
    }
}

#region BasicToolPreparation
    try {
        $TD_ExporttoOD = [Environment]::GetFolderPath("mydocuments")
        $ExportFolderPath="$TD_ExporttoOD\StorageSANKit"
        If(!(Test-Path -Path $ExportFolderPath)){
            try {
                $TD_ExportFolderCreated = New-Item $ExportFolderPath -ItemType Directory -ErrorAction Stop
                $TD_tb_ExportPath.Text = $TD_ExportFolderCreated.Name
            }
            catch {
                SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
            }

        }else{
            $TD_tb_ExportPath.Text = $ExportFolderPath
            #PowerShell Create directory if not exists
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        Write-Error -Message $_.Exception.Message
        #$TD_tb_Exportpath.Text = $_.Exception.Message
    }
    <# MainWindow Background IMG #>
    $TD_LogoImage.Source = "$PSRootPath\Resources\PROFI_Logo_2022_dark.png"
    $TD_LogoImageSmall.Source = "$PSRootPath\Resources\PROFI_Logo_2022_dark.png"
    $TD_LogoImageSmall.Visibility = "hidden"
#endregion

#region Menu Button
<# Button Area Menu #>
$TD_btn_IBM_SV.add_click({
    $TD_label_ExpPath.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl1.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl1)}
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserControlRightSide.Children.Remove($TD_UserControl3_2)
    $TD_UserControlLeftSide.Children.Remove($TD_UserControl3_1)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    
})
$TD_btn_Broc_SAN.add_click({
    $TD_label_ExpPath.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl2.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl2)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserControlRightSide.Children.Remove($TD_UserControl3_2)
    $TD_UserControlLeftSide.Children.Remove($TD_UserControl3_1)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_btn_Stor_San.add_click({
    $TD_label_ExpPath.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl3.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl3); $TD_UserControlLeftSide.Children.add($TD_UserControl3_1);$TD_UserControlRightSide.Children.add($TD_UserControl3_2)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_btn_Settings.add_click({
    if(!($TD_UserControl4.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl4)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserControlRightSide.Children.Remove($TD_UserControl3_2)
    $TD_UserControlLeftSide.Children.Remove($TD_UserControl3_1)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
<# Button Export Settings #>
$TD_btn_ChangeExportPath.add_click({
    $TD_ChPathdialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($TD_ChPathdialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $TD_DirectoryName = $TD_ChPathdialog.SelectedPath
        #Write-Host "Directory selected is $TD_DirectoryName"
        $TD_tb_ExportPath.Text = $TD_DirectoryName
    }
    $TD_label_ExpPath.Content ="Export Path: $($TD_tb_ExportPath.Text)"
})
#endregion

#region SSH Setings
<# ssh-agent Status check #>
$TD_lb_SSHStatusMsg.Visibility ="Visible"
$TD_lb_SSHStatusMsg.Content ="SSH-Agent Status is:`n$((Get-Service ssh-agent).Status)"
if(((Get-Service ssh-agent).Status)-eq "Running"){
    $TD_btn_Start_sshAgent.Content="Stop ssh-agent"
    $TD_btn_Start_sshAgent.Background="coral"
}else {
    <# Action when all if and elseif conditions are false #>
    $TD_btn_Start_sshAgent.Content="Start ssh-agent"
    $TD_btn_Start_sshAgent.Background="#FFDDDDDD"
}
<# Try to start/stop the ssh-agent #>
$TD_btn_Start_sshAgent.add_click({
    $TD_btn_Text=$TD_btn_Start_sshAgent.Content
    switch ($TD_btn_Text) {
        {($_ -like "Start*")} { 
                                try {
                                    $TD_btn_Start_sshAgent.Content="Stop ssh-agent"
                                    $TD_btn_Start_sshAgent.Background="coral"
                                    Start-Service ssh-agent -ErrorAction Stop
                                }
                                catch {
                                    <#Do this if a terminating exception happens#>
                                    $TD_btn_Start_sshAgent.Content="Start ssh-agent"
                                    $TD_btn_Start_sshAgent.Background="#FFDDDDDD"
                                    SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning
                                }
                                $TD_lb_SSHStatusMsg.Content ="SSH-Agent Status is:`n$((Get-Service ssh-agent).Status) "
                            }
        {($_ -like "Stop*")} {
                                try {
                                    $TD_btn_Start_sshAgent.Content="Start ssh-agent"
                                    $TD_btn_Start_sshAgent.Background="#FFDDDDDD"
                                    Stop-Service ssh-agent -ErrorAction Stop
                                }
                                catch {
                                    <#Do this if a terminating exception happens#>
                                    $TD_btn_Start_sshAgent.Content="Stop ssh-agent"
                                    $TD_btn_Start_sshAgent.Background="coral"
                                    SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning
                                }
                                $TD_lb_SSHStatusMsg.Content ="SSH-Agent Status is:`n$((Get-Service ssh-agent).Status) "
                            }
        Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong by get informations about the ssh-agent." -TD_ToolMSGType Error}
    }
    $TD_UserControl4.Dispatcher.Invoke([System.Action]{},"Render")
})

$TD_BTN_AddSSHKey.add_click({
    $TD_ButtonColorSSH=$TD_btn_addsshkeyone.Background
    if($TD_ButtonColorSSH -like "*90EE90"){
        RemoveSSHKeyfromLine -TD_SSHKeyForLine 1 -TD_Storage "yes"
    }else {
        AddSSHKeytoLine -TD_SSHKeyForLine 1 -TD_Storage "yes"
    }
})
#endregion

#region AddDeviceCred
$TD_TBTN_SaveCredtoDG.add_click({

    $TD_CredfGUIArray = SST_GetCredfGUI -TD_AddaNewDevice "yes"
    Start-Sleep -Seconds 0.3
    if(!([string]::IsNullOrEmpty($TD_CredfGUIArray))){
        $TD_TB_DeviceIPAddr.Text=""
        $TD_TB_DeviceUserName.Text=""
        $TD_TB_DevicePassword.Password=""
        $TD_TB_PathtoSSHKeyNotVisibil.Text=""
        $TD_CB_SVCorVF.IsChecked=$false
    }
})
#endregion

#region InAndSST_ExportCred
<# Button Credentials In-/ Export #>
$TD_btn_ExportCred.add_click({
    <# Not all needs to exported, if you want to modify the Export got to the SST_ExportCred Func #>
    $TD_SST_ExportCred = SST_ExportCredential -TD_CollectedCredData $TD_DG_KnownDeviceList.ItemsSource
    <# Save to Dir #>
    $TD_SaveCred = SST_SaveFile_to_Directory -TD_UserDataObject $TD_SST_ExportCred
    if([string]::IsNullOrEmpty($TD_SaveCred.FileName)){
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Export failed!") -TD_ToolMSGType Warning
    }else {
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully exported to $($TD_SaveCred.FileName)") -TD_ToolMSGType Message
    }
})
$TD_btn_ImportCred.add_click({

    $TD_ImportedCredentials = SST_ImportCredential
    if($TD_ImportedCredentials -lt 1){
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Import failed!") -TD_ToolMSGType Warning
    }else {
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully Import") -TD_ToolMSGType Message
    }
    
})
<# this part is needed if there are any Updates on the cred in DG #>
$TD_DG_KnownDeviceList.add_SelectionChanged({
    <# to prevent the function from being executed more than once #>
    if(!([string]::IsNullOrWhiteSpace($TD_DG_KnownDeviceList.selecteditem.IPAddress))){
        if($TD_CB_CredUpdate.IsChecked){
            $TD_DG_KnownDeviceList | ForEach-Object {
                $TD_CB_DeviceType.Text = $_.selecteditem.DeviceTyp
                if($_.selecteditem.ConnectionTyp -eq "plink"){$TD_CB_DeviceConnectionType.Text = "Classic (UN/PW)"}else{$TD_CB_DeviceConnectionType.Text = "Secure Shell (SSH)"}
                $TD_TB_DeviceIPAddr.Text = $_.selecteditem.IPAddress
                $TD_TB_DeviceUserName.Text = $_.selecteditem.UserName
                if($_.selecteditem.SVCorVF -ne ""){$TD_CB_SVCorVF.IsChecked=$true}else{$TD_CB_SVCorVF.IsChecked=$false}
            }
        }else{
            SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $TD_DG_KnownDeviceList.selecteditem.DeviceTyp -TD_Selected_DeviceConnectionType $TD_DG_KnownDeviceList.selecteditem.ConnectionTyp -TD_Selected_DeviceIPAddr $TD_DG_KnownDeviceList.selecteditem.IPAddress -TD_Selected_DeviceUserName $TD_DG_KnownDeviceList.selecteditem.UserName -TD_Selected_DevicePassword $TD_DG_KnownDeviceList.selecteditem.Password -TD_Selected_SVCorVF $TD_DG_KnownDeviceList.selecteditem.SVCorVF
        }
    }
})
#endregion

#region IBM Button
$TD_btn_IBM_Eventlog.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_lb_StorageEventLogOne,$TD_lb_StorageEventLogTwo,$TD_lb_StorageEventLogThree,$TD_lb_StorageEventLogFour |ForEach-Object {
        if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_IBM_EventLogShow = IBM_EventLog -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_lb_StorageEventLogOne.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 2)} { $TD_lb_StorageEventLogTwo.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 3)} { $TD_lb_StorageEventLogThree.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 4)} { $TD_lb_StorageEventLogFour.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 5)} { $TD_lb_StorageEventLogOne.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 6)} { $TD_lb_StorageEventLogOne.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 7)} { $TD_lb_StorageEventLogOne.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 8)} { $TD_lb_StorageEventLogOne.ItemsSource = $TD_IBM_EventLogShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_StorageEventLog.Visibility="Visible" 

})

$TD_btn_IBM_CatAuditLog.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_StorageAuditLogOne,$TD_dg_StorageAuditLogTwo,$TD_dg_StorageAuditLogThree,$TD_dg_StorageAuditLogFour |ForEach-Object {
        if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_CatAuditLog = IBM_CatAuditLog -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_StorageAuditLogOne.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 2)} { $TD_dg_StorageAuditLogTwo.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 3)} { $TD_dg_StorageAuditLogThree.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 4)} { $TD_dg_StorageAuditLogFour.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 5)} { $TD_dg_StorageAuditLogOne.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 6)} { $TD_dg_StorageAuditLogOne.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 7)} { $TD_dg_StorageAuditLogOne.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 8)} { $TD_dg_StorageAuditLogOne.ItemsSource = $TD_CatAuditLog }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_CatAuditLog | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IBM_CatAuditLog_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_StorageAuditLog.Visibility="Visible" 

})

$TD_btn_IBM_HostVolumeMap.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_HostVolInfoOne,$TD_dg_HostVolInfoTwo,$TD_dg_HostVolInfoThree,$TD_dg_HostVolInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true };
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_Host_Volume_Map = IBM_Host_Volume_Map -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_HostVolInfoOne.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 2)} { $TD_dg_HostVolInfoTwo.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 3)} { $TD_dg_HostVolInfoThree.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 4)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 5)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 6)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 7)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 8)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Host_Volume_Map }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_Host_Volume_Map | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_Host_Vol_Map_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_HostVolInfo.Visibility="Visible" 

})
<# filter View for Host Volume Map #>
<# to keep this file clean :D export the following lines to a func in one if the next Version #>
$TD_btn_FilterHVM.Add_Click({
    $TD_btn_ClearFilterHVM.Visibility="Visible"
    [string]$filter= $TD_tb_filter.Text
    [int]$TD_Filter_DG = $TD_cb_ListFilterStorageHVM.Text
    [string]$TD_Filter_DG_Colum = $TD_cb_StorageHVM.Text
    try {
        [array]$TD_CollectVolInfo = Import-Csv -Path $Env:TEMP\$($TD_Filter_DG)_Host_Vol_Map_Temp.csv -ErrorAction Stop
        switch ($TD_Filter_DG) {
            1 { $TD_Host_Volume_Map = $TD_dg_HostVolInfo.ItemsSource }
            2 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoTwo.ItemsSource }
            3 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoThree.ItemsSource }
            4 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoFour.ItemsSource }
            Default {}
        }
        if($TD_Host_Volume_Map.Count -ne $TD_CollectVolInfo.Count){
            $TD_Host_Volume_Map = $TD_CollectVolInfo }
             
            switch ($TD_Filter_DG_Colum) {
                "Host" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.HostName -Match $filter } }
                "HostCluster" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.HostCluster -Match $filter } }
                "Volume" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.VolumeName -Match $filter } }
                "UID" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.UID -Match $filter } }
                "Capacity" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.Capacity -Match $filter } }
                Default {Write-Host "Something went wrong" -ForegroundColor DarkMagenta}
            }
            switch ($TD_Filter_DG) {
                1 { $TD_dg_HostVolInfo.ItemsSource = $WPF_dataGrid }
                2 { $TD_dg_HostVolInfoTwo.ItemsSource = $WPF_dataGrid }
                3 { $TD_dg_HostVolInfoThree.ItemsSource = $WPF_dataGrid }
                4 { $TD_dg_HostVolInfoFour.ItemsSource = $WPF_dataGrid }
                Default {}
            }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $TD_lb_ErrorMsgHVM.Content = $_.Exception.Message
    }

})

$TD_btn_ClearFilterHVM.Add_Click({

    [int]$TD_Filter_DG = $TD_cb_ListFilterStorageHVM.Text
    $TD_tb_filter.Text = ""
    try {
        [array]$TD_CollectVolInfo = Import-Csv -Path $Env:TEMP\$($TD_Filter_DG)_Host_Vol_Map_Temp.csv -ErrorAction Stop

        switch ($TD_Filter_DG) {
            1 { $TD_dg_HostVolInfo.ItemsSource = $TD_CollectVolInfo }
            2 { $TD_dg_HostVolInfoTwo.ItemsSource = $TD_CollectVolInfo }
            3 { $TD_dg_HostVolInfoThree.ItemsSource = $TD_CollectVolInfo }
            4 { $TD_dg_HostVolInfoFour.ItemsSource = $TD_CollectVolInfo }
            Default {}
        }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $TD_lb_ErrorMsgHVM.Content = $_.Exception.Message
    }
})

$TD_btn_IBM_DriveInfo.add_click({
    $TD_lb_DriveInfoOne.Visibility = "Hidden";
    $TD_lb_DriveInfoTwo.Visibility = "Hidden";
    $TD_lb_DriveInfoThree.Visibility = "Hidden";
    $TD_lb_DriveInfoFour.Visibility = "Hidden"; 

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_DriveInfo,$TD_dg_DriveInfoTwo,$TD_dg_DriveInfoThree,$TD_dg_DriveInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    
    $TD_Credentials | ForEach-Object {
        [array]$TD_DriveInfo = IBM_DriveInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_DriveInfoOne.ItemsSource = $TD_DriveInfo }
            {($_ -eq 2)} { $TD_dg_DriveInfoTwo.ItemsSource = $TD_DriveInfo }
            {($_ -eq 3)} { $TD_dg_DriveInfoThree.ItemsSource = $TD_DriveInfo }
            {($_ -eq 4)} { $TD_dg_DriveInfoFour.ItemsSource = $TD_DriveInfo }
            {($_ -eq 5)} { $TD_dg_DriveInfoFour.ItemsSource = $TD_DriveInfo }
            {($_ -eq 6)} { $TD_dg_DriveInfoFour.ItemsSource = $TD_DriveInfo }
            {($_ -eq 7)} { $TD_dg_DriveInfoFour.ItemsSource = $TD_DriveInfo }
            {($_ -eq 8)} { $TD_dg_DriveInfoFour.ItemsSource = $TD_DriveInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_DriveInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_DriveInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_StorageEventLog,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_DriveInfo.Visibility="Visible" 

})

$TD_btn_IBM_FCPortStats.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_FCPortStatsOne,$TD_dg_FCPortStatsTwo,$TD_dg_FCPortStatsThree,$TD_dg_FCPortStatsFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FCPortStats = IBM_FCPortStats -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $TD_Credential.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_FCPortStatsOne.ItemsSource = $TD_FCPortStats }
            {($_ -eq 2)} { $TD_dg_FCPortStatsTwo.ItemsSource = $TD_FCPortStats }
            {($_ -eq 3)} { $TD_dg_FCPortStatsThree.ItemsSource = $TD_FCPortStats }
            {($_ -eq 4)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortStats }
            {($_ -eq 5)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortStats }
            {($_ -eq 6)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortStats }
            {($_ -eq 7)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortStats }
            {($_ -eq 8)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortStats }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FCPortStats | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FCPortStats_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_StorageEventLog,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_FCPortStats.Visibility="Visible" 

})

$TD_btn_IBM_FCPortInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_FCPortInfoOne,$TD_dg_FCPortInfoTwo,$TD_dg_FCPortInfoThree,$TD_dg_FCPortInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FCPortInfo = IBM_FCPortInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_FCPortStatsOne.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 2)} { $TD_dg_FCPortStatsTwo.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 3)} { $TD_dg_FCPortStatsThree.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 4)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 5)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 6)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 7)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 8)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FCPortInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FCPortInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_IBM_FCPortInfo.Visibility="Visible"
    
})

$TD_btn_IBM_PolicyBased_Rep.add_click({
    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_StorageEventLog,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_PolicyBased_Rep.Visibility="Visible"
})

$TD_btn_FilterPBR.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    [string]$TD_RepInfoChose = $TD_cb_ListFilterStoragePBR.Text

    switch ($TD_RepInfoChose) {
        "ReplicationPolicy" {

            $TD_dg_ReplicationPolicyOne,$TD_dg_ReplicationPolicyTwo,$TD_dg_ReplicationPolicyThree,$TD_dg_ReplicationPolicyFour,$TD_dg_VolumeGrpReplicationOne,$TD_dg_VolumeGrpReplicationTwo,$TD_dg_VolumeGrpReplicationThree,$TD_dg_VolumeGrpReplicationFour |ForEach-Object {
                if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
            }

            $TD_Credentials | ForEach-Object {
                [array]$TD_PolicyBased_Rep = IBM_PolicyBased_Rep -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $TD_Credential.SVCorVF -TD_RepInfoChose $TD_RepInfoChose -TD_Exportpath $TD_tb_ExportPath.Text
                switch ($_.ID) {
                    {($_ -eq 1)} { $TD_dg_ReplicationPolicyOne.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 2)} { $TD_dg_ReplicationPolicyTwo.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 3)} { $TD_dg_ReplicationPolicyThree.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 4)} { $TD_dg_ReplicationPolicyFour.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 5)} { $TD_dg_ReplicationPolicyFour.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 6)} { $TD_dg_ReplicationPolicyFour.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 7)} { $TD_dg_ReplicationPolicyFour.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 8)} { $TD_dg_ReplicationPolicyFour.ItemsSource = $TD_PolicyBased_Rep }
                    Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
                }
            }
        }
        "VolumeGroupReplication" { 

            $TD_dg_ReplicationPolicyOne,$TD_dg_ReplicationPolicyTwo,$TD_dg_ReplicationPolicyThree,$TD_dg_ReplicationPolicyFour,$TD_dg_VolumeGrpReplicationOne,$TD_dg_VolumeGrpReplicationTwo,$TD_dg_VolumeGrpReplicationThree,$TD_dg_VolumeGrpReplicationFour |ForEach-Object {
                if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
            }

            $TD_Credentials | ForEach-Object {
                [array]$TD_VolumeGroupRep = IBM_PolicyBased_Rep -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $TD_Credential.SVCorVF -TD_RepInfoChose $TD_RepInfoChose -TD_Exportpath $TD_tb_ExportPath.Text
                switch ($_.ID) {
                    {($_ -eq 1)} { $TD_dg_VolumeGrpReplicationOne.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 2)} { $TD_dg_VolumeGrpReplicationTwo.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 3)} { $TD_dg_VolumeGrpReplicationThree.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 4)} { $TD_dg_VolumeGrpReplicationFour.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 5)} { $TD_dg_VolumeGrpReplicationFour.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 6)} { $TD_dg_VolumeGrpReplicationFour.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 7)} { $TD_dg_VolumeGrpReplicationFour.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 8)} { $TD_dg_VolumeGrpReplicationFour.ItemsSource = $TD_VolumeGroupRep }
                    Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
                }
            }
         }
        Default {}
    }
    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}
})

$TD_btn_IBM_BaseStorageInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_BaseStorageInfoOne,$TD_dg_BaseStorageInfoTwo,$TD_dg_BaseStorageInfoThree,$TD_dg_BaseStorageInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_BaseStorageInfo = IBM_BaseStorageInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $TD_Credential.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_BaseStorageInfoOne.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 2)} { $TD_dg_BaseStorageInfoTwo.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 3)} { $TD_dg_BaseStorageInfoThree.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 4)} { $TD_dg_BaseStorageInfoFour.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 5)} { $TD_dg_BaseStorageInfoFour.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 6)} { $TD_dg_BaseStorageInfoFour.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 7)} { $TD_dg_BaseStorageInfoFour.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 8)} { $TD_dg_BaseStorageInfoFour.ItemsSource = $TD_BaseStorageInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_BaseStorageInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_BaseStorageInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    
    $TD_stp_BaseStorageInfo.Visibility="Visible"
})

$TD_btn_IBM_CleanUpDumps.add_click({
    $ErrorActionPreference="Continue"

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_Credentials | ForEach-Object {
        $TD_CleanUpDumpInfo = $null
        $TD_CleanUpDumpInfo = IBM_CleanUpDumps -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_tb_CleanUpDumpInfoOne.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 2)} { $TD_tb_CleanUpDumpInfoTwo.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 3)} { $TD_tb_CleanUpDumpInfoThree.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 4)} { $TD_tb_CleanUpDumpInfoFour.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 5)} { $TD_tb_CleanUpDumpInfoFour.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 6)} { $TD_tb_CleanUpDumpInfoFour.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 7)} { $TD_tb_CleanUpDumpInfoFour.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 8)} { $TD_tb_CleanUpDumpInfoFour.Text = $TD_CleanUpDumpInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
    }
    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_CleanUpDump.Visibility="Visible"
})

$TD_btn_IBM_BackUpConfig.add_click({
    $ErrorActionPreference="Continue"

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_Credentials | ForEach-Object {
        $TD_StorageBackUpInfo = $null
        $TD_StorageBackUpInfo = IBM_BackUpConfig -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_tb_BackUpInfoDeviceOne.Text = $TD_StorageBackUpInfo }
            {($_ -eq 2)} { $TD_tb_BackUpInfoDeviceTwo.Text = $TD_StorageBackUpInfo }
            {($_ -eq 3)} { $TD_tb_BackUpInfoDeviceThree.Text = $TD_StorageBackUpInfo }
            {($_ -eq 4)} { $TD_tb_BackUpInfoDeviceFour.Text = $TD_StorageBackUpInfo }
            {($_ -eq 5)} { $TD_tb_BackUpInfoDeviceFour.Text = $TD_StorageBackUpInfo }
            {($_ -eq 6)} { $TD_tb_BackUpInfoDeviceFour.Text = $TD_StorageBackUpInfo }
            {($_ -eq 7)} { $TD_tb_BackUpInfoDeviceFour.Text = $TD_StorageBackUpInfo }
            {($_ -eq 8)} { $TD_tb_BackUpInfoDeviceFour.Text = $TD_StorageBackUpInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_StorageBackUpInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_BaseStorageInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }    
    
    try {
        $TD_ExportFiles = Get-ChildItem -Path $TD_tb_Exportpath.Text -Filter "svc.config.backup.*" -ErrorAction Stop
        #Write-Host $TD_ExportFiles.count = $TD_ExportFiles
        #$TD_tb_BackUpFileErrorInfo.Text = $TD_tb_Exportpath
        $TD_tb_BackUpFileInfoDevice.ItemsSource = $TD_ExportFiles
        <# maybe add a filter #>
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error 
        $TD_tb_BackUpFileErrorInfo.Text = $_.Exception.Message
    }

    $TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_BackUpConfig.Visibility="Visible"
})

$TD_btn_IBM_HostInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_CollectedHostInfoOne,$TD_dg_CollectedHostInfoTwo,$TD_dg_CollectedHostInfoThree,$TD_dg_CollectedHostInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true }
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_Collected_HostInfoResult = IBM_Host_Volume_Map -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_CollectedHostInfoOne.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 2)} { $TD_dg_CollectedHostInfoTwo.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 3)} { $TD_dg_CollectedHostInfoThree.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 4)} { $TD_dg_CollectedHostInfoFour.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 5)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 6)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 7)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 8)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Collected_HostInfoResult }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_Collected_HostInfoResult | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_Collected_HostInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_IBM_HostInfo.Visibility="Visible" 

})

$TD_btn_IBM_IPPortInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_IPPortInfoOne,$TD_dg_IPPortInfoTwo,$TD_dg_IPPortInfoThree,$TD_dg_IPPortInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_IPPortInfo = IBM_IPPortInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_IPPortInfoOne.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 2)} { $TD_dg_IPPortInfoTwo.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 3)} { $TD_dg_IPPortInfoThree.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 4)} { $TD_dg_IPPortInfoFour.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 5)} { $TD_dg_IPPortInfoFour.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 6)} { $TD_dg_IPPortInfoFour.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 7)} { $TD_dg_IPPortInfoFour.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 8)} { $TD_dg_IPPortInfoFour.ItemsSource = $TD_IPPortInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_IPPortInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IPPortInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_IBM_IPPortInfo.Visibility="Visible"
    
})
#endregion

#region SAN Button
$TD_btn_FOS_BasicSwitchInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_dg_sanBasicSwitchInfoOne,$TD_dg_sanBasicSwitchInfoTwo,$TD_dg_sanBasicSwitchInfoThree,$TD_dg_sanBasicSwitchInfoFour |ForEach-Object {
        if($_.items.count -gt 0){ $_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        $FOS_BasicSwitch = $null
        $FOS_BasicSwitch = FOS_BasicSwitchInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_sanBasicSwitchInfoOne.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 2)} { $TD_dg_sanBasicSwitchInfoTwo.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 3)} { $TD_dg_sanBasicSwitchInfoThree.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 4)} { $TD_dg_sanBasicSwitchInfoFour.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 5)} { $TD_dg_sanBasicSwitchInfoFour.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 6)} { $TD_dg_sanBasicSwitchInfoFour.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 7)} { $TD_dg_sanBasicSwitchInfoFour.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 8)} { $TD_dg_sanBasicSwitchInfoFour.ItemsSource = $FOS_BasicSwitch }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $FOS_BasicSwitch | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_BasicSwitchInfos_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanSwitchShow,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanBasicSwitchInfo.Visibility="Visible"

})

$TD_btn_FOS_SwitchShow.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_lb_SwitchShowOne,$TD_lb_SwitchShowTwo,$TD_lb_SwitchShowThree,$TD_lb_SwitchShowFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$FOS_SwitchShow = FOS_SwitchShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_lb_SwitchShowOne.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 2)} { $TD_lb_SwitchShowTwo.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 3)} { $TD_lb_SwitchShowThree.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 4)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 5)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 6)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 7)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 8)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $FOS_SwitchShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_SwitchShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanSwitchShow.Visibility="Visible"

})
<# filter View for Host Volume Map #>
<# to keep this file clean :D export the following lines to a func in one if the next Version #>
$TD_btn_FilterSANSwShow.Add_Click({
    [string]$filter= $TD_tb_FilterWordSANSwShow.Text
    [string]$ColumFilter= $TD_cb_FilterColumSANSwShow.Text
    [int]$TD_SANFilter_DG_Colum = $TD_cb_ListFilterSANSwShow.Text
    try {
        [array]$TD_CollectVolInfo = Import-Csv -Path $Env:TEMP\$($TD_SANFilter_DG_Colum)_SwitchShow_Temp.csv -ErrorAction Stop
        switch ($TD_SANFilter_DG_Colum) {
            1 { $FOS_SwitchShow = $TD_lb_SwitchShowOne.ItemsSource }
            2 { $FOS_SwitchShow = $TD_lb_SwitchShowTwo.ItemsSource }
            3 { $FOS_SwitchShow = $TD_lb_SwitchShowThree.ItemsSource }
            4 { $FOS_SwitchShow = $TD_lb_SwitchShowFour.ItemsSource }
            Default {Write-Host "Something went wrong at Switchshow" -ForegroundColor DarkMagenta}
        }
        if($FOS_SwitchShow.Count -ne $TD_CollectVolInfo.Count){
            $FOS_SwitchShow = $TD_CollectVolInfo }

            switch ($ColumFilter) {
                "Port" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Port -Match $filter } }
                "Speed" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Speed -Match $filter } }
                "State" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.State -Match $filter } }
                "PortConnect" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.PortConnect -Match $filter } }
                Default {Write-Host "Something went wrong at Switchshow" -ForegroundColor DarkMagenta}
            }

            switch ($TD_SANFilter_DG_Colum) {
                1 { $TD_lb_SwitchShowOne.ItemsSource = $WPF_dataGrid }
                2 { $TD_lb_SwitchShowTwo.ItemsSource = $WPF_dataGrid }
                3 { $TD_lb_SwitchShowThree.ItemsSource = $WPF_dataGrid }
                4 { $TD_lb_SwitchShowFour.ItemsSource = $WPF_dataGrid }
                Default {Write-Host "Something went wrong at Switchshow" -ForegroundColor DarkMagenta}
            }
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $TD_lb_ErrorMsgSANSwShow.Content = $_.Exception.Message
    }
})

$TD_btn_FOS_ZoneDetailsShow.add_click({

    $TD_lb_FabricOne.Visibility = "Hidden";
    $TD_lb_FabricTwo.Visibility = "Hidden";
    $TD_stp_FilterFabricOneVisibilty.Visibility = "Collapsed"
    $TD_stp_FilterFabricTwoVisibilty.Visibility = "Collapsed"

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_dg_ZoneDetailsOne,$TD_dg_ZoneDetailsTwo,$FOS_EffeZoneNameThree |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    foreach($TD_Credential in $TD_Credentials){
        <# QaD needs a Codeupdate #>
        #Write-Debug -Message $TD_Credential
        switch ($TD_Credential.ID) {
            {($_ -eq 1)} 
            {   
                $TD_FOS_ZoneShow, $FOS_EffeZoneNameOne = FOS_ZoneDetails -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
                Start-Sleep -Seconds 0.5
                $TD_dg_ZoneDetailsOne.ItemsSource =$TD_FOS_ZoneShow
                $TD_lb_FabricOne.Visibility = "Visible";
                $TD_lb_FabricOne.Content = $FOS_EffeZoneNameOne
                $TD_stp_FilterFabricOneVisibilty.Visibility = "Visible"
                $TD_FOS_ZoneShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($FOS_EffeZoneNameOne)_ZoneShow_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
            }
            {($_ -eq 2) } <# -or ($_ -eq 3) -or ($_ -eq 4)}  for later use maybe #>
            {            
                $TD_FOS_ZoneShow, $FOS_EffeZoneNameTwo = FOS_ZoneDetails -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
                if($FOS_EffeZoneNameOne -ne $FOS_EffeZoneNameTwo){
                Start-Sleep -Seconds 0.5
                $TD_dg_ZoneDetailsTwo.ItemsSource =$TD_FOS_ZoneShow
                $TD_lb_FabricTwo.Visibility = "Visible";
                $TD_stp_FilterFabricTwoVisibilty.Visibility = "Visible"
                $TD_lb_FabricTwo.Content = $FOS_EffeZoneNameTwo
                $TD_FOS_ZoneShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($FOS_EffeZoneNameTwo)_ZoneShow_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
                }
            }
            {($_ -eq 3) } <# -or ($_ -eq 3) -or ($_ -eq 4)}  for later use maybe #>
            {            
                $TD_FOS_ZoneShow, $FOS_EffeZoneNameThree = FOS_ZoneDetails  -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
                Start-Sleep -Seconds 0.5
                if($FOS_EffeZoneNameOne -ne $FOS_EffeZoneNameThree){
                    if($FOS_EffeZoneNameThree -ne $FOS_EffeZoneNameTwo){
                        Start-Sleep -Seconds 0.5
                        $FOS_EffeZoneNameThree.ItemsSource =$TD_FOS_ZoneShow}
                        $TD_FOS_ZoneShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($FOS_EffeZoneNameThree)_ZoneShow_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
                    }
            }
            <# not needed becaus max support at moment are 2 fabs #>
            #{($_ -eq 4) }
            #{            
            #    $TD_FOS_PortbufferShow += FOS_ZoneDetails -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
            #    Start-Sleep -Seconds 0.5
            #    $TD_lb_PortBufferShowFour.ItemsSource =$TD_FOS_PortbufferShow
            #}
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error}
        }
    }
    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanSwitchShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanZoneDetailsShow.Visibility="Visible"

})
<# filter View for Host Volume Map #>
<# to keep this file clean :D export the following lines to a func in one if the next Version #>
$TD_btn_FilterFabricOne.Add_Click({
    [string]$FOS_filter= $TD_tb_FilterFabricOne.Text
    [string]$TD_Filter_DG_Colum = $TD_cb_FilterFabricOne.Text
    try {
        [array]$TD_CollectZoneInfo = Import-Csv -Path $Env:TEMP\$($TD_lb_FabricOne.Content)_ZoneShow_Temp.csv -ErrorAction Stop
        $TD_FOS_ZoneShow = $TD_dg_ZoneDetailsOne.ItemsSource
        if($TD_FOS_ZoneShow.Count -ne $TD_CollectZoneInfo.Count){
            $TD_FOS_ZoneShow = $TD_CollectZoneInfo }
             
            switch ($TD_Filter_DG_Colum) {
                "Zone" { [array]$WPF_dataGrid = $TD_FOS_ZoneShow | Where-Object { $_.Zone -Match $FOS_filter } }
                "WWPN" { [array]$WPF_dataGrid = $TD_FOS_ZoneShow | Where-Object { $_.WWPN -Match $FOS_filter } }
                "Alias" { [array]$WPF_dataGrid = $TD_FOS_ZoneShow | Where-Object { $_.Alias -Match $FOS_filter } }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error}
            }
            
            $TD_dg_ZoneDetailsOne.ItemsSource = $WPF_dataGrid
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
    }
})
$TD_btn_FilterFabricTwo.Add_Click({
    [string]$FOS_filter= $TD_tb_FilterFabricTwo.Text
    [string]$TD_Filter_DG_Colum = $TD_cb_FilterFabricTwo.Text
    try {
        [array]$TD_CollectZoneInfo = Import-Csv -Path $Env:TEMP\$($TD_lb_FabricTwo.Content)_ZoneShow_Temp.csv -ErrorAction Stop
        $TD_FOS_ZoneShow = $TD_dg_ZoneDetailsTwo.ItemsSource
        if($TD_FOS_ZoneShow.Count -ne $TD_CollectZoneInfo.Count){
            $TD_FOS_ZoneShow = $TD_CollectZoneInfo }
             
            switch ($TD_Filter_DG_Colum) {
                "Zone" { [array]$WPF_dataGrid = $TD_FOS_ZoneShow | Where-Object { $_.Zone -Match $FOS_filter } }
                "WWPN" { [array]$WPF_dataGrid = $TD_FOS_ZoneShow | Where-Object { $_.WWPN -Match $FOS_filter } }
                "Alias" { [array]$WPF_dataGrid = $TD_FOS_ZoneShow | Where-Object { $_.Alias -Match $FOS_filter } }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error}
            }
            
            $TD_dg_ZoneDetailsTwo.ItemsSource = $WPF_dataGrid
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
    }
})

$TD_btn_FOS_PortLicenseShow.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_lb_SANInfoOne,$TD_lb_SANInfoTwo,$TD_lb_SANInfoThree,$TD_lb_SANInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_PortLicenseShow = FOS_PortLicenseShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { 
                $TD_lb_SANInfoOne.Visibility="Visible"
                $TD_lb_SANInfoOne.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)
            }
            {($_ -eq 2)} { 
                $TD_lb_SANInfoTwo.Visibility="Visible"
                $TD_lb_SANInfoTwo.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)
            }
            {($_ -eq 3)} {
                $TD_lb_SANInfoThree.Visibility="Visible"
                $TD_lb_SANInfoThree.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)
            }
            {($_ -eq 4)} { 
                $TD_lb_SANInfoFour.Visibility="Visible"
                $TD_lb_SANInfoFour.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)
            }
            {($_ -eq 5)} { $TD_lb_SwitchShowFour.ItemsSource = $TD_FOS_PortLicenseShow }
            {($_ -eq 6)} { $TD_lb_SwitchShowFour.ItemsSource = $TD_FOS_PortLicenseShow }
            {($_ -eq 7)} { $TD_lb_SwitchShowFour.ItemsSource = $TD_FOS_PortLicenseShow }
            {($_ -eq 8)} { $TD_lb_SwitchShowFour.ItemsSource = $TD_FOS_PortLicenseShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FOS_PortLicenseShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_PortLicenseShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanSwitchShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanLicenseShow.Visibility="Visible"

})

$TD_btn_FOS_SensorShow.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_tb_SensorInfoOne,$TD_tb_SensorInfoTwo,$TD_tb_SensorInfoThree,$TD_tb_SensorInfoFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_SensorShow = FOS_SensorShow -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { 
                $TD_tb_SensorInfoOne.Visibility="Visible"
                $TD_tb_SensorInfoOne.Text = (Out-String -InputObject $TD_FOS_SensorShow)
            }
            {($_ -eq 2)} { 
                $TD_tb_SensorInfoTwo.Visibility="Visible"
                $TD_tb_SensorInfoTwo.Text = (Out-String -InputObject $TD_FOS_SensorShow)
            }
            {($_ -eq 3)} {
                $TD_tb_SensorInfoThree.Visibility="Visible"
                $TD_tb_SensorInfoThree.Text = (Out-String -InputObject $TD_FOS_SensorShow)
            }
            {($_ -eq 4)} {
                $TD_tb_SensorInfoFour.Visibility="Visible"
                $TD_tb_SensorInfoFour.Text = (Out-String -InputObject $TD_FOS_SensorShow)
            }
            {($_ -eq 5)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 6)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 7)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 8)} { $TD_lb_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FOS_SensorShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_SensorShow_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanSwitchShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanLicenseShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanSensorShow.Visibility="Visible"

})

<# Unnecessary duplicated code with TD_btn_StatsClear, needs a better implementation but for the first step it's okay. #>
$TD_btn_FOS_PortErrorShow.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_lb_PortErrorShowOne,$TD_lb_PortErrorShowTwo,$TD_lb_PortErrorShowThree,$TD_lb_PortErrorShowFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_PortErrShow = FOS_PortErrShowInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_lb_PortErrorShowOne.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 2)} { $TD_lb_PortErrorShowTwo.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 3)} { $TD_lb_PortErrorShowThree.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 4)} { $TD_lb_PortErrorShowFour.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 5)} { $TD_lb_PortErrorShowFour.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 6)} { $TD_lb_PortErrorShowFour.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 7)} { $TD_lb_PortErrorShowFour.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 8)} { $TD_lb_PortErrorShowFour.ItemsSource = $TD_FOS_PortErrShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FOS_PortErrShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_PortErrShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortBufferShow,$TD_stp_sanSwitchShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanPortErrorShow.Visibility="Visible"

})

$TD_btn_FOS_SFPHealthShow.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_dg_SFPShowOne,$TD_dg_SFPShowTwo,$TD_dg_SFPShowThree,$TD_dg_SFPShowFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_SFPDetailsShow = FOS_SFPDetails -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_SFPShowOne.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 2)} { $TD_dg_SFPShowTwo.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 3)} { $TD_dg_SFPShowThree.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 4)} { $TD_dg_SFPShowFour.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 5)} { $TD_dg_SFPShowFour.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 6)} { $TD_dg_SFPShowFour.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 7)} { $TD_dg_SFPShowFour.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 8)} { $TD_dg_SFPShowFour.ItemsSource = $TD_FOS_SFPDetailsShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FOS_SFPDetailsShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_SFPDetails_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortErrorShow,$TD_stp_sanSwitchShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanPortBufferShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanSFPShow.Visibility="Visible"

})

<# Unnecessary duplicated code with TD_btn_FOS_PortErrorShow, needs a better implementation but for the first step it's okay. #>
$TD_btn_StatsClear.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    foreach($TD_Credential in $TD_Credentials){
        <# QaD needs a Codeupdate because Grouping dose not work #>
        $TD_FOS_PortErrShow =@()
        switch ($TD_Credential.ID) {
            {($_ -eq 1)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_tb_pathtokey.Text) $SANUserName@$Device_IP "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }else{
                    try {
                        $TD_FOS_StatsClear = plink $SANUserName@$Device_IP -pw $($([Net.NetworkCredential]::new('', $TD_Credential.Password).Password)) -batch "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true 
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }
                if($TD_FOS_StatsClearDone){
                    $TD_lb_PortErrorShowOne.ItemsSource = $EmptyVar
                    $TD_lb_OneClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_lb_PortErrorShowOne.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 2)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_tb_pathtokey.Text) $SANUserName@$Device_IP "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }else{
                    try {
                        $TD_FOS_StatsClear = plink $SANUserName@$Device_IP -pw $($([Net.NetworkCredential]::new('', $TD_Credential.Password).Password)) -batch "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }
                if($TD_FOS_StatsClearDone){
                    $TD_lb_PortErrorShowTwo.ItemsSource = $EmptyVar
                    $TD_lb_TwoClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_lb_PortErrorShowTwo.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 3)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_tb_pathtokey.Text) $SANUserName@$Device_IP "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }else{
                    try {
                        $TD_FOS_StatsClear = plink $SANUserName@$Device_IP -pw $($([Net.NetworkCredential]::new('', $TD_Credential.Password).Password)) -batch "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }
                if($TD_FOS_StatsClearDone){
                    $TD_lb_PortErrorShowThree.ItemsSource = $EmptyVar
                    $TD_lb_ThreeClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_lb_PortErrorShowThree.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 4)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_tb_pathtokey.Text) $SANUserName@$Device_IP "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }else{
                    try {
                        $TD_FOS_StatsClear = plink $SANUserName@$Device_IP -pw $($([Net.NetworkCredential]::new('', $TD_Credential.Password).Password)) -batch "statsClear" 2>&1
                        $TD_FOS_StatsClearDone = $true
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
                        Write-Host $_.Exception.Message
                        #$TD_tb_BackUpInfoDeviceOne.Text = $_.Exception.Message
                    }
                }
                if($TD_FOS_StatsClearDone){
                    $TD_lb_PortErrorShowFour.ItemsSource = $EmptyVar
                    $TD_lb_FourClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_lb_PortErrorShowFour.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error}
        }
    }
})

$TD_btn_FOS_PortBufferShow.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_lb_PortBufferShowOne,$TD_lb_PortBufferShowTwo,$TD_lb_PortBufferShowThree,$TD_lb_PortBufferShowFour |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_PortbufferShow = FOS_PortbufferShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_lb_PortBufferShowOne.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 2)} { $TD_lb_PortBufferShowTwo.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 3)} { $TD_lb_PortBufferShowThree.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 4)} { $TD_lb_PortBufferShowFour.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 5)} { $TD_lb_PortBufferShowFour.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 6)} { $TD_lb_PortBufferShowFour.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 7)} { $TD_lb_PortBufferShowFour.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 8)} { $TD_lb_PortBufferShowFour.ItemsSource = $TD_FOS_PortbufferShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FOS_PortbufferShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_PortbufferShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortErrorShow,$TD_stp_sanSwitchShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanPortBufferShow.Visibility="Visible"

})
#endregion

#region Health Check
$TD_btn_Storage_SysCheck.add_click({
    
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    foreach($TD_Credential in $TD_Credentials){
        <# QaD needs a Codeupdate because Grouping dose not work #>
        $TD_SystemCheck = $TD_cb_Device_HealthCheck.Text
        switch ($TD_Credential.ID) {
            {(($_ -eq 1) -and ($TD_SystemCheck-eq "Check the First"))} 
            {
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
            }
            {(($_ -eq 2) -and ($TD_SystemCheck-eq "Check the Second"))} 
            {
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
            }
            {(($_ -eq 3) -and ($TD_SystemCheck-eq "Check the Third"))}  
            {
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
            }
            {(($_ -eq 4) -and ($TD_SystemCheck-eq "Check the Fourth"))}  
            {
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Exportpath $TD_tb_ExportPath.Text
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error}
        }
    }
})
$TD_btn_HC_OpenGUI_One.add_click({
    Start-Process "https://$($TD_tb_storageIPAdr.Text)"
})
$TD_btn_HC_OpenGUI_Two.add_click({
    Start-Process "https://$($TD_tb_storageIPAdrOne.Text)"
})
$TD_btn_HC_OpenGUI_Three.add_click({
    Start-Process "https://$($TD_tb_storageIPAdrTwo.Text)"
})
$TD_btn_HC_OpenGUI_Four.add_click({
    Start-Process "https://$($TD_tb_storageIPAdrThree.Text)"
})
#endregion

$TD_btn_CloseAll.add_click({
    <#CleanUp before close #>
    try {
        Remove-Item -Path $PSRootPath\ToolLog\ToolTEMP\* -Filter '*_Temp.csv' -Force -ErrorAction SilentlyContinue
        Write-Debug -Message "Remove Files from TEMP-Folder, done."
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Debug -Message "Remove Files fail."
        Write-Debug -Message $_.Exception.Message
    }
    Write-Debug -Message "Close the appl via CloseBtn"
    $Mainform.Close()
})

Get-Variable TD_*

$Mainform.showDialog()
$Mainform.activate()

}