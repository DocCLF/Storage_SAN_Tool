function SST_ImportCredential {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$SST_ImportDevicesonStartUp = "no",
        $SST_ToInportDeviceInfos
    )
    if($SST_ImportDevicesonStartUp -eq "no"){
        $TD_ImportCredentialObjs = SST_OpenFile_from_Directory

        if($TD_ImportCredentialObjs.FileName -ne ""){
            $TD_ImportedCredentials = Import-Clixml -Path $TD_ImportCredentialObjs.FileName 
            <# must used this line if there is only one entry #>
        }
    }else {
        <# give them the object to import them in the DG #>
        $TD_ImportedCredentials = $SST_ToInportDeviceInfos
    }

    [array]$TD_ExportCredtoDG = $TD_ImportedCredentials | Where-Object { $_ }
    $TD_DG_KnownDeviceList.ItemsSource = $TD_ExportCredtoDG
    <# if the TD_CB_OnlineCheckbyImport is checked this part will connect to the devices #>
    if(($TD_CB_OnlineCheckbyImport.IsChecked)-and($SST_ImportDevicesonStartUp -eq "yes")){
        $TD_ExportCredtoDG | ForEach-Object {
            SST_DeviceConnecCheck -TD_Selected_Items "yes" -TD_Selected_DeviceType $_.DeviceTyp -TD_Selected_DeviceConnectionType $_.ConnectionTyp -TD_Selected_DeviceIPAddr $_.IPAddress -TD_Selected_DeviceUserName $_.UserName -TD_Selected_DevicePassword $_.Password -TD_Selected_SVCorVF $_.SVCorVF
            Start-Sleep -Seconds 0.5
        }
    }
   #$TD_ExportCredtoDG
}