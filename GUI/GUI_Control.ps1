Add-Type -AssemblyName PresentationCore,PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

<# Create the xaml Files / Base of GUI Mainwindow #>
function Storage_SAN_Tool {
[CmdletBinding()]
#$ErrorActionPreference="SilentlyContinue"

#$ResDicxamlFile ="$PSScriptRoot\ResourcesDictionaryXAML.xaml"
#$blabla = Get-Content -Path $ResDicxamlFile -raw
#[xml]$ResDicinputXAML = $blabla
#[Xml.XmlNodeReader] $ResDicReader = $ResDicinputXAML 
#$ResDicWindow = [Windows.Markup.XamlReader]::Load( $ResDicReader )


$MainxamlFile ="$PSScriptRoot\MainWindow.xaml"
$inputXAML=Get-Content -Path $MainxamlFile -raw
[xml]$MainXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
#[xml]$MainXAML=$inputXAML
[System.Xml.XmlNodeReader] $Mainreader = $MainXAML
$MainWindow =[Windows.Markup.XamlReader]::Load($Mainreader)
#$Mainform.Resources.MergedDictionaries.Add($ResDicWindow)
$MainXAML.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $MainWindow.FindName($_.Name)}



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
    <# Clean all LogFiles if there older than 90 Days #>
    SST_FileCleanUp
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
    #$TD_ButtonColorSSH=$TD_btn_addsshkeyone.Background
    $IsKeyIn = $TD_TB_PathtoSSHKeyNotVisibil.Text
    if([string]::IsNullOrWhiteSpace($IsKeyIn)){
        RemoveSSHKeyfromLine -TD_Storage "yes"
    }else {
        AddSSHKeytoLine -TD_Storage "yes"
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

    $TD_lb_StorageEventLogOne,$TD_lb_StorageEventLogTwo,$TD_lb_StorageEventLogThree,$TD_lb_StorageEventLogFour,$TD_lb_StorageEventLogFive,$TD_lb_StorageEventLogSix,$TD_lb_StorageEventLogSeven,$TD_lb_StorageEventLogEight |ForEach-Object {
        if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_IBM_EventLogShow = IBM_EventLog -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_lb_StorageEventLogOne.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 2)} { $TD_lb_StorageEventLogTwo.ItemsSource = $TD_IBM_EventLogShow }  
            {($_ -eq 3)} { $TD_lb_StorageEventLogThree.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 4)} { $TD_lb_StorageEventLogFour.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 5)} { $TD_lb_StorageEventLogFive.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 6)} { $TD_lb_StorageEventLogSix.ItemsSource = $TD_IBM_EventLogShow }  
            {($_ -eq 7)} { $TD_lb_StorageEventLogSeven.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 8)} { $TD_lb_StorageEventLogEight.ItemsSource = $TD_IBM_EventLogShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_StorageEventLog.Visibility="Visible" 

})

$TD_btn_IBM_CatAuditLog.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_StorageAuditLogOne,$TD_dg_StorageAuditLogTwo,$TD_dg_StorageAuditLogThree,$TD_dg_StorageAuditLogFour,$TD_dg_StorageAuditLogFive,$TD_dg_StorageAuditLogSix,$TD_dg_StorageAuditLogSeven,$TD_dg_StorageAuditLogEight |ForEach-Object {
        if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_CatAuditLog = IBM_CatAuditLog -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_StorageAuditLogOne.ItemsSource = $TD_CatAuditLog  }
            {($_ -eq 2)} { $TD_dg_StorageAuditLogTwo.ItemsSource = $TD_CatAuditLog  }
            {($_ -eq 3)} { $TD_dg_StorageAuditLogThree.ItemsSource = $TD_CatAuditLog} 
            {($_ -eq 4)} { $TD_dg_StorageAuditLogFour.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 5)} { $TD_dg_StorageAuditLogFive.ItemsSource = $TD_CatAuditLog }
            {($_ -eq 6)} { $TD_dg_StorageAuditLogSix.ItemsSource = $TD_CatAuditLog  }
            {($_ -eq 7)} { $TD_dg_StorageAuditLogSeven.ItemsSource = $TD_CatAuditLog}
            {($_ -eq 8)} { $TD_dg_StorageAuditLogEight.ItemsSource = $TD_CatAuditLog}
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_CatAuditLog | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IBM_CatAuditLog_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_StorageAuditLog.Visibility="Visible" 

})

