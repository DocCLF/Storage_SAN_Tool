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
# ------------------------------
# Load WPF styles BEFORE window
# ------------------------------
$StyleFiles = @(
    "$PSRootPath\Resources\Styles\ColorStyle.xaml",
    "$PSRootPath\Resources\Styles\AppStyle.xaml",
    "$PSRootPath\Resources\Styles\TextBoxStyle.xaml",
    "$PSRootPath\Resources\Styles\ButtonStyle.xaml"
)

$global:LoadedStyles = @()
foreach ($file in $styleFiles) {
    $dict = [Windows.Markup.XamlReader]::Parse((Get-Content $file -Raw))
    $global:LoadedStyles += ,$dict
}

#$ErrorActionPreference="SilentlyContinue"
SST_ToolMessageCollector -TD_ToolMSGCollector "Start reading Storage_SAN_Tool func" -TD_ToolMSGType Message -TD_Shown no
$inputXAML=Get-Content -Raw -Path "$PSScriptRoot\MainWindow.xaml"
[xml]$MainXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace "^<Win.*","<Window"
[System.Xml.XmlNodeReader] $Mainreader = $MainXAML
$MainWindow =[Windows.Markup.XamlReader]::Load($Mainreader)
foreach ($style in $global:LoadedStyles) {
    $MainWindow.Resources.MergedDictionaries.Add($style)
}
$MainXAML.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "TD_$($_.Name)" -Value $MainWindow.FindName($_.Name)}

<# add ResourceDictionary for WPF to App #>

#
foreach ($file in $StyleFiles){
    $style = [Windows.Markup.XamlReader]::Parse((Get-Content $file -Raw))
    $MainWindow.Resources.MergedDictionaries.Add( $style)
}
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
    if ($fileName -like "*l1" -or $fileName -like "*l4") {
        $TD_UserControl.DataContext = $DashBoardIcons
    }

    # --------------------------
    # Assign to global variable for later use
    # --------------------------
    Set-Variable -Name "TD_$fileName" -Value $TD_UserControl
}

$TD_BTN_Dashboard.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl1.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl1)}
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_IBMSpectrVirt.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl2.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl2)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_BrocSAN.add_click({
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
$TD_BTN_STOSANHealth.add_click({
    $TD_LB_ExpPathMainWindow.Content ="Export Path: $($TD_tb_ExportPath.Text)"
    if(!($TD_UserControl4.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl4); SST_MainHealthCheckFunc -SST_UCOBJ $TD_UserControl4 -SST_UCSTYLEOBJ $ButtonStyles }
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl5)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$TD_BTN_ToolSettings.add_click({
    if(!($TD_UserControl5.IsLoaded)){$TD_UserContrArea.Children.Add($TD_UserControl5)}
    $TD_UserContrArea.Children.Remove($TD_UserControl1)
    $TD_UserContrArea.Children.Remove($TD_UserControl2)
    $TD_UserContrArea.Children.Remove($TD_UserControl3)
    $TD_UserContrArea.Children.Remove($TD_UserControl4)
    $TD_UserContrArea.Children.Remove($TD_UserControl6)
    if($TD_LogoImageSmall.Visibility -eq "hidden"){$TD_LogoImageSmall.Visibility = "visible"}
})
$MainWindow.showDialog()

$MainWindow.activate()

}