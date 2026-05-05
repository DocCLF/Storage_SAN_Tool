function SST_SaveLoadToolSettings {
    [CmdletBinding()]
    param (
        [bool]$SST_LoadSettings = $false,
        [bool]$SST_SaveSettings = $false,
        [bool]$SST_LoadSettingsBTN = $false,
        $SST_SavedToolSettings = $null,
        $CockpitView
    )
    
    begin {
        $TD_BTN_SaveToolSettings.Background="#F5F7FA"
        $TD_BTN_LoadToolSettings.Background="#F5F7FA"
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        try {
            $SST_SavedToolSettingsDB = SST_ToolSettingsDB -SST_InfoType "LoadToolSettings"
            <# die clixml muss da abgelegt werden wo die Cred abgelegt werden $TD_LB_CerdExportPath.Content #>
            $SST_SavedToolSettingsXML = Get-Item -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -ErrorAction SilentlyContinue
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector $("SaveLoadToolSettings $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown no
            Write-Error $_.Exception.Message
            #$TD_BTN_LoadToolSettings.Background="LightCoral"
            $SST_SavedToolSettingsDB = $null
            $SST_SavedToolSettingsXML = $null
        }
    }
    
    process {
        <# Can be extended with additional parameters at any time #>

        if($SST_SaveSettings){
            <#Save in DB#>  
            $SST_ExportToolSettingsDB = "" | Select-Object LoadSettingsOnStartUp, OnlineCheckbyImport, PRISMactiv, IsCustomer, CustomerNumber
            $SST_ExportToolSettingsDB.LoadSettingsOnStartUp = $TD_CB_LoadSettingsatStartUp.IsChecked
            $SST_ExportToolSettingsDB.OnlineCheckbyImport = $TD_CB_OnlineCheckbyImport.IsChecked
            $SST_ExportToolSettingsDB.PRISMactiv = $TD_CB_PRISMConnectOnOff.IsChecked
            $SST_ExportToolSettingsDB.IsCustomer = $TD_CB_CustomerYN.IsChecked
            $SST_ExportToolSettingsDB.CustomerNumber = $TD_TB_CustomerInfoName.Text
            try {
                SST_ToolSettingsDB -SST_InfoType "SaveToolSettings" -SST_NewDBObject $SST_ExportToolSettingsDB
            }
            catch {
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
            if ($TD_LB_CerdExportPath.Content -ne "Empty") { $TD_LB_CerdExportPath.Content } else { $TD_LB_CerdExportPath.Content = $($TD_TB_ExportPath.Text); Write-Host $($TD_TB_ExportPath.Text)}
            $SST_ExportCustomerSettingsDB = "" | Select-Object CustomerNumber, ExportPath, ExportPathCredential
            $SST_ExportCustomerSettingsDB.CustomerNumber = $TD_TB_CustomerInfoName.Text
            $SST_ExportCustomerSettingsDB.ExportPath = $TD_TB_ExportPath.Text
            $SST_ExportCustomerSettingsDB.ExportPathCredential = $TD_LB_CerdExportPath.Content
            try {
                SST_CustomerDB -SST_InfoType "SaveCustomerSetUp" -SST_NewDBObject $SST_ExportCustomerSettingsDB
            }
            catch {
                Write-Host $_.Exception.Message -ForegroundColor green
            }

            <#Save in clixml as BackUp if there is no Path found to the "normal export"#>
            $SST_ExportToolSettingsXML = "" | Select-Object DevicestoInExport
            $SST_ExportToolSettingsXML.DevicestoInExport = $TD_DG_KnownDeviceList.ItemsSource
            try {
                $SST_ExportToolSettingsXML | Export-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -Confirm:$false
                SST_ToolMessageCollector -TD_ToolMSGCollector "Settings have been saved in Resources folder." -TD_ToolMSGType Message -TD_Shown yes
                $TD_BTN_SaveToolSettings.Background="LightGreen"
            }
            catch {
                SST_ToolMessageCollector -TD_ToolMSGCollector $("Settings have NOT been saved in Resources folder: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
                $TD_BTN_SaveToolSettings.Background="LightCoral"
            }
        }
        <#Load Toolsettings#>
        if($SST_LoadSettingsBTN -or ($SST_LoadSettings -and (($null -ne $SST_SavedToolSettingsXML)-and($SST_SavedToolSettingsDB.LoadSettingsOnStartUp)))){
            try {
                $SST_SavedCustomerSettingsDB = SST_CustomerDB -SST_InfoType "LoadCustomerSetUp" -SST_Customer $SST_SavedToolSettingsDB.CustomerNumber
                $SST_LoadedToolSettingsXML = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" 
                if($SST_SavedToolSettingsDB.LoadSettingsOnStartUp -eq $true){
                    $TD_CB_LoadSettingsatStartUp.IsChecked = $SST_SavedToolSettingsDB.LoadSettingsOnStartUp
                    if($SST_SavedToolSettingsDB.IsCustomer){
                        $TD_CB_CustomerYN.IsChecked = $SST_SavedToolSettingsDB.IsCustomer
                        $TD_TB_CustomerInfoName.Text = $SST_SavedCustomerSettingsDB.CustomerNumber
                        $TD_TB_ExportPath.Text = $SST_SavedCustomerSettingsDB.ExportPath
                        $TD_LB_CerdExportPath.Content = $SST_SavedCustomerSettingsDB.ExportPathCredential
                    }
                    $TD_InportedDevices = $SST_LoadedToolSettingsXML.DevicestoInExport
                    $TD_CB_OnlineCheckbyImport.IsChecked = $SST_SavedToolSettingsDB.OnlineCheckbyImport
                    <# PRISM need a Update if is in Job mode or anything #>
                    $TD_CB_PRISMConnectOnOff.IsChecked = $SST_SavedToolSettingsDB.PRISMactiv
                    if($SST_SavedToolSettingsDB.PRISMactiv){
                        $PRISMData = SST_ToolAdvSaveDB -SST_InfoType "HasData"
                        if($PRISMData){
                            $TD_BTN_SaveAZConnectionPRISM.Visibility = "Collapsed"
                            $TD_TB_CustomerAZPPRISMConString.Visibility = "Collapsed"
                            $TD_TB_CustomerAZPPRISMDB.Visibility = "Collapsed"
                            $TD_TB_CustomerAZPPRISMUM.Visibility = "Collapsed"
                            $TD_TB_CustomerAZPPRISMUMP.Visibility = "Collapsed"
                            $TD_LB_CustomerAZPPRISM.Content="Reset the PRISM connection"
                            $TD_BTN_ChangeAZConnectionPRISM.Visibility = "Visible"
                        }
                    }
                    <# check on startup for later use #>
                    #SST_ExtensionChecker -LoadedToolSettings $SST_LoadedToolSettings -SST_MWOBJ $SST_MWOBJ -SST_UCOBJ $TD_UserControl5
                }else {
                    if($SST_SavedToolSettingsDB.IsCustomer){
                        $TD_CB_CustomerYN.IsChecked = $SST_SavedToolSettingsDB.IsCustomer
                        $TD_TB_CustomerInfoName.Text = $SST_SavedCustomerSettingsDB.CustomerNumber
                        $TD_TB_ExportPath.Text = $SST_SavedCustomerSettingsDB.ExportPath
                        $TD_LB_CerdExportPath.Content = $SST_SavedCustomerSettingsDB.ExportPathCredential
                    }
                    $TD_InportedDevices = $SST_LoadedToolSettingsXML.DevicestoInExport
                    $TD_CB_OnlineCheckbyImport.IsChecked = $SST_SavedToolSettingsDB.OnlineCheckbyImport
                    $TD_CB_PRISMConnectOnOff.IsChecked = $SST_SavedToolSettingsDB.PRISMactiv
                }
                
            }
            catch {
                SST_ToolMessageCollector -TD_ToolMSGCollector $("LoadSettings have a Problem: $($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
                Write-Error $_.Exception.Message
            }

        }else {
            if((($null -ne $SST_SavedToolSettingsXML)-and($SST_SavedToolSettingsDB.LoadSettingsOnStartUp)) -and $SST_SaveSettings -eq $false){
                SST_ToolMessageCollector -TD_ToolMSGCollector "No settings have been loaded, check whether the settings have been saved. (File)" -TD_ToolMSGType Warning -TD_Shown yes
                $TD_BTN_LoadToolSettings.Background="LightCoral"
            }
        }
        <# ohne funktion #>
        #if(($TD_DBisActive.count -ge 1)-and($PSVersionTable.PSVersion.Major -ge 5)){
        #    $TD_BTN_ActivateDB.Background = "LightGreen"
        #    $TD_BTN_ActivateDB.Content = "LocalDB active"
        #    $TD_BTN_DeleteDB.Visibility = "Visible"
        #}
    }
    
    end {
        if($SST_LoadSettings -and (($null -ne $SST_SavedToolSettingsXML)-and($SST_SavedToolSettingsDB.LoadSettingsOnStartUp))){
            SST_ImportCredential -SST_ImportDevicesonStartUp "yes" -SST_ToInportDeviceInfos $TD_InportedDevices -CockpitView $CockpitView | Out-Null
        }
        $SST_ExportToolSettingsXML = $null
    }
}