<# wichtig um die dll auch zu finden #>
$PSRootPath = Split-Path -Path $PSScriptRoot -Parent
<# Abfrage der PWSH Version da es nur mit pwsh ab der Version 7 und höher funktioniert #>
if($PSVersionTable.PSVersion.Major -ge 7){
    Add-Type -Path "$PSRootPath\Resources\DBFolder\System.Data.SQLite.dll"
    #Add-Type -Path ".\OxyPlot.dll"
    #Add-Type -Path ".\OxyPlot.Wpf.dll"
}
if($PSVersionTable.PSVersion.Major -eq 5){
    Add-Type -Path "$PSRootPath\Resources\DBFolder\PWSH5\System.Data.SQLite.dll"
}
Add-Type -AssemblyName PresentationFramework, PresentationCore, System.Windows.Forms, WindowsBase

<# Ab hier start des eigentlichen "programms" #>
<# Create the xaml Files / Base of GUI Mainwindow #>
function Storage_SAN_Tool {
[CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("DEFAULT","SAN","CONFIG","HEALTH","STORAGE","POWER","JobMode")]
        $CockpitView = $null
    )
#$ErrorActionPreference="SilentlyContinue"
SST_ToolMessageCollector -TD_ToolMSGCollector "Start reading Storage_SAN_Tool func" -TD_ToolMSGType Message -TD_Shown no
$inputXAML=Get-Content -Raw -Path "$PSScriptRoot\MainWindow.xaml"
[xml]$MainXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
[System.Xml.XmlNodeReader] $Mainreader = $MainXAML
$MainWindow =[Windows.Markup.XamlReader]::Load($Mainreader)

$MainXAML.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $MainWindow.FindName($_.Name)}
<# add ResourceDictionary for WPF to App #>
$AppStyles = [Windows.Markup.XamlReader]::Parse((Get-Content -Path "$PSRootPath\Resources\Styles\AppStyle.xaml" -Raw))
$MainWindow.Resources.MergedDictionaries.Add( $AppStyles )
$TextBoxStyle = [Windows.Markup.XamlReader]::Parse((Get-Content -Path "$PSRootPath\Resources\Styles\TextBoxStyle.xaml" -Raw))
$MainWindow.Resources.MergedDictionaries.Add( $TextBoxStyle )
$ButtonStyles = [Windows.Markup.XamlReader]::Parse((Get-Content -Path "$PSRootPath\Resources\Styles\ButtonStyle.xaml" -Raw))
$MainWindow.Resources.MergedDictionaries.Add( $ButtonStyles )
SST_ToolMessageCollector -TD_ToolMSGCollector "Load MainWindo Resources done" -TD_ToolMSGType Message -TD_Shown no

<# PowerShell WPF XAML simple data binding datacontext #>
class DashBoardIMG {
    [string]$IBMFS73Icon
    [string]$SAN64B7Icon
    [string]$IBMPower11Icon
    [string]$RefrehIcon96
}
$DashBoardIcons =[DashBoardIMG]::new()
$DashBoardIcons.IBMFS73Icon = "$PSRootPath\Resources\Icons\IBMFS73Icon.png"
$DashBoardIcons.SAN64B7Icon = "$PSRootPath\Resources\Icons\SAN64B7Icon.png"
$DashBoardIcons.IBMPower11Icon = "$PSRootPath\Resources\Icons\IBMPower11Icon.png"
$DashBoardIcons.RefrehIcon96 = "$PSRootPath\Resources\Icons\iconrefresh96.png"


<# Create UserControls as basis of Content for MainWindow #>
$UserCxamlFile = Get-ChildItem "$PSScriptRoot\UserControl*.xaml"
foreach($file in $UserCxamlFile){
    $fileName = ($file.Name).trim(".xaml")
    Set-Variable -Name "TD_$($fileName)"
<<<<<<< Updated upstream
    <# if you want more UserControls then add them here #>
    switch -wildcard ($fileName) {
        "*l1" { 
            $UserC1=Get-Content -Path $file -raw
            $UserC1=$UserC1 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML1=$UserC1
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML1
            $TD_UserControl1=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML1.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl1.FindName($_.Name) }
            $TD_UserControl1.DataContext = $DashBoardIcons
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
        "*l4" { 
            $UserC4=Get-Content -Path $file -raw
            $UserC4=$UserC4 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML4=$UserC4
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML4
            $TD_UserControl4=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML4.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl4.FindName($_.Name) }
            $TD_UserControl4.DataContext = $DashBoardIcons
         }
         "*l5" { 
            $UserC5=Get-Content -Path $file -raw
            $UserC5=$UserC5 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML5=$UserC5
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML5
            $TD_UserControl5=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML5.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl5.FindName($_.Name) }
         }
         "*l6" { 
            $UserC6=Get-Content -Path $file -raw
            $UserC6=$UserC6 -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
            [xml]$UserXAML6=$UserC6
            $Userreader = New-Object System.Xml.XmlNodeReader $UserXAML6
            $TD_UserControl6=[Windows.Markup.XamlReader]::Load($Userreader)
            $UserXAML6.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl6.FindName($_.Name) }
         }
        Default { SST_ToolMessageCollector -TD_ToolMSGCollector "Create UserControl $fileName had a problem" -TD_ToolMSGType Error -TD_Shown no
            Write-Host "Something did not work, start the application in debug mod and/or check the log file." -ForegroundColor Red; Start-Sleep -Seconds 5; exit 
        }
=======

    $UserC=Get-Content -Path $file -Raw
    $UserC=$UserC -replace 'mc:Ignorable="d"','' -replace "x:N","N"
    [xml]$UserXAML=$UserC
    $UserReader = New-Object System.Xml.XmlNodeReader $UserXAML
    $TD_UserControl = [Windows.Markup.XamlReader]::Load($UserReader)

    # --------------------------
    # Inject Styles into UserControl
    # --------------------------
    foreach ($style in $global:LoadedStyles) {
        $TD_UserControl.Resources.MergedDictionaries.Add($style)
    }

    # --------------------------
    # Set variables for named elements
    # --------------------------
    $UserXAML.SelectNodes("//*[@Name]") | ForEach-Object {
        Set-Variable -Name "TD_$($_.Name)" -Value $TD_UserControl.FindName($_.Name)
    }

    # --------------------------
    # Set DataContext if needed
    # --------------------------
    if ($fileName -like "*Dash" -or $fileName -like "*Health" -or $fileName -like "*SetUp"-or $fileName -like "*PWR") {
        $TD_UserControl.DataContext = $ViewModel
    }
    if ($fileName -like "*STO") {
        $TD_UserControl.DataContext = $ViewModel
    }
    $TD_AllUserControls += $TD_UserControl
    # --------------------------
    # Assign to global variable for later use
    # --------------------------
    Set-Variable -Name "TD_$fileName" -Value $TD_UserControl 
}

if ($null -eq $TD_BTN_IBM_OpenSFPHistory) {
    Write-Host 'BTN_IBM_OpenSFPHistory wurde im IBM-Storage-UserControl nicht gefunden.' `
        -ForegroundColor Red
}

foreach ($uc in $TD_AllUserControls) {
    $searchBox = $uc.FindName("TB_GlobalGridSearch")
    if ($null -ne $searchBox) {
        Initialize-GlobalDataGridSearch -RootControl $uc -SearchBox $searchBox
>>>>>>> Stashed changes
    }
}

#region BasicToolPreparation
    try {
        $TD_ExporttoOD = [Environment]::GetFolderPath("mydocuments")
        $ExportFolderPath="$TD_ExporttoOD\StorageSANTool"
        If(!(Test-Path -Path $ExportFolderPath)){
            try {
                $TD_ExportFolderCreated = New-Item $ExportFolderPath -ItemType Directory -ErrorAction Stop
                $TD_tb_ExportPath.Text = $TD_ExportFolderCreated.Name
            }
            catch {
                SST_ToolMessageCollector -TD_ToolMSGCollector "BasicToolPreparation ExportFolderPath $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown no
            }

        }else{
            $TD_tb_ExportPath.Text = $ExportFolderPath
            #PowerShell Create directory if not exists
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector "BasicToolPreparation ExportFolderPath $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown no
        Write-Error -Message $_.Exception.Message
        #$TD_tb_Exportpath.Text = $_.Exception.Message
    }
    <# MainWindow Background IMG #>
    $TD_LogoImage.Source = "$PSRootPath\Resources\Icons\PROFI_Logo_2022_dark.png"
    $TD_LogoImageSmall.Source = "$PSRootPath\Resources\Icons\PROFI_Logo_2022_dark.png"
    $TD_LogoImageSmall.Visibility = "hidden"
    # Since the switch to SQLite, the DB can also be used with PowerShell V5.
    if($PSVersionTable.PSVersion.Major -ge 7){
        $TD_LB_DBSettings.Content ="Your PSWH Version is $($PSVersionTable.PSVersion), you can use the local DB."
    }else {
        $TD_LB_DBSettings.Content ="Your PSWH Version is $($PSVersionTable.PSVersion), you can use the local DB! `nBut it has currently only been tested with the PWSH Version 7.x and above."
        $TD_LB_DBSettings.Height="50"
        #$TD_BTN_DeleteDB,$TD_BTN_ActivateDB | ForEach-Object {$_.Visibility = "Collapsed"}
    }
    function CheckBoxReseter {
        param ()
        $TD_CB_STO_DG1,$TD_CB_STO_DG2,$TD_CB_STO_DG3,$TD_CB_STO_DG4,$TD_CB_STO_DG5,$TD_CB_STO_DG6,$TD_CB_STO_DG7,$TD_CB_STO_DG8 | ForEach-Object {if($_.IsChecked=$true){$_.IsChecked=$false; $_.Visibility="Collapsed";}}
    }
    SST_ToolMessageCollector -TD_ToolMSGCollector "BasicToolPreparation done" -TD_ToolMSGType Message -TD_Shown no
#endregion

#region Menu Button
SST_ToolMessageCollector -TD_ToolMSGCollector "Load Menu Button" -TD_ToolMSGType Message -TD_Shown no
<# Button Area Menu #>
$TD_btn_Dashboard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl1.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl1)}
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_btn_IBM_SV.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl2.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl2)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_btn_Broc_SAN.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl3.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl3)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_PowerBoard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl6.IsLoaded)){
        $TD_UserContrArea.Children.Add($TD_UserControl6) 
        IBM_PowerMainFunc -PSRootPath $PSRootPath -SST_UCOBJ $TD_UserControl6
        $SST_BTN_PowerBoardTooltip = $TD_UserControl6.FindName("BTN_HMCCollectorTooltip")
        if($PSVersionTable.PSVersion.Major -ge 7){
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "PowerHMC"}
            if($TD_Credentials.count -ge 1){
                $TD_BTN_HMCCollector.Background = "LightGreen"
                $TD_BTN_HMCCollector.Content = "HMCScan RDY"
                $SST_BTN_PowerBoardTooltip.Text = "HMC Credentials are loaded!"
            }else{
                $TD_BTN_HMCCollector.Background = "Coral"
                $SST_BTN_PowerBoardTooltip.Text = "No HMC Credentials are loaded!"
            }
        }else {
            <# Action when all if and elseif conditions are false #>
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_}
            if($TD_Credentials.count -ge 1){
                $TD_BTN_HMCCollector.Background = "LightGreen"
                $TD_BTN_HMCCollector.Content = "HMCScan RDY"
                $SST_BTN_PowerBoardTooltip.Text = "Credentials are loaded, please check that HMC login details are included.!"
            }
        }
    }
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_btn_Stor_San.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl4.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl4); SST_MainHealthCheckFunc -SST_UCOBJ $TD_UserControl4 -SST_UCSTYLEOBJ $ButtonStyles }
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_btn_Settings.add_click({
    if(!($TD_UserControl5.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl5)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})

<# Button Export Settings #>
$TD_btn_ChangeExportPath.add_click({
    $TD_ChPathdialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($TD_ChPathdialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $TD_DirectoryName = $TD_ChPathdialog.SelectedPath
        $TD_tb_ExportPath.Text = $TD_DirectoryName
    }
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
})
<# Refresh Button #>
$TD_BTN_RefreshUC1.add_click({

    <#wenn refresh sollte der Counter auf 0 gestellt werden #>
    $TD_TB_ALLHostCount,$TD_TB_OfflHostCount,$TD_TB_OnlinelHostCount | ForEach-Object {$_.Text="0"}
    $TD_TB_NKNResOne,$TD_TB_NKNResTwo,$TD_TB_NKNResThree | ForEach-Object {$_.Text=$null}
    $TD_TB_SANFOSOne,$TD_TB_SANFOSTwo,$TD_TB_SANFOSThree,$TD_TB_SANFOSFour | ForEach-Object {$_.Text=$null}
    $TD_TB_STOHostStatusChangedOne,$TD_TB_STOHostStatusChangedTwo,$TD_TB_STOHostStatusChangedThree,$TD_TB_STOHostStatusChangedFour,$TD_TB_STOHostStatusChangedFive | ForEach-Object {$_.Text=""}

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
    $TD_Credentials | ForEach-Object {
        [array]$TD_BaseStorageInfo = IBM_BaseStorageInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        try {
            SST_LiteDBControl -SST_InfoType "StorageBase" -SST_CollectedInformations $TD_BaseStorageInfo
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
        }
        [array]$TD_Collected_HostInfoResult = IBM_HostInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text -TD_Storage $_.SVCorVF
        $TD_Collected_HostInfoResult = $TD_Collected_HostInfoResult | Where-Object { -not [string]::IsNullOrWhiteSpace($_.HostName) }
        try {
            SST_LiteDBControl -SST_InfoType "StorageHostInfo" -SST_CollectedInformations $TD_Collected_HostInfoResult
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
        }
    }

    $TD_Credentials =$null
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "SAN"}
    $TD_Credentials | ForEach-Object {
        $FOS_BasicSwitch = $null
        $FOS_BasicSwitch = FOS_BasicSwitchInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
        try {
            SST_LiteDBControl -SST_InfoType "SANBase" -SST_CollectedInformations $FOS_BasicSwitch
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
        }
    }

    SST_DashBoardMain -MainPath $PSRootPath -SST_UCOBJ $TD_UserControl1
})
#endregion

#region Settings Button
SST_ToolMessageCollector -TD_ToolMSGCollector "Load Settings Button" -TD_ToolMSGType Message -TD_Shown no
$TD_BTN_SaveToolSettings.add_click({
    SST_SaveLoadToolSettings -SST_SaveSettings $true 
})
$TD_BTN_LoadToolSettings.add_click({
    SST_SaveLoadToolSettings -SST_LoadSettings $true
})
#endregion

#region PRISM
SST_ToolMessageCollector -TD_ToolMSGCollector "Load PRISM" -TD_ToolMSGType Message -TD_Shown no
$TD_BTN_SaveConnectionStringPRISM.add_click({
    $TD_BTN_SaveConnectionStringPRISM.Background="#FFDDDDDD"
    SST_SaveLoadToolSettings -SST_SaveSettings $true
    $SST_LoadedToolSettings = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" 
    $ConnectionStringPRISM = [System.Net.NetworkCredential]::new("", $SST_LoadedToolSettings.ConnectionStringPRISM).Password
    IF(!([string]::IsNullOrEmpty($ConnectionStringPRISM))){
        $TD_TB_ConnectionStringPRISM.Visibility="Collapsed"
        $TD_BTN_SaveConnectionStringPRISM.Content = "Test Connection"
    }
    if(($TD_TB_ConnectionStringPRISM.Visibility -eq "Collapsed")-and ($TD_BTN_SaveConnectionStringPRISM.Content -like "Test Connection")){
        try {
            $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
            $SQLConnection.ConnectionString=$TD_TB_ConnectionStringPRISM.Password
            $SQLConnection.Open()
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
            $TD_LB_ConnectionStringLabelPRISM.Content = "$($_.Exception.Message)"
            $TD_BTN_SaveConnectionStringPRISM.Background = "Coral"
            $TD_BTN_ChangeConnectionStringPRISM.Visibility = "Visible"
        }
        if(($SQLConnection.State -eq 'Open') -and ($TD_BTN_ConnetionToPRISM.Content -notlike "Test Connection")){
            $TD_BTN_SaveConnectionStringPRISM.Content = "Connection String valid"
            $TD_BTN_SaveConnectionStringPRISM.Background = "lightgreen"
            $SQLConnection.Close()
            $TD_BTN_ChangeConnectionStringPRISM.Visibility = "Visible"
            $TD_LB_ConnectionStringLabelPRISM.Content ="Connection valid"
        }
    }
})
$TD_BTN_ConnetionToPRISM.add_click({
    $TD_BTN_ConnetionToPRISM.Background="#FFDDDDDD"
    try {
        $SST_LoadedToolSettings = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -ErrorAction SilentlyContinue
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }
     
    $ConnectionStringPRISM = [System.Net.NetworkCredential]::new("", $SST_LoadedToolSettings.ConnectionStringPRISM).Password
    try {
        $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
        $SQLConnection.ConnectionString=$ConnectionStringPRISM 
        $SQLConnection.Open()
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM Status $($SQLConnection.Open()) Info: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        $TD_LB_TestConnectionPRISM.Foreground = "Coral"
        $TD_BTN_ConnetionToPRISM.Background ="Coral"
    }
    if(($SQLConnection.State -eq 'Open') -and ($TD_BTN_ConnetionToPRISM.Content -like "Close Connection")){
        $SQLConnection.Close()
        $TD_BTN_ConnetionToPRISM.Background ="#FFDDDDDD"
        $TD_LB_TestConnectionPRISM.Foreground = "coral"
        $TD_LB_TestConnectionPRISM.Content = "Connect to PROFI PRISM."
        $TD_BTN_ConnetionToPRISM.Content ="Connetion to PRISM"
        $SST_LoadedToolSettings.ConnectionStringPRISM = $null
        $ConnectionStringPRISM = $null
    }
    if(($SQLConnection.State -eq 'Open') -and ($TD_BTN_ConnetionToPRISM.Content -like "Connetion to PRISM")){
        $TD_BTN_ConnetionToPRISM.Background ="LightGreen"
        $TD_LB_TestConnectionPRISM.Foreground = "DarkGreen"
        $TD_LB_TestConnectionPRISM.Content = "$($SQLConnection.State)"
        $TD_BTN_ConnetionToPRISM.Content ="Close Connection"
    }
})
$TD_BTN_ChangeConnectionStringPRISM.add_click({
    $TD_TB_ConnectionStringPRISM.Visibility = "Visible"
    $TD_TB_ConnectionStringPRISM.Password = $null
    $TD_BTN_SaveConnectionStringPRISM.Content = "Save Connection String"
    $TD_BTN_SaveConnectionStringPRISM.Background="#FFDDDDDD"
    $TD_BTN_ChangeConnectionStringPRISM.Visibility = "Collapsed"
})
$TD_BTN_SendDataToPRISM.add_click({
    SST_PRISMDBControl
    #Start-Process pwsh -ArgumentList '-NoExit -ExecutionPolicy Bypass -Command "& { . ''D:\GitRePo\Storage_SAN_Tool\TOOLFunc\SST_PRISMDBControl.ps1''; SST_PRISMDBControl}"'
})
SST_ToolMessageCollector -TD_ToolMSGCollector "Load PRISM done" -TD_ToolMSGType Message -TD_Shown no
#endregion