$TD_btn_IBM_HostVolumeMap.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_HostVolInfoOne,$TD_dg_HostVolInfoTwo,$TD_dg_HostVolInfoThree,$TD_dg_HostVolInfoFour,$TD_dg_HostVolInfoFive,$TD_dg_HostVolInfoSix,$TD_dg_HostVolInfoSeven,$TD_dg_HostVolInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true };
    }

    $TD_Credentials | ForEach-Object {  
        [array]$TD_Host_Volume_Map = IBM_Host_Volume_Map -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_HostVolInfoOne.ItemsSource = $TD_Host_Volume_Map  }
            {($_ -eq 2)} { $TD_dg_HostVolInfoTwo.ItemsSource = $TD_Host_Volume_Map  }
            {($_ -eq 3)} { $TD_dg_HostVolInfoThree.ItemsSource = $TD_Host_Volume_Map}
            {($_ -eq 4)} { $TD_dg_HostVolInfoFour.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 5)} { $TD_dg_HostVolInfoFive.ItemsSource = $TD_Host_Volume_Map }
            {($_ -eq 6)} { $TD_dg_HostVolInfoSix.ItemsSource = $TD_Host_Volume_Map  }
            {($_ -eq 7)} { $TD_dg_HostVolInfoSeven.ItemsSource = $TD_Host_Volume_Map}
            {($_ -eq 8)} { $TD_dg_HostVolInfoEight.ItemsSource = $TD_Host_Volume_Map}
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_Host_Volume_Map | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_Host_Vol_Map_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_HostVolInfo.Visibility="Visible" 

})
<# filter View for Host Volume Map #>
<# to keep this file clean :D export the following lines to a func in one if the next Version #>
$TD_btn_FilterHVM.Add_Click({
    $TD_btn_ClearFilterHVM.Visibility="Visible"
    [string]$filter= $TD_tb_filter.Text
    [int]$TD_Filter_DG = $TD_cb_ListFilterStorageHVM.Text
    [string]$TD_Filter_DG_Colum = $TD_cb_StorageHVM.Text
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {(($_.DeviceTyp -eq "Storage")-and($_.ID -eq $TD_Filter_DG))}
    try {
        [array]$TD_CollectVolInfo = Import-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($TD_Filter_DG)_$($TD_Credentials.DeviceName)_Host_Vol_Map_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv -ErrorAction Stop
        switch ($TD_Filter_DG) {
            1 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoOne.ItemsSource }
            2 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoTwo.ItemsSource }
            3 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoThree.ItemsSource }
            4 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoFour.ItemsSource }
            5 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoFive.ItemsSource }
            6 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoSix.ItemsSource }
            7 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoSeven.ItemsSource }
            8 { $TD_Host_Volume_Map = $TD_dg_HostVolInfoEight.ItemsSource }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, there are no or wrong Data in $($TD_CollectVolInfo.count) found.") -TD_ToolMSGType Error}
        }
        if($TD_Host_Volume_Map.Count -ne $TD_CollectVolInfo.Count){
            $TD_Host_Volume_Map = $TD_CollectVolInfo }
             
            switch ($TD_Filter_DG_Colum) {
                "Host" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.HostName -Match $filter } }
                "HostCluster" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.HostCluster -Match $filter } }
                "Volume" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.VolumeName -Match $filter } }
                "UID" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.UID -Match $filter } }
                "Capacity" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.Capacity -Match $filter } }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, there are no or wrong Data in CollectVolInfo found.") -TD_ToolMSGType Error}
            }
            switch ($TD_Filter_DG) {
                1 { $TD_dg_HostVolInfoOne.ItemsSource = $WPF_dataGrid }
                2 { $TD_dg_HostVolInfoTwo.ItemsSource = $WPF_dataGrid }
                3 { $TD_dg_HostVolInfoThree.ItemsSource = $WPF_dataGrid }
                4 { $TD_dg_HostVolInfoFour.ItemsSource = $WPF_dataGrid }
                5 { $TD_dg_HostVolInfoFive.ItemsSource = $WPF_dataGrid }
                6 { $TD_dg_HostVolInfoSix.ItemsSource = $WPF_dataGrid }
                7 { $TD_dg_HostVolInfoSeven.ItemsSource = $WPF_dataGrid }
                8 { $TD_dg_HostVolInfoEight.ItemsSource = $WPF_dataGrid }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the the Filter or Datapath.") -TD_ToolMSGType Error}
            }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $TD_lb_ErrorMsgHVM.Visibility="visible"
        $TD_lb_ErrorMsgHVM.Content = $_.Exception.Message
    }

})

$TD_btn_ClearFilterHVM.Add_Click({

    [int]$TD_Filter_DG = $TD_cb_ListFilterStorageHVM.Text
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {(($_.DeviceTyp -eq "Storage")-and($_.ID -eq $TD_Filter_DG))}
    
    $TD_tb_filter.Text = ""
    try {
        [array]$TD_CollectVolInfo = Import-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($TD_Filter_DG)_$($TD_Credentials.DeviceName)_Host_Vol_Map_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv -ErrorAction Stop
        switch ($TD_Filter_DG) {
            1 { $TD_dg_HostVolInfoOne.ItemsSource = $TD_CollectVolInfo }
            2 { $TD_dg_HostVolInfoTwo.ItemsSource = $TD_CollectVolInfo }
            3 { $TD_dg_HostVolInfoThree.ItemsSource = $TD_CollectVolInfo }
            4 { $TD_dg_HostVolInfoFour.ItemsSource = $TD_CollectVolInfo }
            5 { $TD_dg_HostVolInfoFive.ItemsSource = $TD_CollectVolInfo }
            6 { $TD_dg_HostVolInfoSix.ItemsSource = $TD_CollectVolInfo }
            7 { $TD_dg_HostVolInfoSeven.ItemsSource = $TD_CollectVolInfo }
            8 { $TD_dg_HostVolInfoEight.ItemsSource = $TD_CollectVolInfo }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, ID $($TD_Filter_DG) or DeviceName $($TD_Credentials.DeviceName) can not be found") -TD_ToolMSGType Error}
        }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $TD_lb_ErrorMsgHVM.Visibility="visible"
        $TD_lb_ErrorMsgHVM.Content = $_.Exception.Message
    }
})

$TD_btn_IBM_DriveInfo.add_click({
    $TD_lb_DriveInfoOne.Visibility = "Hidden"; $TD_lb_DriveInfoTwo.Visibility = "Hidden"; $TD_lb_DriveInfoThree.Visibility = "Hidden"; $TD_lb_DriveInfoFour.Visibility = "Hidden"; 
    $TD_lb_DriveInfoFive.Visibility = "Hidden"; $TD_lb_DriveInfoSix.Visibility = "Hidden"; $TD_lb_DriveInfoSeven.Visibility = "Hidden"; $TD_lb_DriveInfoEight.Visibility = "Hidden";

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_DriveInfo,$TD_dg_DriveInfoTwo,$TD_dg_DriveInfoThree,$TD_dg_DriveInfoFour,$TD_dg_DriveInfoFive,$TD_dg_DriveInfoSix,$TD_dg_DriveInfoSeven,$TD_dg_DriveInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    
    $TD_Credentials | ForEach-Object {
        [array]$TD_DriveInfo = IBM_DriveInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_DriveInfoOne.ItemsSource = $TD_DriveInfo }
            {($_ -eq 2)} { $TD_dg_DriveInfoTwo.ItemsSource = $TD_DriveInfo }
            {($_ -eq 3)} { $TD_dg_DriveInfoThree.ItemsSource = $TD_DriveInfo }
            {($_ -eq 4)} { $TD_dg_DriveInfoFour.ItemsSource = $TD_DriveInfo }
            {($_ -eq 5)} { $TD_dg_DriveInfoFive.ItemsSource = $TD_DriveInfo }
            {($_ -eq 6)} { $TD_dg_DriveInfoSix.ItemsSource = $TD_DriveInfo }
            {($_ -eq 7)} { $TD_dg_DriveInfoSeven.ItemsSource = $TD_DriveInfo }
            {($_ -eq 8)} { $TD_dg_DriveInfoEight.ItemsSource = $TD_DriveInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_DriveInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_DriveInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_StorageEventLog,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_DriveInfo.Visibility="Visible" 

})

$TD_btn_IBM_FCPortStats.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_FCPortStatsOne,$TD_dg_FCPortStatsTwo,$TD_dg_FCPortStatsThree,$TD_dg_FCPortStatsFour,$TD_dg_FCPortStatsFive,$TD_dg_FCPortStatsSix,$TD_dg_FCPortStatsSeven,$TD_dg_FCPortStatsEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FCPortStats = IBM_FCPortStats -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_FCPortStatsOne.ItemsSource = $TD_FCPortStats }
            {($_ -eq 2)} { $TD_dg_FCPortStatsTwo.ItemsSource = $TD_FCPortStats }
            {($_ -eq 3)} { $TD_dg_FCPortStatsThree.ItemsSource = $TD_FCPortStats }
            {($_ -eq 4)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortStats }
            {($_ -eq 5)} { $TD_dg_FCPortStatsFive.ItemsSource = $TD_FCPortStats }
            {($_ -eq 6)} { $TD_dg_FCPortStatsSix.ItemsSource = $TD_FCPortStats }
            {($_ -eq 7)} { $TD_dg_FCPortStatsSeven.ItemsSource = $TD_FCPortStats }
            {($_ -eq 8)} { $TD_dg_FCPortStatsEight.ItemsSource = $TD_FCPortStats }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FCPortStats | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FCPortStats_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_StorageEventLog,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_FCPortStats.Visibility="Visible" 

})

