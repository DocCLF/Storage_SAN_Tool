function IBM_SSHFCPortStats {
    <#
    .SYNOPSIS
        Display the PortStats of IBM SVC & Storage
    .DESCRIPTION
        To view the port transfer and failure counts and Small Form-factor Pluggable (SFP) diagnostics data that is recorded in the statistics file for a node.
    .NOTES
        Supported with IBM Storage Virtualize 8.4.x and higher
    .NOTES
        Version:
        1.0.1 Initail Release
    .LINK
        IBM Doku to lsportstats
        https://www.ibm.com/docs/en/flashsystem-5x00/8.5.x?topic=commands-lsportstats
    .EXAMPLE
        Note: You need an admin account and you should use the cluster IP to get all data of all devices.
        IBM_SSHFCPortStats -TD_UserName AdminUser -TD_DeviceIP 1.1.1.1

        IBM_SSHFCPortStats -TD_UserName AdminUser -TD_DeviceIP 1.1.1.1 -TD_export yes

        IBM_SSHFCPortStats -TD_UserName AdminUser -TD_DeviceIP 1.1.1.1 -TD_Storage FSystem -TD_export yes

        IBM_SSHFCPortStats -TD_UserName AdminUser -TD_DeviceIP 1.1.1.1 -TD_Storage SVC -TD_export yes
    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("FSystem","SVC")]
        [string]$TD_Storage = "FSystem",
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_export = "yes",
        [string]$TD_Exportpath
    )
    begin {
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        $TD_lb_PortStatsErrorInfo.Visibility="Collapsed"
        $TD_PortStats_Overview = @()
        [int]$ProgCounter=0
        [int]$i=0
        #$test =@('enclosure_serial_number','panel_name','id','name','WWNN','Nn_stats','type','port','wwpn','lf','lsy','lsi','pspe','itw','icrc','bbcz','tmp','txpwr','rxpwr')

        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Storage -eq "FSystem"){
            if($TD_Device_ConnectionTyp -eq "ssh"){
                $TD_CollectInfos = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lsnodecanister -delim . -nohdr && lsnodecanister -nohdr |while read id name IO_group_id;do lsportstats -node $id ;echo;done'
            }else{
                $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -delim . -nohdr && lsnodecanister -nohdr |while read id name IO_group_id;do lsportstats -node $id ;echo;done'
            }
        }else {
            if($TD_Device_ConnectionTyp -eq "ssh"){
                $TD_CollectInfos = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lsnode -delim . -nohdr && lsnode -nohdr |while read id name IO_group_id;do lsportstats -node $id ;echo;done'
            }else{
                $TD_CollectInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnode -delim . -nohdr && lsnode -nohdr |while read id name IO_group_id;do lsportstats -node $id ;echo;done'
            }
        }

        0..$TD_CollectInfos.Count |ForEach-Object{
            if($TD_CollectInfos[$_] -match 'Nn_stats_'){
                if([string]::IsNullOrEmpty($NodeBasicInfos)){
                    $NodeBasicInfos = $TD_CollectInfos |Select-Object -First $_
                }
            }
        }
        foreach ($NodeBasicInfo in $NodeBasicInfos){
            if($TD_Storage -eq "SVC"){
                $NodeSN = ($NodeBasicInfo|Select-String -Pattern '\.(\w{6,8})\.(|\d+)\.(|\d+)\.(|\w{6,8})' -AllMatches).Matches.Groups[1].Value
            }else{
                $NodeSN = ($NodeBasicInfo|Select-String -Pattern '\.\d+\.\d+\.(\w{6,8})\.' -AllMatches).Matches.Groups[1].Value
            }
            [array]$NodeList += [PSCustomObject]@{
                NodeID = ($NodeBasicInfo|Select-String -Pattern '^(\d+)\.' -AllMatches).Matches.Groups[1].Value
                NodeSN = $NodeSN
                NodeName = ($NodeBasicInfo|Select-String -Pattern '^\d+\.([\w\-]+)\.' -AllMatches).Matches.Groups[1].Value
                NodeWWNN = ($NodeBasicInfo|Select-String -Pattern '\.([0-9a-zA-Z]{14,18})\.' -AllMatches).Matches.Groups[1].Value
            }
        }
        $NodePortStatsInfos = $TD_CollectInfos |Select-Object -Skip ($NodeBasicInfos.Count)
    }

    process {

        foreach($TD_CollectInfo in $NodePortStatsInfos){
            [string]$TD_NodeStatsID
            if($NodeList.Count -ge 1 -and ($TD_CollectInfo -match 'Nn_stats_')){
                $TD_PortStatsSplitInfos = "" | Select-Object RowID,NodeID,SerialNumber,NodeName,WWNN,CardType,CardID,PortID,WWPN,LinkFailure,LoseSync,LoseSig,PSErrCount,InvTransErr,CRCErr,ZeroBtB,SFPTemp,TXPwr,TXPwrlow,RXPwr,RXPwrlow
                [int]$TD_PortStatsSplitInfos.NodeID = $NodeList.NodeID[$i]
                [string]$TD_PortStatsSplitInfos.SerialNumber = $NodeList.SerialNumber[$i]
                [string]$TD_PortStatsSplitInfos.NodeName = $NodeList.NodeName[$i]
                [string]$TD_PortStatsSplitInfos.WWNN = $NodeList.WWNN[$i]
                $NodeSNTemp = $NodeList.SerialNumber[$i]
                $NodeWWNNTemp = $NodeList.WWNN[$i]
                $NodeNameTemp = $NodeList.NodeName[$i]
                $i++
            }
            [string]$TD_PortStatsSplitInfos.SerialNumber = $NodeSNTemp
            [string]$TD_PortStatsSplitInfos.WWNN = $NodeWWNNTemp
            <# Card Info #>
            [string]$TD_PortStatsSplitInfos.CardType = ($TD_CollectInfo|Select-String -Pattern '^typ.*(FC)' -AllMatches).Matches.Groups[1].Value
            [string]$TD_PortStatsSplitInfos.CardID = (($TD_CollectInfo|Select-String -Pattern '^type_id.*(\d)' -AllMatches).Matches.Value).Trim('type_id="')
            [string]$TD_PortStatsSplitInfos.PortID = (($TD_CollectInfo|Select-String -Pattern 'port\sid.*(\d)' -AllMatches).Matches.Value).Trim('port id="')
            [string]$TD_PortStatsSplitInfos.WWPN = (($TD_CollectInfo|Select-String -Pattern 'wwpn.*0x([0-9a-f]+)' -AllMatches).Matches.Groups[1].Value)
            <# diagnostics data #>
            <# Block 1#>
            [int]$TD_PortStatsSplitInfos.LinkFailure = ($TD_CollectInfo|Select-String -Pattern 'lf="(\d+)"' -AllMatches).Matches.Groups[1].Value
            [int]$TD_PortStatsSplitInfos.LoseSync = ($TD_CollectInfo|Select-String -Pattern 'lsy="(\d+)"' -AllMatches).Matches.Groups[1].Value
            [int]$TD_PortStatsSplitInfos.LoseSig = ($TD_CollectInfo|Select-String -Pattern 'lsi="(\d+)"' -AllMatches).Matches.Groups[1].Value
            [int]$TD_PortStatsSplitInfos.PSErrCount = ($TD_CollectInfo|Select-String -Pattern 'pspe="(\d+)"' -AllMatches).Matches.Groups[1].Value
            <# Block 2#>
            [int]$TD_PortStatsSplitInfos.InvTransErr = ($TD_CollectInfo|Select-String -Pattern 'itw="(\d+)"' -AllMatches).Matches.Groups[1].Value
            [int]$TD_PortStatsSplitInfos.CRCErr = ($TD_CollectInfo|Select-String -Pattern 'icrc="(\d+)"' -AllMatches).Matches.Groups[1].Value
            [int]$TD_PortStatsSplitInfos.ZeroBtB = ($TD_CollectInfo|Select-String -Pattern 'bbcz="(\d+)"' -AllMatches).Matches.Groups[1].Value
            <# Block 3#>
            [int]$TD_PortStatsSplitInfos.SFPTemp = ($TD_CollectInfo|Select-String -Pattern 'tmp="(\d+)"' -AllMatches).Matches.Groups[1].Value
            [int]$TD_PortStatsSplitInfos.TXPwr = ($TD_CollectInfo|Select-String -Pattern 'txpwr="(\d+)"' -AllMatches).Matches.Groups[1].Value
            [int]$TD_PortStatsSplitInfos.RXPwr = ($TD_CollectInfo|Select-String -Pattern 'rxpwr="(\d+)"' -AllMatches).Matches.Groups[1].Value
            $TD_PortStatsSplitInfos.RowID = "$($TD_PortStatsSplitInfos.SerialNumber)|$($TD_PortStatsSplitInfos.PortID)"
            if($TD_CollectInfo -eq "/>"){
                if($TD_PortStatsSplitInfos.CardType -ne "FC"){continue}
                $TD_PortStats_Overview += $TD_PortStatsSplitInfos
                $TD_PortStatsSplitInfos = "" | Select-Object RowID,SerialNumber,WWNN,CardType,CardID,PortID,WWPN,LinkFailure,LoseSync,LoseSig,PSErrCount,InvTransErr,CRCErr,ZeroBtB,SFPTemp,TXPwr,TXPwrlow,RXPwr,RXPwrlow
            }
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($NodeNameTemp)" -PercentComplete (($ProgCounter/$NodePortStatsInfos.Count) * 100)
        }
    }

    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        
        SST_CustomerSTODBInsertTable -SST_InfoType "FCPortStats" -SST_CollectedInformations $TD_PortStats_Overview
        <# export y or n #>
        if($TD_export -eq "yes"){

            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_PortStats_Overview | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_PortStats_Overview | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_PortStats_Overview
        }
        return $TD_PortStats_Overview
    }
}
