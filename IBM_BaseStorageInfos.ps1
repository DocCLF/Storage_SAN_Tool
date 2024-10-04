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
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        switch ($TD_Storage) {
            "FSystem" { 
                if($TD_Device_ConnectionTyp -eq "ssh"){
                    $TD_BaseInformations = ssh $TD_Device_UserName@$TD_Device_DeviceIP 'lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister -delim : $id;echo;done'
                }else {
                    $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister -delim : $id;echo;done'
                }
              }
            "SVC" { 
                if($TD_Device_ConnectionTyp -eq "ssh"){
                    $TD_BaseInformations = ssh $TD_Device_UserName@$TD_Device_DeviceIP 'lsnode -nohdr |while read id name IO_group_id;do lsnode -delim : $id;echo;done'
                }else {
                    $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnode -nohdr |while read id name IO_group_id;do lsnode -delim : $id;echo;done'
                }
             }
            Default {}
        }
    }
    
    process {

        $TD_StorageInfo = foreach($TD_FSBaseInfo in $TD_BaseInformations){
            $TD_FSBaseTemp = "" | Select-Object ID,Name,WWNN,Status,IO_group_id,IO_group_Name,Serial_Number,Product_MTM,Code_Level,Config_Node
            $TD_FSBaseTemp.ID = ($TD_FSBaseInfo|Select-String -Pattern '^id:(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Name = ($TD_FSBaseInfo|Select-String -Pattern '^name:(.*)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.WWNN = ($TD_FSBaseInfo|Select-String -Pattern '^WWNN:(.*)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Status = ($TD_FSBaseInfo|Select-String -Pattern '^status:(.*)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.IO_group_id = ($TD_FSBaseInfo|Select-String -Pattern '^IO_group_id:(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.IO_group_Name = ($TD_FSBaseInfo|Select-String -Pattern '^IO_group_name:(.*)' -AllMatches).Matches.Groups[1].Value
            if($TD_Storage -eq "FSystem"){
                $TD_FSBaseTemp.Serial_Number = ($TD_FSBaseInfo|Select-String -Pattern '^enclosure_serial_number:(.*)' -AllMatches).Matches.Groups[1].Value
            }else {
                $TD_FSBaseTemp.Serial_Number = ($TD_FSBaseInfo|Select-String -Pattern '^serial_number:(.*)' -AllMatches).Matches.Groups[1].Value
            }
            $TD_FSBaseTemp.Product_MTM = ($TD_FSBaseInfo|Select-String -Pattern '^product_mtm:(.*)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Code_Level = ($TD_FSBaseInfo|Select-String -Pattern '^code_level:(\d+.\d+.\d+.\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Config_Node = ($TD_FSBaseInfo|Select-String -Pattern '^config_node:(yes|no)' -AllMatches).Matches.Groups[1].Value

            if($TD_FSBaseInfo |Select-String -Pattern "^$"){
                $TD_FSBaseTemp
                $TD_FSBaseTemp = "" | Select-Object ID,Name,WWNN,Status,IO_group_id,IO_group_Name,Enclosure_Serial_Number,Product_MTM,Code_Level,Config_Node
            }
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_BaseInformations.Count) * 100)
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                $TD_StorageInfo | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_StorageInfo | Export-Csv -Path $PSScriptRoot\Export\$($TD_Line_ID)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
            #Write-Host "The Export can be found at $TD_Exportpath " -ForegroundColor Green
            #Invoke-Item "$TD_Exportpath\FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv"
        }else {
            <# output on the promt #>
            #Write-Host "Result:`n" -ForegroundColor Yellow
            Start-Sleep -Seconds 0.5
            return $TD_StorageInfo
        }
	    #Write-Host $TD_PortStats_Overview -ForegroundColor Yellow
        return $TD_StorageInfo
        <# wait a moment #>
        #Start-Sleep -Seconds 1
        <# Cleanup all TD* Vars #>
        #Clear-Variable TD* -Scope Global
    }
}