function IBM_BaseStorageInfos {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("FSystem","SVC")]
        [string]$TD_Storage = "FSystem",
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        $TD_lb_BaseStorageErrorInfo.Visibility="Collapsed"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        switch ($TD_Storage) {
            "FSystem" { 
                if($TD_Device_ConnectionTyp -eq "ssh"){
                    $TD_BaseInformations = ssh $TD_Device_UserName@$TD_Device_DeviceIP 'lsnodecanister -delim : && lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister -delim : $id ;echo;done'
                }else {
                    $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -delim : && lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister -delim : $id ;echo;done'
              }
            }
            "SVC" { 
                if($TD_Device_ConnectionTyp -eq "ssh"){
                    $TD_BaseInformations = ssh $TD_Device_UserName@$TD_Device_DeviceIP 'lsnode -delim : && lsnode -nohdr |while read id name IO_group_id;do lsnode -delim : $id;echo;done'
                }else {
                    $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnode -delim : && lsnode -nohdr |while read id name IO_group_id;do lsnode -delim : $id;echo;done'
                }
             }
            Default {}
        }
        $TD_BaseInformations = $TD_BaseInformations |Select-Object -Skip 1
    }
    
    process {
        $TD_StorageInfo = foreach($TD_FSBaseInfo in $TD_BaseInformations){
            $TD_FSBaseTemp = "" | Select-Object ID,Name,WWNN,Status,IO_group_id,IO_group_Name,Serial_Number,Code_Level,Config_Node,SideID,SideName,Prod_MTM
            $TD_FSBaseTemp.ID = ($TD_FSBaseInfo|Select-String -Pattern '^(\d+):' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Name = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.WWNN = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Status = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9-_]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[2].Value
            $TD_FSBaseTemp.IO_group_id = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9-_]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[3].Value
            $TD_FSBaseTemp.IO_group_Name = ($TD_FSBaseInfo|Select-String -Pattern '\d+:([a-zA-Z0-9-_]+):(yes|no):' -AllMatches).Matches.Groups[1].Value
            if($TD_Storage -eq "FSystem"){
               $TD_FSBaseTemp.Serial_Number = ($TD_FSBaseInfo|Select-String -Pattern ':\d+:\d+:([a-zA-Z0-9]+):' -AllMatches).Matches.Groups[1].Value
            }else {
                $TD_FSBaseTemp.Serial_Number = ($TD_FSBaseInfo|Select-String -Pattern ':([a-zA-Z0-9]+):(\d+|):(\d+|):([a-zA-Z0-9]+|):(\d+|):([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            }
            $TD_FSBaseTemp.Config_Node = ($TD_FSBaseInfo|Select-String -Pattern '\d+:([a-zA-Z0-9-_]+):(yes|no):' -AllMatches).Matches.Groups[2].Value
            $TD_FSBaseTemp.SideID = ($TD_FSBaseInfo|Select-String -Pattern ':(\d+|):([a-zA-Z0-9-_]+)$' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.SideName = ($TD_FSBaseInfo|Select-String -Pattern ':(\d+|):([a-zA-Z0-9-_]+)$' -AllMatches).Matches.Groups[2].Value
            $TD_FSBaseTemp.Prod_MTM = ($TD_BaseInformations|Select-String -Pattern '^product_mtm:([a-zA-Z0-9-]+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Code_Level = ($TD_BaseInformations|Select-String -Pattern '^code_level:(\d+.\d+.\d+.\d+)' -AllMatches).Matches.Groups[1].Value

            if ((![string]::IsNullOrEmpty($TD_DriveSplitInfos.ProductID))-and(![string]::IsNullOrEmpty($TD_DriveSplitInfos.FWlev))-and(![string]::IsNullOrEmpty($TD_NodeSplitInfo.ProdName))){
                if(($TD_DriveSplitInfos.Serial_Number)-ne($TD_DriveSplitInfosSerial_Number)){
                    [string]$TD_LatestDriveFW = IBM_StorageSWCheck -IBM_CurrentSpectrVirtuFW $TD_FSBaseTemp.Code_Level -IBM_ProdMTM $TD_FSBaseTemp.Prod_MTM
                    $TD_DriveSplitInfosSerial_Number = $TD_DriveSplitInfos.Serial_Number
                    
                    Write-Debug -Message $TD_DriveSplitInfos.FWlev $TD_LatestDriveFW
                    if($TD_DriveSplitInfos.FWlev -eq $TD_LatestDriveFW){
                        [string]$TD_DriveSplitInfos.FWlevStatus = "LightGreen"
                        [string]$TD_DriveSplitInfos.LatestDriveFW = $TD_LatestDriveFW
                    }elseif ($TD_LatestDriveFW -eq "unknown") {
                        [string]$TD_DriveSplitInfos.FWlevStatus = "LightGray"
                        [string]$TD_DriveSplitInfos.LatestDriveFW = $TD_LatestDriveFW
                    }else {    
                        [string]$TD_DriveSplitInfos.FWlevStatus = "Lightyellow"
                        [string]$TD_DriveSplitInfos.LatestDriveFW = $TD_LatestDriveFW
                    }
                }else {
                    if($TD_DriveSplitInfos.FWlev -eq $TD_LatestDriveFW){
                        [string]$TD_DriveSplitInfos.FWlevStatus = "LightGreen"
                        [string]$TD_DriveSplitInfos.LatestDriveFW = $TD_LatestDriveFW
                    }elseif ($TD_LatestDriveFW -eq "unknown") {
                        [string]$TD_DriveSplitInfos.FWlevStatus = "LightGray"
                        [string]$TD_DriveSplitInfos.LatestDriveFW = $TD_LatestDriveFW
                    }else {    
                        [string]$TD_DriveSplitInfos.FWlevStatus = "Lightyellow"
                        [string]$TD_DriveSplitInfos.LatestDriveFW = $TD_LatestDriveFW
                    }
                }
            }
        
            if(([String]::IsNullOrEmpty($TD_FSBaseTemp.ID))){continue}
            $TD_FSBaseTemp
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_BaseInformations.Count) * 100)
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_export -eq "yes"){

            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                $TD_StorageInfo | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_StorageInfo | Export-Csv -Path $PSScriptRoot\Export\$($TD_Line_ID)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
        }else {
            Start-Sleep -Seconds 0.5
            return $TD_StorageInfo
        }
        return $TD_StorageInfo 
    }
}