#region LocalDB
SST_ToolMessageCollector -TD_ToolMSGCollector "Load LocalDB" -TD_ToolMSGType Message -TD_Shown no
$TD_BTN_ActivateDB.add_click({
    try {
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
    }
    catch {
        Write-Host $_.exception.message
        SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
        $TD_BTN_DeleteDB.Visibility = "Visible"
        $TD_BTN_DeleteDB.Background = "Coral"
    }
    if(($SST_SQLiteCon.State -eq "Open")-and($SST_SQLiteCon.DataSource -eq "SSTLocalDB")){
        $TD_BTN_DeleteDB.Visibility = "Visible"
        $TD_BTN_ActivateDB.Visibility="Collapsed"
        $SST_SQLiteCon.Close()
    }
})
$TD_BTN_DeleteDB.add_click({
    try {
        $TD_DBtoDelete = Get-Item -Path "$PSRootPath\Resources\DBFolder\SSTLocalDB.db"
        if(!([string]::IsNullOrEmpty($TD_DBtoDelete.Name))){
            $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
            $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
            $SST_SQLiteCon.Close()
            $SST_SQLiteCon.Dispose()
            
        }
        SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB: This action deletes the $($TD_DBtoDelete.Name)" -TD_ToolMSGType Warning -TD_Shown yes
        Remove-Item -Path "$PSRootPath\Resources\DBFolder\SSTLocalDB.db" -Confirm:$false -Force -ErrorAction Continue 
        SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB: $($TD_DBtoDelete.Name) are deleted" -TD_ToolMSGType Message -TD_Shown yes
        $TD_BTN_ActivateDB.Visibility = "Visible"
        $TD_BTN_DeleteDB.Visibility="Collapsed"
    }
    catch {
        Write-Host $_.exception.message
        SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB: $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
        $TD_BTN_DeleteDB.Visibility = "Visible"
        $TD_BTN_DeleteDB.Background = "Coral"
    }
})
SST_ToolMessageCollector -TD_ToolMSGCollector "Load LocalDB" -TD_ToolMSGType Message -TD_Shown no
#endregion

<# The ssh settings are deactivated for the time being and a better implementation should be sought. #>
#region SSH Setings
<# ssh-agent Status check #>
#$TD_lb_SSHStatusMsg.Visibility ="Visible"
#$TD_lb_SSHStatusMsg.Content ="SSH-Agent Status is:`n$((Get-Service ssh-agent).Status)"
#if(((Get-Service ssh-agent).Status)-eq "Running"){
#    $TD_btn_Start_sshAgent.Content="Stop ssh-agent"
#    $TD_btn_Start_sshAgent.Background="coral"
#}else {
#    <# Action when all if and elseif conditions are false #>
#    $TD_btn_Start_sshAgent.Content="Start ssh-agent"
#    $TD_btn_Start_sshAgent.Background="#FFDDDDDD"
#}
<# Try to start/stop the ssh-agent #>

#$TD_btn_Start_sshAgent.add_click({
#    $TD_btn_Text=$TD_btn_Start_sshAgent.Content
#    switch ($TD_btn_Text) {
#        {($_ -like "Start*")} { 
#                                try {
#                                    $TD_btn_Start_sshAgent.Content="Stop ssh-agent"
#                                    $TD_btn_Start_sshAgent.Background="coral"
#                                    Start-Service ssh-agent -ErrorAction Stop
#                                }
#                                catch {
#                                    <#Do this if a terminating exception happens#>
#                                    $TD_btn_Start_sshAgent.Content="Start ssh-agent"
#                                    $TD_btn_Start_sshAgent.Background="#FFDDDDDD"
#                                    SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning
#                                }
#                                $TD_lb_SSHStatusMsg.Content ="SSH-Agent Status is:`n$((Get-Service ssh-agent).Status) "
#                            }
#        {($_ -like "Stop*")} {
#                                try {
#                                    $TD_btn_Start_sshAgent.Content="Start ssh-agent"
#                                    $TD_btn_Start_sshAgent.Background="#FFDDDDDD"
#                                    Stop-Service ssh-agent -ErrorAction Stop
#                                }
#                                catch {
#                                    <#Do this if a terminating exception happens#>
#                                    $TD_btn_Start_sshAgent.Content="Stop ssh-agent"
#                                    $TD_btn_Start_sshAgent.Background="coral"
#                                    SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning
#                                }
#                                $TD_lb_SSHStatusMsg.Content ="SSH-Agent Status is:`n$((Get-Service ssh-agent).Status) "
#                            }
#        Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong by get informations about the ssh-agent." -TD_ToolMSGType Error}
#    }
#    $TD_UserControl4.Dispatcher.Invoke([System.Action]{},"Render")
#})
#
#$TD_BTN_AddSSHKey.add_click({
#    #$TD_ButtonColorSSH=$TD_btn_addsshkeyone.Background
#    $IsKeyIn = $TD_TB_PathtoSSHKeyNotVisibil.Text
#    if([string]::IsNullOrWhiteSpace($IsKeyIn)){
#        RemoveSSHKeyfromLine -TD_Storage "yes"
#    }else {
#        AddSSHKeytoLine -TD_Storage "yes"
#    }
#})
#
#endregion

#region AddDeviceCred
$TD_TBTN_SaveCredtoDG.add_click({
    if($TD_CB_CredUpdate.IsChecked){
        SST_ToolMessageCollector -TD_ToolMSGCollector "Cred Update" -TD_ToolMSGType Message -TD_Shown no
        $TD_CredfGUIArray = SST_GetCredfGUI -TD_AddaNewDevice "no"
    }else{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Cred AddaNewDevice" -TD_ToolMSGType Message -TD_Shown no
        $TD_CredfGUIArray = SST_GetCredfGUI -TD_AddaNewDevice "yes"
        Start-Sleep -Seconds 0.3
        if(!([string]::IsNullOrEmpty($TD_CredfGUIArray))){
            $TD_TB_DeviceIPAddr.Text=""
            $TD_TB_DeviceUserName.Text=""
            $TD_TB_DevicePassword.Password=""
            $TD_TB_PathtoSSHKeyNotVisibil.Text=""
            $TD_CB_SVCorVF.IsChecked=$false
        }
    }

})
#endregion

#region InAndSST_ExportCred
<# Button Credentials In-/ Export #>
$TD_btn_ExportCred.add_click({
    <# Not all needs to exported, if you want to modify the Export got to the SST_ExportCred Func #>
    $TD_SST_ExportCred = SST_ExportCredential -TD_CollectedCredDatas $TD_DG_KnownDeviceList.ItemsSource
    <# Save to Dir #>
    $TD_SaveCred = SST_SaveFile_to_Directory -TD_UserDataObject $TD_SST_ExportCred
    if([string]::IsNullOrEmpty($TD_SaveCred.FileName)){
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Export failed!") -TD_ToolMSGType Warning -TD_Shown yes
    }else {
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully exported to $($TD_SaveCred.FileName)") -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_btn_ImportCred.add_click({

    $TD_ImportedCredentials = SST_ImportCredential

    if($TD_ImportedCredentials.count -lt 1){
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Import failed!") -TD_ToolMSGType Warning -TD_Shown yes
    }else {
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully Import") -TD_ToolMSGType Message -TD_Shown yes
        $SST_BTN_PowerBoard = $TD_UserControl6.FindName("BTN_HMCCollector")
        $SST_BTN_PowerBoard.Content="HMC Scanner"
        $SST_BTN_PowerBoard.IsEnabled=$true
        if($TD_CB_OnlineCheckbyImport.IsChecked){
            Write-Host ($TD_CB_OnlineCheckbyImport.IsChecked) $CockpitView
            $TD_ImportedCredentials | ForEach-Object {
                SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $_.DeviceTyp -TD_Selected_DeviceConnectionType $_.ConnectionTyp -TD_Selected_DeviceIPAddr $_.IPAddress -TD_Selected_DeviceUserName $_.UserName -TD_Selected_DevicePassword $_.Password -TD_Selected_SVCorVF $_.SVCorVF
                Start-Sleep -Seconds 0.5
            }
        }
    }
})
<<<<<<< Updated upstream
=======
#endregion
#region LocalDB
if($TD_BTN_DeleteDB.Visibility -eq "Visible"){$TD_BTN_ActivateDB.Visibility = "Collapsed"}
$TD_BTN_ActivateDB.add_click({
    if(($TD_BTN_ActivateDB.Background -notlike "*FFFC4242")-and($TD_TB_CustomerInfoName.Background -notlike "*FFFA8C8C")){
        $DBName = $TD_TB_CustomerInfoName.Text
        try {
            $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\$DBName.db;Version=3;"
            $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
            $SST_SQLiteCon.Open()
        }
        catch {
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
        }
        Write-Host $SST_SQLiteCon.State $SST_SQLiteCon.DataSource
        Write-Host (($SST_SQLiteCon.State -eq "Open")-and($SST_SQLiteCon.DataSource -eq "$DBName"))
        if(($SST_SQLiteCon.State -eq "Open")-and($SST_SQLiteCon.DataSource -eq "$DBName")){
            $TD_BTN_DeleteDB.Visibility = "Visible"
            $TD_BTN_DeleteDB.Background = "coral"
            if($TD_CB_CustomerYN.IsChecked){$TD_BTN_ActivateDB.Visibility = "Collapsed"}
            $SST_SQLiteCon.Close()
            #$TD_CB_DataBaseChoice.ItemsSource = $null
            #$TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
            #Write-Host $TD_DataBaseChoice -ForegroundColor Green
            #$TD_CB_DataBaseChoice.IsEnabled = $true
            #$TD_CB_DataBaseChoice.ItemsSource = $TD_DataBaseChoice
            #$TD_CB_DataBaseChoice.SelectedIndex = 0
            SST_CustomerDeviceDBCreateTable
        }
    }else {
        [System.Windows.MessageBox]::Show(
            "Please enter the Customer Number!", "Invalid input", 'OK', 'Warning'
        )
    }
})
$TD_BTN_DeleteDB.add_click({
    $DBName = $TD_TB_CustomerInfoName.Text -replace ".db",""
    try {
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
        if ($DBName -match '^\d{6}$') {
            $DBFilePath = Join-Path $PSRootPath "Resources\DBFolder\$DBName.db"
            if (Test-Path -LiteralPath $DBFilePath) {
                Remove-Item -LiteralPath $DBFilePath -Confirm:$false -Force -ErrorAction SilentlyContinue
            }
        }
        $TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
        if([string]::IsNullOrWhiteSpace($TD_DataBaseChoice)){
            $TD_TB_CustomerInfoName.Text = "Customer Nbr"
            $TD_TB_CustomerInfoName.IsEnabled = $true
            $TD_BTN_ActivateDB.Visibility = "Visible"
        }else {
            $TD_CB_DataBaseChoice.ItemsSource = $null
            $TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
            $TD_CB_DataBaseChoice.ItemsSource = $TD_DataBaseChoice
            $TD_CB_DataBaseChoice.SelectedIndex = 0
            Write-Host $TD_DataBaseChoice
        }
        
    }
    catch {
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
        Write-Host $_.Exception.Message
    }
        SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB: $($TD_DBtoDelete.Name) are deleted" -TD_ToolMSGType Message -TD_Shown yes
        #$TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
})
$TD_BTN_DBRefresh.add_click({
    $TD_CB_DataBaseChoice.ItemsSource = $null
    $TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
    if ($TD_DataBaseChoice.Count -eq 0) {
        $TD_CB_DataBaseChoice.ItemsSource = @("Customer Nbr")
        $TD_CB_DataBaseChoice.SelectedIndex = 0
        $TD_CB_DataBaseChoice.IsEnabled = $false
        $TD_BTN_DeleteDB.Visibility = "Collapsed"
    } else {
        $TD_CB_DataBaseChoice.ItemsSource = $TD_DataBaseChoice
        $TD_CB_DataBaseChoice.IsEnabled = $true
        $TD_CB_DataBaseChoice.SelectedIndex = 0
    }
})
$TD_CB_CustomerYN.Add_Checked({
    if((Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db").count -eq 1){
        $TD_TB_CustomerInfoName.IsEnabled = $false
    }elseif (((Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db").count -lt 1)) {
        $TD_TB_CustomerInfoName.IsEnabled = $true
    }
    if (((Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db").count -ge 1)) {
        $TD_BTN_ActivateDB.Visibility = "Collapsed"
    }
    if((-not $TD_UserControl_Dash.IsLoaded)-and($TD_UserControl_CustomerBoard.IsLoaded)){
        $TD_UserContrArea.Children.Add($TD_UserControl_Dash)
    }
})
$TD_CB_CustomerYN.Add_Unchecked({
    $TD_TB_CustomerInfoName.IsEnabled = $true
    if($TD_BTN_ActivateDB.Visibility -eq "Collapsed"){
        $TD_BTN_ActivateDB.Visibility = "Visible"
        # To Update the Local DB place the func here ;)
    }
})
$TD_CB_DataBaseChoice.add_SelectionChanged({
    if(!([string]::IsNullOrEmpty($TD_CB_DataBaseChoice.SelectedItem))){
        $CustomerDB = $TD_CB_DataBaseChoice.SelectedItem.tostring()
        $SST_SavedCustomerSettingsDB = SST_CustomerDB -SST_InfoType "LoadCustomerSetUp" -SST_Customer $CustomerDB
        $TD_TB_ExportPath.Text = $SST_SavedCustomerSettingsDB.ExportPath
        $TD_LB_CerdExportPath.Content = $SST_SavedCustomerSettingsDB.ExportPathCredential
    }
})
#endregion
#region PRISM
SST_ToolMessageCollector -TD_ToolMSGCollector "Load PRISM" -TD_ToolMSGType Message -TD_Shown no
# If data is available, hide the fields
if($(SST_PRISMLocalDataCheck -PSRootPath $PSRootPath)){
    $TD_TB_CustomerAZPPRISMConString.Visibility = "Collapsed"
    $TD_TB_CustomerAZPPRISMDB.Visibility = "Collapsed"
    $TD_TB_CustomerAZPPRISMUM.Visibility = "Collapsed"
    $TD_TB_CustomerAZPPRISMUMP.Visibility = "Collapsed"
}
$TD_BTN_SaveAZConnectionPRISM.add_click({
    $AZConnection =$false
    [int]$ProgCounter=10
    if(($TD_TB_CustomerInfoName.Text.Length -ge 6)-and($TD_TB_CustomerAZPPRISMConString.Text.Length -ge 10)-and($TD_TB_CustomerAZPPRISMDB.Text -ge 6)){
        $ProgressBar = New-ProgressBar
        $AZPRISM = [PSCustomObject]@{
            CustomerNBR = $TD_TB_CustomerInfoName.Text
            CustomerP = (ConvertTo-SecureString $(Get-RandomPassword -PasswordLength 16) -AsPlainText -Force | ConvertFrom-SecureString)
            AZConString = (ConvertTo-SecureString $($TD_TB_CustomerAZPPRISMConString.Text) -AsPlainText -Force | ConvertFrom-SecureString)
            AZDBNAM = (ConvertTo-SecureString $($TD_TB_CustomerAZPPRISMDB.Text) -AsPlainText -Force | ConvertFrom-SecureString)
        }
        #ConnectionStringPRISM = "Server=tcp:pwshdemo.database.windows.net,1433;Initial Catalog={replaceone};Persist Security Info=False;User ID={replacetwo};Password={replacethree};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=15;"
        $ConString = $TD_TB_CustomerAZPPRISMConString.Text
        $AZCredDB  = $TD_TB_CustomerAZPPRISMDB.Text
        $CustomerP  = Convert-SecureStringToPlainText ($AZPRISM.CustomerP | ConvertTo-SecureString)
        $ConnectionStringPRISM = $ConString.Replace('{replaceone}',[string]$AZCredDB).Replace('{replacetwo}',"$($TD_TB_CustomerAZPPRISMUM.Text)").Replace('{replacethree}',"$($TD_TB_CustomerAZPPRISMUMP.Password)")
        $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
        $SQLConnection.ConnectionString=$ConnectionStringPRISM
        if ($SQLConnection.State -ne "Closed") { $SQLConnection.Close()}
        try{
            while (!($AZConnection)) {
                $ProgCounter++
                if($ProgCounter -gt 50){break}
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Try to connect PRISM" -PercentComplete (($ProgCounter/50) * 100)    
                try {
                    $SQLConnection.Open()
                    $SQLCommand = $SQLConnection.CreateCommand()
                    $SQLCommand.CommandText ="EXEC dbo.usp_CreateManagedUser @UserName = @UserName, @Password = @Password;"
                    $SQLCommand.Parameters.AddWithValue("@UserName",$TD_TB_CustomerInfoName.Text)
                    $SQLCommand.Parameters.AddWithValue("@Password",$CustomerP)
                    $SQLCommand.ExecuteNonQuery()
                    $ConString = $null
                    $AZCredDB = $null
                    $CustomerP = $null
                    $TD_BTN_SaveAZConnectionPRISM.Visibility = "Collapsed"
                    $TD_TB_CustomerAZPPRISMConString.Text = $null
                    $TD_TB_CustomerAZPPRISMDB.Text = $null
                    $TD_TB_CustomerAZPPRISMUM.Text = $null
                    $TD_TB_CustomerAZPPRISMUMP.Password = $null
                    $TD_TB_CustomerAZPPRISMConString.Visibility = "Collapsed"
                    $TD_TB_CustomerAZPPRISMDB.Visibility = "Collapsed"
                    $TD_TB_CustomerAZPPRISMUM.Visibility = "Collapsed"
                    $TD_TB_CustomerAZPPRISMUMP.Visibility = "Collapsed"
                    $TD_LB_CustomerAZPPRISM.Content="Reset the PRISM connection"
                    $TD_BTN_ChangeAZConnectionPRISM.Visibility = "Visible"
                    $AZConnection =$true
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "$($SQLConnection.State) - $($_.Exception.Message)" -ForegroundColor Yellow
                }finally{
                    if ($SQLCommand) {
                        $SQLCommand.Dispose()
                        $SQLCommand = $null
                    }
                    if ($SQLConnection.State -eq "Open") {
                        $SQLConnection.Close()
                    }
                }
            } 
        }finally{
            if ($SQLConnection) {
                if ($SQLConnection.State -eq "Open") {$SQLConnection.Close()}
                $SQLConnection.Dispose()
            }
            Close-ProgressBar -ProgressBar $ProgressBar
        }
        if($AZConnection){
            SST_ToolAdvSaveDB -SST_InfoType "SavePRISMSettings" -SST_NewDBObject $AZPRISM
        }
    }
})
$TD_BTN_ConnetionToPRISM.add_click({
    $TD_BTN_ConnetionToPRISM.Background="#FFF5F7FA" #default color

    try {
        $TD_AZDBObj = SST_ToolAdvSaveDB -SST_InfoType "LoadPRISMSettings"
        $AZConString = Convert-SecureStringToPlainText ($TD_AZDBObj.AZConString | ConvertTo-SecureString)
        $CustomerP  = Convert-SecureStringToPlainText ($TD_AZDBObj.CustomerP | ConvertTo-SecureString)
        $AZDBNAM  = Convert-SecureStringToPlainText ($TD_AZDBObj.AZDBNAM | ConvertTo-SecureString)

        $ConnectionStringPRISM = $AZConString.Replace('{replaceone}',[string]$AZDBNAM).Replace('{replacetwo}',"$($TD_TB_CustomerInfoName.Text)").Replace('{replacethree}',"$($CustomerP)")
        $AZConString = $null
        $AZDBNAM = $null
        $CustomerP = $null
        $PROFIprism = $true
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        $PROFIprism = $false
    }
    <#  #>
    $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
    $SQLConnection.ConnectionString=$ConnectionStringPRISM 
    $ConnectionStringPRISM = $null
    $MaxRetries = 10
    $RetryDelaySeconds = 3
    $AZConnection = $false
    [int]$ProgCounter=10
    $ProgressBar = New-ProgressBar
    for ($Attempt = 1; $Attempt -le $MaxRetries -and -not $AZConnection -and $PROFIprism; $Attempt++) {
        try {
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Try to connect PRISM ($Attempt/$MaxRetries)" -PercentComplete (($Attempt / $MaxRetries) * 100)
        
            if ($SQLConnection.State -ne [System.Data.ConnectionState]::Closed) {
                $SQLConnection.Close()
            }
        
            $SQLConnection.Open()
        
            if ($SQLConnection.State -eq [System.Data.ConnectionState]::Open) {
                $AZConnection = $true
                $TD_BTN_ConnetionToPRISM.Content = "Test successful"
                $TD_BTN_ConnetionToPRISM.Background = "LightGreen"
                SST_ToolMessageCollector -TD_ToolMSGCollector "Azure SQL connection successful on attempt $Attempt." -TD_ToolMSGType Message -TD_Shown yes
            }
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "Attempt $Attempt/$MaxRetries failed: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        
            if ($Attempt -lt $MaxRetries) {
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }
    if (-not $AZConnection) {
        $TD_BTN_ConnetionToPRISM.Content = "Test failed"
        $TD_BTN_ConnetionToPRISM.Background = "Coral"
        SST_ToolMessageCollector -TD_ToolMSGCollector "Azure SQL connection failed after $MaxRetries attempts, or is PRISM Var is $PROFIprism." -TD_ToolMSGType Error -TD_Shown yes
    }   
    if ($SQLConnection) {
        if ($SQLConnection.State -ne [System.Data.ConnectionState]::Closed) {
            $SQLConnection.Close()
        }
        $SQLConnection.Dispose()
    }
    Close-ProgressBar -ProgressBar $ProgressBar
})
$TD_BTN_ChangeAZConnectionPRISM.add_click({
    $TD_BTN_SaveAZConnectionPRISM.Visibility = "Visible"
    $TD_TB_CustomerAZPPRISMConString.Text = $null
    $TD_TB_CustomerAZPPRISMDB.Text = $null
    $TD_TB_CustomerAZPPRISMUM.Text = $null
    $TD_TB_CustomerAZPPRISMUMP.Password = $null
    $TD_TB_CustomerAZPPRISMConString.Visibility = "Visible"
    $TD_TB_CustomerAZPPRISMDB.Visibility = "Visible"
    $TD_TB_CustomerAZPPRISMUM.Visibility = "Visible"
    $TD_TB_CustomerAZPPRISMUMP.Visibility = "Visible"
    $TD_LB_CustomerAZPPRISM.Content="Enter the PRISM connection details"
    $TD_BTN_ChangeAZConnectionPRISM.Visibility = "Collapsed"
})
$TD_BTN_SendDataToPRISM.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $UserSelection = $TD_CB_SQltoAzDB.SelectedItem.Tag
    
    try {
        $LocalCustomerData = SST_ReadLocalSendtoPRISM -SST_InfoType $UserSelection -SST_Customer $CustomerNumber
        
        SST_PRISMDBControl -SST_InfoType $UserSelection -SST_CollectedInformations $LocalCustomerData -CustomerNumber $CustomerNumber
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector "SendDataToPRISM $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }
})
SST_ToolMessageCollector -TD_ToolMSGCollector "Load PRISM done" -TD_ToolMSGType Message -TD_Shown no
#endregion
#region DashBoard
$TD_BTN_RefreshDashBoard.add_click({
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource
    SST_DashBoardRefreshData -Device $TD_Credentials -ExportPath $TD_TB_ExportPath.Text
    $CustomerDBDashBoard = $(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "$($TD_TB_CustomerInfoName.Text).db").BaseName
    SST_DashBoardMain -MainPath $PSRootPath -SST_UCOBJ $TD_UserControl_Dash -FoundLocalDB $CustomerDBDashBoard
})
#endregion
#endregion
#region Devices
#region IBM Storage
$TD_BTN_IBM_BaseStorageInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $baseResult  = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTBaseStorageInfos -SSHFunc IBM_SSHBaseStorageInfos
        
        $dev = $baseResult.DeviceIdent
        $mapStorageInfo = @{
            ID             = 'ID'
            Name           = 'Name'
            WWNN           = 'WWNN'
            Status         = 'Status'
            IO_group_id    = 'IO_group_id'
            IO_group_Name  = 'IO_group_Name'
            ProdMTM        = 'ProdMTM'
            SerialNumber   = 'SerialNumber'
            CodeLevel      = 'CodeLevel'
            RecommendedPTF = 'RecommendedPTF'
            ConfigNode     = 'ConfigNode'
            SideID         = 'SideID'
            SideName       = 'SideName'
        } 

        Add-MappedRows -Collection $dev.BaseRows -Source $baseResult.FuncResult.StorageInfo -IdProperty 'RowID' -Map $mapStorageInfo

        #$FunctionResult = $null
        $ipqResult  = RestThenSshForCombiView -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTIPQuorum -SSHFunc IBM_SSHIPQuorum
        $mapIPQuorum = @{
            QuorumIndex    = 'QuorumIndex'
            ID             = 'ID'
            Name           = 'Name'
            Status         = 'Status'
            ControllerID   = 'ControllerID'
            ControllerName = 'ControllerName'
            Active         = 'Active'
            ObjectType     = 'ObjectType'
            Override       = 'Override'
            SideID         = 'SideID'
            SideName       = 'SideName'
        } 
        Add-MappedRows -Collection $dev.IPQuorumRows -Source $ipqResult -IdProperty 'RowID' -Map $mapIPQuorum

        $UCVMMain.DeviceToggles.Add($dev)
    }
    $UCVMMain.SelectedView = "Base"
})
$TD_BTN_IBM_Eventlog.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTEventLog -SSHFunc IBM_SSHEventLog
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $mapStorageEvents = @{
            ID          = 'SeqID'
            LastTime    = 'LastTime'
            ObjectType  = 'ObjectType'
            ObjectID    = 'ObjectID'
            ObjectName  = 'ObjectName'
            CopyID      = 'CopyID'
            Status      = 'Status'
            Fixed       = 'Fixed'
            ErrorCode   = 'ErrorCode'
            Description = 'Description'
        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.EventRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapStorageEvents

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
    }
    $UCVMMain.SelectedView = "Events"
    # Refresh global search/filter for all DataGrids inside this UserControl
    Update-GlobalDataGridSearchFilter -RootControl $TD_UserControl_IBMSTO -SearchBox $TD_UserControl_IBMSTO.FindName("TB_GlobalGridSearch")
})
$TD_BTN_IBM_CatAuditLog.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTCatAuditLog -SSHFunc IBM_SSHCatAuditLog
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $mapCatAuditLog = @{
            AuditSeqNo          = 'AuditSeqNo'  <# not to display #>
            TimeStamp           = 'TimeStamp'
            User                = 'User'
            Challenge           = 'Challenge'   <# not to display #>
            SourcePanel         = 'SourcePanel' 
            TargetPanel         = 'TargetPanel'
            SSH_IP              = 'SSH_IP'
            Result              = 'Result'      <# not to display #>
            ResObjID            = 'ResObjID'    <# not to display #>
            UsedCommand         = 'UsedCommand'
            Origin              = 'Origin'      <# not to display #>
            TwoPersonIntegrity  = 'TwoPersonIntegrity'
        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.AuditLogRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapCatAuditLog

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
    }
    $UCVMMain.SelectedView = "CatAuditLog"
})
$TD_BTN_IBM_HostVolumeMap.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTHost_Volume_Map -SSHFunc IBM_SSHHost_Volume_Map
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $mapHostVolumeMap = @{
            HostID          = 'HostID'  
            HostName        = 'HostName'
            HostClusterID   = 'HostClusterID'
            HostCluster     = 'HostCluster'   
            MappingType     = 'MappingType' <# not to display #>
            SCSIID          = 'SCSIID'      <# not to display #>
            VolumeID        = 'VolumeID'
            VolumeName      = 'VolumeName'
            VolumeGroupName = 'VolumeGroupName'
            UID             = 'UID'      
            Capacity        = 'Capacity'    
        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.HostVolumeMapRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapHostVolumeMap

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
    }
    $UCVMMain.SelectedView = "HostVolumeMap"
})
$TD_BTN_IBM_HostInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    $Global:HostStatusChanges.Clear()
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTHostInfo -SSHFunc IBM_SSHHostInfo

        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $mapHost = @{
            HostID                  = 'ID'  
            HostName                = 'HostName'
            PortCount               = 'PortCount'
            PartitionName           = 'PartitionName'  
            IOGrpCount              = 'IOGrpCount'  <# not to display #>
            Status                  = 'Status'
            SiteID                  = 'SiteID'      <# not to display #>
            SiteName                = 'SiteName'    
            HostStateInfo           = 'HostStateInfo'      
            HostClusterID           = 'HostClusterID'   <# not to display #>
            HostClusterName         = 'HostClusterName'  
            Protocol                = 'Protocol'
            StatusPolicy            = 'StatusPolicy'
            StatusSite              = 'StatusSite'  
            WWPNOne                 = 'WWPNOne'
            NodeLoggedInCountOne    = 'NodeLoggedInCountOne'
            StateOne                = 'StateOne'   
            WWPNTwo                 = 'WWPNTwo' 
            NodeLoggedInCountTwo    = 'NodeLoggedInCountTwo'
            StateTwo                = 'StateTwo'
            WWPNThree               = 'WWPNThree'      
            NodeLoggedInCountThree  = 'NodeLoggedInCountThree' 
            StateThree              = 'StateThree'
            WWPNFour                = 'WWPNFour'
            NodeLoggedInCountFour   = 'NodeLoggedInCountFour'   
            StateFour               = 'StateFour' 
            OwnerID                 = 'OwnerID'     <# not to display #>
            OwnerName               = 'OwnerName'   <# not to display #>
            PortsetID               = 'PortsetID'   <# not to display #>
            PortsetName             = 'PortsetName' <# not to display #>
        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.HostRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapHost

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
    }
    $UCVMMain.SelectedView = "HostMap"
