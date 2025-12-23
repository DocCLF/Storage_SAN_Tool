<# Load everything we need  #>
<# important to find the dll as well #>
$PSRootPath = Split-Path -Path $PSScriptRoot -Parent
<# Query the PWSH version because of the DB files and REST function #>
if($PSVersionTable.PSVersion.Major -le 7){
    Add-Type -Path "$PSRootPath\Resources\DBFolder\System.Data.SQLite.dll"
    #Add-Type -Path ".\OxyPlot.dll"
    #Add-Type -Path ".\OxyPlot.Wpf.dll"
}else {
    Add-Type -Path "$PSRootPath\Resources\DBFolder\PWSH5\System.Data.SQLite.dll"
}
<# Required for WPF, etc. #>
Add-Type -AssemblyName PresentationFramework, PresentationCore, System.Windows.Forms, WindowsBase
<# beginn of the Main part #>
function Storage_SAN_Tool {
[CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("DEFAULT","SAN","CONFIG","HEALTH","STORAGE","POWER","JobMode")]
        $CockpitView = $null
    )
#$ErrorActionPreference="SilentlyContinue"
#region Create Window and UC
# ------------------------------
# Load WPF styles BEFORE window
# ------------------------------
$StyleFiles = @(
    "$PSRootPath\Resources\Styles\ColorStyle.xaml",
    "$PSRootPath\Resources\Styles\OtherControlStyle.xaml",
    "$PSRootPath\Resources\Styles\TextBoxStyle.xaml",
    "$PSRootPath\Resources\Styles\ButtonStyle.xaml"
)
$global:LoadedStyles = @()
foreach ($file in $styleFiles) {
    $dict = [Windows.Markup.XamlReader]::Parse((Get-Content $file -Raw))
    $global:LoadedStyles += ,$dict
}
<# create the MainWindow #>

$inputXAML=Get-Content -Raw -Path "$PSScriptRoot\MainWindow.xaml"
[xml]$MainXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
[System.Xml.XmlNodeReader] $Mainreader = $MainXAML
$MainWindow =[Windows.Markup.XamlReader]::Load($Mainreader)
foreach ($style in $global:LoadedStyles) {
    $MainWindow.Resources.MergedDictionaries.Add($style)
}
$MainXAML.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $MainWindow.FindName($_.Name)}

<# add ResourceDictionary for WPF to App #>
foreach ($file in $StyleFiles){
    $style = [Windows.Markup.XamlReader]::Parse((Get-Content $file -Raw))
    $MainWindow.Resources.MergedDictionaries.Add( $style)
}
<# PowerShell WPF XAML simple data binding datacontext #>

$ViewModel = [RootViewModel]::new()
$ViewModel.IBMFS73Icon = "$PSRootPath\Resources\Icons\IBMFS73Icon.png"
$ViewModel.SAN64B7Icon = "$PSRootPath\Resources\Icons\SAN64B7Icon.png"
$ViewModel.IBMPower11Icon = "$PSRootPath\Resources\Icons\IBMPower11Icon.png"
$ViewModel.RefrehIcon96 = "$PSRootPath\Resources\Icons\iconrefresh96.png"
$ViewModel.CustomerYN    = $true

<# PROFI Logo in MainWindow #>
$MainWindow.DataContext = $ViewModel
$TD_LogoImage.Source = "$PSRootPath\Resources\Icons\PROFI_Logo_2022_dark.png"
$TD_LogoImageSmall.Source = "$PSRootPath\Resources\Icons\PROFI_Logo_2022_dark.png"
$TD_LogoImageSmall.Visibility = "hidden"