$TD_btn_IBM_FCPortInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_FCPortInfoOne,$TD_dg_FCPortInfoTwo,$TD_dg_FCPortInfoThree,$TD_dg_FCPortInfoFour,$TD_dg_FCPortInfoFive,$TD_dg_FCPortInfoSix,$TD_dg_FCPortInfoSeven,$TD_dg_FCPortInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FCPortInfo = IBM_FCPortInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_FCPortInfoOne.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 2)} { $TD_dg_FCPortInfoTwo.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 3)} { $TD_dg_FCPortInfoThree.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 4)} { $TD_dg_FCPortInfoFour.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 5)} { $TD_dg_FCPortInfoFive.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 6)} { $TD_dg_FCPortInfoSix.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 7)} { $TD_dg_FCPortInfoSeven.ItemsSource = $TD_FCPortInfo }
            {($_ -eq 8)} { $TD_dg_FCPortInfoEight.ItemsSource = $TD_FCPortInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FCPortInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FCPortInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_IBM_FCPortInfo.Visibility="Visible"
    
})

$TD_btn_IBM_PolicyBased_Rep.add_click({
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_StorageEventLog,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

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
                [array]$TD_PolicyBased_Rep = IBM_PolicyBased_Rep -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_RepInfoChose $TD_RepInfoChose -TD_Exportpath $TD_tb_ExportPath.Text
                switch ($_.ID) {
                    {($_ -eq 1)} { $TD_dg_ReplicationPolicyOne.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 2)} { $TD_dg_ReplicationPolicyTwo.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 3)} { $TD_dg_ReplicationPolicyThree.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 4)} { $TD_dg_ReplicationPolicyFour.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 5)} { $TD_dg_ReplicationPolicyFive.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 6)} { $TD_dg_ReplicationPolicySix.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 7)} { $TD_dg_ReplicationPolicySeven.ItemsSource = $TD_PolicyBased_Rep }
                    {($_ -eq 8)} { $TD_dg_ReplicationPolicyEight.ItemsSource = $TD_PolicyBased_Rep }
                    Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
                }
            }
        }
        "VolumeGroupReplication" { 

            $TD_dg_ReplicationPolicyOne,$TD_dg_ReplicationPolicyTwo,$TD_dg_ReplicationPolicyThree,$TD_dg_ReplicationPolicyFour,$TD_dg_VolumeGrpReplicationOne,$TD_dg_VolumeGrpReplicationTwo,$TD_dg_VolumeGrpReplicationThree,$TD_dg_VolumeGrpReplicationFour |ForEach-Object {
                if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
            }

            $TD_Credentials | ForEach-Object {
                [array]$TD_VolumeGroupRep = IBM_PolicyBased_Rep -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_RepInfoChose $TD_RepInfoChose -TD_Exportpath $TD_tb_ExportPath.Text
                switch ($_.ID) {
                    {($_ -eq 1)} { $TD_dg_VolumeGrpReplicationOne.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 2)} { $TD_dg_VolumeGrpReplicationTwo.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 3)} { $TD_dg_VolumeGrpReplicationThree.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 4)} { $TD_dg_VolumeGrpReplicationFour.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 5)} { $TD_dg_VolumeGrpReplicationFive.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 6)} { $TD_dg_VolumeGrpReplicationSix.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 7)} { $TD_dg_VolumeGrpReplicationSeven.ItemsSource = $TD_VolumeGroupRep }
                    {($_ -eq 8)} { $TD_dg_VolumeGrpReplicationEight.ItemsSource = $TD_VolumeGroupRep }
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

    $TD_dg_BaseStorageInfoOne,$TD_dg_BaseStorageInfoTwo,$TD_dg_BaseStorageInfoThree,$TD_dg_BaseStorageInfoFour,$TD_dg_BaseStorageInfoFive,$TD_dg_BaseStorageInfoSix,$TD_dg_BaseStorageInfoSeven,$TD_dg_BaseStorageInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_BaseStorageInfo = IBM_BaseStorageInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_BaseStorageInfoOne.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 2)} { $TD_dg_BaseStorageInfoTwo.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 3)} { $TD_dg_BaseStorageInfoThree.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 4)} { $TD_dg_BaseStorageInfoFour.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 5)} { $TD_dg_BaseStorageInfoFive.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 6)} { $TD_dg_BaseStorageInfoSix.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 7)} { $TD_dg_BaseStorageInfoSeven.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 8)} { $TD_dg_BaseStorageInfoEight.ItemsSource = $TD_BaseStorageInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_BaseStorageInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_BaseStorageInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }
    $TD_dg_IPQuorumInfoOne,$TD_dg_IPQuorumInfoTwo,$TD_dg_IPQuorumInfoThree,$TD_dg_IPQuorumInfoFour,$TD_dg_IPQuorumInfoFive,$TD_dg_IPQuorumInfoSix,$TD_dg_IPQuorumInfoSeven,$TD_dg_IPQuorumInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_IPQuorumInfo = IBM_IPQuorum -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_IPQuorumInfoOne.ItemsSource = $TD_IPQuorumInfo;   }
            {($_ -eq 2)} { $TD_dg_IPQuorumInfoTwo.ItemsSource = $TD_IPQuorumInfo ;  }
            {($_ -eq 3)} { $TD_dg_IPQuorumInfoThree.ItemsSource = $TD_IPQuorumInfo; }
            {($_ -eq 4)} { $TD_dg_IPQuorumInfoFour.ItemsSource = $TD_IPQuorumInfo ; }
            {($_ -eq 5)} { $TD_dg_IPQuorumInfoFive.ItemsSource = $TD_IPQuorumInfo ; }
            {($_ -eq 6)} { $TD_dg_IPQuorumInfoSix.ItemsSource = $TD_IPQuorumInfo ;  }
            {($_ -eq 7)} { $TD_dg_IPQuorumInfoSeven.ItemsSource = $TD_IPQuorumInfo; }
            {($_ -eq 8)} { $TD_dg_IPQuorumInfoEight.ItemsSource = $TD_IPQuorumInfo; }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_IPQuorumInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IPQuorumInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    
    $TD_stp_BaseStorageInfo.Visibility="Visible"
})

