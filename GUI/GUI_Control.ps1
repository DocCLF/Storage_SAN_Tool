<# Load everything we need  #>
<# important to find the dll as well #>
$PSRootPath = Split-Path -Path $PSScriptRoot -Parent
<# Query the PWSH version because of the DB files and REST function #>
if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) {
    throw "Storage_SAN_Tool GUI uses WPF and is only supported on Windows."
}else{
    if($PSVersionTable.PSVersion.Major -ge 6){
        Add-Type -Path "$PSRootPath\Resources\DBFolder\System.Data.SQLite.dll"
        #Add-Type -Path ".\OxyPlot.dll"
        #Add-Type -Path ".\OxyPlot.Wpf.dll"
    }else {
        Add-Type -Path "$PSRootPath\Resources\DBFolder\PWSH5\System.Data.SQLite.dll"
    }
    <# Required for WPF, etc. #>
    Add-Type -AssemblyName PresentationFramework, PresentationCore, System.Windows.Forms, WindowsBase
}
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
    "$PSRootPath\Resources\Styles\ButtonStyle.xaml",
    "$PSRootPath\Resources\Styles\ViewSTOVisibilityStyles.xaml"
    "$PSRootPath\Resources\Styles\ViewSANVisibilityStyles.xaml"
    "$PSRootPath\Resources\Styles\ViewPWRVisibilityStyles.xaml"
    "$PSRootPath\Resources\Styles\ViewTapeVisibilityStyles.xaml"
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
<# RootViewModel is in *Classes.ps1 #>
$ViewModel = [RootViewModel]::new()
$ViewModel.IBMFS73Icon = "$PSRootPath\Resources\Icons\IBMFS73Icon.png"
$ViewModel.STOIcon = "$PSRootPath\Resources\Icons\ibmstoicon.png"
$ViewModel.BrocadeIcon = "$PSRootPath\Resources\Icons\broadcom-96.png"
$ViewModel.SAN64B7Icon = "$PSRootPath\Resources\Icons\SAN64B7Icon.png"
$ViewModel.IBMPower11Icon = "$PSRootPath\Resources\Icons\IBMPower11Icon.png"
$ViewModel.RefreshIcon96 = "$PSRootPath\Resources\Icons\iconrefresh96.png"
$ViewModel.HMCIcon = "$PSRootPath\Resources\Icons\HMCicon.png"
$ViewModel.PowerIcon = "$PSRootPath\Resources\Icons\powericon01.png"
$ViewModel.ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
$ViewModel.SAN720 = "$PSRootPath\SAN\Brocade\IMG\switchG720.png"
$ViewModel.IBMArchive = "$PSRootPath\Resources\Icons\ibmarchive.png"

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
#region Global DataGrid Search
#. "$PSRootPath\ToolFunc\SST_SearchFuncs.ps1"