if ($Global:HostStatusChanges.Count -eq 0) {

    $Global:HostStatusChanges.Add(
        "No Host Status changes since the last check."
    )
}
})
$TD_BTN_IBM_PoolVolumeInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $MDiskResult  = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTMDiskInfo -SSHFunc IBM_SSHMDiskInfo
        
        $dev = $MDiskResult.DeviceIdent

        $mapMDiskInfo = @{
            ID             = 'ID'
            Name           = 'Name'
            Status         = 'Status'
            MDiskCount     = 'MDiskCount'
            VdiskCount     = 'VdiskCount'
            Capacity       = 'Capacity'
            ExtentSize     = 'ExtentSize'
            FreeCapacity   = 'FreeCapacity'
            VirtualCapacity= 'VirtualCapacity'
            UsedCapacity   = 'UsedCapacity'
            RealCapacity   = 'RealCapacity'
            Overallocation = 'Overallocation'
        } 
        Add-MappedRows -Collection $dev.MDiskRows -Source $MDiskResult.FuncResult -IdProperty 'RowID' -Map $mapMDiskInfo

        #$FunctionResult = $null
        $VolumeResult  = RestThenSshForCombiView -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTVolumeInfo -SSHFunc IBM_SSHVolumeInfo

        $mapVolumeInfo = @{
            Name                    = 'Name'
            DisplayName             = 'DisplayName'
            IOGroupName             = 'IOGroupName'
            Status                  = 'Status'
            MdiskGrpName            = 'MdiskGrpName'
            VolumeGroupName         = 'VolumeGroupName'
            Capacity                = 'Capacity'
            SnapshotCount           = 'SnapshotCount'
            VdiskUID                = 'VdiskUID'
            Protocol                = 'Protocol'
            VolumeType              = 'VolumeType'
            Safeguarded             = 'Safeguarded'
        
            IsSnapshot              = 'IsSnapshot'
            SnapshotID              = 'SnapshotID'
            SnapshotName            = 'SnapshotName'
            SnapshotTime            = 'SnapshotTime'
            ExpirationTime          = 'ExpirationTime'
            WrittenCapacity         = 'WrittenCapacity'
        
            GroupKey                = 'GroupKey'
            GroupName               = 'GroupName'
            RowType                 = 'RowType'
            RowOrder                = 'RowOrder'
        
            HAType                  = 'HAType'
        }

        Add-MappedRows -Collection $dev.VolumeRows -Source $VolumeResult -IdProperty 'RowID' -Map $mapVolumeInfo

        $VolumeView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($dev.VolumeRows)
        $VolumeView.GroupDescriptions.Clear()
        $VolumeView.SortDescriptions.Clear()
        $VolumeView.GroupDescriptions.Add(
            [System.Windows.Data.PropertyGroupDescription]::new('GroupKey')
        )
        $VolumeView.SortDescriptions.Add(
            [System.ComponentModel.SortDescription]::new('RowOrder', [System.ComponentModel.ListSortDirection]::Ascending)
        )
        $UCVMMain.DeviceToggles.Add($dev)
        
    }
    $UCVMMain.SelectedView = "PoolVolumeInfo"
})
$TD_BTN_IBM_DriveInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        if($TD_Creds.SVCorVF -like "*SVC*"){continue}
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTDriveInfo -SSHFunc IBM_SSHDriveInfo
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $mapDrive = @{
            ID                      = 'ID'  
            Status                  = 'Status'
            Capacity                = 'Capacity'
            ProductID               = 'ProductID'  
            FirmwareLevel           = 'FirmwareLevel'  
            LatestFirmwareLevel     = 'LatestFirmwareLevel'
            SlotID                  = 'SlotID'      
            PhysicalCapacity        = 'PhysicalCapacity'    
            PhysicalUsedCapacity    = 'PhysicalUsedCapacity'      
            EffectiveUsedCapacity   = 'EffectiveUsedCapacity'   
            FirmwareLevelStatus     = 'FirmwareLevelStatus'  
        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.DriveRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapDrive

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        $UCVMMain.SelectedView = "DriveMap"
    }
})
$TD_BTN_IBM_FCPortInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTFCPortInfo -SSHFunc IBM_SSHFCPortInfo
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $mapFCPort = @{
            ID              = 'ID'
            CardID          = 'CardID'
            CardPortID      = 'CardPortID'
            Speed           = 'Speed'
            Status          = 'Status'
            WWPN            = 'WWPN'
            WWNN            = 'WWNN'
            NodeName        = 'NodeName'
            HostIOPermitted = 'HostIOPermitted'
            Virtualized     = 'Virtualized'
            Protocol        = 'Protocol'
            HostCount       = 'HostCount'
            ActiveLoginCount = 'ActiveLoginCount'
            Attachment      = 'Attachment'
        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.FCPortRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapFCPort

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
    }
    $UCVMMain.SelectedView = "FCPort"
})
$TD_BTN_IBM_FCPortStats.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTFCPortStats -SSHFunc IBM_SSHFCPortStats
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        
        $mapFCPortStats = @{
            NodeID      = 'NodeID'
            NodeName    = 'NodeName'
            CardType    = 'CardType'
            PortID      = 'PortID'
            WWPN        = 'WWPN'
            LinkFailure = 'LinkFailure'
            LoseSync    = 'LoseSync'
            LoseSig     = 'LoseSig'
            PSErrCount  = 'PSErrCount'
            InvTransErr = 'InvTransErr'
            CRCErr      = 'CRCErr'
            ZeroBtB     = 'ZeroBtB'
            SFPTemp     = 'SFPTemp'
            TXPwr       = 'TXPwr'
            TXPwrlow    = 'TXPwrlow'
            RXPwr       = 'RXPwr'
            RXPwrlow    = 'RXPwrlow'

        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.FCPortStatsRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapFCPortStats

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
    }
    $UCVMMain.SelectedView = "FCPortStats"
})
$TD_BTN_IBM_PartitionInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="visible"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTPartitionInfos -SSHFunc $null
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $mapPartition = @{
            ID                      = 'ID'  
            Name                    = 'Name'
            PreferredManagementSystemName = 'PreferredManagementSystemName'
            ReplicationPolicyName   = 'ReplicationPolicyName'  
            Location1SystemName     = 'Location1SystemName'  
            Location2SystemName     = 'Location2SystemName'
            HostCount               = 'HostCount'      
            HostClusterCount        = 'HostClusterCount'    
            VolumeGroupCount        = 'VolumeGroupCount'      
            HAStatus                = 'HAStatus'   
            LinkStatus              = 'LinkStatus'  
        }
        $PartitionResult = @($FunctionResult.FuncResult)
        if ($PartitionResult.Count -gt 0) {
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.PartitionRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapPartition
        }
        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        $UCVMMain.SelectedView = "Partition"
    }
})
$TD_BTN_IBM_SecurityInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="Collapsed"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTStorageSecurity -SSHFunc $null
        
        $mapSecurity = @{
            Key             = 'Key'
            Value           = 'Value'
            RecommendedValue = 'RecommendedValue'  
            IsRecommended    = 'IsRecommended'
        }
        Add-MappedRows -Collection $FunctionResult.DeviceIdent.SecurityRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapSecurity

        $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        $UCVMMain.SelectedView = "Security"
    }
})
$TD_BTN_IBM_UserInfo.add_click({
    $TD_GB_SearchFilterSTO.Visibility="Collapsed"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTUserInfo -SSHFunc $null
        $dev = $FunctionResult.DeviceIdent
        $dev.DeviceTitle = "UserInfo for - $($dev.DeviceTitle)"

        $mapUserInfo = @{
            ID                 = 'ID'
            UserName           = 'UserName'
            Password           = 'Password'
            SSHKey            = 'SSHKey'
            Remote             = 'Remote'
            UserGrpID         = 'UserGrpID'
            UserGrpName       = 'UserGrpName'
            OwnerID           = 'OwnerID'
            OwnerName         = 'OwnerName'
            Locked             = 'Locked'
            PWChangerequired = 'PWChangerequired'
        }
        Add-MappedRows -Collection $dev.UserInfoRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapUserInfo

        $UCVMMain.DeviceToggles.Add($dev)
        $UCVMMain.SelectedView = "UserInfo"
    }
})
$TD_BTN_IBM_CleanUpDumps.add_click({
    $TD_GB_SearchFilterSTO.Visibility="Collapsed"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTCleanUpDumps -SSHFunc IBM_SSHCleanUpDumps
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $dev = $FunctionResult.DeviceIdent

        $mapDumpInfo = @{
            DeviceName  = 'DeviceName'
            DumpMsg     = 'DumpMsg'
            UpgradeMsg  = 'UpgradeMsg'
        }
        Add-MappedRows -Collection $dev.DumpInfoRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapDumpInfo
        # dynamische Überschrift
        $dev.DumpInfoTitle = "Dump cleanup for - $($dev.Label)"

        # Textblock-Inhalt aus Rows zusammensetzen (DumpMsg je Zeile)
        $dev.DumpInfoText = (@($dev.DumpInfoRows) | ForEach-Object { $_.DumpMsg } | Where-Object { $_ }) -join "`n"

        $UCVMMain.DeviceToggles.Add($dev)
    }
    <#one for each view is fine do need to be inside the foreach #>
    $UCVMMain.SelectedView = "DumpInfo"
})
$TD_BTN_IBM_BackUpConfig.add_click({
    $TD_GB_SearchFilterSTO.Visibility="Collapsed"
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Storage*"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    foreach($TD_Creds in $TD_Credentials){
        $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -SSHFunc IBM_SSHBackUpConfig
        # Links = Propertyname im PSCustomObject (das bindet dein XAML)
        # Rechts = Propertyname im Source-Objekt
        $dev = $FunctionResult.DeviceIdent

        $mapBackUpInfo = @{
            DeviceName  = 'DeviceName'
            BackUpMsg     = 'BackUpMsg'
        }
        Add-MappedRows -Collection $dev.BackUpInfoRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapBackUpInfo
        # dynamische Überschrift
        $dev.BackUpInfoTitle = "BackUp for - $($dev.Label)"

        # Textblock-Inhalt aus Rows zusammensetzen (BackUpMsg je Zeile)
        $dev.BackUpInfoText = (@($dev.BackUpInfoRows) | ForEach-Object { $_.BackUpMsg } | Where-Object { $_ }) -join "`n"

        $UCVMMain.DeviceToggles.Add($dev)
    }
    <#one for each view is fine do need to be inside the foreach #>
    $UCVMMain.SelectedView = "BackUpInfo"
})
#endregion
#region Brocade SAN
$TD_BTN_FOS_BasicSwitchInfo.add_click({
    $TD_GB_SearchFilter.Visibility = "Collapsed"
    try{
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource | Where-Object { $_.DeviceTyp -like "*SAN*" }
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }

        $UCVMMain = $UCDataContext.Main
        $UCVMMain.DeviceToggles.Clear()

        $mapSANSwitchInfo = [ordered]@{
            SwitchName          = 'SwitchName'
            ActiveZoneCFG      = 'ActiveZoneCFG'
            DomainID            = 'DomainID'
            SwitchWWNN          = 'SwitchWWN'
            SwitchType          = 'SwitchType'
            vFabricID           = 'FabricID'
            BrocadeProductName  = 'BrocadeName'
            MTM                 = 'MTM'
            SerialNumber        = 'SerialNumber'
            FabricOS            = 'FabricOS'
            EthernetIPAddress   = 'IPAddress'
            EthernetSubnetMask  = 'Subnetmask'
            GatewayIPAddress    = 'GatewayIP'
            DHCP                = 'DHCP'
            SwitchState         = 'SwitchState'
            SwitchRole          = 'SwitchRole'
        }

        foreach ($TD_Creds in $TD_Credentials) {

            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeBaseInfo -SSHFunc FOS_SSHBasicSwitchInfos

            $deviceIdent = $FunctionResult['DeviceIdent']
            $funcResult  = $FunctionResult['FuncResult']

            # If it is an array: take the IDictionary element (and NOT the first one)
            if ($funcResult -is [object[]]) {
                $funcResult = @($funcResult) | Where-Object { $_ -is [System.Collections.IDictionary] -or $_.PSObject.Properties.Count -gt 0 } | Select-Object -First 1
            }

            #if ($deviceIdent.PSObject.Properties.Match('IsChecked').Count -gt 0) {
            #    $deviceIdent.IsChecked = $true
            #}

            Add-MappedKeyValueRows -Collection $deviceIdent.SANSwitchBaseRows -Source $funcResult -Map $mapSANSwitchInfo

            $UCVMMain.DeviceToggles.Add($deviceIdent)
        }
        $UCVMMain.SelectedView = "SANSwitchBase"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeBaseInfo done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_SwitchShow.add_click({
    $TD_GB_SearchFilter.Visibility = "visible"

    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){

           <# VFID Check / Zone Rows sammeln #>
            $AllSwitchShowRows = @()
            $FunctionResult = $null
            $VFIDs = @()
            if($TD_Creds.SVCorVF -like "*vFabric*"){
                $VFIDs = @(Get-BrocadeVFIDsFromDB -Device $TD_Creds)
            }
            if($VFIDs.Count -gt 0){
            
                foreach($VFID in $VFIDs){
                
                    $TD_Creds | Add-Member -NotePropertyName VFID -NotePropertyValue $VFID -Force

                    $TmpResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeSwitchShow -SSHFunc FOS_SSHSwitchShowInfo

                    if(!($FunctionResult)){
                        $FunctionResult = $TmpResult
                    }
                
                    $AllSwitchShowRows += @($TmpResult.FuncResult)
                }
                <# Sort the Ports #>
                $AllSwitchShowRows = @(
                    $AllSwitchShowRows | Sort-Object `
                        @{ Expression = { [int](($_.Port -replace '^.*?/','')) } }, `
                        @{ Expression = { [int]($_.VFID) } }
                )
            }else{
                if($TD_Creds.PSObject.Properties['VFID']){
                    $TD_Creds.PSObject.Properties.Remove('VFID')
                }

                $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeSwitchShow -SSHFunc FOS_SSHSwitchShowInfo

                $AllSwitchShowRows += @($FunctionResult.FuncResult)
            }

            # Links = Propertyname im PSCustomObject (das bindet dein XAML)
            # Rechts = Propertyname im Source-Objekt
            $mapSwitchShowInfo = @{ 
                IsVirtualFabricPort = 'IsVirtualFabricPort'
                VFIDDisplay     = 'VFIDDisplay'
                Index           = 'Index'
                Port            = 'Port'
                Address         = 'Address'
                Media           = 'Media'
                Speed           = 'Speed'
                State           = 'State'
                Proto           = 'Proto'
                PortConnect     = 'PortConnect'
                PortStateInfo   = 'PortStateInfo'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.SANSwitchShowRows -Source $AllSwitchShowRows -IdProperty 'RowID' -Map $mapSwitchShowInfo

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        $UCVMMain.SelectedView = "SANSwitchShow"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeSwitchShow done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_PortBufferShow.add_click({
    $TD_GB_SearchFilter.Visibility = "visible"

    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){

           <# VFID Check / Zone Rows sammeln #>
            $AllPortBufferRows = @()
            $FunctionResult = $null
            $VFIDs = @()
            if($TD_Creds.SVCorVF -like "*vFabric*"){
                $VFIDs = @(Get-BrocadeVFIDsFromDB -Device $TD_Creds)
            }
            if($VFIDs.Count -gt 0){
            
                foreach($VFID in $VFIDs){
                
                    $TD_Creds | Add-Member -NotePropertyName VFID -NotePropertyValue $VFID -Force

                    $TmpResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadePortBufferStats -SSHFunc FOS_SSHPortbufferShowInfo

                    if(!($FunctionResult)){
                        $FunctionResult = $TmpResult
                    }
                
                    $AllPortBufferRows += @($TmpResult.FuncResult)
                }
                <# Sort the Ports #>
                $AllPortBufferRows = @(
                    $AllPortBufferRows | Sort-Object `
                        @{ Expression = { [int](($_.Port -replace '^.*?/','')) } }, `
                        @{ Expression = { [int]($_.VFID) } }
                )
            }else{
                if($TD_Creds.PSObject.Properties['VFID']){
                    $TD_Creds.PSObject.Properties.Remove('VFID')
                }

                $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadePortBufferStats -SSHFunc FOS_SSHPortbufferShowInfo

                $AllPortBufferRows += @($FunctionResult.FuncResult)
            }
        
            $mapPortbufferShow = @{ 
                IsVirtualFabricPort = 'IsVirtualFabricPort'
                VFIDDisplay = 'VFIDDisplay'
                Port        = 'Port'
                PortType    = 'PortType'
                State       = 'State'
                Speed       = 'Speed'
                ReservedBuffers     = 'ReservedBuffers'
                CurrentBufferUsage  = 'CurrentBufferUsage'
                RecommendedBuffers  = 'RecommendedBuffers'
                AvgTxBufferUsage    = 'AvgTxBufferUsage'
                AvgRxBufferUsage    = 'AvgRxBufferUsage'
                AvgTxFrameSize      = 'AvgTxFrameSize'
                AvgRxFrameSize      = 'AvgRxFrameSize'
                ChipBuffersAvailable    = 'ChipBuffersAvailable'
                CreditRecoveryEnabled   = 'CreditRecoveryEnabled'
                CreditRecoveryActive    = 'CreditRecoveryActive'
                CongestionSignalEnabled = 'CongestionSignalEnabled'
                FportBuffers        = 'FportBuffers'
                BBzero      = 'BBzero'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.SANPortbufferShowRows -Source $AllPortBufferRows -IdProperty 'RowID' -Map $mapPortbufferShow

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        $UCVMMain.SelectedView = "SANPortbufferShow"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadePortBufferStats done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_PortErrorShow.add_click({
    $TD_GB_SearchFilter.Visibility = "visible"

    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){

           <# VFID Check / Zone Rows sammeln #>
            $AllErrorsShowRows = @()
            $FunctionResult = $null
            $VFIDs = @()
            if($TD_Creds.SVCorVF -like "*vFabric*"){
                $VFIDs = @(Get-BrocadeVFIDsFromDB -Device $TD_Creds)
            }
            if($VFIDs.Count -gt 0){
            
                foreach($VFID in $VFIDs){
                
                    $TD_Creds | Add-Member -NotePropertyName VFID -NotePropertyValue $VFID -Force

                    $TmpResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadePortErrorStats -SSHFunc FOS_SSHPortErrShowInfos

                    if(!($FunctionResult)){
                        $FunctionResult = $TmpResult
                    }
                
                    $AllErrorsShowRows += @($TmpResult.FuncResult)
                }
                <# Sort the Ports #>
                $AllErrorsShowRows = @(
                    $AllErrorsShowRows | Sort-Object `
                        @{ Expression = { [int](($_.Port -replace '^.*?/','')) } }, `
                        @{ Expression = { [int]($_.VFID) } }
                )
            }else{
                if($TD_Creds.PSObject.Properties['VFID']){
                    $TD_Creds.PSObject.Properties.Remove('VFID')
                }

                $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadePortErrorStats -SSHFunc FOS_SSHPortErrShowInfos

                $AllErrorsShowRows += @($FunctionResult.FuncResult)
            }

            # Links = Propertyname im PSCustomObject (das bindet dein XAML)
            # Rechts = Propertyname im Source-Objekt

            $mapPortErrorShow = @{ 
                IsVirtualFabricPort = 'IsVirtualFabricPort'
                VFIDDisplay     = 'VFIDDisplay'
                Port            = 'Port'
                EncIn           = 'EncIn'
                CrcErr          = 'CrcErr'
                TooShort        = 'TooShort'
                TooLong         = 'TooLong'
                BadEOF          = 'BadEOF'
                EncOut          = 'EncOut'
                DiscC3          = 'DiscC3'
                LinkFail        = 'LinkFail'
                LossSync        = 'LossSync'
                LossSig         = 'LossSig'
                StateTransitions    = 'StateTransitions'
                BBZero          = 'BBZero'
                FECuncorrected  = 'FECuncorrected'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.SANPortErrorShowRows -Source $AllErrorsShowRows -IdProperty 'RowID' -Map $mapPortErrorShow

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        $UCVMMain.SelectedView = "SANPortErrorShow"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadePortErrorStats done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_SFPHealthShow.add_click({
    $TD_GB_SearchFilter.Visibility = "visible"

    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }
 
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){

           <# VFID Check / Zone Rows sammeln #>
            $AllSFPRows = @()
            $FunctionResult = $null
            $VFIDs = @()
            if($TD_Creds.SVCorVF -like "*vFabric*"){
                $VFIDs = @(Get-BrocadeVFIDsFromDB -Device $TD_Creds)
            }
            if($VFIDs.Count -gt 0){
            
                foreach($VFID in $VFIDs){
                
                    $TD_Creds | Add-Member -NotePropertyName VFID -NotePropertyValue $VFID -Force

                    $TmpResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeSFPShow -SSHFunc FOS_SSHSFPDetails

                    if(!($FunctionResult)){
                        $FunctionResult = $TmpResult
                    }
                
                    $AllSFPRows += @($TmpResult.FuncResult)
                }
                <# Sort the Ports #>
                $AllSFPRows = @(
                    $AllSFPRows | Sort-Object `
                        @{ Expression = { [int](($_.Port -replace '^.*?/','')) } }, `
                        @{ Expression = { [int]($_.VFID) } }
                )
            }else{
                if($TD_Creds.PSObject.Properties['VFID']){
                    $TD_Creds.PSObject.Properties.Remove('VFID')
                }

                $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeSFPShow -SSHFunc FOS_SSHSFPDetails

                $AllSFPRows += @($FunctionResult.FuncResult)
            }

            $mapSFPDetails = @{ 
                IsVirtualFabricPort = 'IsVirtualFabricPort'
                VFIDDisplay     = 'VFIDDisplay'
                Port            = 'Port'
                SFPUsed         = 'SFPUsed'
                Media           = 'Media'
                SFPTyp          = 'SFPTyp'
                Vendor          = 'Vendor'
                SerialNo        = 'SerialNo'
                SpeedRange      = 'SpeedRange'
                Temperature     = 'Temperature'
                TempState       = 'TempState'
                RxPower         = 'RxPower'
                OpticalState    = 'OpticalState'
                TxPower         = 'TxPower'
                Voltage         = 'Voltage'
                Wavelength      = 'Wavelength'
                PowerOnTime     = 'PowerOnTime'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.SANSFPDetailsRows -Source $AllSFPRows -IdProperty 'RowID' -Map $mapSFPDetails

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        $UCVMMain.SelectedView = "SANSFPDetails"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeSFPShow done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_SecureCheck.add_click({
        #$TD_GB_SearchFilter.Visibility = "visible"
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc GET-BrocadeSecureCheck -SSHFunc $null
            # Get the function's return value
            $dev = $FunctionResult.DeviceIdent
            $SecureResult = $FunctionResult.FuncResult

            $dev.DeviceTitle = "SecureCheck for - $($dev.Label)"

            $OptionalProperties = @(
                'SSHHostKeyAlgorithms'
                'SSHPublicKeyAlgorithms'
                'RSACipher'
                'FACipher'
                'SMTPSCipher'
                'RSATLSProtocol'
                'FATLSProtocol'
                'SMTPSTLSProtocol'
                'FIPSInside'
            )

            # Check each result object individually
            foreach ($SecureRow in @($SecureResult)) {
            
                foreach ($PropertyName in $OptionalProperties) {
                
                    $Property = $SecureRow.PSObject.Properties[$PropertyName]
                
                    if ($null -eq $Property) {
                        # REST—or rather, the function—did not create this property on this object at all
                        $SecureRow | Add-Member -MemberType NoteProperty -Name $PropertyName -Value 'Not provided by REST or FOS Version'
                    }
                    elseif ($null -eq $Property.Value) {
                        # The property exists but does not contain a value
                        $Property.Value = 'Not provided by REST or FOS Version'
                    }
                }
            }

            $mapSecureCheck = @{
                #IP Filter
                IPFilterPolicyCount       = 'IPFilterPolicyCount'
                IPFilterError             = 'IPFilterError'
                # Security
                SSHCipher                 = 'SSHCipher'
                SSHKeyExchange            = 'SSHKeyExchange'
                SSHMacConfiguration       = 'SSHMacConfiguration'
                SSHHostKeyAlgorithms      = 'SSHHostKeyAlgorithms'
                SSHPublicKeyAlgorithms    = 'SSHPublicKeyAlgorithms'

                HTTPSCipherExpression     = 'HTTPSCipherExpression'
                HTTPSTLS13Cipher          = 'HTTPSTLS13Cipher'
                RADIUSCipherExpression    = 'RADIUSCipherExpression'
                LDAPCipherExpression      = 'LDAPCipherExpression'
                SYSLOGCipherExpression    = 'SYSLOGCipherExpression'
                RSACipher                 = 'RSACipher'
                FACipher                  = 'FACipher'
                SMTPSCipher               = 'SMTPSCipher'

                HTTPSTLSProtocol          = 'HTTPSTLSProtocol'
                RADIUSTLSProtocol         = 'RADIUSTLSProtocol'
                LDAPTLSProtocol           = 'LDAPTLSProtocol'
                SYSLOGTLSProtocol         = 'SYSLOGTLSProtocol'
                RSATLSProtocol            = 'RSATLSProtocol'
                FATLSProtocol             = 'FATLSProtocol'
                SMTPSTLSProtocol          = 'SMTPSTLSProtocol'

                X509ValidationMode        = 'X509ValidationMode'
                CryptoVersion             = 'CryptoVersion'
                FIPSInside                = 'FIPSInside'
                BootUpSelfTestEnabled     = 'BootUpSelfTestEnabled'

                DataSource                = 'DataSource'
                RestEndpoint              = 'RestEndpoint'
            }
            Add-MappedRows -Collection $dev.SecureCheckRows -Source $SecureResult -IdProperty 'RowID' -Map $mapSecureCheck
            $MappedSecureRow = $dev.SecureCheckRows |  Select-Object -Last 1
            $SourceSecureRow = @($SecureResult) | Select-Object -First 1
            if ($null -ne $MappedSecureRow -and $null -ne $SourceSecureRow) {
                $IPFilterPolicies = @($SourceSecureRow.IPFilterPolicies | Where-Object { $null -ne $_ })
                $MappedSecureRow | Add-Member -MemberType NoteProperty -Name IPFilterPolicies -Value ([object[]]@($SourceSecureRow.IPFilterPolicies)) -Force      
            }
            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        $UCVMMain.SelectedView = "SecureCheck"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "GET_BrocadeSecureCheck done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_UserCFG.add_click({
        #$TD_GB_SearchFilter.Visibility = "visible"
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeUserCFGOverview -SSHFunc $null
            # Get the function's return value
            $dev = $FunctionResult.DeviceIdent
            $UserCFGResult = $FunctionResult.FuncResult

            $mapUserCFGCheck = @{
                UserName                = 'UserName'              
                Description             = 'Description'           
                IsEnabled               = 'IsEnabled'             
                UsesDefaultPassword     = 'UsesDefaultPassword'   
                PasswordChangeEnforced  = 'PasswordChangeEnforced'
                IsLocked                = 'IsLocked'              
                HomeVirtualFabric       = 'HomeVirtualFabric'     
                VirtualFabricRoles      = 'VirtualFabricRoles'    
                VirtualFabricRolesText  = 'VirtualFabricRolesText'
                ChassisAccessRole       = 'ChassisAccessRole'     
                AccessStartTime         = 'AccessStartTime'       
                AccessEndTime           = 'AccessEndTime'         
                AuthTokenPresent        = 'AuthTokenPresent'
                CreationTime            = 'CreationTime'      
                RawData                 = 'RawData'                            
            }
            Add-MappedRows -Collection $dev.UserCFGCheckRows -Source $UserCFGResult -IdProperty 'RowID' -Map $mapUserCFGCheck

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        $UCVMMain.SelectedView = "UserCFGCheck"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeUserCFG done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_PWCFG.add_click({
    #$TD_GB_SearchFilter.Visibility = "visible"
    try {
        # Get all Device Cred and count them 
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource | Where-Object { $_.DeviceTyp -like '*SAN*' }
        # Retrieve the DataContext of the Brocade UserControl.
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { 
            Write-Host 'DataContext ist NULL!' -ForegroundColor Red
            return
        }

        $UCVMMain = $UCDataContext.Main

        # Remove the previous device view.
        $UCVMMain.DeviceToggles.Clear()

        # The order will later correspond to the order in the DataGrid.
        $mapPWCFGCheck = [ordered]@{
            HashType                   = 'HashType'
            ManualHashEnabled          = 'ManualHashEnabled'
            MinimumLength              = 'MinimumLength'
            CharacterSet               = 'CharacterSet'
            UserNameAllowed            = 'UserNameAllowed'

            MinimumLowerCaseCharacters = 'MinimumLowerCaseCharacters'
            MinimumUpperCaseCharacters = 'MinimumUpperCaseCharacters'
            MinimumNumericCharacters   = 'MinimumNumericCharacters'
            MinimumSpecialCharacters   = 'MinimumSpecialCharacters'

            PastPasswordHistory        = 'PastPasswordHistory'
            MinimumPasswordAge         = 'MinimumPasswordAge'
            MaximumPasswordAge         = 'MaximumPasswordAge'
            WarnOnExpire               = 'WarnOnExpire'

            LockOutThreshold           = 'LockOutThreshold'
            LockOutDuration            = 'LockOutDuration'
            AdminLockOutEnabled        = 'AdminLockOutEnabled'

            RepeatCharacterLimit       = 'RepeatCharacterLimit'
            SequenceCharacterLimit     = 'SequenceCharacterLimit'
            ReverseUserNameAllowed     = 'ReverseUserNameAllowed'
            MinimumDifference          = 'MinimumDifference'

            PasswordConfigChanged      = 'PasswordConfigChanged'
            DataSource                 = 'DataSource'
            CreationTime               = 'CreationTime'
        }

        foreach ($TD_Creds in $TD_Credentials) {

            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadePWCFG -SSHFunc $null

            $deviceIdent = $FunctionResult['DeviceIdent']
            $funcResult  = $FunctionResult['FuncResult']

            # New-DeviceBlock currently returns FuncResult as an array.
            # For the static password policy, we need exactly
            # a single result object.
            if ($funcResult -is [object[]]) {
                $funcResult = @($funcResult | Where-Object {$null -ne $_ -and $_.PSObject.Properties.Count -gt 0 }) | Select-Object -First 1
            }

            # Do not display the REST error object as a password policy.
            $IsRestError = $null -ne $funcResult -and $funcResult.PSObject.Properties['Success'] -and -not [bool]$funcResult.Success

            if ($IsRestError) {
                SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadePWCFG failed for $($TD_Creds.IPAddress): $($funcResult.Error)" -TD_ToolMSGType Error -TD_Shown yes
                continue
            }

            if ($null -eq $funcResult) {
                SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadePWCFG returned no data for $($TD_Creds.IPAddress)." -TD_ToolMSGType Warning -TD_Shown yes
                continue
            }

            # Generate key/value rows from the static object.
            Add-MappedKeyValueRows -Collection $deviceIdent.PWCFGCheckRows -Source $funcResult -Map $mapPWCFGCheck

            $UCVMMain.DeviceToggles.Add($deviceIdent)
        }
        $UCVMMain.SelectedView = 'PWCFGCheck'
    }
    finally {
        SST_ToolMessageCollector -TD_ToolMSGCollector 'Get-BrocadePWCFG done' -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_ZoneDetailsShow.add_click({
    $TD_GB_SearchFilter.Visibility = "visible"

    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){

            <# VFID Check / Zone Rows sammeln #>
            $AllZoneRows = @()
            $FunctionResult = $null
            $VFIDs = @()
            if($TD_Creds.SVCorVF -like "*vFabric*"){
                $VFIDs = @(Get-BrocadeVFIDsFromDB -Device $TD_Creds)
            }
            if($VFIDs.Count -gt 0){
            
                foreach($VFID in $VFIDs){
                
                    $TD_Creds | Add-Member -NotePropertyName VFID -NotePropertyValue $VFID -Force
                
                    $TmpResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeEffectiveZoneShow -SSHFunc FOS_SSHZoneDetails
                
                    if(!($FunctionResult)){
                        $FunctionResult = $TmpResult
                    }
                
                    $AllZoneRows += @($TmpResult.FuncResult)
                }
            }else{
                if($TD_Creds.PSObject.Properties['VFID']){
                    $TD_Creds.PSObject.Properties.Remove('VFID')
                }
            
                $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeEffectiveZoneShow -SSHFunc FOS_SSHZoneDetails
            
                $AllZoneRows += @($FunctionResult.FuncResult)
            }
            $mapZoneDetails = @{ 
                VFIDDisplay = 'VFIDDisplay'
                ZoneGroup   = 'ZoneGroup'
                ZoneName    = 'ZoneName'
                ZoneType    = 'ZoneTypeDisplay'
                MemberRole  = 'MemberRole'
                WWPN        = 'WWPN'
                Alias       = 'Alias'
                Member      = 'Member'
            }

            Add-MappedRows -Collection $FunctionResult.DeviceIdent.SANZoneDetailsRows -Source $AllZoneRows -IdProperty 'RowID' -Map $mapZoneDetails
            <# for Grouping in DG #>
            $ZoneView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($FunctionResult.DeviceIdent.SANZoneDetailsRows)
            $ZoneView.GroupDescriptions.Clear()
            $ZoneView.GroupDescriptions.Add( (New-Object System.Windows.Data.PropertyGroupDescription("ZoneGroup")) ) | Out-Null
            $ZoneView.Refresh()
            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        $UCVMMain.SelectedView = "SANZoneDetails"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeEffectiveZoneShow done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_PortLicenseShow.add_click({
    $TD_GB_SearchFilter.Visibility = "Collapsed"

    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){

            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeLicenseOverview -SSHFunc FOS_SSHPortLicenseShowInfo
            # Links = Propertyname im PSCustomObject (das bindet dein XAML)
            # Rechts = Propertyname im Source-Objekt
            $dev = $FunctionResult.DeviceIdent
            $License = $FunctionResult.FuncResult
            $dev.DeviceTitle = "LicenseInfo for - $($dev.Label)"

            $LicenseText = @(
                "License ID     : $($License.LicenseID)"
                "License Count  : $($License.LicenseCount)"
                "Licensed Ports : $($License.LicensedPorts)"
                "Reserved Ports : $($License.ReservedPorts)"
                "Free Ports     : $($License.FreePorts)"
                ""
            )

            $Counter = 0
            foreach($Lic in @($License.Licenses)){
                $Counter++
            
                $LicenseText += "License $Counter :"
                $LicenseText += "-------------------------------------------------------------"
                $LicenseText += "License serial number : $($Lic.LicenseName)"
            
                if($Lic.FeatureString){ $LicenseText += "License features : $($Lic.FeatureString)" }
                if($Lic.GenerationDate){ $LicenseText += "Generation date : $($Lic.GenerationDate)" }
                if($Lic.ExpirationDate){ $LicenseText += "Expiry date : $($Lic.ExpirationDate)" }
                if($Lic.LicenseFormat){ $LicenseText += "License format : $($Lic.LicenseFormat)" }
                $LicenseText += ""
            }

            $dev.LicenseInfoText = $LicenseText -join "`n"
            $UCVMMain.DeviceToggles.Add($dev)
        }
        <#one for each view is fine do need to be inside the foreach #>
        $UCVMMain.SelectedView = "LicenseInfo"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeLicenseOverview done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_FOS_SensorShow.add_click({
    $TD_GB_SearchFilter.Visibility = "Collapsed"

    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){

            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeSensorOverview -SSHFunc FOS_SSHSensorShow
            # Links = Propertyname im PSCustomObject (das bindet dein XAML)
            # Rechts = Propertyname im Source-Objekt
            $Sensor = $FunctionResult.FuncResult
            $dev = $FunctionResult.DeviceIdent
            $Deg = [char]0x00B0

            $dev.SensorShowTitle = "Sensorinfo for - $($dev.Label)"

            $SensorText = @(
                "Overall Health : $($Sensor.OverallHealth)"
                ""
                "Temperature"
                "-------------------------------------------------------------"
                "  Average Temp : $($Sensor.TemperatureAverage) $Deg`C"
                "  Max Temp     : $($Sensor.TemperatureMax) $Deg`C"
                "  Min Temp     : $($Sensor.TemperatureMin) $Deg`C"
                "  Temp Health  : $($Sensor.TemperatureHealth)"
                "  Hot Sensors  : $($Sensor.HotSensors)"
                ""
                "Fans"
                "-------------------------------------------------------------"
                "  Fan Count    : $($Sensor.FanCount)"
                "  Failed Fans  : $($Sensor.FailedFans)"
            )

            foreach($Fan in @($Sensor.Fans)){
                $SensorText += ""
                $SensorText += "  $($Fan.Fan)"
                $SensorText += "    State              : $($Fan.State)"
                $SensorText += "    Speed RPM          : $($Fan.SpeedRPM)"
                $SensorText += "    Airflow            : $($Fan.Airflow)"
                $SensorText += "    Time Awake Hours   : $($Fan.TimeAwakeHours)"
            }

            $SensorText += ""
            $SensorText += "Power Supplies"
            $SensorText += "-------------------------------------------------------------"
            $SensorText += "  PSU Count            : $($Sensor.PSUCount)"
            $SensorText += "  Failed PSUs          : $($Sensor.FailedPowerSupplies)"

            foreach($PSU in @($Sensor.PowerSupplies)){
                $SensorText += ""
                $SensorText += "  $($PSU.PowerSupply)"
                $SensorText += "    State              : $($PSU.State)"
                $SensorText += "    Severity           : $($PSU.Severity)"
                $SensorText += "    Power Source       : $($PSU.PowerSource)"
                $SensorText += "    Input Voltage      : $($PSU.InputVoltage)"
                $SensorText += "    Power Usage        : $($PSU.PowerUsage)"
                $SensorText += "    Airflow            : $($PSU.Airflow)"
                $SensorText += "    Serial Number      : $($PSU.SerialNumber)"
                $SensorText += "    Part Number        : $($PSU.PartNumber)"
            }

            $dev.SensorShowText = $SensorText -join "`n"

            $UCVMMain.DeviceToggles.Add($dev)
        }
        <#one for each view is fine do need to be inside the foreach #>
        $UCVMMain.SelectedView = "SensorInfo"
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeSensorOverview done" -TD_ToolMSGType Message -TD_Shown yes
    }
})  
$TD_BTN_FOS_AuditDump.add_click({
    $TD_GB_SearchFilter.Visibility = "visible"
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*SAN*" }

        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_BRSAN.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc GET-BrocadeAuditInfo -SSHFunc $null
            # Get the function's return value
            $dev = $FunctionResult.DeviceIdent
            $UserCFGResult = $FunctionResult.FuncResult

            $mapUserCFGCheck = @{
                          
            }

        }
        
    }finally{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Get-BrocadeUserCFG done" -TD_ToolMSGType Message -TD_Shown yes
    }
})
#endregion
#region IBM Power
$TD_BTN_PWR_HMCInfo.add_click({
    $TD_GBPWRHMCInfo.Visibility = "Visible";$TD_GB_SearchFilterPWR.Visibility="Collapsed"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare the function" -PercentComplete 10
        $TD_GBPWRLPARSum,$TD_GBPWRManagSysInfo | ForEach-Object {$_.Visibility = "Collapsed"}
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource | Where-Object { $_.DeviceTyp -like "*PowerHMC*" }
        $UCDataContext = $TD_UserControl_PWR.DataContext
        if (-not $UCDataContext) { [System.Windows.MessageBox]::Show("DataContext ist NULL!") | Out-Null; return }
        $UCVMMain = $UCDataContext.Main

        $UCVMMain.DeviceToggles.Clear()
        Write-ProgressBar -ProgressBar $PB -Activity "Call REST HMCConsole, pls wait. This may take a while." -PercentComplete 25
        foreach($TD_Creds in $TD_Credentials){
            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCConsole

            #if (-not $FunctionResult.DeviceIdent.HmcRows) {
            #    $FunctionResult.DeviceIdent | Add-Member -NotePropertyName HmcRows `
            #        -NotePropertyValue (New-Object System.Collections.ObjectModel.ObservableCollection[object]) -Force
            #}

            $mapHMC = @{
                HmcName            = 'HMCName'
                MachineType        = 'HMCMTM'
                Model              = 'Model'
                SerialNumber       = 'SerialNumber'
                BIOS               = 'BIOS'
                DisplayVersion     = 'DisplayVersion'
                IFix               = 'IFix'
                PrimaryIP          = 'PrimaryIP'
                IPsAll             = 'IPsAll'
                ManagedSystemCount = 'ManagedSystemCount'
                ManagedSystemUuids = 'ManagedSystemUuids'
                UUID               = 'UUID'
                Url                = 'Url'
            }

            Add-MappedRows -Collection $FunctionResult.DeviceIdent.HmcRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapHMC

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare GUI" -PercentComplete 60
        $UCVMMain.SelectedView = "HMC"
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
$TD_BTN_PWR_ManagedSystemInfo.add_click({
    $TD_GBPWRManagSysInfo.Visibility = "Visible";$TD_GB_SearchFilterPWR.Visibility="Collapsed"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare the function" -PercentComplete 10
        $TD_GBPWRHMCInfo,$TD_GBPWRLPARSum | ForEach-Object {$_.Visibility = "Collapsed"}
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource | Where-Object { $_.DeviceTyp -like "*PowerHMC*" }

        $UCDataContext = $TD_UserControl_PWR.DataContext
        if (-not $UCDataContext) { [System.Windows.MessageBox]::Show("DataContext ist NULL!") | Out-Null; return }
        $UCVMMain = $UCDataContext.Main

        $UCVMMain.DeviceToggles.Clear()
        Write-ProgressBar -ProgressBar $PB -Activity "Call REST ManagedSystems, pls wait. This may take a while!" -PercentComplete 25
        foreach($TD_Creds in $TD_Credentials){
            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCManagedSystems

            # Falls Rows-Collection noch nicht existiert
            #if (-not $FunctionResult.DeviceIdent.ManagedSystemRows) {
            #    $FunctionResult.DeviceIdent | Add-Member -NotePropertyName ManagedSystemRows `
            #        -NotePropertyValue (New-Object System.Collections.ObjectModel.ObservableCollection[object]) -Force
            #}

            $mapMS = @{
                SystemName       = 'SystemName'
                State            = 'State'
                SerialNumber     = 'SerialNumber'
                MachineTypeModel = 'MachineTypeModel'
                ECNumber         = 'ECNumber'
                ActivatedLevel   = 'ActivatedLevel'
                UUID             = 'UUID'
                Url              = 'Url'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.ManagedSystemRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapMS
            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }

        $UCVMMain.SelectedView = "ManagedSystem"
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare GUI" -PercentComplete 60
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
$TD_BTN_PWR_LparSummary.add_click({
    $TD_GBPWRLPARSum.Visibility = "Visible"; $TD_GB_SearchFilterPWR.Visibility="visible"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare the function" -PercentComplete 10
        $TD_GBPWRHMCInfo,$TD_GBPWRManagSysInfo | ForEach-Object {$_.Visibility = "Collapsed"}
        
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource | Where-Object { $_.DeviceTyp -like "*PowerHMC*" }
        
        $UCDataContext = $TD_UserControl_PWR.DataContext
        if (-not $UCDataContext) { [System.Windows.MessageBox]::Show("DataContext ist NULL!") | Out-Null; return }
        $UCVMMain = $UCDataContext.Main

        $UCVMMain.DeviceToggles.Clear()
        Write-ProgressBar -ProgressBar $PB -Activity "Call LogicalPartitions, pls wait. This may take a while." -PercentComplete 25
        foreach($TD_Creds in $TD_Credentials){
            $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCLogicalPartitions

            $mapLPAR = @{
                ManagedSystemName       = 'ManagedSystemName'
                ManagedSystemMTMS       = 'ManagedSystemMTMS'
                ManagedSystemSerial     = 'ManagedSystemSerial'
                ManagedSystemUUID       = 'ManagedSystemUUID'
            
                LparName                = 'LparName'
                LparUUID                = 'LparUUID'
                PartitionId             = 'PartitionId'
                PartitionRole           = 'PartitionRole'
            
                State                   = 'State'
                Environment             = 'Environment'
                OsVersion               = 'OsVersion'
                RmcIp                   = 'RmcIp'
                RmcState                = 'RmcState'
            
                DefaultProfile          = 'DefaultProfile'
                CurrentProfileHref      = 'CurrentProfileHref'
                CurrentProcessingUnits  = 'CurrentProcessingUnits'
                CurrentMemoryMB         = 'CurrentMemoryMB'
            }

            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LparRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapLPAR

            
            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare GUI" -PercentComplete 60
        
        $UCVMMain.SelectedView = "LPARs"
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
$TD_BTN_PWR_ShowAll.add_click({
    $PB = New-ProgressBar

    try {
        $DBName = $TD_TB_CustomerInfoName.Text
        $TD_Credentials = @($TD_DG_KnownDeviceList.ItemsSource | Where-Object { $_.DeviceTyp -like '*PowerHMC*' })
        $UCDataContext = $TD_UserControl_PWR.DataContext
        if (-not $UCDataContext) {
            [System.Windows.MessageBox]::Show('DataContext ist NULL!') | Out-Null
            return
        }
        $UCVMMain = $UCDataContext.Main
        $UCVMMain.DeviceToggles.Clear()
        Write-ProgressBar -ProgressBar $PB -Activity 'Prepare the collection' -PercentComplete 10
        # ========================================================
        # HMC
        # ========================================================
        try {
            [array]$DBPowerHMC = SST_CustomerPWRDBReadTable -SST_InfoType 'PowerHMC' -SST_Customer $DBName

            if (@($DBPowerHMC).Count -eq 0) {
                foreach ($TD_Creds in $TD_Credentials) {
                    $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCConsole

                    $mapHMC = @{
                        HmcName            = 'HMCName'
                        MachineType        = 'HMCMTM'
                        Model              = 'Model'
                        SerialNumber       = 'SerialNumber'
                        BIOS               = 'BIOS'
                        DisplayVersion     = 'DisplayVersion'
                        IFix               = 'IFix'
                        PrimaryIP          = 'PrimaryIP'
                        IPsAll             = 'IPsAll'
                        ManagedSystemCount = 'ManagedSystemCount'
                        ManagedSystemUuids = 'ManagedSystemUuids'
                        UUID               = 'UUID'
                        Url                = 'Url'
                    }

                    Add-MappedRows -Collection $FunctionResult.DeviceIdent.HmcRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapHMC

                    $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
                }

                # Clear the database view so that no old database data remains
                $TD_IC_IBMPowerHMCDBView.ItemsSource = $null
            }
            else {
                $TD_IC_IBMPowerHMCDBView.ItemsSource = $DBPowerHMC
            }
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "PWR_ShowAll HMC: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        }

        Write-ProgressBar -ProgressBar $PB -Activity 'HMC RESTHMCConsole done' -PercentComplete 25

        # ========================================================
        # Managed Systems
        # ========================================================
        try {
            [array]$DBPowerSysSum = SST_CustomerPWRDBReadTable -SST_InfoType 'PowerSysSummary' -SST_Customer $DBName

            if (@($DBPowerSysSum).Count -eq 0) {
                foreach ($TD_Creds in $TD_Credentials) {
                    $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCManagedSystems

                    $mapMS = @{
                        SystemName       = 'SystemName'
                        State            = 'State'
                        SerialNumber     = 'SerialNumber'
                        MachineTypeModel = 'MachineTypeModel'
                        ECNumber         = 'ECNumber'
                        ActivatedLevel   = 'ActivatedLevel'
                        UUID             = 'UUID'
                        Url              = 'Url'
                    }

                    Add-MappedRows -Collection $FunctionResult.DeviceIdent.ManagedSystemRows -Source $FunctionResult.FuncResult -IdProperty 'RowID' -Map $mapMS
                    $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
                }
                $TD_IC_IBMPowerSysDBView.ItemsSource = $null
            }
            else {
                $TD_IC_IBMPowerSysDBView.ItemsSource = $DBPowerSysSum
            }
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "PWR_ShowAll ManagedSystem: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        }

        Write-ProgressBar -ProgressBar $PB -Activity 'REST ManagedSystems done' -PercentComplete 55

        # ========================================================
        # LPARs
        # ========================================================
        try {
            [array]$DBPowerLPAR = SST_CustomerPWRDBReadTable `
                -SST_InfoType 'LPARSummary' `
                -SST_Customer $DBName
        
            $mapLPAR = @{
                ManagedSystemName      = 'ManagedSystemName'
                ManagedSystemMTMS      = 'ManagedSystemMTMS'
                ManagedSystemSerial    = 'ManagedSystemSerial'
                ManagedSystemUUID      = 'ManagedSystemUUID'
            
                LparName               = 'LparName'
                LparUUID               = 'LparUUID'
                PartitionId            = 'PartitionId'
                PartitionRole          = 'PartitionRole'
            
                State                  = 'State'
                Environment            = 'Environment'
                OsVersion              = 'OsVersion'
                RmcIp                  = 'RmcIp'
                RmcState               = 'RmcState'
            
                DefaultProfile         = 'DefaultProfile'
                CurrentProfileHref     = 'CurrentProfileHref'
                CurrentProcessingUnits = 'CurrentProcessingUnits'
                CurrentMemoryMB        = 'CurrentMemoryMB'
            }
        
            if (@($DBPowerLPAR).Count -eq 0) {
            
                # ----------------------------------------------------
                # No current database data available:
                # Use REST/MVVM view
                # ----------------------------------------------------
                $TD_DG_IBMPowerLPARDBView.ItemsSource = $null
                $TD_DG_IBMPowerLPARDBView.Visibility = 'Collapsed'
            
                $TD_IC_IBMPowerLPARRestView.Visibility = 'Visible'
            
                foreach ($TD_Creds in $TD_Credentials) {
                    $FunctionResult = New-DeviceBlock `
                        -Device $TD_Creds `
                        -ExportPath $TD_TB_ExportPath.Text `
                        -RESTFunc HMC_RESTHMCLogicalPartitions
                
                    if (
                        $null -eq $FunctionResult -or
                        $null -eq $FunctionResult.DeviceIdent
                    ) {
                        continue
                    }
                
                    Add-MappedRows `
                        -Collection $FunctionResult.DeviceIdent.LparRows `
                        -Source $FunctionResult.FuncResult `
                        -IdProperty 'RowID' `
                        -Map $mapLPAR
                
                    $UCVMMain.DeviceToggles.Add(
                        $FunctionResult.DeviceIdent
                    )
                }
            }
            else {
            
                # ----------------------------------------------------
                # Current DB data available:
                # Use the DB DataGrid directly
                # ----------------------------------------------------
                $TD_DG_IBMPowerLPARDBView.ItemsSource = $DBPowerLPAR
                $TD_DG_IBMPowerLPARDBView.Visibility = 'Visible'
            
                $TD_IC_IBMPowerLPARRestView.Visibility = 'Collapsed'
            }
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "PWR_ShowAll LPARs: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        }

        Write-ProgressBar -ProgressBar $PB -Activity 'REST LogicalPartitions done' -PercentComplete 85
        # ========================================================
        # Enable all three views
        # ========================================================
        $UCVMMain.SelectedView = 'PowerShowAll'
        $TD_GBPWRHMCInfo,$TD_GBPWRManagSysInfo,$TD_GBPWRLPARSum |ForEach-Object {$_.Visibility = 'Visible'}
        $TD_GB_SelectAllSTOCB.Visibility ='Collapsed'
        Write-ProgressBar -ProgressBar $PB -Activity 'Power information completed' -PercentComplete 100
    }
    finally {
        Close-ProgressBar -ProgressBar $PB
    }
})
#endregion
#region IBM Tape
$TD_BTN_IBM_TapeLibrary.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $TD_GB_TapeSearch.Visibility="Collapsed"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_IBMTape.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            $LibBaseInfo = $null; $LibApiVersion = $null;$LibInfo=$null
            Write-ProgressBar -ProgressBar $PB -Activity "Read baseinfo" -PercentComplete 0
            $LibBaseInfo = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'library/baseinfo'
            Write-ProgressBar -ProgressBar $PB -Activity "Baseinfo completed" -PercentComplete 25
            $LibInfo = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'library'
            Write-ProgressBar -ProgressBar $PB -Activity "Library info complete" -PercentComplete 50
            $LibApiVersion = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'apiversion'
            Write-ProgressBar -ProgressBar $PB -Activity "API version completed" -PercentComplete 75
            $MergeLibObj = Merge-PSCustomObject -InputObject @($($LibBaseInfo.BaseInfo), $LibInfo)
            SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryBaseInfo" -SST_CollectedInformations $MergeLibObj
            $MergeLibObj | Export-Csv -Path "$($TD_TB_ExportPath.Text)\$($TD_Creds.ID)_LibraryBaseInfo_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation
            Write-ProgressBar -ProgressBar $PB -Activity "Database completed" -PercentComplete 80

            $FunctionResult = ReadDBandBuildDB -Device $TD_Creds -ReadDBFunc SST_CustomerLibraryDBReadTable -SST_InfoType "LibraryBaseInfo" -SST_Customer $CustomerNumber -SST_AdditionalInformation $($LibInfo.sn)
            $mapLibraryBaseInfo = @{ 
                ProductID           = 'ProductID'
                MTM                 = 'MTM'
                SerialNumber        = 'SerialNumber'
                Status	            = 'Status'
                BaseFWRevision      = 'BaseFWRevision'
                LicensedCapacity    = 'LicensedCapacity'
                TotalCapacity       = 'TotalCapacity'
                AssignedCartridges  = 'AssignedCartridges'
                ExpansionFWRevision = 'ExpansionFWRevision'
                RoboticHWRevision   = 'RoboticHWRevision'
                RoboticFWRevision   = 'RoboticFWRevision'
                RoboticSerialNumber = 'RoboticSerialNumber'
                NoOfModules         = 'NoOfModules'
                SecureCommunications= 'SecureCommunications'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LibraryBaseRows -Source $FunctionResult.FuncResult -IdProperty 'SerialNumberMTM' -Map $mapLibraryBaseInfo

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        Write-ProgressBar -ProgressBar $PB -Activity "Tape Library scan completed" -PercentComplete 90
        $UCVMMain.SelectedView = "TapeLibraryShow"
    }catch{
        SST_ToolMessageCollector -TD_ToolMSGCollector "TapeLibraryShow. $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }

})
$TD_BTN_IBM_TapeInventoryDrives.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $TD_GB_TapeSearch.Visibility="visible"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_IBMTape.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            Write-ProgressBar -ProgressBar $PB -Activity "Baseinfo completed" -PercentComplete 25
            $LibInventoryDrives = $null
            $LibInventoryDrives = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'library/inventory'
            try {
                $LibrarySerialNumberMTM = SST_CustomerLibraryDBReadTable -SST_InfoType "GetLibrarySerialNumberMTM" -SST_Customer $($TD_TB_CustomerInfoName.Text) -SST_NeededInformations $($TD_Creds.TapeWWNN)
                SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryInventoryDrives" -SST_CollectedInformations $($LibInventoryDrives.Drives) -SST_NeededInformations $LibrarySerialNumberMTM
                $LibInventoryDrives | Export-Csv -Path "$($TD_TB_ExportPath.Text)\$($TD_Creds.ID)_LibraryInventoryDrives_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation
                Write-ProgressBar -ProgressBar $PB -Activity "Database completed" -PercentComplete 75
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Verbose $_.Exception.Message
            }
            $FunctionResult = ReadDBandBuildDB -Device $TD_Creds -ReadDBFunc SST_CustomerLibraryDBReadTable -SST_InfoType "LibraryInventoryDrives" -SST_Customer $CustomerNumber -SST_AdditionalInformation $LibrarySerialNumberMTM

            $mapLibraryInventoryDrives = @{ 
                PhysicalNumber  = 'PhysicalNumber'
                LogicalNumber   = 'LogicalNumber'
                Module          = 'Module'
                LogicalLibrary  = 'LogicalLibrary'
                Barcode         = 'Barcode'
                Vendor          = 'Vendor'
                Product         = 'Product'
                FWRevision      = 'FWRevision'
                SerialNumber    = 'SerialNumber'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LibraryInventoryDrivesRows -Source $FunctionResult.FuncResult -IdProperty 'SerialNumberMTM' -Map $mapLibraryInventoryDrives

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
            Write-ProgressBar -ProgressBar $PB -Activity "Tape Library scan completed" -PercentComplete 90
        }
        $UCVMMain.SelectedView = "LibraryInventoryDrivesShow"
    }catch{
        SST_ToolMessageCollector -TD_ToolMSGCollector "LibraryInventoryDrivesShow: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
$TD_BTN_IBM_TapeInventorySlots.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $TD_GB_TapeSearch.Visibility="visible"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_IBMTape.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            Write-ProgressBar -ProgressBar $PB -Activity "Baseinfo completed" -PercentComplete 25
            $LibInventorySlots = $null
            $LibInventorySlots = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'logicalLibrary/information'    
            try {
                $LibrarySerialNumberMTM = SST_CustomerLibraryDBReadTable -SST_InfoType "GetLibrarySerialNumberMTM" -SST_Customer $($TD_TB_CustomerInfoName.Text) -SST_NeededInformations $($TD_Creds.TapeWWNN)
                SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryInventorySlots" -SST_CollectedInformations $($LibInventorySlots.Slots) -SST_NeededInformations $LibrarySerialNumberMTM
                $LibInventorySlots | Export-Csv -Path "$($TD_TB_ExportPath.Text)\$($TD_Creds.ID)_LibraryInventorySlots_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation
                Write-ProgressBar -ProgressBar $PB -Activity "Database completed" -PercentComplete 75
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Verbose $_.Exception.Message
            }

            $FunctionResult = ReadDBandBuildDB -Device $TD_Creds -ReadDBFunc SST_CustomerLibraryDBReadTable -SST_InfoType "LibraryInventorySlots" -SST_Customer $CustomerNumber -SST_AdditionalInformation $LibrarySerialNumberMTM

            $mapLibraryInventorySlots = @{ 
                PhysicalNumber  = 'PhysicalNumber'
                LogicalNumber   = 'LogicalNumber'
                Module          = 'Module'
                LogicalLibrary  = 'LogicalLibrary'
                Mailslot        = 'Mailslot'
                Cartridge       = 'Cartridge'
                CartridgeType   = 'CartridgeType'
                CartridgeSubType    = 'CartridgeSubType'
                CartridgeGeneration = 'CartridgeGeneration'
                Access          = 'Access'
                Blocked         = 'Blocked'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LibraryInventorySlotsRows -Source $FunctionResult.FuncResult -IdProperty 'SerialNumberMTM' -Map $mapLibraryInventorySlots

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
            rite-ProgressBar -ProgressBar $PB -Activity "Tape Library scan completed" -PercentComplete 90
        }
        $UCVMMain.SelectedView = "LibraryInventorySlotsShow"
    }catch{
        SST_ToolMessageCollector -TD_ToolMSGCollector "TapeLibraryShow. $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
$TD_BTN_IBM_TapeDrive.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $TD_GB_TapeSearch.Visibility="visible"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_IBMTape.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            Write-ProgressBar -ProgressBar $PB -Activity "Read baseinfo" -PercentComplete 0
            $LibDrives = $null; $LibDriveInfo=$null
            Write-ProgressBar -ProgressBar $PB -Activity "Baseinfo completed" -PercentComplete 25
            $LibDrives = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'drive'
            Write-ProgressBar -ProgressBar $PB -Activity "drive info complete" -PercentComplete 50
            $LibDriveInfo = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'drive/information'
            try {
                #need a better solution
                $MergeLibObj = foreach ($LibDrive in $LibDrives) {
                    $match = $LibDriveInfo | Where-Object { $_.SerialNumber -eq $LibDrive.sn } | Select-Object -First 1
                
                    [PSCustomObject]@{
                        DriveLocation          = $LibDrive.location
                        DriveMediaType         = $LibDrive.mediaType
                        DriveState             = $LibDrive.state
                        DriveMTM               = $LibDrive.mtm
                        DriveLogicalLibrary    = $LibDrive.logicalLibrary
                        DriveUse               = $LibDrive.use
                        DriveFirmware          = $LibDrive.firmware
                        DriveEncryption        = $LibDrive.encryption
                        DriveMounts            = $LibDrive.mounts
                        DriveBarcode           = $LibDrive.barcode
                        DriveWWNN              = $LibDrive.wwnn
                        DriveElementAddress    = $LibDrive.elementAddress
                    
                        InfoLogicalNumber      = $match.LogicalNumber
                        InfoPhysicalNumber     = $match.PhysicalNumber
                        InfoModule             = $match.Module
                        InfoLogicalLibraryID   = $match.LogicalLibrary
                        InfoGeneration         = $match.Generation
                        InfoCartridge          = $match.Cartridge
                        InfoBarcode            = $match.Barcode
                        InfoVendor             = $match.Vendor
                        InfoSerialNumber       = $match.SerialNumber
                        InfoWWNodeName         = $match.WWNodeName
                        InfoInterface          = $match.Interface
                        InfoMFGSerialNumber    = $match.MFGSerialNumber
                        InfoErrorState         = $match.ErrorState
                        InfoPower              = $match.Power
                        InfoPresence           = $match.Presence
                        InfoADTMode            = $match.ADTMode
                    }
                }
                $LibrarySerialNumberMTM = SST_CustomerLibraryDBReadTable -SST_InfoType "GetLibrarySerialNumberMTM" -SST_Customer $($TD_TB_CustomerInfoName.Text) -SST_NeededInformations $($TD_Creds.TapeWWNN)
                SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryDrive" -SST_CollectedInformations $MergeLibObj -SST_NeededInformations $LibrarySerialNumberMTM
                $MergeLibObj | Export-Csv -Path "$($TD_TB_ExportPath.Text)\$($TD_Creds.ID)_LibraryDrive_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation
                Write-ProgressBar -ProgressBar $PB -Activity "Database completed" -PercentComplete 75
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Verbose $_.Exception.Message
            }

            $FunctionResult = ReadDBandBuildDB -Device $TD_Creds -ReadDBFunc SST_CustomerLibraryDBReadTable -SST_InfoType "LibraryDrive" -SST_Customer $CustomerNumber -SST_AdditionalInformation $LibrarySerialNumberMTM

            $mapLibraryDrive = @{ 
                Location        = 'Location'
                SerialNumber    = 'SerialNumber'
                MFGSerialNumber = 'MFGSerialNumber'
                MediaType       = 'MediaType'
                State           = 'State'
                LogicalLibrary  = 'LogicalLibrary'
                Firmware        = 'Firmware'
                Encryption      = 'Encryption'
                Mounts          = 'Mounts'
                Barcode         = 'Barcode'
                WWNN            = 'WWNN'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LibraryDriveRows -Source $FunctionResult.FuncResult -IdProperty 'SerialNumberMTM' -Map $mapLibraryDrive

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
            Write-ProgressBar -ProgressBar $PB -Activity "Tape Library scan completed" -PercentComplete 90
        }
        $UCVMMain.SelectedView = "LibraryDriveShow"
    }catch{
        SST_ToolMessageCollector -TD_ToolMSGCollector "TapeLibraryShow. $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
<# not needed at first time but maybe later#>
#$TD_BTN_IBM_TapeLogicalLib.add_click({
#    <#Get all Device Cred and count them #>
#    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
#    foreach($TD_Creds in $TD_Credentials){
#        $LogicalLibraryInfo = $null
#        $LogicalLibraryInfo = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'logicalLibrary/information'    
#        try {
#            $LibrarySerialNumberMTM = SST_CustomerLibraryDBReadTable -SST_InfoType "GetLibrarySerialNumberMTM" -SST_Customer $($TD_TB_CustomerInfoName.Text) -SST_NeededInformations $($TD_Creds.TapeWWNN)
#            SST_CustomerLibraryDBInsertTable -SST_InfoType "LogicalLibraryInfo" -SST_CollectedInformations $LogicalLibraryInfo -SST_NeededInformations $LibrarySerialNumberMTM
#        }
#        catch {
#            <#Do this if a terminating exception happens#>
#            Write-Verbose $_.Exception.Message
#        }
#    }
#})
$TD_BTN_IBM_TapeMediaInfo.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $TD_GB_TapeSearch.Visibility="visible"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_IBMTape.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()

        foreach($TD_Creds in $TD_Credentials){
            $LibInfo = $null
            $LibInfo = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'library/mediainfo'    
            Write-ProgressBar -ProgressBar $PB -Activity "Baseinfo completed" -PercentComplete 25
            try {
                $LibrarySerialNumberMTM = SST_CustomerLibraryDBReadTable -SST_InfoType "GetLibrarySerialNumberMTM" -SST_Customer $($TD_TB_CustomerInfoName.Text) -SST_NeededInformations $($TD_Creds.TapeWWNN)
                SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryMediaInfo" -SST_CollectedInformations $LibInfo -SST_NeededInformations $LibrarySerialNumberMTM
                $LibInfo | Export-Csv -Path "$($TD_TB_ExportPath.Text)\$($TD_Creds.ID)_LibraryMediaInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation
                Write-ProgressBar -ProgressBar $PB -Activity "Database completed" -PercentComplete 75
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Verbose $_.Exception.Message
            }

            $FunctionResult = ReadDBandBuildDB -Device $TD_Creds -ReadDBFunc SST_CustomerLibraryDBReadTable -SST_InfoType "LibraryMediaInfo" -SST_Customer $CustomerNumber -SST_AdditionalInformation $LibrarySerialNumberMTM

            $mapLibraryMediaInfo = @{ 
                Barcode         = 'Barcode'
                LocationType    = 'LocationType'
                LogicalNumber   = 'LogicalNumber'
                PhysicalNumber  = 'PhysicalNumber'
                Cleaning        = 'Cleaning'
                LogicalLibrary  = 'LogicalLibrary'
                Generation      = 'Generation'
                SubType         = 'SubType'
                Protection      = 'Protection'
                Encryption      = 'Encryption'
                NoLoads         = 'NoLoads'
                MBRead          = 'MBRead'
                MBWritten       = 'MBWritten'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LibraryMediaRows -Source $FunctionResult.FuncResult -IdProperty 'SerialNumberMTM' -Map $mapLibraryMediaInfo

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
            Write-ProgressBar -ProgressBar $PB -Activity "Tape Library scan completed" -PercentComplete 90
        }
        $UCVMMain.SelectedView = "LibraryMediaShow"
    }catch{
        SST_ToolMessageCollector -TD_ToolMSGCollector "TapeLibraryShow. $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
$TD_BTN_IBM_TapeReports.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $TD_GB_TapeSearch.Visibility="visible"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_IBMTape.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            Write-ProgressBar -ProgressBar $PB -Activity "Read baseinfo" -PercentComplete 0
            $LibraryReports = $null
            $LibraryReports = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'reports/mountHistory'  
            Write-ProgressBar -ProgressBar $PB -Activity "Baseinfo completed" -PercentComplete 35
            try {
                $LibrarySerialNumberMTM = SST_CustomerLibraryDBReadTable -SST_InfoType "GetLibrarySerialNumberMTM" -SST_Customer $($TD_TB_CustomerInfoName.Text) -SST_NeededInformations $($TD_Creds.TapeWWNN)
                SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryReports" -SST_CollectedInformations $LibraryReports -SST_NeededInformations $LibrarySerialNumberMTM
                $LibraryReports | Export-Csv -Path "$($TD_TB_ExportPath.Text)\$($TD_Creds.ID)_LibraryReports_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation
                Write-ProgressBar -ProgressBar $PB -Activity "Database completed" -PercentComplete 80
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Verbose $_.Exception.Message
            }

            $FunctionResult = ReadDBandBuildDB -Device $TD_Creds -ReadDBFunc SST_CustomerLibraryDBReadTable -SST_InfoType "LibraryReports" -SST_Customer $CustomerNumber -SST_AdditionalInformation $LibrarySerialNumberMTM

            $mapLibraryReports = @{ 
                Barcode                 = 'Barcode'
                LogicalLibrary          = 'LogicalLibrary'
                Location                = 'Location'
                MountTime	            = 'MountTime'
                UnmountTime             = 'UnmountTime'
                HostIOReads             = 'HostIOReads'
                HostIOWrites            = 'HostIOWrites'
                CompressionRate         = 'CompressionRate'
                ErrorsCorrectedWrites   = 'ErrorsCorrectedWrites'
                ErrorsUncorrectedWrites = 'ErrorsUncorrectedWrites'
                ErrorsCorrectedReads    = 'ErrorsCorrectedReads'
                ErrorsUncorrectedReads  = 'ErrorsUncorrectedReads'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LibraryReportsRows -Source $FunctionResult.FuncResult -IdProperty 'SerialNumberMTM' -Map $mapLibraryReports

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
        }
        Write-ProgressBar -ProgressBar $PB -Activity "Tape Library scan completed" -PercentComplete 90
        $UCVMMain.SelectedView = "LibraryReportsShow"
    }catch{
        SST_ToolMessageCollector -TD_ToolMSGCollector "TapeLibraryShow. $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
$TD_BTN_IBM_TapeEvents.add_click({
    $CustomerNumber = $TD_TB_CustomerInfoName.Text
    $TD_GB_TapeSearch.Visibility="visible"
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    try{
        <#Get all Device Cred and count them #>
        $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -like "*Tape"}
        <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
        $UCDataContext = $TD_UserControl_IBMTape.DataContext
        if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
        <# if there is a DataContext find th Main Part und put it into UCVMMain#>
        $UCVMMain = $UCDataContext.Main
        <# if there a something in, its better to clean it up befor we use it again #>
        $UCVMMain.DeviceToggles.Clear()
        foreach($TD_Creds in $TD_Credentials){
            Write-ProgressBar -ProgressBar $PB -Activity "Read baseinfo" -PercentComplete 0
            $LibraryEvents = $null
            $LibraryEvents = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'events'    
            Write-ProgressBar -ProgressBar $PB -Activity "Baseinfo completed" -PercentComplete 35
            try {
                $LibrarySerialNumberMTM = SST_CustomerLibraryDBReadTable -SST_InfoType "GetLibrarySerialNumberMTM" -SST_Customer $($TD_TB_CustomerInfoName.Text) -SST_NeededInformations $($TD_Creds.TapeWWNN)
                SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryEvents" -SST_CollectedInformations $LibraryEvents -SST_NeededInformations $LibrarySerialNumberMTM
                $LibraryEvents | Export-Csv -Path "$($TD_TB_ExportPath.Text)\$($TD_Creds.ID)_LibraryEvents_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation
                Write-ProgressBar -ProgressBar $PB -Activity "Database completed" -PercentComplete 70
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Verbose $_.Exception.Message
            }

            $FunctionResult = ReadDBandBuildDB -Device $TD_Creds -ReadDBFunc SST_CustomerLibraryDBReadTable -SST_InfoType "LibraryEvents" -SST_Customer $CustomerNumber -SST_AdditionalInformation $LibrarySerialNumberMTM

            $mapLibraryEvents = @{ 
                LibID       = 'LibID'
                Severity    = 'Severity'
                Type        = 'Type'
                Location    = 'Location'
                Description = 'Description'
                ErrorCode   = 'ErrorCode'
                EventTime   = 'EventTime'
            }
            Add-MappedRows -Collection $FunctionResult.DeviceIdent.LibraryEventsRows -Source $FunctionResult.FuncResult -IdProperty 'SerialNumberMTM' -Map $mapLibraryEvents 

            $UCVMMain.DeviceToggles.Add($FunctionResult.DeviceIdent)
            Write-ProgressBar -ProgressBar $PB -Activity "Tape Library scan completed" -PercentComplete 90
        }
        $UCVMMain.SelectedView = "TapeLibraryEventsShow"
    }catch{
        SST_ToolMessageCollector -TD_ToolMSGCollector "TapeLibraryShow. $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }
})
#endregion
#region LiveCharts
$TD_BTN_IBM_OpenSFPHistory.Add_Click({
    try {
        $CustomerNbr = $null

        if (
            $null -ne $TD_TB_CustomerInfoName -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$TD_TB_CustomerInfoName.Text
            )
        ) {
            $CustomerNbr = [string]$TD_TB_CustomerInfoName.Text
        }
        elseif (
            $null -ne $SST_NewDBObject -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$SST_NewDBObject.CustomerNumber
            )
        ) {
            $CustomerNbr =
                [string]$SST_NewDBObject.CustomerNumber
        }

        if (
            [string]::IsNullOrWhiteSpace($CustomerNbr) -or
            $CustomerNbr -notmatch '^\d{6}$'
        ) {
            [System.Windows.MessageBox]::Show(
                'Es wurde keine gültige sechsstellige Kundennummer gefunden.',
                'Storage SFP History',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null

            return
        }

        Show-StorageSFPHistory `
            -CustomerNbr $CustomerNbr
    }
    catch {
        Write-Host (
            "Storage SFP History konnte nicht geöffnet werden: " +
            $_.Exception.Message
        ) -ForegroundColor Red
    }
})
#endregion
#endregion
>>>>>>> Stashed changes

<# this part is needed if there are any Updates on the cred in DG #>
$TD_DG_KnownDeviceList.add_SelectionChanged({
    <# to prevent the function from being executed more than once #>
    if(!([string]::IsNullOrWhiteSpace($TD_DG_KnownDeviceList.selecteditem.IPAddress))){
        if($TD_CB_CredUpdate.IsChecked){
            $TD_DG_KnownDeviceList | ForEach-Object {
                $TD_CB_DeviceType.Text = $_.selecteditem.DeviceTyp
                #if($_.selecteditem.ConnectionTyp -eq "plink"){$TD_CB_DeviceConnectionType.Text = "Classic (UN/PW)"}else{$TD_CB_DeviceConnectionType.Text = "Secure Shell (SSH)"}
                $TD_TB_DeviceIPAddr.Text = $_.selecteditem.IPAddress
                $TD_TB_DeviceUserName.Text = $_.selecteditem.UserName
                if(($_.selecteditem.DeviceTyp -eq "Storage")-and($_.selecteditem.SVCorVF -eq "SVC")){$TD_CB_SVCorVF.IsChecked=$true}else{$TD_CB_SVCorVF.IsChecked=$false}
                if(($_.selecteditem.DeviceTyp -eq "SAN")-and($_.selecteditem.SVCorVF -eq "VF")){$TD_CB_SVCorVF.IsChecked=$true}else{$TD_CB_SVCorVF.IsChecked=$false}
                $_.selecteditem | Export-Clixml -Path $PSRootPath\ToolLog\ToolTEMP\UpdateCred.xml
            }

        }else{
            SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $TD_DG_KnownDeviceList.selecteditem.DeviceTyp -TD_Selected_DeviceConnectionType $TD_DG_KnownDeviceList.selecteditem.ConnectionTyp -TD_Selected_DeviceIPAddr $TD_DG_KnownDeviceList.selecteditem.IPAddress -TD_Selected_DeviceUserName $TD_DG_KnownDeviceList.selecteditem.UserName -TD_Selected_DevicePassword $TD_DG_KnownDeviceList.selecteditem.Password -TD_Selected_SVCorVF $TD_DG_KnownDeviceList.selecteditem.SVCorVF
        }
    }
})
#endregion

#region IBM Storage Button
SST_ToolMessageCollector -TD_ToolMSGCollector $("Begin IBM Storage Button") -TD_ToolMSGType Message -TD_Shown no

$TD_btn_IBM_Eventlog.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_lb_StorageEventLogOne,$TD_lb_StorageEventLogTwo,$TD_lb_StorageEventLogThree,$TD_lb_StorageEventLogFour,$TD_lb_StorageEventLogFive,$TD_lb_StorageEventLogSix,$TD_lb_StorageEventLogSeven,$TD_lb_StorageEventLogEight |ForEach-Object {
        if($_.items.count -gt 0){$TD_UCRefresh = $true}; $_.ItemsSource = $EmptyVar
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_IBM_EventLogShow = IBM_EventLog -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        try {
            SST_LiteDBControl -SST_InfoType "StorageEventLog" -SST_CollectedInformations $TD_IBM_EventLogShow
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
        }
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_lb_StorageEventLogOne.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 2)} { $TD_lb_StorageEventLogTwo.ItemsSource = $TD_IBM_EventLogShow }  
            {($_ -eq 3)} { $TD_lb_StorageEventLogThree.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 4)} { $TD_lb_StorageEventLogFour.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 5)} { $TD_lb_StorageEventLogFive.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 6)} { $TD_lb_StorageEventLogSix.ItemsSource = $TD_IBM_EventLogShow }  
            {($_ -eq 7)} { $TD_lb_StorageEventLogSeven.ItemsSource = $TD_IBM_EventLogShow }
            {($_ -eq 8)} { $TD_lb_StorageEventLogEight.ItemsSource = $TD_IBM_EventLogShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at EventLog, please check the prompt output first and then the log files.") -TD_ToolMSGType Error }
        }
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_StorageEventLog.Visibility="Visible" 

})

$TD_btn_IBM_CatAuditLog.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at CatAuditLog, please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown no}
        }
        $TD_CatAuditLog | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IBM_CatAuditLog_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_StorageAuditLog.Visibility="Visible" 

})

$TD_btn_IBM_HostVolumeMap.add_click({
    CheckBoxReseter
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at Host_Volume_Map, please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown no}
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
    $TD_lb_ErrorMsgHVM.Content = ""
    $TD_lb_ErrorMsgHVM.Visibility="Collapsed"
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
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at filter View for Host Volume Map, there are no or wrong Data found.") -TD_ToolMSGType Error -TD_Shown yes}
        }
        if($TD_Host_Volume_Map.Count -ne $TD_CollectVolInfo.Count){
            $TD_Host_Volume_Map = $TD_CollectVolInfo }
             
            switch ($TD_Filter_DG_Colum) {
                "Host" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.HostName -Match $filter } }
                "HostCluster" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.HostCluster -Match $filter } }
                "Volume" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.VolumeName -Match $filter } }
                "UID" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.UID -Match $filter } }
                "Capacity" { [array]$WPF_dataGrid = $TD_Host_Volume_Map | Where-Object { $_.Capacity -Match $filter } }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, there are no or wrong Data in CollectVolInfo found.") -TD_ToolMSGType Error -TD_Shown yes}
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
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at filter View for Host Volume Map, please check the the Filter or Datapath.") -TD_ToolMSGType Error -TD_Shown yes}
            }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown no
        $TD_lb_ErrorMsgHVM.Visibility="visible"
        $TD_lb_ErrorMsgHVM.Content = $_.Exception.Message
    }

})

$TD_btn_ClearFilterHVM.Add_Click({

    [int]$TD_Filter_DG = $TD_cb_ListFilterStorageHVM.Text
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {(($_.DeviceTyp -eq "Storage")-and($_.ID -eq $TD_Filter_DG))}
    $TD_lb_ErrorMsgHVM.Content = ""
    $TD_lb_ErrorMsgHVM.Visibility="Collapsed"
    
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
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at ClearFilterHVM, ID $($TD_Filter_DG) or DeviceName $($TD_Credentials.DeviceName) can not be found") -TD_ToolMSGType Error -TD_Shown yes}
        }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at ClearFilterHVM, please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error
        $TD_lb_ErrorMsgHVM.Visibility="visible"
        $TD_lb_ErrorMsgHVM.Content = $_.Exception.Message
    }
})

$TD_btn_IBM_DriveInfo.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_StorageEventLog,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")
    $TD_lb_DriveInfoOne,$TD_lb_DriveInfoTwo,$TD_lb_DriveInfoThree,$TD_lb_DriveInfoFour,$TD_lb_DriveInfoFive,$TD_lb_DriveInfoSix,$TD_lb_DriveInfoSeven,$TD_lb_DriveInfoEight  |ForEach-Object {
        $_.Visibility = "Collapsed"
    }

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_DriveInfo,$TD_dg_DriveInfoTwo,$TD_dg_DriveInfoThree,$TD_dg_DriveInfoFour,$TD_dg_DriveInfoFive,$TD_dg_DriveInfoSix,$TD_dg_DriveInfoSeven,$TD_dg_DriveInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    [Int16]$TD_DevCounter = 0
    $TD_Credentials | ForEach-Object {
        if(!($_.SVCorVF -eq "SVC")){
            $TD_DevCounter = $TD_DevCounter +1

            [array]$TD_DriveInfo = IBM_DriveInfo -TD_Line_ID $TD_DevCounter -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
            try {
                SST_LiteDBControl -SST_InfoType "StorageDrive" -SST_CollectedInformations $TD_DriveInfo
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Debug -Message $_.exception.message
                SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
            }
            try {
                SST_PRISMDBControl -SST_InfoType "StorageDrive" -SST_CollectedInformations $TD_DriveInfo
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Debug -Message $_.exception.message
                SST_ToolMessageCollector -TD_ToolMSGCollector "PRISMDB - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
            }

            switch ($TD_DevCounter) {
                {($_ -eq 1)} { $TD_IC_STODriveViewOne.ItemsSource = $TD_DriveInfo }
                {($_ -eq 2)} { $TD_IC_STODriveViewTwo.ItemsSource = $TD_DriveInfo  }
                {($_ -eq 3)} { $TD_IC_STODriveViewThree.ItemsSource = $TD_DriveInfo  }
                {($_ -eq 4)} { $TD_IC_STODriveViewFour.ItemsSource = $TD_DriveInfo }
                {($_ -eq 5)} { $TD_IC_STODriveViewFive.ItemsSource = $TD_DriveInfo }
                {($_ -eq 6)} { $TD_IC_STODriveViewix.ItemsSource = $TD_DriveInfo }
                {($_ -eq 7)} { $TD_IC_STODriveViewSeven.ItemsSource = $TD_DriveInfo }
                {($_ -eq 8)} { $TD_IC_STODriveViewEight.ItemsSource = $TD_DriveInfo }
                Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at DriveInfo DeviceID $TD_DevCounter, please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
            }

            $TD_DriveInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_DriveInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv

        }else{
            $TD_lb_DriveErrorInfo.Visibility = "Visible"; $TD_lb_DriveErrorInfo.Content = "An SVC has no hard drives or FlashCore Modules."
        }
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_DriveInfo.Visibility="Visible" 

})

$TD_btn_IBM_FCPortStats.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_StorageEventLog,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_FCPortStatsOne,$TD_dg_FCPortStatsTwo,$TD_dg_FCPortStatsThree,$TD_dg_FCPortStatsFour,$TD_dg_FCPortStatsFive,$TD_dg_FCPortStatsSix,$TD_dg_FCPortStatsSeven,$TD_dg_FCPortStatsEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_FCPortStats = IBM_FCPortStats -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        $TD_FCPortStatsClean = $TD_FCPortStats| Where-Object { $_ }
        try {
            SST_LiteDBControl -SST_InfoType "FCPortStats" -SST_CollectedInformations $TD_FCPortStatsClean
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Debug -Message $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - FCPortStats - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
        }
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_FCPortStatsOne.ItemsSource = $TD_FCPortStatsClean }
            {($_ -eq 2)} { $TD_dg_FCPortStatsTwo.ItemsSource = $TD_FCPortStatsClean }
            {($_ -eq 3)} { $TD_dg_FCPortStatsThree.ItemsSource = $TD_FCPortStatsClean }
            {($_ -eq 4)} { $TD_dg_FCPortStatsFour.ItemsSource = $TD_FCPortStatsClean }
            {($_ -eq 5)} { $TD_dg_FCPortStatsFive.ItemsSource = $TD_FCPortStatsClean }
            {($_ -eq 6)} { $TD_dg_FCPortStatsSix.ItemsSource = $TD_FCPortStatsClean }
            {($_ -eq 7)} { $TD_dg_FCPortStatsSeven.ItemsSource = $TD_FCPortStatsClean }
            {($_ -eq 8)} { $TD_dg_FCPortStatsEight.ItemsSource = $TD_FCPortStatsClean }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FCPortStats DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
        }
        $TD_FCPortStatsClean | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FCPortStats_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_FCPortStats.Visibility="Visible" 
    
})

$TD_btn_IBM_FCPortInfo.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")

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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FCPortInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error  -TD_Shown yes }
        }
        $TD_FCPortInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FCPortInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_FCPortInfo.Visibility="Visible"
    
})