$TD_btn_IBM_PoolVolumeInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_ExpandMDiskInfoOne,$TD_dg_ExpandMDiskInfoTwo,$TD_dg_ExpandMDiskInfoThree,$TD_dg_ExpandMDiskInfoFour,$TD_dg_ExpandMDiskInfoFive,$TD_dg_ExpandMDiskInfoSix,$TD_dg_ExpandMDiskInfoSeven,$TD_dg_ExpandMDiskInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_ExpandMDiskInfo = IBM_MDiskInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_ExpandMDiskInfoOne.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 2)} { $TD_dg_ExpandMDiskInfoTwo.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 3)} { $TD_dg_ExpandMDiskInfoThree.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 4)} { $TD_dg_ExpandMDiskInfoFour.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 5)} { $TD_dg_ExpandMDiskInfoFive.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 6)} { $TD_dg_ExpandMDiskInfoSix.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 7)} { $TD_dg_ExpandMDiskInfoSeven.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 8)} { $TD_dg_ExpandMDiskInfoEight.ItemsSource = $TD_ExpandMDiskInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_ExpandMDiskInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_ExpandMDiskInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }
    $TD_dg_ExpandVolumeInfoOne,$TD_dg_ExpandVolumeInfoTwo,$TD_dg_ExpandVolumeInfoThree,$TD_dg_ExpandVolumeInfoFour,$TD_dg_ExpandVolumeInfoFive,$TD_dg_ExpandVolumeInfoSix,$TD_dg_ExpandVolumeInfoSeven,$TD_dg_ExpandVolumeInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    $TD_Credentials | ForEach-Object {
        [array]$TD_ExpandVolumeInfo = IBM_VolumeInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_ExpandVolumeInfoOne.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 2)} { $TD_dg_ExpandVolumeInfoTwo.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 3)} { $TD_dg_ExpandVolumeInfoThree.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 4)} { $TD_dg_ExpandVolumeInfoFour.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 5)} { $TD_dg_ExpandVolumeInfoFive.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 6)} { $TD_dg_ExpandVolumeInfoSix.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 7)} { $TD_dg_ExpandVolumeInfoSeven.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 8)} { $TD_dg_ExpandVolumeInfoEight.ItemsSource = $TD_ExpandVolumeInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_ExpandVolumeInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_ExpandVolumeInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_BaseStorageInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    
    $TD_stp_PoolVolumeInfo.Visibility="Visible"
})

$TD_btn_IBM_CleanUpDumps.add_click({
    $ErrorActionPreference="Continue"

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_Credentials | ForEach-Object {
        $TD_CleanUpDumpInfo = $null
        $TD_CleanUpDumpInfo = IBM_CleanUpDumps -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_tb_CleanUpDumpInfoOne.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 2)} { $TD_tb_CleanUpDumpInfoTwo.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 3)} { $TD_tb_CleanUpDumpInfoThree.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 4)} { $TD_tb_CleanUpDumpInfoFour.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 5)} { $TD_tb_CleanUpDumpInfoFive.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 6)} { $TD_tb_CleanUpDumpInfoSix.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 7)} { $TD_tb_CleanUpDumpInfoSeven.Text = $TD_CleanUpDumpInfo }
            {($_ -eq 8)} { $TD_tb_CleanUpDumpInfoEight.Text = $TD_CleanUpDumpInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
    }
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_CleanUpDump.Visibility="Visible"
})

$TD_btn_IBM_BackUpConfig.add_click({
    $ErrorActionPreference="Continue"

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_Credentials | ForEach-Object {
        $TD_StorageBackUpInfo = $null
        $TD_StorageBackUpInfo = IBM_BackUpConfig -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_tb_BackUpInfoDeviceOne.Text = $TD_StorageBackUpInfo }
            {($_ -eq 2)} { $TD_tb_BackUpInfoDeviceTwo.Text = $TD_StorageBackUpInfo }
            {($_ -eq 3)} { $TD_tb_BackUpInfoDeviceThree.Text = $TD_StorageBackUpInfo }
            {($_ -eq 4)} { $TD_tb_BackUpInfoDeviceFour.Text = $TD_StorageBackUpInfo }
            {($_ -eq 5)} { $TD_tb_BackUpInfoDeviceFive.Text = $TD_StorageBackUpInfo }
            {($_ -eq 6)} { $TD_tb_BackUpInfoDeviceSix.Text = $TD_StorageBackUpInfo }
            {($_ -eq 7)} { $TD_tb_BackUpInfoDeviceSeven.Text = $TD_StorageBackUpInfo }
            {($_ -eq 8)} { $TD_tb_BackUpInfoDeviceEight.Text = $TD_StorageBackUpInfo }
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

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_BackUpConfig.Visibility="Visible"
})

