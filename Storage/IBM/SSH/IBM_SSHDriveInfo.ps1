function IBM_SSHDriveInfo {
    <#
    .SYNOPSIS
       Display Drive information
    .DESCRIPTION
        Shows the most important information of the hard disks in my opinion and exports them if desired.
    .NOTES
        Tested from IBM Spectrum Virtualize 8.5.x in combination with pwsh 5.1 and 7.4
    .NOTES
        current Verion: 1.0.2
        fix: TD_* Wildcard at Username, DeviceIP and Export
        
        old Version:
        1.0.1 Initail Release
    .LINK
        IBM Link for lsvdisk: https://www.ibm.com/docs/en/flashsystem-5x00/8.5.x?topic=commands-lsdrive
        GitHub Link for Script support: https://github.com/DocCLF/ps_collection/blob/main/IBM_DriveInfo.ps1
    .EXAMPLE
        IBM_DriveInfo -TD_UserName MoUser -TD_DeviceIP 123.234.345.456 -TD_export no
        Result for: rz1-N1_superstorage
        Product: 4666-AH8
        Firmware: 8.6.0.3

        DriveID          : 35
        DriveCap         : 26.2TB
        PhyDriveCap      : 8.73TB
        PhyUsedDriveCap  : 1.18TB
        EffeUsedDriveCap : 4.50TB
        DriveStatus      : online
        ProductID        : 101406B1
        FWlev            : 3_1_11
        Slot             : 22
    .EXAMPLE
        IBM_DriveInfo -TD_UserName MoUser -TD_DeviceIP 123.234.345.456 -TD_export yes   
        .\NodeName_Drive_Overview_Date.csv 
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Int16]$TD_Line_ID,
        [Parameter(Mandatory)]
        [string]$TD_Device_ConnectionTyp,
        [Parameter(Mandatory)]
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [Parameter(Mandatory)]
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("FSystem","SVC")]
        [string]$TD_Storage = "FSystem",
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    begin {
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        $ProgressBar = New-ProgressBar
        $TD_DriveSplitInfosProductID = ""
        $TD_DriveOverview = @()
        [int]$ProgCounter=0
        <# Connect to Device and get all needed Data #>
        if($TD_Storage -eq "FSystem"){
            $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -nohdr -delim : && lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister $id;echo;done && lsdrive -nohdr |while read id name IO_group_id;do lsdrive $id ;echo;done'
        }
        $TD_TempNodeInfo = "" | Select-Object SerialNumber,WWNN
        0..$TD_CollectInfos.count |ForEach-Object {
            if($TD_CollectInfos[$_] -match ':([0-9a-zA-Z]{16}):'){
                $TD_TempNodeInfo.WWNN = ($TD_CollectInfos[$_]|Select-String -Pattern ':([0-9a-zA-Z]{15,17}):' -AllMatches).Matches.Groups[1].Value
                $TD_TempNodeInfo.SerialNumber = ($TD_CollectInfos[$_]|Select-String -Pattern ':\d:\d:([0-9A-Z]{7}):' -AllMatches).Matches.Groups[1].Value
            }
            <# Split the infos in 2 var #>
            if($TD_CollectInfos[$_] -match '^serial_number'){
                $TD_NodeInfoTemp = $TD_CollectInfos |Select-Object -First $_
                $TD_CollectInfosTemp = $TD_CollectInfos |Select-Object -Skip $_
                if([string]::IsNullOrEmpty($TD_TransProt)){
                    $TD_TransProt = (($TD_CollectInfos|Select-String -Pattern '^transport_protocol\s+(\w+)' -AllMatches).Matches.Groups[1].Value)
                }
            }
        }
        Start-Sleep -Seconds 0.2
    }
    
    process {
        
        <# Node Info#>
        $TD_NodeSplitInfo = "" | Select-Object NodeName,ProdName,NodeFW
        [array]$TD_NodeSplitInfo = foreach($TD_NodeInfoLine in $TD_NodeInfoTemp){
            $TD_NodeSplitInfo.NodeName = ($TD_NodeInfoLine|Select-String -Pattern '^failover_name\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_NodeSplitInfo.ProdName = ($TD_NodeInfoLine|Select-String -Pattern '^product_mtm\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_NodeSplitInfo.NodeFW = ($TD_NodeInfoLine|Select-String -Pattern '^code_level\s+([a-zA-Z0-9-_.]+)' -AllMatches).Matches.Groups[1].Value
            Write-Debug -Message $TD_NodeSplitInfo
        }

        <# Drive Info #>
        $TD_DriveSplitInfos = "" | Select-Object RowID,ID,Status,Capacity,ProductID,FirmwareLevel,LatestFirmwareLevel,SlotID,PhysicalCapacity,PhysicalUsedCapacity,EffectiveUsedCapacity,FirmwareLevelStatus,SerialNumber,WWNN
        foreach($TD_CollectInfo in $TD_CollectInfosTemp){
            [int]$TD_DriveSplitInfos.ID = ($TD_CollectInfo|Select-String -Pattern '^id\s+(\d+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.Status = ($TD_CollectInfo|Select-String -Pattern '^status\s+(online|offline|degraded)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.Capacity = ($TD_CollectInfo|Select-String -Pattern '^capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.ProductID = ($TD_CollectInfo|Select-String -Pattern '^product_id\s+([A-Z0-9]+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.FirmwareLevel = ($TD_CollectInfo|Select-String -Pattern '^firmware_level\s+([A-Z0-9_]+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.SlotID = ($TD_CollectInfo|Select-String -Pattern '^slot_id\s+(\d+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.PhysicalCapacity = ($TD_CollectInfo|Select-String -Pattern '^physical_capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.PhysicalUsedCapacity = ($TD_CollectInfo|Select-String -Pattern '^physical_used_capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.EffectiveUsedCapacity = ($TD_CollectInfo|Select-String -Pattern '^effective_used_capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value

            if ((![string]::IsNullOrEmpty($TD_DriveSplitInfos.ProductID))-and(![string]::IsNullOrEmpty($TD_DriveSplitInfos.FirmwareLevel))-and(![string]::IsNullOrEmpty($TD_NodeSplitInfo.ProdName))){
                if(($TD_DriveSplitInfos.ProductID)-ne($TD_DriveSplitInfosProductID)){
                    [string]$TD_LatestDriveFW = IBM_DriveFirmwareCheck -IBM_DriveProdID $TD_DriveSplitInfos.ProductID -IBM_DriveCurrentFW $TD_DriveSplitInfos.FirmwareLevel -IBM_ProdMTM $TD_NodeSplitInfo.ProdName
                    $TD_DriveSplitInfosProductID = $TD_DriveSplitInfos.ProductID
                    
                    Write-Debug -Message $TD_DriveSplitInfos.FirmwareLevel $TD_LatestDriveFW
                    if($TD_LatestDriveFW -like "*$($TD_DriveSplitInfos.FirmwareLevel)*"){
                        [string]$TD_DriveSplitInfos.FirmwareLevelStatus = "LightGreen"
                        [string]$TD_DriveSplitInfos.LatestDriveFW = $TD_LatestDriveFW
                    }elseif ($TD_LatestDriveFW -eq "unknown") {
                        [string]$TD_DriveSplitInfos.FirmwareLevelStatus = "LightGray"
                        [string]$TD_DriveSplitInfos.LatestFirmwareLevel = $TD_LatestDriveFW
                    }else {    
                        [string]$TD_DriveSplitInfos.FirmwareLevelStatus = "Lightyellow"
                        [string]$TD_DriveSplitInfos.LatestFirmwareLevel = $TD_LatestDriveFW
                    }
                }else {
                    if($TD_LatestDriveFW -like "*$($TD_DriveSplitInfos.FirmwareLevel)*" ){
                        [string]$TD_DriveSplitInfos.FirmwareLevelStatus = "LightGreen"
                        [string]$TD_DriveSplitInfos.LatestFirmwareLevel = $TD_LatestDriveFW
                    }elseif ($TD_LatestDriveFW -eq "unknown") {
                        [string]$TD_DriveSplitInfos.FirmwareLevelStatus = "LightGray"
                        [string]$TD_DriveSplitInfos.LatestFirmwareLevel = $TD_LatestDriveFW
                    }else {    
                        [string]$TD_DriveSplitInfos.FirmwareLevelStatus = "Lightyellow"
                        [string]$TD_DriveSplitInfos.LatestFirmwareLevel = $TD_LatestDriveFW
                    }
                }
            }
            [string]$TD_DriveSplitInfos.WWNN = $TD_TempNodeInfo.WWNN
            [string]$TD_DriveSplitInfos.SerialNumber = $TD_TempNodeInfo.SerialNumber
            $TD_DriveSplitInfos.RowID = "$($TD_DriveSplitInfos.SerialNumber)|$($TD_DriveSplitInfos.DriveID)"
            <# Not the best option but for the first stepp ok #>
            if($TD_TransProt -eq "nvme"){
                if (![string]::IsNullOrEmpty($TD_DriveSplitInfos.EffeUsedDriveCap)){
                    $TD_DriveOverview += $TD_DriveSplitInfos
                    Write-Debug -Message  $TD_DriveOverview
                    $TD_DriveSplitInfos = "" | Select-Object RowID,ID,Status,Capacity,ProductID,FirmwareLevel,LatestFirmwareLevel,SlotID,PhysicalCapacity,PhysicalUsedCapacity,EffectiveUsedCapacity,FirmwareLevelStatus,SerialNumber,WWNN
                }
            }else{
                if (![string]::IsNullOrEmpty($TD_DriveSplitInfos.PhyDriveCap)){
                    $TD_DriveOverview += $TD_DriveSplitInfos
                    Write-Debug -Message  $TD_DriveOverview
                    $TD_DriveSplitInfos = "" | Select-Object RowID,ID,Status,Capacity,ProductID,FirmwareLevel,LatestFirmwareLevel,SlotID,PhysicalCapacity,PhysicalUsedCapacity,EffectiveUsedCapacity,FirmwareLevelStatus,SerialNumber,WWNN
                }
            }

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_CollectInfosTemp.Count) * 100)
        }
    }

    end{
        Close-ProgressBar -ProgressBar $ProgressBar
        SST_CustomerSTODBInsertTable -SST_InfoType "StorageDrive" -SST_CollectedInformations $TD_DriveOverview
        
        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_DriveOverview | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug -TD_Shown no
            }else {
                $TD_DriveOverview | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug -TD_Shown no
            }
            Start-Sleep -Seconds 0.2
        }else {
            <# output on the promt #>
            SST_ToolMessageCollector -TD_ToolMSGCollector "Result for:`nName: $($TD_NodeSplitInfo.NodeName) `nProduct: $($TD_NodeSplitInfo.ProdName) `nFirmware: $($TD_NodeSplitInfo.NodeFW)" -TD_ToolMSGType Debug -TD_Shown no
            Start-Sleep -Seconds 0.2
            return $TD_DriveOverview
        }
        return $TD_DriveOverview
    }
}