$TD_btn_IBM_PolicyBased_Rep.add_click({
    CheckBoxReseter
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
                    Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at PolicyBased_Rep DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
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
                    Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at PolicyBased_Rep DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
                }
            }
         }
        Default {}
    }
    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}
})

$TD_btn_IBM_BaseStorageInfo.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_BaseStorageInfoOne,$TD_dg_BaseStorageInfoTwo,$TD_dg_BaseStorageInfoThree,$TD_dg_BaseStorageInfoFour,$TD_dg_BaseStorageInfoFive,$TD_dg_BaseStorageInfoSix,$TD_dg_BaseStorageInfoSeven,$TD_dg_BaseStorageInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_BaseStorageInfo = IBM_BaseStorageInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        #$TD_SystemInfo = IBM_SystemInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_BaseStorageInfoSN $TD_BaseStorageInfo.Serial_Number -TD_BaseStorageInfoMTM $TD_BaseStorageInfo.Prod_MTM
        try {
            SST_LiteDBControl -SST_InfoType "StorageBase" -SST_CollectedInformations $TD_BaseStorageInfo
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Debug -Message $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
        }
        try {
            SST_PRISMDBControl -SST_InfoType StorageBase -SST_CollectedInformations $TD_BaseStorageInfo
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Debug -Message $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "PRISMDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
        }
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_BaseStorageInfoOne.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 2)} { $TD_dg_BaseStorageInfoTwo.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 3)} { $TD_dg_BaseStorageInfoThree.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 4)} { $TD_dg_BaseStorageInfoFour.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 5)} { $TD_dg_BaseStorageInfoFive.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 6)} { $TD_dg_BaseStorageInfoSix.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 7)} { $TD_dg_BaseStorageInfoSeven.ItemsSource = $TD_BaseStorageInfo }
            {($_ -eq 8)} { $TD_dg_BaseStorageInfoEight.ItemsSource = $TD_BaseStorageInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at BaseStorageInfos DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
        }
        $TD_BaseStorageInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_BaseStorageInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }
    $TD_dg_IPQuorumInfoOne,$TD_dg_IPQuorumInfoTwo,$TD_dg_IPQuorumInfoThree,$TD_dg_IPQuorumInfoFour,$TD_dg_IPQuorumInfoFive,$TD_dg_IPQuorumInfoSix,$TD_dg_IPQuorumInfoSeven,$TD_dg_IPQuorumInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_IPQuorumInfo = IBM_IPQuorum -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_IPQuorumInfoOne.ItemsSource = $TD_IPQuorumInfo;   }
            {($_ -eq 2)} { $TD_dg_IPQuorumInfoTwo.ItemsSource = $TD_IPQuorumInfo ;  }
            {($_ -eq 3)} { $TD_dg_IPQuorumInfoThree.ItemsSource = $TD_IPQuorumInfo; }
            {($_ -eq 4)} { $TD_dg_IPQuorumInfoFour.ItemsSource = $TD_IPQuorumInfo ; }
            {($_ -eq 5)} { $TD_dg_IPQuorumInfoFive.ItemsSource = $TD_IPQuorumInfo ; }
            {($_ -eq 6)} { $TD_dg_IPQuorumInfoSix.ItemsSource = $TD_IPQuorumInfo ;  }
            {($_ -eq 7)} { $TD_dg_IPQuorumInfoSeven.ItemsSource = $TD_IPQuorumInfo; }
            {($_ -eq 8)} { $TD_dg_IPQuorumInfoEight.ItemsSource = $TD_IPQuorumInfo; }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at IPQuorum DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
        }
        $TD_IPQuorumInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IPQuorumInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_BaseStorageInfo.Visibility="Visible"
})

