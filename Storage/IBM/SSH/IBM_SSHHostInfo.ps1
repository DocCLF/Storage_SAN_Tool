function IBM_SSHHostInfo {
    <#
    .SYNOPSIS
        Displays a list of host/cluster infos
    .NOTES
        v1.0.1
    .NOTES
        Tested with version IBM Spectrum Virtualize Software 7.8.x to 8.6.x
    .LINK
        
    .EXAMPLE

    .EXAMPLE

    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Storage,
        [string]$TD_Exportpath
    )
    
    begin {
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"

        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        
        if($TD_Storage -eq "SVC"){
            $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lshost -nohdr |while read id name IO_group_id;do lshost -delim : $id ;echo;done && lsnode -delim . -nohdr && lssystem -delim . |grep name'
        }else {
            $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lshost -nohdr |while read id name IO_group_id;do lshost -delim : $id ;echo;done && lsnodecanister -delim . -nohdr && lssystem -delim . |grep name'
        }

        $TD_EventSplitInfoWWNN = ($TD_CollectInfos|Select-String -Pattern '\.([0-9a-zA-Z]{14,18})\.' -AllMatches).Matches.Groups[1].Value
        $TD_STOName = ($TD_CollectInfos|Select-String -Pattern '^name\.([\w\-\.]+)' -AllMatches).Matches.Groups[1].Value
        if($TD_Storage -eq "SVC"){
            $TD_FSBaseSerialNumber = ($TD_CollectInfos|Select-String -Pattern '\.(\w{6,8})\.(|\d+)\.(|\d+)\.(|\w{6,8})' -AllMatches).Matches.Groups[1].Value
        }else{
            $TD_FSBaseSerialNumber = ($TD_CollectInfos|Select-String -Pattern '\.\d+\.\d+\.(\w{6,8})\.' -AllMatches).Matches.Groups[1].Value
        }
        $TD_CollectInfos = $TD_CollectInfos | Select-Object -SkipLast 6

        if([string]::IsNullOrWhiteSpace($TD_Device_DeviceName)){
            $TD_Device_DeviceName = $TD_STOName
        }
    }
    
    process {
        $iCounter=0;
        $TD_HostBaseTemp = "" | Select-Object RowID,ID,HostName,PortCount,Type,Status,HostStateInfo,SiteName,HostClusterName,Protocol,StatusPolicy,StatusSite,WWPNOne,NodeLoggedInCountOne,StateOne,WWPNTwo,NodeLoggedInCountTwo,StateTwo,WWPNThree,NodeLoggedInCountThree,StateThree,WWPNFour,NodeLoggedInCountFour,StateFour,STOName,WWNN,SerialNumber
        [array]$CollectedHostInfo = foreach($TD_CollectInfo in $TD_CollectInfos){
            if([string]::IsNullOrWhiteSpace($TD_CollectInfo) -or ($iCounter -gt ($TD_CollectInfos.Count - 2)) ){
                $TD_HostBaseTemp;
                $iCounter++
                if(!([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.HostName))){
                    $TD_HostBaseTemp.HostStateInfo = SST_IBMDBFunc -STOWWN $TD_EventSplitInfoWWNN -STOHostID $TD_HostBaseTemp.HostID -STOHostName $TD_HostBaseTemp.HostName -STOHostState $TD_HostBaseTemp.Status
                }
                $TD_HostBaseTemp = "" | Select-Object RowID,ID,HostName,PortCount,Type,IOGrpCount,Status,HostStateInfo,SiteID,SiteName,HostClusterID,HostClusterName,Protocol,StatusPolicy,StatusSite,WWPNOne,NodeLoggedInCountOne,StateOne,WWPNTwo,NodeLoggedInCountTwo,StateTwo,WWPNThree,NodeLoggedInCountThree,StateThree,WWPNFour,NodeLoggedInCountFour,StateFour,STOName,WWNN,SerialNumber
                continue    
            }
            $TD_HostBaseTemp.ID = ($TD_CollectInfo|Select-String -Pattern '^id:(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.HostName = ($TD_CollectInfo|Select-String -Pattern '^name:([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.PortCount = ($TD_CollectInfo|Select-String -Pattern '^port_count:(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.Type = ($TD_CollectInfo|Select-String -Pattern '^Type:(generic|openvms|adminlun|hpux)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.Status = ($TD_CollectInfo|Select-String -Pattern '^status:(online|offline|degraded)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.SiteName = ($TD_CollectInfo|Select-String -Pattern '^site_name:([a-zA-Z0-9-_]+|)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.HostClusterName = ($TD_CollectInfo|Select-String -Pattern '^host_cluster_name:([a-zA-Z0-9-_]+|)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.Protocol = ($TD_CollectInfo|Select-String -Pattern '^protocol:(scsi|fcnvme|nvme|rdmanvme|fcscsi|sas|scsi)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.StatusPolicy = ($TD_CollectInfo|Select-String -Pattern '^status_policy:(.*)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.StatusSite = ($TD_CollectInfo|Select-String -Pattern '^status_site:(.*)' -AllMatches).Matches.Groups[1].Value
            switch (($TD_CollectInfo|Select-String -Pattern '^WWPN:(.*)' -AllMatches).Matches.Groups[1].Value) {
                {($_ -ne $TD_HostBaseTemp.WWPNOne) -and ([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNOne)) } { 
                    $TD_HostBaseTemp.WWPNOne = ($TD_CollectInfo|Select-String -Pattern 'WWPN:(.*)' -AllMatches).Matches.Groups[1].Value
                    
                }
                {($_ -ne $TD_HostBaseTemp.WWPNOne) -and ([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNTwo))} { 
                    $TD_HostBaseTemp.WWPNTwo = ($TD_CollectInfo|Select-String -Pattern '^WWPN:(.*)' -AllMatches).Matches.Groups[1].Value
                    $TDCheckTwo =$true
                }
                {(($_ -ne $TD_HostBaseTemp.WWPNTwo) -and ($_ -ne $TD_HostBaseTemp.WWPNOne)) -and ([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNThree)) } { 
                    $TD_HostBaseTemp.WWPNThree = ($TD_CollectInfo|Select-String -Pattern '^WWPN:(.*)' -AllMatches).Matches.Groups[1].Value
                    $TDCheckThree =$true
                }
                {(($_ -ne $TD_HostBaseTemp.WWPNThree) -and ($_ -ne $TD_HostBaseTemp.WWPNTwo) -and ($_ -ne $TD_HostBaseTemp.WWPNOne)) -and ([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNFour)) } { 
                    $TD_HostBaseTemp.WWPNFour = ($TD_CollectInfo|Select-String -Pattern '^WWPN:(.*)' -AllMatches).Matches.Groups[1].Value
                    $TDCheckFour =$true
                }
                Default {}
            }
            if(([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNTwo)-and(!([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNOne))))){
                $TD_HostBaseTemp.NodeLoggedInCountOne = (($TD_CollectInfo|Select-String -Pattern '^node_logged_in_count:(\d+)' -AllMatches).Matches.Groups[1].Value)
                $TD_HostBaseTemp.StateOne = (($TD_CollectInfo|Select-String -Pattern '^state:(.*)' -AllMatches).Matches.Groups[1].Value)
            }
            if(([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNThree)-and(!([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNTwo))))){
                $TD_HostBaseTemp.NodeLoggedInCountTwo = (($TD_CollectInfo|Select-String -Pattern '^node_logged_in_count:(\d+)' -AllMatches).Matches.Groups[1].Value)
                $TD_HostBaseTemp.StateTwo = (($TD_CollectInfo|Select-String -Pattern '^state:(.*)' -AllMatches).Matches.Groups[1].Value)
            }
            if(([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNFour)-and(!([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNThree))))){
                $TD_HostBaseTemp.NodeLoggedInCountThree = (($TD_CollectInfo|Select-String -Pattern '^node_logged_in_count:(\d+)' -AllMatches).Matches.Groups[1].Value)
                $TD_HostBaseTemp.StateThree = (($TD_CollectInfo|Select-String -Pattern '^state:(.*)' -AllMatches).Matches.Groups[1].Value)
            }
            if((!([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.StateThree))-and(!([string]::IsNullOrWhiteSpace($TD_HostBaseTemp.WWPNFour))))){
                $TD_HostBaseTemp.NodeLoggedInCountFour = (($TD_CollectInfo|Select-String -Pattern '^node_logged_in_count:(\d+)' -AllMatches).Matches.Groups[1].Value)
                $TD_HostBaseTemp.StateFour = (($TD_CollectInfo|Select-String -Pattern '^state:(.*)' -AllMatches).Matches.Groups[1].Value)
            }
            $TD_HostBaseTemp.WWNN = $TD_EventSplitInfoWWNN
            $TD_HostBaseTemp.SerialNumber = $TD_FSBaseSerialNumber
            $TD_HostBaseTemp.STOName = $TD_STOName
            $TD_HostBaseTemp.RowID = "$($TD_HostBaseTemp.SerialNumber)|$($TD_HostBaseTemp.ID)"
            $iCounter++
            
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_CollectInfos.Count) * 100)
        }
        
        
    }
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $CollectedHostInfo | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_($TD_Device_DeviceName)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_($TD_Device_DeviceName)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $CollectedHostInfo | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_($TD_Device_DeviceName)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_($TD_Device_DeviceName)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $CollectedHostInfo
        }
        return $CollectedHostInfo 
    }
}