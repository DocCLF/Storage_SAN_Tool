function IBM_IPQuorum { 
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
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
            $TD_DeviceInformation = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP 'lsquorum -delim :'
        }else {
            $TD_DeviceInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsquorum -delim :'
        }
        
        $TD_DeviceInformation = $TD_DeviceInformation |Select-Object -Skip 1
    }
    
    process {
        switch ($TD_DeviceInformation.Count) {
            {($_ -ge 3)} { 
                $TD_Quorum = foreach($TD_Line in $TD_DeviceInformation) {
                    $TD_QuorumInfo = "" | Select-Object QuorumIndex,Status,ID,Name,SiteName
                    $TD_QuorumInfo.QuorumIndex = ($TD_Line|Select-String -Pattern '^(\d):(online|offline|degraded):'-AllMatches).Matches.Groups[1].Value
                    $TD_QuorumInfo.Status = ($TD_Line|Select-String -Pattern '^(\d):(online|offline|degraded):'-AllMatches).Matches.Groups[2].Value
                    $TD_QuorumInfo.ID = ($TD_Line|Select-String -Pattern '^(\d):(online|offline|degraded):(\d+):'-AllMatches).Matches.Groups[3].Value
                    $TD_QuorumInfo.Name = ($TD_Line|Select-String -Pattern '^(\d):(online|offline|degraded):(\d+):([a-zA-Z0-9_]+):'-AllMatches).Matches.Groups[4].Value
                    if([String]::IsNullOrEmpty($TD_QuorumInfo.Name)){
                        $TD_QuorumInfo.SiteName = ($TD_Line|Select-String -Pattern ':([a-zA-Z0-9_/.-]+)$'-AllMatches).Matches.Groups[1].Value
                    }
                    $TD_QuorumInfo
                    <# Progressbar  #>
                    $ProgCounter++
                    Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_DeviceInformation.Count) * 100)
                }
             }
            {($_ -lt 3)} { $TD_Quorum = $null }
            Default { SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at lsquorum" -TD_ToolMSGType Error }
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\Export\"){
                $TD_Quorum | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_Quorum | Export-Csv -Path $PSCommandPath\Export\$($TD_Line_ID)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
        }else {
            <# output on the promt #>
            return $TD_Quorum
        }
        return $TD_Quorum
    }
}