$TD_btn_IBM_PoolVolumeInfo.add_click({
    CheckBoxReseter
    $TD_stp_BaseStorageInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}

    $TD_dg_ExpandMDiskInfoOne,$TD_dg_ExpandMDiskInfoTwo,$TD_dg_ExpandMDiskInfoThree,$TD_dg_ExpandMDiskInfoFour,$TD_dg_ExpandMDiskInfoFive,$TD_dg_ExpandMDiskInfoSix,$TD_dg_ExpandMDiskInfoSeven,$TD_dg_ExpandMDiskInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_ExpandMDiskInfo = IBM_MDiskInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_ExpandMDiskInfoOne.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 2)} { $TD_dg_ExpandMDiskInfoTwo.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 3)} { $TD_dg_ExpandMDiskInfoThree.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 4)} { $TD_dg_ExpandMDiskInfoFour.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 5)} { $TD_dg_ExpandMDiskInfoFive.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 6)} { $TD_dg_ExpandMDiskInfoSix.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 7)} { $TD_dg_ExpandMDiskInfoSeven.ItemsSource = $TD_ExpandMDiskInfo }
            {($_ -eq 8)} { $TD_dg_ExpandMDiskInfoEight.ItemsSource = $TD_ExpandMDiskInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at MDiskInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
        }
        $TD_ExpandMDiskInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_ExpandMDiskInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }
    $TD_dg_ExpandVolumeInfoOne,$TD_dg_ExpandVolumeInfoTwo,$TD_dg_ExpandVolumeInfoThree,$TD_dg_ExpandVolumeInfoFour,$TD_dg_ExpandVolumeInfoFive,$TD_dg_ExpandVolumeInfoSix,$TD_dg_ExpandVolumeInfoSeven,$TD_dg_ExpandVolumeInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true}
    }
    $TD_Credentials | ForEach-Object {
        [array]$TD_ExpandVolumeInfo = IBM_VolumeInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_ExpandVolumeInfoOne.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 2)} { $TD_dg_ExpandVolumeInfoTwo.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 3)} { $TD_dg_ExpandVolumeInfoThree.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 4)} { $TD_dg_ExpandVolumeInfoFour.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 5)} { $TD_dg_ExpandVolumeInfoFive.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 6)} { $TD_dg_ExpandVolumeInfoSix.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 7)} { $TD_dg_ExpandVolumeInfoSeven.ItemsSource = $TD_ExpandVolumeInfo }
            {($_ -eq 8)} { $TD_dg_ExpandVolumeInfoEight.ItemsSource = $TD_ExpandVolumeInfo }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at VolumeInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
        }
        $TD_ExpandVolumeInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_ExpandVolumeInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_PoolVolumeInfo.Visibility="Visible"
})