foreach ($uc in $TD_AllUserControls) {
    $searchBox = $uc.FindName("TB_GlobalGridSearch")
    if ($null -ne $searchBox) {
        Initialize-GlobalDataGridSearch -RootControl $uc -SearchBox $searchBox
    }
}
#endregion
#endregion
#region Tool Prep
<# Default Export Path #>
try {
    $TD_ExporttoOD = [Environment]::GetFolderPath("mydocuments")
    $ExportFolderPath="$TD_ExporttoOD\StorageSANTool"
    If(!(Test-Path -Path $ExportFolderPath)){
        try {
            $TD_ExportFolderCreated = New-Item $ExportFolderPath -ItemType Directory -ErrorAction Stop
            $TD_TB_ExportPath.Text = $TD_ExportFolderCreated.Name
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "BasicToolPreparation ExportFolderPath $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown no
        }
    }else{
        $TD_TB_ExportPath.Text = $ExportFolderPath
        #PowerShell Create directory if not exists
    }
}
catch {
    <#Do this if a terminating exception happens#>
    SST_ToolMessageCollector -TD_ToolMSGCollector "BasicToolPreparation ExportFolderPath $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown no
    Write-Error -Message $_.Exception.Message
}
<# Check if the ToolDB is available if not deploy #>
if(!(Test-Path -Path "$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db")){
    try {
        $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
    }
    catch {
        Write-Host $_.exception.message
        SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
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
    $TD_CB_DataBaseChoice.ItemsSource = @("Customer Nbr")
    $TD_CB_DataBaseChoice.IsEnabled = $false
} else {
    $TD_CB_DataBaseChoice.ItemsSource = @($TD_DataBaseChoice.Name)
    $TD_CB_DataBaseChoice.SelectedIndex = 0
    $TD_BTN_DeleteDB.Visibility = "Visible"
    $TD_BTN_DeleteDB.Background = "coral"
}
$Global:HostStatusChanges = [System.Collections.ObjectModel.ObservableCollection[string]]::new()
$Global:SANPortStatusChanges = [System.Collections.ObjectModel.ObservableCollection[string]]::new()
#endregion

#region ToolBTN
#region MenuBTN
$TD_BTN_Dashboard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_Dash -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    $TD_CB_SelectAllSTOCB.IsChecked = $false
    $TD_IC_STOHostStatusChanges.ItemsSource = $Global:HostStatusChanges
    $TD_IC_SANPortStatusChanges.ItemsSource = $Global:SANPortStatusChanges
})
$TD_BTN_IBMSpectrVirt.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_IBMSTO -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    $UCDataContext = $TD_UserControl_IBMSTO.DataContext
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    $TD_CB_SelectAllSTOCB.IsChecked = $false
})
$TD_BTN_PowerBoard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_PWR -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    $TD_CB_SelectAllSTOCB.IsChecked = $false
})
$TD_BTN_IBMTape.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_IBMTape -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    $TD_CB_SelectAllSTOCB.IsChecked = $false
})
$TD_BTN_BrocSAN.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_BRSAN -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    $UCDataContext = $TD_UserControl_BRSAN.DataContext
    <# if there is a DataContext find th Main Part und put it into UCVMMain#>
    $UCVMMain = $UCDataContext.Main
    <# if there a something in, its better to clean it up befor we use it again #>
    $UCVMMain.DeviceToggles.Clear()
    $TD_CB_SelectAllSTOCB.IsChecked = $false
})
$TD_BTN_STOSANHealth.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_Health -AllUserControls $TD_AllUserControls
    SST_MainHealthCheckFunc -SST_UCOBJ $TD_UserControl_Health
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    $TD_CB_SelectAllSTOCB.IsChecked = $false
})
$TD_BTN_CustomerBoard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_CustomerBoard -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    $TD_CB_SelectAllSTOCB.IsChecked = $false
})
$TD_BTN_ToolSettings.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
    SST_ShowUserControl -MainWindowArea $TD_UserContrArea -ShowUserControl $TD_UserControl_SetUp -AllUserControls $TD_AllUserControls
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
    <# Used to limit the customer number to a certain range and display it in red or green. #>
    $TB_CustomerInfoName = $TD_UserControl_SetUp.FindName("TB_CustomerInfoName")
    if ($TB_CustomerInfoName -and -not $TB_CustomerInfoName.Tag) {

        $TB_CustomerInfoName.Tag = "HandlersWired"

        $TB_CustomerInfoName.Add_TextChanged({
            param($sender, $e)

            $text = [string]$sender.Text

            if ($text -match '^\d{6}$') {
                $sender.Background = [Windows.Media.Brushes]::LightGreen
                $sender.Tag = "Valid"
            } else {
                $sender.Background = [Windows.Media.Brushes]::LightCoral
                $sender.Tag = "Invalid"
            }

            if ($text -eq 'Customer Nbr') {
                $sender.Background = [Windows.Media.Brushes]::LightCoral
                $sender.Tag = "Invalid"
            }
        })

        $TB_CustomerInfoName.Add_PreviewTextInput({
            param($sender, $e)
            $e.Handled = -not ($e.Text -match '^\d$')
        })
    }
    $TD_CB_SelectAllSTOCB.IsChecked = $false
})
#endregion
#region ToolSettingsBTN
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
            "Please enter the Customer Number!", "Invalid input", 'OK', 'Warning'
        )
    }
})
$TD_BTN_LoadToolSettings.add_click({
    SST_SaveLoadToolSettings -SST_LoadSettings $true -CockpitView $null -SST_LoadSettingsBTN $true
})
<# Button Export Settings #>
$TD_BTN_ChangeExportPath.add_click({
    $TD_ChPathdialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($TD_ChPathdialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $TD_DirectoryName = $TD_ChPathdialog.SelectedPath
        $TD_TB_ExportPath.Text = $TD_DirectoryName
    }
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_TB_ExportPath.Text)"
})
#endregion
#region CredentialBTN
$TD_BTN_SaveCredtoDG.add_click({
    if($TD_CB_CredUpdate.IsChecked){
        SST_ToolMessageCollector -TD_ToolMSGCollector "Cred Update" -TD_ToolMSGType Message -TD_Shown no
        try {
            $TD_CredfGUIArray = SST_GetCredfGUI -TD_AddaNewDevice "no"
        }
        catch {
            Write-Host $_.Exception.Message
        }
        
    }else{
        SST_ToolMessageCollector -TD_ToolMSGCollector "Cred AddaNewDevice" -TD_ToolMSGType Message -TD_Shown no
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
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Export failed!") -TD_ToolMSGType Warning -TD_Shown yes
    }else {
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully exported to $($TD_SaveCred.FileName)") -TD_ToolMSGType Message -TD_Shown yes
    }
})
$TD_BTN_ImportCred.add_click({
    $TD_ImportedCredentials = SST_ImportCredential
    if($TD_ImportedCredentials.count -lt 1){
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Import failed!") -TD_ToolMSGType Warning -TD_Shown yes
    }else {
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Credentials successfully Import") -TD_ToolMSGType Message -TD_Shown yes
        #$SST_BTN_PowerBoard = $TD_UserControl6.FindName("BTN_HMCCollector")
        #$SST_BTN_PowerBoard.Content="HMC Scanner"
        #$SST_BTN_PowerBoard.IsEnabled=$true
        if($TD_CB_OnlineCheckbyImport.IsChecked){
            Write-Host ($TD_CB_OnlineCheckbyImport.IsChecked) $CockpitView
            $TD_ImportedCredentials | ForEach-Object {
                if($_.DeviceTyp -like "*Tape"){
                    $TD_Creds =@{
                        IPAddress = $_.IPAddress
                        UserName = $_.UserName
                        Password = $_.Password
                        Endpoint = 'library/baseinfo'
                    }
                    SST_DeviceConnecCheck -TD_TapeCred $TD_Creds 
                }else {
                    <# Action when all if and elseif conditions are false #>
                    SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $_.DeviceTyp -TD_Selected_DeviceConnectionType $_.ConnectionTyp -TD_Selected_DeviceIPAddr $_.IPAddress -TD_Selected_DeviceUserName $_.UserName -TD_Selected_DevicePassword $_.Password -TD_Selected_SVCorVF $_.SVCorVF
                }
                Start-Sleep -Seconds 0.5
            }
        }
    }
})
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
    <# for ProgressBar #>
    $PB = New-ProgressBar
    <# ProgressBar #>
    $DBName = $TD_TB_CustomerInfoName.Text
    $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource | Where-Object { $_.DeviceTyp -like "*PowerHMC*" }
    $UCDataContext = $TD_UserControl_PWR.DataContext
    if (-not $UCDataContext) { [System.Windows.MessageBox]::Show("DataContext ist NULL!") | Out-Null; return }
    $UCVMMain = $UCDataContext.Main
    $UCVMMain.DeviceToggles.Clear()
    Write-ProgressBar -ProgressBar $PB -Activity "Prepare the collection" -PercentComplete 10
    try {
        [array]$DBPowerHMC = SST_CustomerPWRDBReadTable -SST_InfoType "PowerHMC" -SST_Customer $DBName
        if($null -eq $DBPowerHMC){
            foreach($TD_Creds in $TD_Credentials){

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
            $UCVMMain.SelectedView = "HMC"
        }else {
            $TD_IC_IBMPowerHMCDBView.ItemsSource = $DBPowerHMC
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector "PWR_ShowAll HMC: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }
    Write-ProgressBar -ProgressBar $PB -Activity "HMC RESTHMCConsole done" -PercentComplete 20
    try {
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare HMC_RESTHMCManagedSystems" -PercentComplete 30
        [array]$DBPowerSysSum = SST_CustomerPWRDBReadTable -SST_InfoType "PowerSysSummary" -SST_Customer $DBName
        if($null -eq $DBPowerSysSum){
            foreach($TD_Creds in $TD_Credentials){
            
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
        
            $UCVMMain.SelectedView = "ManagedSystem"
        }else {
            $TD_IC_IBMPowerSysDBView.ItemsSource = $DBPowerSysSum
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector "PWR_ShowAll ManagedSystem: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }    
    Write-ProgressBar -ProgressBar $PB -Activity "REST ManagedSystems done" -PercentComplete 45
    try {
        Write-ProgressBar -ProgressBar $PB -Activity "Prepare REST LogicalPartitions" -PercentComplete 60
        [array]$DBPowerLPAR = SST_CustomerPWRDBReadTable -SST_InfoType "LPARSummary" -SST_Customer $DBName
        if($null -eq $DBPowerLPAR){
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
            $UCVMMain.SelectedView = "LPARs"
        }else {
            $TD_IC_IBMPowerLPARDBView.ItemsSource = $DBPowerLPAR
        }
        Write-ProgressBar -ProgressBar $PB -Activity "REST LogicalPartitions done" -PercentComplete 80
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector "PWR_ShowAll LPARs: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
    }finally{
        <# for ProgressBar #>
        Close-ProgressBar -ProgressBar $PB
        <# ProgressBar #>
    }   
    $TD_GBPWRHMCInfo,$TD_GBPWRManagSysInfo,$TD_GBPWRLPARSum | ForEach-Object {$_.Visibility = "Visible"}
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
#endregion

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
                if($_.selecteditem.DeviceTyp -like "*PowerHMC"){$TD_CB_SVCorVF.Visibility="Collapsed"}
                if($_.selecteditem.DeviceTyp -like "*Tape"){$TD_CB_SVCorVF.Visibility="Collapsed"}
                $_.selecteditem | Export-Clixml -Path $PSRootPath\ToolLog\ToolTEMP\UpdateCred.xml
            }

        }else{
            SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $TD_DG_KnownDeviceList.selecteditem.DeviceTyp -TD_Selected_DeviceConnectionType $TD_DG_KnownDeviceList.selecteditem.ConnectionTyp -TD_Selected_DeviceIPAddr $TD_DG_KnownDeviceList.selecteditem.IPAddress -TD_Selected_DeviceUserName $TD_DG_KnownDeviceList.selecteditem.UserName -TD_Selected_DevicePassword $TD_DG_KnownDeviceList.selecteditem.Password -TD_Selected_SVCorVF $TD_DG_KnownDeviceList.selecteditem.SVCorVF
        }
    }
})

$FoundDBforDashBoard = $(Get-ChildItem "$PSRootPath\Resources\DBFolder\*" -Filter "*.db").BaseName
if(!([string]::IsNullOrWhiteSpace($FoundDBforDashBoard))){
    try {
        $SelFirstDB = $FoundDBforDashBoard | Select-Object -First 1
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Found some problems with local customer db") -TD_ToolMSGType Warning -TD_Shown yes
    }
    SST_DashBoardMain -MainPath $PSRootPath -SST_UCOBJ $TD_UserControl_Dash -FoundLocalDB $SelFirstDB
}

$TD_BTN_CloseGUI.add_click({
    <#CleanUp before close #>
    try {
        Remove-Item -Path $PSRootPath\ToolLog\ToolTEMP\* -Filter '*_Temp.csv' -Force -ErrorAction SilentlyContinue
        if(Test-Path -Path "$PSRootPath\Resources\DBFolder\*" -Filter "*.db"){
            #SST_RESTDBControl -SST_InfoType "DeleteToken" | Out-Null
            SST_RESTDBControl -SST_InfoType "DeleteToken"
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $("Remove Files fail: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown no
    }
    $MainWindow.Close()
})

SST_SaveLoadToolSettings -SST_LoadSettings $true -CockpitView $CockpitView -SST_LoadSettingsBTN $false

switch ($CockpitView) {
    "DEFAULT" { $TD_UserContrArea.Children.Add($TD_UserControl_Dash) }
    "STORAGE" { $TD_UserContrArea.Children.Add($TD_UserControl_IBMSTO) }
    "SAN" { $TD_UserContrArea.Children.Add($TD_UserControl_BRSAN) }
    "POWER" { $TD_UserContrArea.Children.Add($TD_UserControl_PWR) }
    "HEALTH" { $TD_UserContrArea.Children.Add($TD_UserControl_Health) }
    "CONFIG" { $TD_UserContrArea.Children.Add($TD_UserControl_SetUp) }
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
        #$MainWindow.Close()
        #Exit
    }
    Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Start Tool with Usercontrol $CockpitView ") -TD_ToolMSGType Message -TD_Shown no}
}
#to make sure the dashboard displays something as soon as the app starts
if ($Global:HostStatusChanges.Count -eq 0) {$Global:HostStatusChanges.Add("No Host Status changes since the last check.")}
if ($Global:SANPortStatusChanges.Count -eq 0) {$Global:SANPortStatusChanges.Add("No SAN Port Status changes since the last check.")}

Get-Variable TD_* |Out-Null
#region show MainWindow
$MainWindow.showDialog()
$MainWindow.activate()
#endregion
}