$TD_btn_IBM_HostInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}


    $TD_dg_CollectedHostInfoOne,$TD_dg_CollectedHostInfoTwo,$TD_dg_CollectedHostInfoThree,$TD_dg_CollectedHostInfoFour,$TD_dg_CollectedHostInfoFive,$TD_dg_CollectedHostInfoSix,$TD_dg_CollectedHostInfoSeven,$TD_dg_CollectedHostInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true }
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_Collected_HostInfoResult = IBM_HostInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_CollectedHostInfoOne.ItemsSource = $TD_Collected_HostInfoResult   }
            {($_ -eq 2)} { $TD_dg_CollectedHostInfoTwo.ItemsSource = $TD_Collected_HostInfoResult   }
            {($_ -eq 3)} { $TD_dg_CollectedHostInfoThree.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 4)} { $TD_dg_CollectedHostInfoFour.ItemsSource = $TD_Collected_HostInfoResult  }
            {($_ -eq 5)} { $TD_dg_CollectedHostInfoFive.ItemsSource = $TD_Collected_HostInfoResult  }
            {($_ -eq 6)} { $TD_dg_CollectedHostInfoSix.ItemsSource = $TD_Collected_HostInfoResult   }
            {($_ -eq 7)} { $TD_dg_CollectedHostInfoSeven.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 8)} { $TD_dg_CollectedHostInfoEight.ItemsSource = $TD_Collected_HostInfoResult }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_Collected_HostInfoResult | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_Collected_HostInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_HostVolInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_IBM_HostInfo.Visibility="Visible" 

})

$TD_btn_IBM_IPPortInfo.add_click({

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_IPPortInfoOne,$TD_dg_IPPortInfoTwo,$TD_dg_IPPortInfoThree,$TD_dg_IPPortInfoFour,$TD_dg_IPPortInfoFive,$TD_dg_IPPortInfoSix,$TD_dg_IPPortInfoSeven,$TD_dg_IPPortInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    
    $TD_Credentials | ForEach-Object {
        [array]$TD_IPPortInfo = IBM_IPPortInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_IPPortInfoOne.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 2)} { $TD_dg_IPPortInfoTwo.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 3)} { $TD_dg_IPPortInfoThree.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 4)} { $TD_dg_IPPortInfoFour.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 5)} { $TD_dg_IPPortInfoFive.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 6)} { $TD_dg_IPPortInfoSix.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 7)} { $TD_dg_IPPortInfoSeven.ItemsSource = $TD_IPPortInfo }
            {($_ -eq 8)} { $TD_dg_IPPortInfoEight.ItemsSource = $TD_IPPortInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_IPPortInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IPPortInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_IBM_IPPortInfo.Visibility="Visible"
    
})
#endregion

#region SAN Button
$TD_btn_FOS_BasicSwitchInfo.add_click({

    $TD_LB_sanBasicSwitchInfoOne,$TD_LB_sanBasicSwitchInfoTwo,$TD_LB_sanBasicSwitchInfoThree,$TD_LB_sanBasicSwitchInfoFour,$TD_LB_sanBasicSwitchInfoFive,$TD_LB_sanBasicSwitchInfoSix,$TD_LB_sanBasicSwitchInfoSeven,$TD_LB_sanBasicSwitchInfoEight |ForEach-Object {
        $_.Visibility="Collapsed"
    }
    $TD_CB_SAN_DG1;$TD_LB_SAN_DG1;$TD_CB_SAN_DG2;$TD_LB_SAN_DG2;$TD_CB_SAN_DG3;$TD_LB_SAN_DG3;$TD_CB_SAN_DG4;$TD_LB_SAN_DG4;$TD_CB_SAN_DG5;$TD_LB_SAN_DG5;$TD_CB_SAN_DG6;$TD_LB_SAN_DG6;$TD_CB_SAN_DG7;$TD_LB_SAN_DG7;$TD_CB_SAN_DG8;$TD_LB_SAN_DG8 |ForEach-Object {
        $_.Visibility="Collapsed"
    }
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_dg_sanBasicSwitchInfoOne,$TD_dg_sanBasicSwitchInfoTwo,$TD_dg_sanBasicSwitchInfoThree,$TD_dg_sanBasicSwitchInfoFour,$TD_dg_sanBasicSwitchInfoFive,$TD_dg_sanBasicSwitchInfoSix,$TD_dg_sanBasicSwitchInfoSeven,$TD_dg_sanBasicSwitchInfoEight |ForEach-Object {
        if($_.items.count -gt 0){ $_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        $FOS_BasicSwitch = $null
        $FOS_BasicSwitch = FOS_BasicSwitchInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_sanBasicSwitchInfoOne.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 2)} { $TD_dg_sanBasicSwitchInfoTwo.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 3)} { $TD_dg_sanBasicSwitchInfoThree.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 4)} { $TD_dg_sanBasicSwitchInfoFour.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 5)} { $TD_dg_sanBasicSwitchInfoFive.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 6)} { $TD_dg_sanBasicSwitchInfoSix.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 7)} { $TD_dg_sanBasicSwitchInfoSeven.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 8)} { $TD_dg_sanBasicSwitchInfoEight.ItemsSource = $FOS_BasicSwitch }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $FOS_BasicSwitch | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_BasicSwitchInfos_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanSwitchShow,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanBasicSwitchInfo.Visibility="Visible"

})