$TD_btn_IBM_CleanUpDumps.add_click({
    $ErrorActionPreference="Continue"
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog | ForEach-Object {$_.Visibility="Collapsed"}

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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at CleanUpDumps DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
        }
    }

    $TD_stp_CleanUpDump.Visibility="Visible"
})

$TD_btn_IBM_BackUpConfig.add_click({
    $ErrorActionPreference="Continue"
    CheckBoxReseter
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at BackUpConfig DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
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
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at BackUpConfig ExportFiles, please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes
        SST_ToolMessageCollector -TD_ToolMSGCollector "BackUpConfig $($_.Exception.Message)" -TD_ToolMSGType Error 
        $TD_tb_BackUpFileErrorInfo.Text = $_.Exception.Message
    }

    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_BackUpConfig.Visibility="Visible"
})

$TD_btn_IBM_HostInfo.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_IPPortInfo,$TD_stp_HostVolInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_StorageEventLog,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")

    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}


    $TD_dg_CollectedHostInfoOne,$TD_dg_CollectedHostInfoTwo,$TD_dg_CollectedHostInfoThree,$TD_dg_CollectedHostInfoFour,$TD_dg_CollectedHostInfoFive,$TD_dg_CollectedHostInfoSix,$TD_dg_CollectedHostInfoSeven,$TD_dg_CollectedHostInfoEight |ForEach-Object {
        if($_.items.count -gt 0){$_.ItemsSource = $EmptyVar; $TD_UCRefresh = $true }
    }

    $TD_Credentials | ForEach-Object {
        [array]$TD_Collected_HostInfoResult = IBM_HostInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
        $TD_Collected_HostInfoResult = $TD_Collected_HostInfoResult | Where-Object { -not [string]::IsNullOrWhiteSpace($_.HostName) }
        try {
            SST_LiteDBControl -SST_InfoType "StorageHostInfo" -SST_CollectedInformations $TD_Collected_HostInfoResult
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
        }
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_CollectedHostInfoOne.ItemsSource = $TD_Collected_HostInfoResult   }
            {($_ -eq 2)} { $TD_dg_CollectedHostInfoTwo.ItemsSource = $TD_Collected_HostInfoResult   }
            {($_ -eq 3)} { $TD_dg_CollectedHostInfoThree.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 4)} { $TD_dg_CollectedHostInfoFour.ItemsSource = $TD_Collected_HostInfoResult  }
            {($_ -eq 5)} { $TD_dg_CollectedHostInfoFive.ItemsSource = $TD_Collected_HostInfoResult  }
            {($_ -eq 6)} { $TD_dg_CollectedHostInfoSix.ItemsSource = $TD_Collected_HostInfoResult   }
            {($_ -eq 7)} { $TD_dg_CollectedHostInfoSeven.ItemsSource = $TD_Collected_HostInfoResult }
            {($_ -eq 8)} { $TD_dg_CollectedHostInfoEight.ItemsSource = $TD_Collected_HostInfoResult }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at HostInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes }
        }
        $TD_Collected_HostInfoResult | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_Collected_HostInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_HostInfo.Visibility="Visible" 

})

