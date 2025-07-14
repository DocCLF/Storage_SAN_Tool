function SST_SaveLoadToolSettings {
    [CmdletBinding()]
    param (
        [bool]$SST_LoadSettings = $false,
        [bool]$SST_SaveSettings = $false,
        $SST_SavedToolSettings = $null
    )
    
    begin {

        $TD_BTN_SaveToolSettings.Background="#FFDDDDDD"
        $TD_BTN_LoadToolSettings.Background="#FFDDDDDD"
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        try {
            $SST_SavedToolSettings = Get-Item -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Debug -Message $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes
            $TD_BTN_LoadToolSettings.Background="LightCoral"
            $SST_SavedToolSettings = $null
        }
        try {
            $TD_DBisActive = Get-Item -Path "$PSRootPath\Resources\DBFolder\SSTLocalDB.db" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Debug -Message $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes
        }
    }
    
    process {
        <# Can be extended with additional parameters at any time #>

        if($SST_SaveSettings){
            $SST_ExportToolSettings = "" | Select-Object ExportPath,LoadSettingsOnStartUp,DevicestoInExport,OnlineCheckbyImport,LocalDB,ConnectionStringPRISM
            $SST_ExportToolSettings.ExportPath = $TD_tb_ExportPath.Text
            $SST_ExportToolSettings.LoadSettingsOnStartUp = $TD_CB_LoadSettingsatStartUp.IsChecked
            $SST_ExportToolSettings.DevicestoInExport = $TD_DG_KnownDeviceList.ItemsSource
            $SST_ExportToolSettings.OnlineCheckbyImport = $TD_CB_OnlineCheckbyImport.IsChecked
            if((!([string]::IsNullOrEmpty($TD_DBisActive.Name)))-and($PSVersionTable.PSVersion.Major -ge 7)){
                $SST_ExportToolSettings.LocalDB = $true
            }else {
                $SST_ExportToolSettings.LocalDB = $false
            }
            if(!([string]::IsNullOrEmpty($TD_TB_ConnectionStringPRISM.Text))){
                $SST_ExportToolSettings.ConnectionStringPRISM = ConvertTo-SecureString $($TD_TB_ConnectionStringPRISM.Text) -AsPlainText -Force
            }else {
                try {
                    $SST_LoadedToolSettings = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -ErrorAction SilentlyContinue
                    $SST_ExportToolSettings.ConnectionStringPRISM = $SST_LoadedToolSettings.ConnectionStringPRISM                    
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Debug -Message $_.Exception.Message
                    SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes
                }
            }
            try {
                $SST_ExportToolSettings | Export-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" -Confirm:$false
                SST_ToolMessageCollector -TD_ToolMSGCollector "Settings have been saved in Resources folder." -TD_ToolMSGType Message -TD_Shown yes
                $TD_BTN_SaveToolSettings.Background="LightGreen"
            }
            catch {
                Write-Debug -Message $_.Exception.Message
                SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes
                $TD_BTN_SaveToolSettings.Background="LightCoral"
            }
        }
        if($SST_LoadSettings -and ($null -ne $SST_SavedToolSettings)){
            try {
                $SST_LoadedToolSettings = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml" 
                if($SST_LoadedToolSettings.LoadSettingsOnStartUp -eq $true){
                    $TD_tb_ExportPath.Text = $SST_LoadedToolSettings.ExportPath
                    $TD_LB_ExpPathMainWindow.Content = $SST_LoadedToolSettings.ExportPath
                    $TD_CB_LoadSettingsatStartUp.IsChecked = $SST_LoadedToolSettings.LoadSettingsOnStartUp
                    $TD_InportedDevices = $SST_LoadedToolSettings.DevicestoInExport
                    $TD_CB_OnlineCheckbyImport.IsChecked = $SST_LoadedToolSettings.OnlineCheckbyImport
                    if(!([string]::IsNullOrEmpty($SST_LoadedToolSettings.ConnectionStringPRISM))){

                        $ConnectionStringPRISM = [System.Net.NetworkCredential]::new("", $SST_LoadedToolSettings.ConnectionStringPRISM).Password
                        $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
                        $SQLConnection.ConnectionString=$ConnectionStringPRISM
                        $SQLConnection.Open()
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
                    if(($SST_LoadedToolSettings.LocalDB -eq $true)-and($PSVersionTable.PSVersion.Major -ge 7)){
                        $TD_BTN_ActivateDB.Background = "LightGreen"
                        $TD_BTN_ActivateDB.Content = "LocalDB active"
                        $TD_BTN_DeleteDB.Visibility = "Visible"
                    }
                    
                    $TD_BTN_LoadToolSettings.Background="LightGreen"
                }
            }
            catch {
                Write-Debug -Message $_.Exception.Message
                SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes
                $TD_BTN_LoadToolSettings.Background="LightCoral"
            }

        }else {
            if($null -eq $SST_SavedToolSettings -and $SST_SaveSettings -eq $false){
                SST_ToolMessageCollector -TD_ToolMSGCollector "No settings have been loaded, check whether the settings have been saved. (File)" -TD_ToolMSGType Warning -TD_Shown yes
                $TD_BTN_LoadToolSettings.Background="LightCoral"
            }
        }
        if((!([string]::IsNullOrEmpty($TD_DBisActive.Name)))-and($PSVersionTable.PSVersion.Major -ge 7)){
            $TD_BTN_ActivateDB.Background = "LightGreen"
            $TD_BTN_ActivateDB.Content = "LocalDB active"
            $TD_BTN_DeleteDB.Visibility = "Visible"
        }
    }
    
    end {
        if($SST_LoadSettings -and ($null -ne $SST_SavedToolSettings)){
            SST_ImportCredential -SST_ImportDevicesonStartUp yes -SST_ToInportDeviceInfos $TD_InportedDevices
        }
    }
}