$TD_btn_FOS_SwitchShow.add_click({

    $TD_LB_SwitchShowOne,$TD_LB_SwitchShowTwo,$TD_LB_SwitchShowThree,$TD_LB_SwitchShowFour,$TD_LB_SwitchShowFive,$TD_LB_SwitchShowSix,$TD_LB_SwitchShowSeven,$TD_LB_SwitchShowEight |ForEach-Object {
        $_.Visibility="Collapsed"
    }

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_DG_SwitchShowOne,$TD_DG_SwitchShowTwo,$TD_DG_SwitchShowThree,$TD_DG_SwitchShowFour,$TD_DG_SwitchShowFive,$TD_DG_SwitchShowSix,$TD_DG_SwitchShowSeven,$TD_DG_SwitchShowEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$FOS_SwitchShow = FOS_SwitchShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_DG_SwitchShowOne.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 2)} { $TD_DG_SwitchShowTwo.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 3)} { $TD_DG_SwitchShowThree.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 4)} { $TD_DG_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 5)} { $TD_DG_SwitchShowFive.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 6)} { $TD_DG_SwitchShowSix.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 7)} { $TD_DG_SwitchShowSeven.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 8)} { $TD_DG_SwitchShowEight.ItemsSource = $FOS_SwitchShow }
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
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {(($_.DeviceTyp -eq "SAN")-and($_.ID -eq $TD_SANFilter_DG_Colum))}
    try {
        [array]$TD_CollectVolInfo = Import-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($TD_SANFilter_DG_Colum)_$($TD_Credentials.DeviceName)_FOS_SwitchShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv -ErrorAction Stop
        switch ($TD_SANFilter_DG_Colum) {
            1 { $FOS_SwitchShow = $TD_DG_SwitchShowOne.ItemsSource }
            2 { $FOS_SwitchShow = $TD_DG_SwitchShowTwo.ItemsSource }
            3 { $FOS_SwitchShow = $TD_DG_SwitchShowThree.ItemsSource }
            4 { $FOS_SwitchShow = $TD_DG_SwitchShowFour.ItemsSource }
            5 { $FOS_SwitchShow = $TD_DG_SwitchShowFive.ItemsSource }
            6 { $FOS_SwitchShow = $TD_DG_SwitchShowSix.ItemsSource }
            7 { $FOS_SwitchShow = $TD_DG_SwitchShowSeven.ItemsSource }
            8 { $FOS_SwitchShow = $TD_DG_SwitchShowEight.ItemsSource }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at Switchshow" -TD_ToolMSGType Error -TD_Shown yes}
        }
        if($FOS_SwitchShow.Count -ne $TD_CollectVolInfo.Count){
            $FOS_SwitchShow = $TD_CollectVolInfo }

            switch ($ColumFilter) {
                "Port" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Port -Match $filter } }
                "Address" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Port -Match $filter } }
                "Speed" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Speed -Match $filter } }
                "State" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.State -Match $filter } }
                "PortConnect" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.PortConnect -Match $filter } }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at Switchshow" -TD_ToolMSGType Error -TD_Shown yes}
            }

            switch ($TD_SANFilter_DG_Colum) {
                1 { $TD_DG_SwitchShowOne.ItemsSource = $WPF_dataGrid }
                2 { $TD_DG_SwitchShowTwo.ItemsSource = $WPF_dataGrid }
                3 { $TD_DG_SwitchShowThree.ItemsSource = $WPF_dataGrid }
                4 { $TD_DG_SwitchShowFour.ItemsSource = $WPF_dataGrid }
                5 { $TD_DG_SwitchShowFive.ItemsSource = $WPF_dataGrid }
                6 { $TD_DG_SwitchShowSix.ItemsSource = $WPF_dataGrid }
                7 { $TD_DG_SwitchShowSeven.ItemsSource = $WPF_dataGrid }
                8 { $TD_DG_SwitchShowEight.ItemsSource = $WPF_dataGrid }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at Switchshow" -TD_ToolMSGType Error -TD_Shown yes}
            }
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $TD_lb_ErrorMsgSANSwShow.Content = $_.Exception.Message
    }
})

$TD_btn_ClearFilterSANSwShow.Add_Click({

    [int]$TD_SANFilter_DG = $TD_cb_ListFilterSANSwShow.Text
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {(($_.DeviceTyp -eq "SAN")-and($_.ID -eq $TD_SANFilter_DG))}
    
    $TD_tb_FilterWordSANSwShow.Text = ""
    try {
        [array]$TD_CollectVolInfo = Import-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($TD_SANFilter_DG)_$($TD_Credentials.DeviceName)_FOS_SwitchShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv -ErrorAction Stop
        switch ($TD_SANFilter_DG) {
            1 { $TD_DG_SwitchShowOne.ItemsSource = $TD_CollectVolInfo }
            2 { $TD_DG_SwitchShowTwo.ItemsSource = $TD_CollectVolInfo }
            3 { $TD_DG_SwitchShowThree.ItemsSource = $TD_CollectVolInfo }
            4 { $TD_DG_SwitchShowFour.ItemsSource = $TD_CollectVolInfo }
            5 { $TD_DG_SwitchShowFive.ItemsSource = $TD_CollectVolInfo }
            6 { $TD_DG_SwitchShowSix.ItemsSource = $TD_CollectVolInfo }
            7 { $TD_DG_SwitchShowSeven.ItemsSource = $TD_CollectVolInfo }
            8 { $TD_DG_SwitchShowEight.ItemsSource = $TD_CollectVolInfo }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, ID $($TD_SANFilter_DG) or DeviceName $($TD_Credentials.DeviceName) can not be found") -TD_ToolMSGType Error}
        }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $lb_ErrorMsgSANSwShow.Visibility="visible"
        $lb_ErrorMsgSANSwShow.Content = $_.Exception.Message
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
                $TD_FOS_ZoneShow, $FOS_EffeZoneNameOne = FOS_ZoneDetails -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Credential.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
                Start-Sleep -Seconds 0.5
                $TD_dg_ZoneDetailsOne.ItemsSource =$TD_FOS_ZoneShow
                $TD_lb_FabricOne.Visibility = "Visible";
                $TD_lb_FabricOne.Content = $FOS_EffeZoneNameOne
                $TD_stp_FilterFabricOneVisibilty.Visibility = "Visible"
                $TD_FOS_ZoneShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($FOS_EffeZoneNameOne)_ZoneShow_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
            }
            {($_ -eq 2) } <# -or ($_ -eq 3) -or ($_ -eq 4)}  for later use maybe #>
            {            
                $TD_FOS_ZoneShow, $FOS_EffeZoneNameTwo = FOS_ZoneDetails -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Credential.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
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
                $TD_FOS_ZoneShow, $FOS_EffeZoneNameThree = FOS_ZoneDetails  -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Credential.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
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
        [array]$TD_CollectZoneInfo = Import-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($TD_lb_FabricOne.Content)_ZoneShow_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv -ErrorAction Stop
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
        [array]$TD_CollectZoneInfo = Import-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($TD_lb_FabricTwo.Content)_ZoneShow_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv -ErrorAction Stop
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

    $TD_LB_SANInfoOne,$TD_LB_SANInfoTwo,$TD_LB_SANInfoThree,$TD_LB_SANInfoFour,$TD_LB_SANInfoFive,$TD_LB_SANInfoSix,$TD_LB_SANInfoSeven,$TD_LB_SANInfoEight |ForEach-Object {
        $_.Visibility="Collapsed"
    }
    $TD_CB_SAN_DG1;$TD_LB_SAN_DG1;$TD_CB_SAN_DG2;$TD_LB_SAN_DG2;$TD_CB_SAN_DG3;$TD_LB_SAN_DG3;$TD_CB_SAN_DG4;$TD_LB_SAN_DG4;$TD_CB_SAN_DG5;$TD_LB_SAN_DG5;$TD_CB_SAN_DG6;$TD_LB_SAN_DG6;$TD_CB_SAN_DG7;$TD_LB_SAN_DG7;$TD_CB_SAN_DG8;$TD_LB_SAN_DG8 |ForEach-Object {
        $_.Visibility="Collapsed"
    }
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_TB_SANInfoOne,$TD_TB_SANInfoTwo,$TD_TB_SANInfoThree,$TD_TB_SANInfoFour,$TD_TB_SANInfoFive,$TD_TB_SANInfoSix,$TD_TB_SANInfoSeven,$TD_TB_SANInfoEight |ForEach-Object {
        if($_.Text -ne ""){$_.Text = ""; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_PortLicenseShow = FOS_PortLicenseShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} {$TD_TB_SANInfoOne.Visibility="Visible"; $TD_TB_SANInfoOne.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)}
            {($_ -eq 2)} {$TD_TB_SANInfoTwo.Visibility="Visible"; $TD_TB_SANInfoTwo.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)}
            {($_ -eq 3)} {$TD_TB_SANInfoThree.Visibility="Visible"; $TD_TB_SANInfoThree.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)}
            {($_ -eq 4)} {$TD_TB_SANInfoFour.Visibility="Visible"; $TD_TB_SANInfoFour.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)}
            {($_ -eq 5)} {$TD_TB_SANInfoFive.Visibility="Visible";  $TD_TB_SANInfoFive.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)}
            {($_ -eq 6)} {$TD_TB_SANInfoSix.Visibility="Visible";  $TD_TB_SANInfoSix.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)}
            {($_ -eq 7)} {$TD_TB_SANInfoSeven.Visibility="Visible";  $TD_TB_SANInfoSeven.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow) }
            {($_ -eq 8)} {$TD_TB_SANInfoEight.Visibility="Visible";  $TD_TB_SANInfoEight.Text = (Out-String -InputObject $TD_FOS_PortLicenseShow)}
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FOS_PortLicenseShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_PortLicenseShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanSwitchShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanLicenseShow.Visibility="Visible"

})