$TD_btn_IBM_IPPortInfo.add_click({
    CheckBoxReseter
    $TD_stp_PoolVolumeInfo,$TD_stp_IBM_FCPortInfo,$TD_stp_IBM_HostInfo,$TD_stp_FCPortStats,$TD_stp_DriveInfo,$TD_stp_HostVolInfo,$TD_stp_BackUpConfig,$TD_stp_BaseStorageInfo,$TD_stp_StorageEventLog,$TD_stp_PolicyBased_Rep,$TD_stp_StorageAuditLog,$TD_stp_CleanUpDump | ForEach-Object {$_.Visibility="Collapsed"}
    $TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render")

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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at IPPortInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
        }
        $TD_IPPortInfo | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_IPPortInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_IBM_IPPortInfo.Visibility="Visible"
    
})
SST_ToolMessageCollector -TD_ToolMSGCollector $("Endregion IBM Storage Button.") -TD_ToolMSGType Message -TD_Shown no
#endregion

#region SAN Button
SST_ToolMessageCollector -TD_ToolMSGCollector $("Region Begin SAN Button.") -TD_ToolMSGType Message -TD_Shown no
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
        try {
            SST_LiteDBControl -SST_InfoType "SANBase" -SST_CollectedInformations $FOS_BasicSwitch
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB SANBase - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
        }
        switch ($_.ID) {
            {($_ -eq 1)} { $TD_dg_sanBasicSwitchInfoOne.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 2)} { $TD_dg_sanBasicSwitchInfoTwo.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 3)} { $TD_dg_sanBasicSwitchInfoThree.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 4)} { $TD_dg_sanBasicSwitchInfoFour.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 5)} { $TD_dg_sanBasicSwitchInfoFive.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 6)} { $TD_dg_sanBasicSwitchInfoSix.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 7)} { $TD_dg_sanBasicSwitchInfoSeven.ItemsSource = $FOS_BasicSwitch }
            {($_ -eq 8)} { $TD_dg_sanBasicSwitchInfoEight.ItemsSource = $FOS_BasicSwitch }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at BasicSwitchInfos DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
        }
        try {
            $FOS_BasicSwitch | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_BasicSwitchInfos_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv -ErrorAction SilentlyContinue
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_BasicSwitchInfos in GUI Func - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
        }
        
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
        
        try {
            $FOS_SwitchShowDB = $FOS_SwitchShow |ForEach-Object {
                if($_.Address -ne "virtuell"){
                    return $_
                }
            }
            SST_LiteDBControl -SST_InfoType "SANPortInfo" -SST_CollectedInformations $FOS_SwitchShowDB
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB SANPortInfo - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
        }

        switch ($_.ID) {
            {($_ -eq 1)} { $TD_DG_SwitchShowOne.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 2)} { $TD_DG_SwitchShowTwo.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 3)} { $TD_DG_SwitchShowThree.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 4)} { $TD_DG_SwitchShowFour.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 5)} { $TD_DG_SwitchShowFive.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 6)} { $TD_DG_SwitchShowSix.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 7)} { $TD_DG_SwitchShowSeven.ItemsSource = $FOS_SwitchShow }
            {($_ -eq 8)} { $TD_DG_SwitchShowEight.ItemsSource = $FOS_SwitchShow }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at SwitchShowInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
        }
        $FOS_SwitchShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_SwitchShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortBufferShow,$TD_stp_sanPortErrorShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanSwitchShow.Visibility="Visible"

})
<# filter View for FilterSANSwShow #>
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
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterSANSwShow with Filter  $($TD_SANFilter_DG_Colum), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
        }
        if($FOS_SwitchShow.Count -ne $TD_CollectVolInfo.Count){
            $FOS_SwitchShow = $TD_CollectVolInfo }

            switch ($ColumFilter) {
                "Port" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Port -Match $filter } }
                "Address" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Port -Match $filter } }
                "Speed" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.Speed -Match $filter } }
                "State" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.State -Match $filter } }
                "PortConnect" { [array]$WPF_dataGrid = $FOS_SwitchShow | Where-Object { $_.PortConnect -Match $filter } }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterSANSwShow with Filter $($ColumFilter), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
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
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterSANSwShow with Filter $($TD_SANFilter_DG_Colum), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
            }
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterSANSwShow, $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
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
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong, ID $($TD_SANFilter_DG) or DeviceName $($TD_Credentials.DeviceName) can not be found") -TD_ToolMSGType Error -TD_Shown yes}
        }
            
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at ClearFilterSANSwShow, $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
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
<# filter View for FilterFabricOne #>
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
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterFabricOne with $TD_Filter_DG_Colum") -TD_ToolMSGType Error -TD_Shown yes}
            }
            
            $TD_dg_ZoneDetailsOne.ItemsSource = $WPF_dataGrid
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterFabricOne, $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
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
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterFabricTwo with $TD_Filter_DG_Colum") -TD_ToolMSGType Error -TD_Shown yes}
            }
            
            $TD_dg_ZoneDetailsTwo.ItemsSource = $WPF_dataGrid
        }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at FilterFabricTwo, $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at PortLicenseShowInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at SensorShow DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at PortErrShowInfos DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at SFPDetails DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 1") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 1") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 2") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 2") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 3") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 3") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 4") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 4") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 5") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 5") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 6") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 6") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 7") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 7") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 8") -TD_ToolMSGType Error
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
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong $TD_FOS_StatsClear Nbr. 8") -TD_ToolMSGType Error
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
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at StatsClear DeviceID $($TD_Credential.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
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
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong at PortbufferShowInfo DeviceID $($_.ID), please check the prompt output first and then the log files.") -TD_ToolMSGType Error -TD_Shown yes}
        }
        $TD_FOS_PortbufferShow | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$($_.ID)_$($_.DeviceName)_FOS_PortbufferShowInfo_$(Get-Date -Format "yyyy-MM-dd")_Temp.csv
    }

    if($TD_UCRefresh){$TD_UserControl1.Dispatcher.Invoke([System.Action]{},"Render");$TD_UCRefresh=$false}

    $TD_stp_sanLicenseShow,$TD_stp_sanPortErrorShow,$TD_stp_sanSwitchShow,$TD_stp_sanBasicSwitchInfo,$TD_stp_sanZoneDetailsShow,$TD_stp_sanSensorShow,$TD_stp_sanSFPShow | ForEach-Object {$_.Visibility="Collapsed"}

    $TD_stp_sanPortBufferShow.Visibility="Visible"

})
SST_ToolMessageCollector -TD_ToolMSGCollector $("Endregion SAN Button.") -TD_ToolMSGType Message -TD_Shown no
#endregion

