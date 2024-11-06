function IBM_PolicyBased_Rep {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_RepInfoChose,
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
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_PolicyRepInformations = ssh $TD_Device_UserName@$TD_Device_DeviceIP 'lsreplicationpolicy && lsvolumegroupreplication'
        }else {
            $TD_PolicyRepInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsreplicationpolicy && lsvolumegroupreplication'
        }
        $TD_PolicyRepInformations = $TD_PolicyRepInformations |Select-Object -Skip 1
    }
    
    process {
        switch ($TD_RepInfoChose) {
            "ReplicationPolicy" { 
                Write-Host "ReplicationPolicy" -ForegroundColor Yellow
                $TD_ReplicationPolicy = foreach($TD_PolicyRepInfo in $TD_PolicyRepInformations){
                    if($TD_PolicyRepInfo |Select-String -Pattern "replication_policy_id"){break}
                    $TD_PolRepTemp = "" | Select-Object ID,Name,Topology,RPOAlert,VolumeGroupCount,Location1SystemName,Location1IOGrpID,Location2SystemName,Location2IOGrpID
                    $TD_PolRepTemp.ID = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+' -AllMatches).Matches.Groups[1].Value
                    $TD_PolRepTemp.Name = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+([a-zA-Z0-9-_]+)\s+([a-zA-Z0-9-_]+)\s+' -AllMatches).Matches.Groups[2].Value
                    $TD_PolRepTemp.Topology = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+([a-zA-Z0-9-_]+)\s+([a-zA-Z0-9-_]+)\s+' -AllMatches).Matches.Groups[3].Value
                    $TD_PolRepTemp.RPOAlert = ($TD_PolicyRepInfo|Select-String -Pattern '(\d+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)' -AllMatches).Matches.Groups[1].Value
                    $TD_PolRepTemp.VolumeGroupCount = ($TD_PolicyRepInfo|Select-String -Pattern '(\d+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)' -AllMatches).Matches.Groups[2].Value
                    $TD_PolRepTemp.Location1SystemName = ($TD_PolicyRepInfo|Select-String -Pattern '(\d+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)' -AllMatches).Matches.Groups[3].Value
                    $TD_PolRepTemp.Location1IOGrpID = ($TD_PolicyRepInfo|Select-String -Pattern '(\d+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)' -AllMatches).Matches.Groups[4].Value
                    $TD_PolRepTemp.Location2SystemName = ($TD_PolicyRepInfo|Select-String -Pattern '(\d+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)' -AllMatches).Matches.Groups[5].Value
                    $TD_PolRepTemp.Location2IOGrpID = ($TD_PolicyRepInfo|Select-String -Pattern '(\d+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)' -AllMatches).Matches.Groups[6].Value
        
                    $TD_PolRepTemp
        
                    <# Progressbar  #>
                    $ProgCounter++
                    Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_PolicyRepInformations.Count) * 100)
                }
             }
            "VolumeGroupReplication" { 
                Write-Host "VolumeGroupReplication" -ForegroundColor Yellow
                $PolicyRepInformationCount = $TD_PolicyRepInformations.count
                0..$PolicyRepInformationCount |ForEach-Object {
                    if($TD_PolicyRepInformations[$_] -match 'replication_policy_id'){
                        $TD_FilteredPolicyRepInformations = $TD_PolicyRepInformations |Select-Object -Skip $_
                    }
                }
                $TD_VolumeGroupRep = foreach($TD_PolicyRepInfo in $TD_FilteredPolicyRepInformations){
                    $TD_VolGrpRepTemp = "" | Select-Object ID,Name,ReplPolicyID,ReplPolicyName,Location1SysName,Location1RepMode,Location1withinRPO,Location2SystemName,Location2RepMode,Location2withinRPO,Link1Status
                    $TD_VolGrpRepTemp.ID = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+' -AllMatches).Matches.Groups[1].Value
                    $TD_VolGrpRepTemp.Name = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+([a-zA-Z0-9-_]+)\s+' -AllMatches).Matches.Groups[2].Value
                    $TD_VolGrpRepTemp.ReplPolicyID = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)' -AllMatches).Matches.Groups[3].Value
                    $TD_VolGrpRepTemp.ReplPolicyName = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[4].Value
                    $TD_VolGrpRepTemp.Location1SysName = ($TD_PolicyRepInfo|Select-String -Pattern '^(\d+)\s+([a-zA-Z0-9-_]+)\s+(\d+)\s+([a-zA-Z0-9-_]+)\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[5].Value
                    $TD_VolGrpRepTemp.Location1RepMode = ($TD_PolicyRepInfo|Select-String -Pattern '\s+([a-zA-Z0-9-_]+)\s+(production|recovery|independent)' -AllMatches).Matches.Groups[2].Value
                    $TD_VolGrpRepTemp.Location1withinRPO = ($TD_PolicyRepInfo|Select-String -Pattern '\s+([a-zA-Z0-9-_]+)\s+(production|recovery|independent)\s+(yes|no|)' -AllMatches).Matches.Groups[3].Value
                    $TD_VolGrpRepTemp.Location2SystemName = ($TD_PolicyRepInfo|Select-String -Pattern '\s+([a-zA-Z0-9-_]+)\s+(production|recovery|independent)\s+(yes|no|)\s+(running|suspended|independent|disconnected|)$' -AllMatches).Matches.Groups[1].Value
                    $TD_VolGrpRepTemp.Location2RepMode = ($TD_PolicyRepInfo|Select-String -Pattern '\s+(production|recovery|independent)\s+(yes|no|)\s+(running|suspended|independent|disconnected|)$' -AllMatches).Matches.Groups[1].Value
                    $TD_VolGrpRepTemp.Location2withinRPO = ($TD_PolicyRepInfo|Select-String -Pattern '\s+(yes|no|)\s+(running|suspended|independent|disconnected|)$' -AllMatches).Matches.Groups[1].Value
                    $TD_VolGrpRepTemp.Link1Status = ($TD_PolicyRepInfo|Select-String -Pattern '\s+(running|suspended|independent|disconnected|)$' -AllMatches).Matches.Groups[1].Value

                    $TD_VolGrpRepTemp
        
                    <# Progressbar  #>
                    $ProgCounter++
                    Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_PolicyRepInformations.Count) * 100)
                }
             }
            Default {Write-Host "Something went wrong please try again or contact tool support" -ForegroundColor Red}
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_export -eq "yes"){

            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                switch ($TD_RepInfoChose) {
                    "lsreplicationpolicy" { $TD_ReplicationPolicy | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_ReplicationPolicy_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation }
                    "lsvolumegroupreplication" { $TD_VolumeGroupRep | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_VolumeGroupRep_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation }
                    Default {Write-Host "Something went wrong please try again or contact tool support" -ForegroundColor Red}
                }
            }else {
                switch ($TD_RepInfoChose) {
                    "lsreplicationpolicy" { $TD_ReplicationPolicy | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_ReplicationPolicy_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation }
                    "lsvolumegroupreplication" { $TD_VolumeGroupRep | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_VolumeGroupRep_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation }
                    Default {Write-Host "Something went wrong please try again or contact tool support" -ForegroundColor Red}
                }
            }
        }else {
            <# output on the promt #>
            switch ($TD_RepInfoChose) {
                "lsreplicationpolicy" { return $TD_ReplicationPolicy }
                "lsvolumegroupreplication" { return $TD_VolumeGroupRep }
                Default {Write-Host "Something went wrong please try again or contact tool support" -ForegroundColor Red}
            }
        }

        switch ($TD_RepInfoChose) {
            "lsreplicationpolicy" { return $TD_ReplicationPolicy }
            "lsvolumegroupreplication" { return $TD_VolumeGroupRep }
            Default {Write-Host "Something went wrong please try again or contact tools upport" -ForegroundColor Red}
        }

    }
}