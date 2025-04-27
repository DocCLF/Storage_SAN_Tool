function IBM_DriveInfo {
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
            if($TD_Device_ConnectionTyp -eq "ssh"){
                $TD_CollectInfos = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister $id;echo;done && lsdrive -nohdr |while read id name IO_group_id;do lsdrive $id ;echo;done'
            }else {
                $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister $id;echo;done && lsdrive -nohdr |while read id name IO_group_id;do lsdrive $id ;echo;done'
            }
        }else {
            <# Action when all if and elseif conditions are false #>
            $TD_lb_DriveErrorInfo.Visibility = "Visible"; $TD_lb_DriveErrorInfo.Content = "An SVC has hard drives or FlashCore Modules."
        }
        #$TD_CollectInfos = Get-Content -Path "C:\Users\mailt\Documents\lsdrive.txt"
        Write-Debug -Message "Number of Lines: $($TD_CollectInfos.count) "
        0..$TD_CollectInfos.count |ForEach-Object {
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
        [arry]$TD_NodeSplitInfo = foreach($TD_NodeInfoLine in $TD_NodeInfoTemp){
            $TD_NodeSplitInfo.NodeName = ($TD_NodeInfoLine|Select-String -Pattern '^failover_name\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_NodeSplitInfo.ProdName = ($TD_NodeInfoLine|Select-String -Pattern '^product_mtm\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_NodeSplitInfo.NodeFW = ($TD_NodeInfoLine|Select-String -Pattern '^code_level\s+([a-zA-Z0-9-_.]+)' -AllMatches).Matches.Groups[1].Value
            Write-Debug -Message $TD_NodeSplitInfo
        }

        <# Drive Info #>
        $TD_DriveSplitInfos = "" | Select-Object DriveID,DriveStatus,DriveCap,ProductID,FWlev,LatestDriveFW,Slot,PhyDriveCap,PhyUsedDriveCap,EffeUsedDriveCap,FWlevStatus
        foreach($TD_CollectInfo in $TD_CollectInfosTemp){
            [int]$TD_DriveSplitInfos.DriveID = ($TD_CollectInfo|Select-String -Pattern '^id\s+(\d+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.DriveStatus = ($TD_CollectInfo|Select-String -Pattern '^status\s+(online|offline|degraded)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.DriveCap = ($TD_CollectInfo|Select-String -Pattern '^capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.ProductID = ($TD_CollectInfo|Select-String -Pattern '^product_id\s+([A-Z0-9]+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.FWlev = ($TD_CollectInfo|Select-String -Pattern '^firmware_level\s+([A-Z0-9_]+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.Slot = ($TD_CollectInfo|Select-String -Pattern '^slot_id\s+(\d+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.PhyDriveCap = ($TD_CollectInfo|Select-String -Pattern '^physical_capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.PhyUsedDriveCap = ($TD_CollectInfo|Select-String -Pattern '^physical_used_capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_DriveSplitInfos.EffeUsedDriveCap = ($TD_CollectInfo|Select-String -Pattern '^effective_used_capacity\s+(\d+\.\d+\w+)' -AllMatches).Matches.Groups[1].Value

            if ((![string]::IsNullOrEmpty($TD_DriveSplitInfos.ProductID))-and(![string]::IsNullOrEmpty($TD_DriveSplitInfos.FWlev))-and(![string]::IsNullOrEmpty($TD_NodeSplitInfo.ProdName))){
                if(($TD_DriveSplitInfos.ProductID)-ne($TD_DriveSplitInfosProductID)){
                    [string]$TD_LatestDriveFW = IBM_DriveFirmwareCheck -IBM_DriveProdID $TD_DriveSplitInfos.ProductID -IBM_DriveCurrentFW $TD_DriveSplitInfos.FWlev -IBM_ProdMTM $TD_NodeSplitInfo.ProdName
                    $TD_DriveSplitInfosProductID = $TD_DriveSplitInfos.ProductID
                    
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
            <# Not the best option but for the first stepp ok #>
            if($TD_TransProt -eq "nvme"){
                if (![string]::IsNullOrEmpty($TD_DriveSplitInfos.EffeUsedDriveCap)){
                    $TD_DriveOverview += $TD_DriveSplitInfos
                    Write-Debug -Message  $TD_DriveOverview
                    $TD_DriveSplitInfos = "" | Select-Object DriveID,DriveStatus,DriveCap,ProductID,FWlev,LatestDriveFW,Slot,PhyDriveCap,PhyUsedDriveCap,EffeUsedDriveCap,FWlevStatus
                }
            }else{
                if (![string]::IsNullOrEmpty($TD_DriveSplitInfos.PhyDriveCap)){
                    $TD_DriveOverview += $TD_DriveSplitInfos
                    Write-Debug -Message  $TD_DriveOverview
                    $TD_DriveSplitInfos = "" | Select-Object DriveID,DriveStatus,DriveCap,ProductID,FWlev,LatestDriveFW,Slot,PhyDriveCap,PhyUsedDriveCap,EffeUsedDriveCap,FWlevStatus
                }
            }

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_CollectInfosTemp.Count) * 100)

        }
    }

    end{
        Close-ProgressBar -ProgressBar $ProgressBar
        if(($TD_Line_ID -eq 1) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoOne.Visibility = "Visible"; $TD_lb_DriveInfoOne.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"    ;$TD_CB_STO_DG1.IsChecked="true";$TD_CB_STO_DG1.Visibility="visible";$TD_LB_STO_DG1.Visibility="visible"; $TD_LB_STO_DG1.Content=$TD_Device_DeviceName }
        if(($TD_Line_ID -eq 2) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoTwo.Visibility = "Visible"; $TD_lb_DriveInfoTwo.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"    ;$TD_CB_STO_DG2.IsChecked="true";$TD_CB_STO_DG2.Visibility="visible";$TD_LB_STO_DG2.Visibility="visible"; $TD_LB_STO_DG2.Content=$TD_Device_DeviceName }
        if(($TD_Line_ID -eq 3) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoThree.Visibility = "Visible"; $TD_lb_DriveInfoThree.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)";$TD_CB_STO_DG3.IsChecked="true";$TD_CB_STO_DG3.Visibility="visible";$TD_LB_STO_DG3.Visibility="visible"; $TD_LB_STO_DG3.Content=$TD_Device_DeviceName }
        if(($TD_Line_ID -eq 4) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoFour.Visibility = "Visible"; $TD_lb_DriveInfoFour.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"  ;$TD_CB_STO_DG4.IsChecked="true";$TD_CB_STO_DG4.Visibility="visible";$TD_LB_STO_DG4.Visibility="visible"; $TD_LB_STO_DG4.Content=$TD_Device_DeviceName }
        if(($TD_Line_ID -eq 5) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoFive.Visibility = "Visible"; $TD_lb_DriveInfoFive.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"  ;$TD_CB_STO_DG5.IsChecked="true";$TD_CB_STO_DG5.Visibility="visible";$TD_LB_STO_DG5.Visibility="visible"; $TD_LB_STO_DG5.Content=$TD_Device_DeviceName }
        if(($TD_Line_ID -eq 6) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoSix.Visibility = "Visible"; $TD_lb_DriveInfoSix.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"    ;$TD_CB_STO_DG6.IsChecked="true";$TD_CB_STO_DG6.Visibility="visible";$TD_LB_STO_DG6.Visibility="visible"; $TD_LB_STO_DG6.Content=$TD_Device_DeviceName }
        if(($TD_Line_ID -eq 7) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoSeven.Visibility = "Visible"; $TD_lb_DriveInfoSeven.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)";$TD_CB_STO_DG7.IsChecked="true";$TD_CB_STO_DG7.Visibility="visible";$TD_LB_STO_DG7.Visibility="visible"; $TD_LB_STO_DG7.Content=$TD_Device_DeviceName }
        if(($TD_Line_ID -eq 8) -and ($TD_Storage -eq "FSystem")){$TD_lb_DriveInfoEight.Visibility = "Visible"; $TD_lb_DriveInfoEight.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)";$TD_CB_STO_DG8.IsChecked="true";$TD_CB_STO_DG8.Visibility="visible";$TD_LB_STO_DG8.Visibility="visible"; $TD_LB_STO_DG8.Content=$TD_Device_DeviceName }
        
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