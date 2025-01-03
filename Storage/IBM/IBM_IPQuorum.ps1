function IBM_IPQuorum { 
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
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Storage,
        [string]$TD_Exportpath
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_DeviceInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lsquorum -delim : -nohdr'
        }else {
            $TD_DeviceInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsquorum -delim : -nohdr'
        }
    }
    
    process {
        switch ($TD_DeviceInformation.Count) {
            {($_ -ge 3)} { 
                $TD_Quorum = foreach($TD_Line in $TD_DeviceInformation) {
                    $TD_QuorumInfo = "" | Select-Object QuorumIndex,Status,ID,Name,Active,ObjectType,Override,SiteName
                    $TD_QuorumInfo.QuorumIndex = ($TD_Line|Select-String -Pattern '^(\d+):'-AllMatches).Matches.Groups[1].Value
                    $TD_QuorumInfo.Status = ($TD_Line|Select-String -Pattern '^\d+:(online|offline|degraded):'-AllMatches).Matches.Groups[1].Value
                    $TD_QuorumInfo.ID = ($TD_Line|Select-String -Pattern '^\d+:(online|offline|degraded):(\d+|):'-AllMatches).Matches.Groups[2].Value
                    $TD_QuorumInfo.Name = ($TD_Line|Select-String -Pattern '^\d+:(online|offline|degraded):(\d+):([a-zA-Z0-9_]+|):'-AllMatches).Matches.Groups[3].Value
                    $TD_QuorumInfo.Active =($TD_Line|Select-String -Pattern ':(yes|no|):(drive|device):(yes|no):(\d+|):(.*)$'-AllMatches).Matches.Groups[1].Value
                    $TD_QuorumInfo.ObjectType =($TD_Line|Select-String -Pattern ':(yes|no|):(drive|device):(yes|no):(\d+|):(.*)$'-AllMatches).Matches.Groups[2].Value
                    $TD_QuorumInfo.Override =($TD_Line|Select-String -Pattern ':(yes|no|):(drive|device):(yes|no):(\d+|):(.*)$'-AllMatches).Matches.Groups[3].Value
                    $TD_QuorumInfo.SiteName = ($TD_Line|Select-String -Pattern ':(yes|no|):(drive|device):(yes|no):(\d+|):(.*)$'-AllMatches).Matches.Groups[5].Value
                    <# if SpVirtSoftware 8.7.x more in Field present there are new Infos to get.
                        application_type, metadata_backup, partner_system_name,... etc
                    #>

                    $TD_QuorumInfo
                    <# Progressbar  #>
                    $ProgCounter++
                    Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_DeviceInformation.Count) * 100)
                }
             }
            {($_ -lt 3)} { $TD_Quorum = $null }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at lsquorum for $($TD_Device_DeviceName)" -TD_ToolMSGType Error }
        }
    }
    
    end {
        if($TD_Line_ID -eq 1){$TD_CB_STO_DG1.Visibility="visible";$TD_LB_STO_DG1.Visibility="visible"; $TD_LB_STO_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_CB_STO_DG2.Visibility="visible";$TD_LB_STO_DG2.Visibility="visible"; $TD_LB_STO_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_CB_STO_DG3.Visibility="visible";$TD_LB_STO_DG3.Visibility="visible"; $TD_LB_STO_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_CB_STO_DG4.Visibility="visible";$TD_LB_STO_DG4.Visibility="visible"; $TD_LB_STO_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_CB_STO_DG5.Visibility="visible";$TD_LB_STO_DG5.Visibility="visible"; $TD_LB_STO_DG5.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 6){$TD_CB_STO_DG6.Visibility="visible";$TD_LB_STO_DG6.Visibility="visible"; $TD_LB_STO_DG6.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 7){$TD_CB_STO_DG7.Visibility="visible";$TD_LB_STO_DG7.Visibility="visible"; $TD_LB_STO_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_CB_STO_DG8.Visibility="visible";$TD_LB_STO_DG8.Visibility="visible"; $TD_LB_STO_DG8.Content=$TD_Device_DeviceName}
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_Quorum | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_($TD_Device_DeviceName)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_($TD_Device_DeviceName)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_Quorum | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_($TD_Device_DeviceName)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_($TD_Device_DeviceName)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_Quorum
        }
        return $TD_Quorum
    }
}