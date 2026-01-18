function IBM_SSHBaseStorageInfos {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
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
            "SVC" { 
                $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnode -delim : && lsnode -nohdr |while read id name IO_group_id;do lsnode -delim : $id ;echo;done && lssystem -delim , |grep name'
                $TD_BaseInformations = $TD_BaseInformations |Select-Object -Skip 1
            }
            Default {
                $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -delim : && lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister -delim : $id ;echo;done && lssystem -delim , |grep name'
                $TD_BaseInformations = $TD_BaseInformations |Select-Object -Skip 1
            }
        }
        Clear-Variable -Name TD_Device_PW -Force
    }

    process {
        $TD_SystemInfo = IBM_SystemInfo -TD_Line_ID $TD_Line_ID -TD_Device_ConnectionTyp $TD_Device_ConnectionTyp -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
        $TD_StorageInfo = foreach($TD_FSBaseInfo in $TD_BaseInformations){
            $TD_FSBaseTemp = "" | Select-Object RowID,ID,Name,ClusterName,WWNN,Status,IO_group_id,IO_group_Name,SerialNumber,CodeLevel,ConfigNode,SideID,SideName,Prod_MTM,RecommendedPTF,MDiskTotalCapacity,MDiskFreeCapacity,MDiskUsedCapacity,PhysicalTotalCapacity,PhysicalFreeCapacity,HostUnmap,BackendUnmap,Topology,Layer,QuorumMode
            $TD_FSBaseTemp.ID = ($TD_FSBaseInfo|Select-String -Pattern '^(\d+):' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Name = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.ClusterName = ($TD_BaseInformations|Select-String -Pattern '^name\,([\w\-]+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.WWNN = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.Status = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9-_]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[2].Value
            $TD_FSBaseTemp.IO_group_id = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9-_]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[3].Value
            $TD_FSBaseTemp.IO_group_Name = ($TD_FSBaseInfo|Select-String -Pattern '\d+:([a-zA-Z0-9-_]+):(yes|no):' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseBackEndSerial_Number = ($TD_FSBaseInfo|Select-String -Pattern ':\d+:\d+:([a-zA-Z0-9]+):' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseSVCSerialNumber = ($TD_FSBaseInfo|Select-String -Pattern ':(\w{6,8}):(|\d+):(|\d+):(|\w{6,8}):' -AllMatches).Matches.Groups[1].Value
            if($TD_Storage -eq "SVC"){
               $TD_FSBaseTemp.SerialNumber = $TD_FSBaseSVCSerialNumber
            }else {
                $TD_FSBaseTemp.SerialNumber = $TD_FSBaseBackEndSerial_Number
            }
            $TD_FSBaseTemp.ConfigNode = ($TD_FSBaseInfo|Select-String -Pattern '\d+:([\w\-]+):(yes|no):' -AllMatches).Matches.Groups[2].Value
            $TD_FSBaseTemp.SideID = ($TD_FSBaseInfo|Select-String -Pattern ':(\d+|):([a-zA-Z0-9-_]+)$' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.SideName = ($TD_FSBaseInfo|Select-String -Pattern ':(\d+|):([a-zA-Z0-9-_]+)$' -AllMatches).Matches.Groups[2].Value
            $TD_FSBaseTemp.Prod_MTM = ($TD_BaseInformations|Select-String -Pattern '^product_mtm:([a-zA-Z0-9-]+)' -AllMatches).Matches.Groups[1].Value
            $TD_FSBaseTemp.CodeLevel = ($TD_BaseInformations|Select-String -Pattern '^code_level:(\d+.\d+.\d+.\d+)' -AllMatches).Matches.Groups[1].Value
            if ((![string]::IsNullOrEmpty($TD_FSBaseTemp.Prod_MTM))-and(![string]::IsNullOrEmpty($TD_FSBaseTemp.CodeLevel))){
                if(($TD_FSBaseTemp.CodeLevel)-ne($TD_FSBaseTempCode_Level)){
                    $TD_SpectrVirtuFWInfos = IBM_StorageSWCheck -IBM_CurrentSpectrVirtuFW $TD_FSBaseTemp.CodeLevel -IBM_ProdMTM $TD_FSBaseTemp.Prod_MTM
                    $TD_FSBaseTempCode_Level = $TD_FSBaseTemp.CodeLevel
                    Write-Debug -Message $TD_FSBaseTemp.CodeLevel $TD_SpectrVirtuFWInfos
                    [string]$TD_FSBaseTemp.RecommendedPTF = $TD_SpectrVirtuFWInfos.RecommendedPTF
                }else {
                    [string]$TD_FSBaseTemp.RecommendedPTF = $TD_SpectrVirtuFWInfos.RecommendedPTF
                }
            }
            $TD_FSBaseTemp.MDiskTotalCapacity=$TD_SystemInfo.'MDiskTotalCapacity'
            $TD_FSBaseTemp.MDiskFreeCapacity=$TD_SystemInfo.'MDiskFreeCapacity'
            $TD_FSBaseTemp.MDiskUsedCapacity=$TD_SystemInfo.'MDiskUsedCapacity'
            $TD_FSBaseTemp.PhysicalTotalCapacity=$TD_SystemInfo.'PhysicalTotalCapacity'
            $TD_FSBaseTemp.PhysicalFreeCapacity=$TD_SystemInfo.'PhysicalFreeCapacity'
            $TD_FSBaseTemp.HostUnmap=$TD_SystemInfo.'HostUnmap'
            $TD_FSBaseTemp.BackendUnmap=$TD_SystemInfo.'BackendUnmap'
            $TD_FSBaseTemp.RowID = "$($TD_FSBaseTemp.SerialNumber)|$($TD_FSBaseTemp.ID)"
            if(([String]::IsNullOrEmpty($TD_FSBaseTemp.ID))){continue}
            $TD_FSBaseTemp
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_BaseInformations.Count) * 100)
        }
        
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        if([string]::IsNullOrEmpty($TD_Device_DeviceName)){$TD_Device_DeviceName = $TD_StorageInfo.Name[0]}
        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_StorageInfo | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_StorageInfo | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }

        [PSCustomObject]@{
            StorageInfo     = $TD_StorageInfo
            ConnectionTyp   = $TD_Device_ConnectionTyp
        }

    }
}