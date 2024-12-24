function IBM_HostInfo {
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
        
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CollectInfos = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP 'lshost -nohdr |while read id name IO_group_id;do lshost -delim : $id ;echo;done'
        }else{
            $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lshost -nohdr |while read id name IO_group_id;do lshost -delim : $id ;echo;done'
        }
    }
    
    process {
        $iCounter=0;
        $TD_HostBaseTemp = "" | Select-Object HostID,HostName,PortCount,Type,Status,SiteName,HostClusterName,Protocol,StatusPolicy,StatusSite,WWPNOne,NodeLoggedInCountOne,StateOne,WWPNTwo,NodeLoggedInCountTwo,StateTwo,WWPNThree,NodeLoggedInCountThree,StateThree,WWPNFour,NodeLoggedInCountFour,StateFour
        [array]$CollectedHostInfo = foreach($TD_CollectInfo in $TD_CollectInfos){
            if([string]::IsNullOrWhiteSpace($TD_CollectInfo) -or ($iCounter -gt ($TD_CollectInfos.Count - 2)) ){
                $TD_HostBaseTemp;
                $iCounter++
                $TD_HostBaseTemp = "" | Select-Object HostID,HostName,PortCount,Type,Status,SiteName,HostClusterName,Protocol,StatusPolicy,StatusSite,WWPNOne,NodeLoggedInCountOne,StateOne,WWPNTwo,NodeLoggedInCountTwo,StateTwo,WWPNThree,NodeLoggedInCountThree,StateThree,WWPNFour,NodeLoggedInCountFour,StateFour
                continue
            }
            $TD_HostBaseTemp.HostID = ($TD_CollectInfo|Select-String -Pattern '^id:(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.HostName = ($TD_CollectInfo|Select-String -Pattern '^name:([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.PortCount = ($TD_CollectInfo|Select-String -Pattern '^port_count:(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.Type = ($TD_CollectInfo|Select-String -Pattern '^Type:(generic|openvms|adminlun|hpux)' -AllMatches).Matches.Groups[1].Value
            $TD_HostBaseTemp.Status = ($TD_CollectInfo|Select-String -Pattern '^status:(online|offline)' -AllMatches).Matches.Groups[1].Value
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
            $iCounter++
            
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_CollectInfos.Count) * 100)
        }
        
        
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $CollectedHostInfo | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_($TD_Device_DeviceName)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $CollectedHostInfo | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_($TD_Device_DeviceName)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
        }else {
            <# output on the promt #>
            return $CollectedHostInfo
        }
        return $CollectedHostInfo 
    }
}