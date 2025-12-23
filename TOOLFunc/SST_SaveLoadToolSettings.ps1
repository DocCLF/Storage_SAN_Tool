function SST_SaveLoadToolSettings {
    [CmdletBinding()]
    param (
        [bool]$SST_LoadSettings = $false,
        [bool]$SST_SaveSettings = $false,
        $SST_SavedToolSettings = $null,
        $CockpitView
    )
    
    begin {
        $TD_BTN_SaveToolSettings.Background="#FFDDDDDD"
        $TD_BTN_LoadToolSettings.Background="#FFDDDDDD"
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        try {
            $SST_SavedToolSettingsDB = SST_ToolDB -SST_InfoType "LoadToolSettings"
            $SST_SavedToolSettingsXML = Get-Item -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -ErrorAction SilentlyContinue
        }
        catch {
            #SST_ToolMessageCollector -TD_ToolMSGCollector $("SaveLoadToolSettings $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown no
            Write-Error $_.Exception.Message
            $TD_BTN_LoadToolSettings.Background="LightCoral"
            $SST_SavedToolSettingsDB = $null
            $SST_SavedToolSettingsXML = $null
        }
        try {
            $TD_DBisActive = Get-Item -Path "$PSRootPath\Resources\DBFolder\*" -Filter "*.db" -ErrorAction SilentlyContinue
        }
        catch {
            #SST_ToolMessageCollector -TD_ToolMSGCollector $("SaveLoadToolSettings $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
        }
    }
    
    process {
        <# Can be extended with additional parameters at any time #>

        if($SST_SaveSettings){
            <#Save in DB#>  
            $SST_ExportToolSettingsDB = "" | Select-Object LoadSettingsOnStartUp, OnlineCheckbyImport, PRISMactiv, IsCustomer
            $SST_ExportToolSettingsDB.LoadSettingsOnStartUp = $TD_CB_LoadSettingsatStartUp.IsChecked
            $SST_ExportToolSettingsDB.OnlineCheckbyImport = $TD_CB_OnlineCheckbyImport.IsChecked
            $SST_ExportToolSettingsDB.PRISMactiv = $TD_CB_PRISMConnectOnOff.IsChecked
            $SST_ExportToolSettingsDB.IsCustomer = $TD_CB_CustomerYN.IsChecked
            try {
                SST_ToolDB -SST_InfoType "SaveToolSettings" -SST_NewDBObject $SST_ExportToolSettingsDB
            }
            catch {
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
            

            $SST_ExportCustomerSettingsDB = "" | Select-Object CustomerName, ExportPath, ExportPathCredential
            $SST_ExportCustomerSettingsDB.CustomerName = $TD_TB_CustomerInfoName.Text
            $SST_ExportCustomerSettingsDB.ExportPath = $TD_TB_ExportPath.Text
            $SST_ExportCustomerSettingsDB.ExportPathCredential = $TD_LB_CerdExportPath.Content
            try {
                SST_CustomerDB -SST_InfoType "SaveCustomerSetUp" -SST_NewDBObject $SST_ExportCustomerSettingsDB
            }
            catch {
                Write-Host $_.Exception.Message -ForegroundColor Cyan
            }

            <#Save in clixml#>
            $SST_ExportToolSettingsXML = "" | Select-Object DevicestoInExport,ConnectionStringPRISM,CustomerNumber
            $SST_ExportToolSettingsXML.DevicestoInExport = $TD_DG_KnownDeviceList.ItemsSource
            
            if(!([string]::IsNullOrEmpty($TD_TB_ConnectionStringPRISM.Password))){
                $SST_ExportToolSettingsXML.ConnectionStringPRISM = ConvertTo-SecureString -String ([string]$($TD_TB_ConnectionStringPRISM.Password)) -AsPlainText -Force
                $SST_ExportToolSettingsXML.CustomerNumber = $TD_TB_CustomerNumberPRISM.Text
            }else {
                try {
                    $SST_LoadedToolSettings = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -ErrorAction SilentlyContinue
                    $SST_ExportToolSettingsXML.ConnectionStringPRISM = $SST_LoadedToolSettings.ConnectionStringPRISM   
                    $SST_ExportToolSettingsXML.CustomerNumber = $SST_LoadedToolSettings.CustomerNumber                 
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    #SST_ToolMessageCollector -TD_ToolMSGCollector $("Settings import failed: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
                }
            }
            try {
                $SST_ExportToolSettingsXML | Export-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -Confirm:$false
                #SST_ToolMessageCollector -TD_ToolMSGCollector "Settings have been saved in Resources folder." -TD_ToolMSGType Message -TD_Shown yes
                $TD_BTN_SaveToolSettings.Background="LightGreen"
            }
            catch {
                #SST_ToolMessageCollector -TD_ToolMSGCollector $("Settings have NOT been saved in Resources folder: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
                $TD_BTN_SaveToolSettings.Background="LightCoral"
            }
        }
        Write-Host ($SST_LoadSettings -and (($null -ne $SST_SavedToolSettingsXML)-and($null -ne $SST_SavedToolSettingsDB)))
        if($SST_LoadSettings -and (($null -ne $SST_SavedToolSettingsXML)-and($null -ne $SST_SavedToolSettingsDB))){
            try {
                $SST_SavedCustomerSettingsDB = SST_CustomerDB -SST_InfoType "LoadCustomerSetUp"
                Write-Host $SST_SavedCustomerSettingsDB
                $SST_LoadedToolSettingsXML = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" 
                if($SST_SavedToolSettingsDB.LoadSettingsOnStartUp -eq $true){
                    $TD_CB_LoadSettingsatStartUp.IsChecked = $SST_SavedToolSettingsDB.LoadSettingsOnStartUp
                    if($SST_SavedToolSettingsDB.IsCustomer){
                        $TD_CB_CustomerYN.IsChecked = $SST_SavedToolSettingsDB.IsCustomer
                        $TD_TB_CustomerInfoName.Text = $SST_SavedCustomerSettingsDB.CustomerName
                        $TD_TB_ExportPath.Text = $SST_SavedCustomerSettingsDB.ExportPath
                        $TD_LB_CerdExportPath.Content = $SST_SavedCustomerSettingsDB.ExportPathCredential
                    }
                    $TD_InportedDevices = $SST_LoadedToolSettingsXML.DevicestoInExport
                    $TD_CB_OnlineCheckbyImport.IsChecked = $SST_SavedToolSettingsDB.OnlineCheckbyImport
                    $TD_CB_PRISMConnectOnOff.IsChecked = $SST_SavedToolSettingsDB.PRISMactiv
                    if($SST_SavedToolSettingsDB.PRISMactiv){
                        $TD_TB_CustomerNumberPRISM.Text = $SST_LoadedToolSettingsXML.CustomerNumber
                        $ConnectionStringPRISM = [System.Net.NetworkCredential]::new("", $SST_LoadedToolSettingsXML.ConnectionStringPRISM).Password
                        $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
                        $SQLConnection.ConnectionString=$ConnectionStringPRISM
                        while ($SQLConnection.State -eq "close") {
                            $SQLConnection.Open()
                        }
                        if($SQLConnection.State -eq 'Open'){
                            $TD_TB_ConnectionStringPRISM.Visibility = "Collapsed"
                            $TD_BTN_SaveConnectionStringPRISM.Content = "Connection String loaded"
                            $TD_BTN_SaveConnectionStringPRISM.Background = "LightGreen"
                            $TD_BTN_ChangeConnectionStringPRISM.Visibility = "Visible"
                            $SQLConnection.Close()
                        }else{
                            <# something should happen if not #>
                        }
                    }
                    <# check on startup for later use #>
                    #SST_ExtensionChecker -LoadedToolSettings $SST_LoadedToolSettings -SST_MWOBJ $SST_MWOBJ -SST_UCOBJ $TD_UserControl5
                }else {
                    if($SST_SavedToolSettingsDB.IsCustomer){
                        $TD_CB_CustomerYN.IsChecked = $SST_SavedToolSettingsDB.IsCustomer
                        $TD_TB_CustomerInfoName.Text = $SST_SavedCustomerSettingsDB.CustomerName
                        $TD_TB_ExportPath.Text = $SST_SavedCustomerSettingsDB.ExportPath
                        $TD_LB_CerdExportPath.Content = $SST_SavedCustomerSettingsDB.ExportPathCredential
                    }
                    $TD_InportedDevices = $SST_LoadedToolSettingsXML.DevicestoInExport
                    $TD_CB_OnlineCheckbyImport.IsChecked = $SST_SavedToolSettingsDB.OnlineCheckbyImport
                    $TD_CB_PRISMConnectOnOff.IsChecked = $SST_SavedToolSettingsDB.PRISMactiv
                }
                
            }
            catch {
                #SST_ToolMessageCollector -TD_ToolMSGCollector $("LoadSettings have a Problem: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
                Write-Error $_.Exception.Message
            }

        }else {
            if((($null -ne $SST_SavedToolSettingsXML)-and($null -ne $SST_SavedToolSettingsDB)) -and $SST_SaveSettings -eq $false){
                #SST_ToolMessageCollector -TD_ToolMSGCollector "No settings have been loaded, check whether the settings have been saved. (File)" -TD_ToolMSGType Warning -TD_Shown yes
                $TD_BTN_LoadToolSettings.Background="LightCoral"
            }
        }
        if(($TD_DBisActive.count -ge 1)-and($PSVersionTable.PSVersion.Major -ge 5)){
            $TD_BTN_ActivateDB.Background = "LightGreen"
            $TD_BTN_ActivateDB.Content = "LocalDB active"
            $TD_BTN_DeleteDB.Visibility = "Visible"
        }
    }
    
    end {
        if($SST_LoadSettings -and (($null -ne $SST_SavedToolSettingsXML)-and($null -ne $SST_SavedToolSettingsDB))){
            #SST_ImportCredential -SST_ImportDevicesonStartUp yes -SST_ToInportDeviceInfos $TD_InportedDevices -CockpitView $CockpitView | Out-Null
        }
        $SST_ExportToolSettingsXML = $null
    }
}