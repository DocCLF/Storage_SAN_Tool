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
        [Parameter(Mandatory)]
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
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        $ProgressBar = New-ProgressBar
        $TD_DriveOverview = @()
        [int]$ProgCounter=0
        <# Connect to Device and get all needed Data #>
        if($TD_Storage -eq "FSystem"){
            if($TD_Device_ConnectionTyp -eq "ssh"){
                $TD_CollectInfos = ssh $TD_Device_UserName@$TD_Device_DeviceIP 'lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister $id;echo;done && lsdrive -nohdr |while read id name IO_group_id;do lsdrive $id ;echo;done'
            }else {
                $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister $id;echo;done && lsdrive -nohdr |while read id name IO_group_id;do lsdrive $id ;echo;done'
            }
        }else {
            <# Action when all if and elseif conditions are false #>
            $TD_lb_DriveErrorInfo.Visibility = "Visible"; $TD_lb_DriveErrorInfo.Content = "An SVC has no any hard drives or FlashCore Modules."
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
        $TD_DriveSplitInfos = "" | Select-Object DriveID,DriveStatus,DriveCap,ProductID,FWlev,Slot,PhyDriveCap,PhyUsedDriveCap,EffeUsedDriveCap
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

            <# Not the best option but for the first stepp ok #>
            If($TD_TransProt -eq "nvme"){
                    if (![string]::IsNullOrEmpty($TD_DriveSplitInfos.EffeUsedDriveCap)){
                        $TD_DriveOverview += $TD_DriveSplitInfos
                        Write-Debug -Message  $TD_DriveOverview
                        $TD_DriveSplitInfos = "" | Select-Object DriveID,DriveStatus,DriveCap,ProductID,FWlev,Slot,PhyDriveCap,PhyUsedDriveCap,EffeUsedDriveCap
                    }
                }else{
                    if (![string]::IsNullOrEmpty($TD_DriveSplitInfos.PhyDriveCap)){
                        $TD_DriveOverview += $TD_DriveSplitInfos
                        Write-Debug -Message  $TD_DriveOverview
                        $TD_DriveSplitInfos = "" | Select-Object DriveID,DriveStatus,DriveCap,ProductID,FWlev,Slot,PhyDriveCap,PhyUsedDriveCap,EffeUsedDriveCap
                    }
                }

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_CollectInfosTemp.Count) * 100)

        }
    }

    end{
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Line_ID -eq 1){$TD_lb_DriveInfoOne.Visibility = "Visible"; $TD_lb_DriveInfoOne.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"}
        if($TD_Line_ID -eq 2){$TD_lb_DriveInfoTwo.Visibility = "Visible"; $TD_lb_DriveInfoTwo.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"}
        if($TD_Line_ID -eq 3){$TD_lb_DriveInfoThree.Visibility = "Visible"; $TD_lb_DriveInfoThree.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"}
        if($TD_Line_ID -eq 4){$TD_lb_DriveInfoFour.Visibility = "Visible"; $TD_lb_DriveInfoFour.Content = "Node Name: $($TD_NodeSplitInfo.NodeName)  Product-Type: $($TD_NodeSplitInfo.ProdName)"}
        
        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                $TD_DriveOverview | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_DriveOverview | Export-Csv -Path $PSScriptRoot\Export\$($TD_Line_ID)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
            Start-Sleep -Seconds 0.2
        }else {
            <# output on the promt #>
            Write-Host "Result for:`nName: $($TD_NodeSplitInfo.NodeName) `nProduct: $($TD_NodeSplitInfo.ProdName) `nFirmware: $($TD_NodeSplitInfo.NodeFW)`n`n" -ForegroundColor Yellow
            Start-Sleep -Seconds 0.2
            return $TD_DriveOverview
        }
        return $TD_DriveOverview

    }
}