<# Create UserControls as basis of Content for MainWindow #>
$TD_AllUserControls = @()
$UserCxamlFile = Get-ChildItem "$PSScriptRoot\UserControl_*.xaml"
foreach($file in $UserCxamlFile){
    $fileName = ($file.Name).TrimEnd(".xaml")
    Set-Variable -Name "TD_$($fileName)"

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
    if ($fileName -like "*Dash" -or $fileName -like "*Health" -or $fileName -like "*SetUp") {
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
#endregion
#region Tool Prep
<# Check if the ToolDB is available if not deploy #>
if(!(Test-Path -Path "$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db")){
    try {
        $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
    }
    catch {
        Write-Host $_.exception.message
        #SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
    }
    if($SST_SQLiteCon.State -eq "Open"){ $SST_SQLiteCon.Close() }
}
$TD_DataBaseChoice = Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Basename
        Path = $_.FullName
    }
}
if ($($TD_DataBaseChoice.Name).Count -lt 1) {
    $TD_CB_DataBaseChoice.ItemsSource = @("Keine Datenbank gefunden")
    $TD_CB_DataBaseChoice.IsEnabled = $false
} else {
    $TD_CB_DataBaseChoice.ItemsSource = @($TD_DataBaseChoice.Name)
    $TD_CB_DataBaseChoice.SelectedIndex = 0
    $TD_BTN_DeleteDB.Visibility = "Visible"
    $TD_BTN_DeleteDB.Background = "coral"
}
#endregion
#region Button
$TD_BTN_Dashboard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_Dash -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_IBMSpectrVirt.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_IBMSTO -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_PowerBoard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_PWR -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_IBMTape.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_IBMTape -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_BrocSAN.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_BRSAN -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_STOSANHealth.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_Health -AllUserControls $TD_AllUserControls
    SST_MainHealthCheckFunc -SST_UCOBJ $TD_UserControl_Health
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_CustomerBoard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_CustomerBoard -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_ToolSettings.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_SetUp -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_SaveToolSettings.add_click({
    if(($TD_BTN_ActivateDB.Background -notlike "*FFFC4242")-and($TD_TB_CustomerInfoName.Background -notlike "*FFFA8C8C")){
        try {
            SST_SaveLoadToolSettings -SST_SaveSettings $true 
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        
    }else {
        [System.Windows.MessageBox]::Show(
            "Please enter the customer name or number!", "Invalid input", 'OK', 'Warning'
        )
    }
})
$TD_BTN_LoadToolSettings.add_click({
    SST_SaveLoadToolSettings -SST_LoadSettings $true
})
$TD_BTN_SaveCredtoDG.add_click({
    if($TD_CB_CredUpdate.IsChecked){
        #SST_ToolMessageCollector -TD_ToolMSGCollector "Cred Update" -TD_ToolMSGType Message -TD_Shown no
        $TD_CredfGUIArray = SST_GetCredfGUI -TD_AddaNewDevice "no"
    }else{
        #SST_ToolMessageCollector -TD_ToolMSGCollector "Cred AddaNewDevice" -TD_ToolMSGType Message -TD_Shown no
        $TD_CredfGUIArray = SST_GetCredfGUI -TD_AddaNewDevice "yes"
        Start-Sleep -Seconds 0.5
        if(!([string]::IsNullOrEmpty($TD_CredfGUIArray))){
            $TD_TB_DeviceIPAddr.Text=""
            $TD_TB_DeviceUserName.Text=""
            $TD_TB_DevicePassword.Password=""
            $TD_CB_SVCorVF.IsChecked=$false
        }
    }

})
$TD_BTN_ExportCred.add_click({
    <# Not all needs to exported, if you want to modify the Export got to the SST_ExportCred Func #>
    $TD_SST_ExportCred = SST_ExportCredential -TD_CollectedCredDatas $TD_DG_KnownDeviceList.ItemsSource
    <# Save to Dir #>
    $TD_SaveCred = SST_SaveFile_to_Directory -TD_UserDataObject $TD_SST_ExportCred
    if([string]::IsNullOrEmpty($TD_SaveCred.FileName)){
        #SST_ToolMessageCollector -TD_ToolMSGCollector $("Export failed!") -TD_ToolMSGType Warning -TD_Shown yes
    }else {
        #SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully exported to $($TD_SaveCred.FileName)") -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_ImportCred.add_click({
    $TD_ImportedCredentials = SST_ImportCredential
    if($TD_ImportedCredentials.count -lt 1){
        #SST_ToolMessageCollector -TD_ToolMSGCollector $("Import failed!") -TD_ToolMSGType Warning -TD_Shown yes
    }else {
        #SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully Import") -TD_ToolMSGType Message -TD_Shown yes
        #$SST_BTN_PowerBoard = $TD_UserControl6.FindName("BTN_HMCCollector")
        #$SST_BTN_PowerBoard.Content="HMC Scanner"
        #$SST_BTN_PowerBoard.IsEnabled=$true
        if($TD_CB_OnlineCheckbyImport.IsChecked){
            Write-Host ($TD_CB_OnlineCheckbyImport.IsChecked) $CockpitView
            $TD_ImportedCredentials | ForEach-Object {
                SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $_.DeviceTyp -TD_Selected_DeviceConnectionType $_.ConnectionTyp -TD_Selected_DeviceIPAddr $_.IPAddress -TD_Selected_DeviceUserName $_.UserName -TD_Selected_DevicePassword $_.Password -TD_Selected_SVCorVF $_.SVCorVF
                Start-Sleep -Seconds 0.5
            }
        }
    }
})
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
        if(($SST_SQLiteCon.State -eq "Open")-and($SST_SQLiteCon.DataSource -eq "$DBName")){
            $TD_BTN_DeleteDB.Visibility = "Visible"
            $TD_BTN_DeleteDB.Background = "coral"
            $SST_SQLiteCon.Close()
            $TD_CB_DataBaseChoice.ItemsSource = $null
            $TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
            $TD_CB_DataBaseChoice.IsEnabled = $true
            $TD_CB_DataBaseChoice.ItemsSource = $TD_DataBaseChoice
            $TD_CB_DataBaseChoice.SelectedIndex = 0
        }
    }else {
        [System.Windows.MessageBox]::Show(
            "Please enter the customer name or number!", "Invalid input", 'OK', 'Warning'
        )
    }
})
$TD_BTN_DeleteDB.add_click({
    $DBName = $TD_TB_CustomerInfoName.Text -replace ".db",""
    try {
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
        Remove-Item -Path "$PSRootPath\Resources\DBFolder\$DBName.db" -Confirm:$false -Force -ErrorAction SilentlyContinue
        $TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
        if([string]::IsNullOrWhiteSpace($TD_DataBaseChoice)){
            $TD_TB_CustomerInfoName.Text = "Keine Datenbank gefunden"
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
        #SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB: $($TD_DBtoDelete.Name) are deleted" -TD_ToolMSGType Message -TD_Shown yes
        #$TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
})
$TD_BTN_DBRefresh.add_click({
    $TD_CB_DataBaseChoice.ItemsSource = $null
    $TD_DataBaseChoice = @(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" | Select-Object -ExpandProperty Basename)
    if ($TD_DataBaseChoice.Count -eq 0) {
        $TD_CB_DataBaseChoice.ItemsSource = @("Keine Datenbank gefunden")
        $TD_CB_DataBaseChoice.SelectedIndex = 0
        $TD_CB_DataBaseChoice.IsEnabled = $false
        $TD_BTN_DeleteDB.Visibility = "Collapsed"
    } else {
        $TD_CB_DataBaseChoice.ItemsSource = $TD_DataBaseChoice
        $TD_CB_DataBaseChoice.IsEnabled = $true
        $TD_CB_DataBaseChoice.SelectedIndex = 0
    }
})
$TD_BTN_CloseGUI.add_click({
    <#CleanUp before close #>
    try {
        Remove-Item -Path $PSRootPath\ToolLog\ToolTEMP\* -Filter '*_Temp.csv' -Force -ErrorAction SilentlyContinue
        if(Test-Path -Path "$PSRootPath\Resources\DBFolder\*" -Filter "*.db"){
            #SST_RESTDBControl -SST_InfoType "DeleteStorageToken" | Out-Null
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        #SST_ToolMessageCollector -TD_ToolMSGCollector $("Remove Files fail: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown no
    }
    $MainWindow.Close()
})
$TD_BTN_IBM_BaseStorageInfo.add_click({
    <#Get all Device Cred and count them #>
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
    <# get the DataConteext of the current View/ means UC and if its nul trow an error #>
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    if (-not $UCDataContext) { Write-Host "DataContext ist NULL!" -ForegroundColor Red; return }
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    $TD_Credentials | ForEach-Object {
        [array]$TD_BaseStorageInfo = IBM_BaseStorageInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text

        $DeviceBlock = [DeviceToggle]::new()
        $DeviceBlock.Id = "DeviceBlock$($_.ID)"
        $DeviceBlock.Label = if([string]::IsNullOrWhiteSpace($TD_BaseStorageInfo.ClusterName)){"$($_.IPAddress)"} else {"$($TD_BaseStorageInfo.ClusterName)"}
        $DeviceBlock.IsChecked = $false
        # Rows hinzufÃ¼gen (Mapping muss zu BaseStorageRow passen)
        foreach ($StorageInfo in $($TD_BaseStorageInfo.StorageInfo)) {
            if ([string]::IsNullOrWhiteSpace([string]$StorageInfo.ID)) { continue }
            $DGRow = [BaseStorageRow]::new()
            $DGRow.ID = $StorageInfo.ID
            $DGRow.Name = $StorageInfo.Name
            $DGRow.ClusterName = $StorageInfo.ClusterName
            $DGRow.WWNN = $StorageInfo.WWNN
            $DGRow.Status = $StorageInfo.Status
            $DGRow.IO_group_id = $StorageInfo.IO_group_id
            $DGRow.IO_group_Name = $StorageInfo.IO_group_Name
            $DGRow.Prod_MTM = $StorageInfo.Prod_MTM
            $DGRow.Serial_Number = $StorageInfo.Serial_Number
            $DGRow.Code_Level = $StorageInfo.Code_Level
            $DGRow.RecommendedPTF = $StorageInfo.RecommendedPTF
            $DGRow.Config_Node = $StorageInfo.Config_Node
            $DGRow.SideID = $StorageInfo.SideID
            $DGRow.SideName = $StorageInfo.SideName

            $DGRow.MDiskTotalCapacity = $StorageInfo.MDiskTotalCapacity
            $DGRow.MDiskFreeCapacity = $StorageInfo.MDiskFreeCapacity
            $DGRow.MDiskUsedCapacity = $StorageInfo.MDiskUsedCapacity
            $DGRow.PhysicalTotalCapacity = $StorageInfo.PhysicalTotalCapacity
            $DGRow.PhysicalFreeCapacity = $StorageInfo.PhysicalFreeCapacity
            $DGRow.HostUnmap = $StorageInfo.HostUnmap
            $DGRow.BackendUnmap = $StorageInfo.BackendUnmap
            $DGRow.Topology = $StorageInfo.Topology
            $DGRow.Layer = $StorageInfo.Layer
            $DGRow.QuorumMode = $StorageInfo.QuorumMode

            $DeviceBlock.DGRow.Add($DGRow)
        }
        $UCVMMain.DeviceToggles.Add($DeviceBlock)
    }
})
#endregion
$TD_CB_DataBaseChoice.add_SelectionChanged({
    if(!([string]::IsNullOrEmpty($TD_CB_DataBaseChoice.SelectedItem))){
        $CustomerDB = $TD_CB_DataBaseChoice.SelectedItem.tostring()
        $SST_SavedCustomerSettingsDB = SST_CustomerDB -SST_InfoType "LoadCustomerSetUp" -SST_Customer $CustomerDB
        $TD_TB_ExportPath.Text = $SST_SavedCustomerSettingsDB.ExportPath
        $TD_LB_CerdExportPath.Content = $SST_SavedCustomerSettingsDB.ExportPathCredential

        Write-Host $CustomerDB -ForegroundColor Cyan
    }
})
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
                if(($_.selecteditem.DeviceTyp -like "*Storage")-and($_.selecteditem.SVCorVF -eq "SVC")){$TD_CB_SVCorVF.IsChecked=$true}else{$TD_CB_SVCorVF.IsChecked=$false}
                if(($_.selecteditem.DeviceTyp -like "*SAN")-and($_.selecteditem.SVCorVF -eq "VF")){$TD_CB_SVCorVF.IsChecked=$true}else{$TD_CB_SVCorVF.IsChecked=$false}
                $_.selecteditem | Export-Clixml -Path $PSRootPath\ToolLog\ToolTEMP\UpdateCred.xml
            }

        }else{
            SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $TD_DG_KnownDeviceList.selecteditem.DeviceTyp -TD_Selected_DeviceConnectionType $TD_DG_KnownDeviceList.selecteditem.ConnectionTyp -TD_Selected_DeviceIPAddr $TD_DG_KnownDeviceList.selecteditem.IPAddress -TD_Selected_DeviceUserName $TD_DG_KnownDeviceList.selecteditem.UserName -TD_Selected_DevicePassword $TD_DG_KnownDeviceList.selecteditem.Password -TD_Selected_SVCorVF $TD_DG_KnownDeviceList.selecteditem.SVCorVF
        }
    }
})


#region show MainWindow
$MainWindow.showDialog()
$MainWindow.activate()
#endregion
}