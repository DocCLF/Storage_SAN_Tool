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
$ColorStyles = [Windows.Markup.XamlReader]::Parse((Get-Content -Path "$PSRootPath\Resources\Styles\ColorStyle.xaml" -Raw))
$AppStyles = [Windows.Markup.XamlReader]::Parse((Get-Content -Path "$PSRootPath\Resources\Styles\AppStyle.xaml" -Raw))
$TextBoxStyles = [Windows.Markup.XamlReader]::Parse((Get-Content -Path "$PSRootPath\Resources\Styles\TextBoxStyle.xaml" -Raw))
$ButtonStyles = [Windows.Markup.XamlReader]::Parse((Get-Content -Path "$PSRootPath\Resources\Styles\ButtonStyle.xaml" -Raw))

foreach ($style in $ColorStyles,$AppStyles,$TextBoxStyles,$ButtonStyles){
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
    }
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