$TD_btn_FOS_SensorShow.add_click({

    $TD_LB_SensorInfoOne,$TD_LB_SensorInfoTwo,$TD_LB_SensorInfoThree,$TD_LB_SensorInfoFour,$TD_LB_SensorInfoFive,$TD_LB_SensorInfoSix,$TD_LB_SensorInfoSeven,$TD_LB_SensorInfoEight |ForEach-Object {
        $_.Visibility="Collapsed"
    }
    $TD_CB_SAN_DG1;$TD_LB_SAN_DG1;$TD_CB_SAN_DG2;$TD_LB_SAN_DG2;$TD_CB_SAN_DG3;$TD_LB_SAN_DG3;$TD_CB_SAN_DG4;$TD_LB_SAN_DG4;$TD_CB_SAN_DG5;$TD_LB_SAN_DG5;$TD_CB_SAN_DG6;$TD_LB_SAN_DG6;$TD_CB_SAN_DG7;$TD_LB_SAN_DG7;$TD_CB_SAN_DG8;$TD_LB_SAN_DG8 |ForEach-Object {
        $_.Visibility="Collapsed"
    }
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_tb_SensorInfoOne,$TD_tb_SensorInfoTwo,$TD_tb_SensorInfoThree,$TD_tb_SensorInfoFour,$TD_tb_SensorInfoFive,$TD_tb_SensorInfoSix,$TD_tb_SensorInfoSeven,$TD_tb_SensorInfoEight |ForEach-Object {
        if($_.Text -ne ""){$_.Text = ""; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_SensorShow = FOS_SensorShow -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_tb_SensorInfoOne.Visibility="Visible"; $TD_tb_SensorInfoOne.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
            {($_ -eq 2)} { $TD_tb_SensorInfoTwo.Visibility="Visible"; $TD_tb_SensorInfoTwo.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
            {($_ -eq 3)} { $TD_tb_SensorInfoThree.Visibility="Visible"; $TD_tb_SensorInfoThree.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
            {($_ -eq 4)} { $TD_tb_SensorInfoFour.Visibility="Visible"; $TD_tb_SensorInfoFour.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
            {($_ -eq 5)} { $TD_tb_SensorInfoFive.Visibility="Visible"; $TD_tb_SensorInfoFive.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
            {($_ -eq 6)} { $TD_tb_SensorInfoSix.Visibility="Visible"; $TD_tb_SensorInfoSix.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
            {($_ -eq 7)} { $TD_tb_SensorInfoSeven.Visibility="Visible"; $TD_tb_SensorInfoSeven.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
            {($_ -eq 8)} { $TD_tb_SensorInfoEight.Visibility="Visible"; $TD_tb_SensorInfoEight.Text = (Out-String -InputObject $TD_FOS_SensorShow) }
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

    $TD_LB_PortErrorShowOne,$TD_LB_PortErrorShowTwo,$TD_LB_PortErrorShowThree,$TD_LB_PortErrorShowFour,$TD_LB_PortErrorShowFive,$TD_LB_PortErrorShowSix,$TD_LB_PortErrorShowSeven,$TD_LB_PortErrorShowEight |ForEach-Object {
        $_.Visibility="Collapsed"
    }

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_DG_PortErrorShowOne,$TD_DG_PortErrorShowTwo,$TD_DG_PortErrorShowThree,$TD_DG_PortErrorShowFour,$TD_DG_PortErrorShowFive,$TD_DG_PortErrorShowSix,$TD_DG_PortErrorShowSeven,$TD_DG_PortErrorShowEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    
    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_PortErrShow = FOS_PortErrShowInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_DG_PortErrorShowOne.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 2)} { $TD_DG_PortErrorShowTwo.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 3)} { $TD_DG_PortErrorShowThree.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 4)} { $TD_DG_PortErrorShowFour.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 5)} { $TD_DG_PortErrorShowFive.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 6)} { $TD_DG_PortErrorShowSix.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 7)} { $TD_DG_PortErrorShowSeven.ItemsSource = $TD_FOS_PortErrShow }
            {($_ -eq 8)} { $TD_DG_PortErrorShowEight.ItemsSource = $TD_FOS_PortErrShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
        $TD_FOS_PortErrShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_PortErrShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortBufferShow,$TD_stp_sanSwitchShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanPortErrorShow.Visibility="Visible"

})

$TD_btn_FOS_SFPHealthShow.add_click({

    $TD_LB_SFPShowOne,$TD_LB_SFPShowTwo,$TD_LB_SFPShowThree,$TD_LB_SFPShowFour,$TD_LB_SFPShowFive,$TD_LB_SFPShowSix,$TD_LB_SFPShowSeven,$TD_LB_SFPShowEight |ForEach-Object {
        $_.Visibility="Collapsed"
    }

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_dg_SFPShowOne,$TD_dg_SFPShowTwo,$TD_dg_SFPShowThree,$TD_dg_SFPShowFour,$TD_dg_SFPShowFive,$TD_dg_SFPShowSix,$TD_dg_SFPShowSeven,$TD_dg_SFPShowEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    
    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_SFPDetailsShow = FOS_SFPDetails -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_SFPShowOne.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 2)} { $TD_dg_SFPShowTwo.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 3)} { $TD_dg_SFPShowThree.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 4)} { $TD_dg_SFPShowFour.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 5)} { $TD_dg_SFPShowFive.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 6)} { $TD_dg_SFPShowSix.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 7)} { $TD_dg_SFPShowSeven.ItemsSource = $TD_FOS_SFPDetailsShow }
            {($_ -eq 8)} { $TD_dg_SFPShowEight.ItemsSource = $TD_FOS_SFPDetailsShow }
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
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowOne.ItemsSource = $EmptyVar
                    $TD_lb_OneClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowOne.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 2)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowTwo.ItemsSource = $EmptyVar
                    $TD_lb_TwoClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowTwo.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 3)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowThree.ItemsSource = $EmptyVar
                    $TD_lb_ThreeClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowThree.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 4)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowFour.ItemsSource = $EmptyVar
                    $TD_lb_FourClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowFour.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 5)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowFive.ItemsSource = $EmptyVar
                    $TD_lb_FiveClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowFive.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 6)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowSix.ItemsSource = $EmptyVar
                    $TD_lb_SixClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowSix.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 7)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowSeven.ItemsSource = $EmptyVar
                    $TD_lb_SevenClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowSeven.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            {($_ -eq 8)} 
            {            
                $SANUserName = $TD_Credential.UserName; $Device_IP = $TD_Credential.IPAddress
                if($TD_Credential.ConnectionTyp -eq "ssh"){
                    try {
                        $TD_FOS_StatsClear = ssh -i $($TD_Credential.SSHKeyPath) $SANUserName@$Device_IP "statsClear" 2>&1
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
                    $TD_DG_PortErrorShowEight.ItemsSource = $EmptyVar
                    $TD_lb_EightClear.Visibility = "Visible"
                    <# next line is a test, because performance#>
                    $TD_UserControl2.Dispatcher.Invoke([System.Action]{},"Render")
                    $TD_FOS_PortErrShow += FOS_PortErrShowInfos -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $TD_Selected_DeviceSSHFile -TD_Exportpath $TD_tb_ExportPath.Text
                    Start-Sleep -Seconds 0.5
                    $TD_DG_PortErrorShowEight.ItemsSource =$TD_FOS_PortErrShow
                    $TD_FOS_StatsClearDone = $false
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error}
        }
    }
})