#region IBM Power
$TD_BTN_HMCCollector.add_click({
    SST_ToolMessageCollector -TD_ToolMSGCollector $("Region IBM Power Button.") -TD_ToolMSGType Message -TD_Shown no
    if (Get-Item -Path "$PSRootPath\Server\IBMPower\HMCScanerTEMP" -ErrorAction SilentlyContinue){
        if(($TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_}).count -ge 1){
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_}
            IBM_PowerMainFunc -SST_UCOBJ $TD_UserControl6 -PSRootPath $PSRootPath -SecureData $TD_Credentials 
        }else{
            $TD_BTN_HMCCollector.Content = "No HMC Creds Loaded"
            SST_ToolMessageCollector -TD_ToolMSGCollector $("No HMC Creds Loaded") -TD_ToolMSGType Message -TD_Shown yes
        }
    }else {
        $SST_BTN_PowerBoardTooltip = $TD_UserControl6.FindName("BTN_HMCCollectorTooltip")
        $TD_BTN_HMCCollector.Background = "Coral"
        $SST_BTN_PowerBoardTooltip.Text = "HMC Scanner Folder not found!"
        <# Action when all if and elseif conditions are false #>
    }

})
#endregion

#region Health Check
#$TD_btn_Storage_SysCheck.add_click({
#    SST_MainHealthCheckFunc
#})
#$TD_btn_HC_OpenGUI_One.add_click({
#    Start-Process "https://$($TD_TB_storageIPAdrOne.Text)"
#})
#$TD_btn_HC_OpenGUI_Two.add_click({
#    Start-Process "https://$($TD_TB_storageIPAdrTwo.Text)"
#})
#$TD_btn_HC_OpenGUI_Three.add_click({
#    Start-Process "https://$($TD_TB_storageIPAdrThree.Text)"
#})
#$TD_btn_HC_OpenGUI_Four.add_click({
#    Start-Process "https://$($TD_TB_storageIPAdrFour.Text)"
#})
#endregion

if(!([string]::IsNullOrWhiteSpace($(Get-ChildItem -Path $PSRootPath\Resources\DBFolder\*.db).Name))){
    SST_ToolMessageCollector -TD_ToolMSGCollector $("Start DashBoardMain from GUI Control") -TD_ToolMSGType Message -TD_Shown no
    SST_DashBoardMain -MainPath $PSRootPath -SST_UCOBJ $TD_UserControl1
}
$TD_btn_CloseAll.add_click({
    <#CleanUp before close #>
    try {
        Remove-Item -Path $PSRootPath\ToolLog\ToolTEMP\* -Filter '*_Temp.csv' -Force -ErrorAction SilentlyContinue
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Remove Files from TEMP-Folder, done.") -TD_ToolMSGType Message -TD_Shown no
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Remove Files fail: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown no
    }
    Write-Debug -Message "Close the appl via CloseBtn"
    $MainWindow.Close()
})

<# does not have to be displayed but can be #>
Get-Variable TD_* |Out-Null
<# Clean all LogFiles if there older than 90 Days #>
SST_ToolMessageCollector -TD_ToolMSGCollector $("Call SST_FileCleanUp Func from GUI Control") -TD_ToolMSGType Message -TD_Shown no
SST_FileCleanUp
<# Load Toolsettings if they saved in Resources folder #>
SST_ToolMessageCollector -TD_ToolMSGCollector $("Start Load Toolsettings if they saved in Resources folder") -TD_ToolMSGType Message -TD_Shown no
SST_SaveLoadToolSettings -SST_LoadSettings $true -SST_MWOBJ $MainWindow -SST_UCOBJ $TD_UserControl6 -CockpitView $CockpitView

switch ($CockpitView) {
    "DEFAULT" { $TD_UserContrArea.Children.Add($TD_UserControl1) }
    "STORAGE" { $TD_UserContrArea.Children.Add($TD_UserControl2) }
    "SAN" { $TD_UserContrArea.Children.Add($TD_UserControl3) }
    "POWER" { $TD_UserContrArea.Children.Add($TD_UserControl6) }
    "HEALTH" { $TD_UserContrArea.Children.Add($TD_UserControl4) }
    "CONFIG" { $TD_UserContrArea.Children.Add($TD_UserControl5) }
    "JobMode" {
        try {
            Remove-Item -Path $PSRootPath\ToolLog\ToolTEMP\* -Filter '*_Temp.csv' -Force -ErrorAction SilentlyContinue
            SST_ToolMessageCollector -TD_ToolMSGCollector $("Remove Files from TEMP-Folder, done.") -TD_ToolMSGType Message -TD_Shown no
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector $("Remove Files fail: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown no
        }
        Write-Debug -Message "Close the appl via CloseBtn"
        $MainWindow.Close()
        Exit
    }
    Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Start Tool with Usercontrol $CockpitView ") -TD_ToolMSGType Message -TD_Shown no}
}

SST_ToolMessageCollector -TD_ToolMSGCollector $("End of SST GUI Control file.") -TD_ToolMSGType Message -TD_Shown no
$MainWindow.showDialog()

$MainWindow.activate()

}