$TD_btn_FOS_PortBufferShow.add_click({

    $TD_LB_PortBufferShowOne,$TD_LB_PortBufferShowTwo,$TD_LB_PortBufferShowThree,$TD_LB_PortBufferShowFour,$TD_LB_PortBufferShowFive,$TD_LB_PortBufferShowSix,$TD_LB_PortBufferShowSeven,$TD_LB_PortBufferShowEight |ForEach-Object {
        $_.Visibility="Collapsed"
    }

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}

    $TD_lb_PortBufferShowOne,$TD_lb_PortBufferShowTwo,$TD_lb_PortBufferShowThree,$TD_lb_PortBufferShowFour,$TD_lb_PortBufferShowFive,$TD_lb_PortBufferShowSix,$TD_lb_PortBufferShowSeven,$TD_lb_PortBufferShowEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FOS_PortbufferShow = FOS_PortbufferShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_DG_PortBufferShowOne.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 2)} { $TD_DG_PortBufferShowTwo.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 3)} { $TD_DG_PortBufferShowThree.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 4)} { $TD_DG_PortBufferShowFour.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 5)} { $TD_DG_PortBufferShowFive.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 6)} { $TD_DG_PortBufferShowSix.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 7)} { $TD_DG_PortBufferShowSeven.ItemsSource = $TD_FOS_PortbufferShow }
            {($_ -eq 8)} { $TD_DG_PortBufferShowEight.ItemsSource = $TD_FOS_PortbufferShow }
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
    <# need to be checked #>
    foreach($TD_Credential in $TD_Credentials){
        <# QaD needs a Codeupdate because Grouping dose not work #>
        $TD_SystemCheck = $TD_cb_Device_HealthCheck.Text
        switch ($TD_Credential.ID) {
            {(($_ -eq 1) -and ($TD_SystemCheck-eq "Check the First"))} 
            {   $TD_TB_storageIPAdrOne.Text ="$($TD_Credential.IPAddress)"
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
            }
            {(($_ -eq 2) -and ($TD_SystemCheck-eq "Check the Second"))} 
            {   $TD_TB_storageIPAdrTwo.Text ="$($TD_Credential.IPAddress)"
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
            }
            {(($_ -eq 3) -and ($TD_SystemCheck-eq "Check the Third"))}  
            {   $TD_TB_storageIPAdrThree.Text ="$($TD_Credential.IPAddress)"
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
            }
            {(($_ -eq 4) -and ($TD_SystemCheck-eq "Check the Fourth"))}  
            {   $TD_TB_storageIPAdrFour.Text ="$($TD_Credential.IPAddress)"
                IBM_StorageHealthCheck -TD_Line_ID $TD_Credential.ID -TD_Device_ConnectionTyp $TD_Credential.ConnectionTyp -TD_Device_UserName $TD_Credential.UserName -TD_Device_DeviceName $TD_Credential.DeviceName -TD_Device_DeviceIP $TD_Credential.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Credential.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error}
        }
    }
})
$TD_btn_HC_OpenGUI_One.add_click({

    Start-Process "https://$($TD_TB_storageIPAdrOne.Text)"
})
$TD_btn_HC_OpenGUI_Two.add_click({
    Start-Process "https://$($TD_TB_storageIPAdrTwo.Text)"
})
$TD_btn_HC_OpenGUI_Three.add_click({
    Start-Process "https://$($TD_TB_storageIPAdrThree.Text)"
})
$TD_btn_HC_OpenGUI_Four.add_click({
    Start-Process "https://$($TD_TB_storageIPAdrFour.Text)"
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
    $MainWindow.Close()
})

Get-Variable TD_*

$MainWindow.showDialog()
$MainWindow.activate()

}