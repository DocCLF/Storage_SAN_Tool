function IBM_VolumeInfo {
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
            $TD_VDiskInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lsvdisk -gui -delim : -nohdr'
        }else {
            $TD_VDiskInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsvdisk -gui -delim : -nohdr'
        }
    }
    
    process {
        $TD_VDiskFuncResault = foreach($TD_VDisk in $TD_VDiskInformation){
            $TD_VDiskinfo = "" | Select-Object Volume_Name,IO_Group,Status,Pool,Capacity,Volume_UID,PreferredNodeID,PreferredNodeName,VolFunc,HAType
            $TD_VDiskinfo.Volume_Name = ($TD_VDisk|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.IO_Group = ($TD_VDisk|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Status = ($TD_VDisk|Select-String -Pattern ':(online|offline|deleting|degraded):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.Pool = ($TD_VDisk|Select-String -Pattern ':(online|offline|deleting|degraded):\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Capacity = ($TD_VDisk|Select-String -Pattern ':(online|offline|deleting|degraded):\d+:[a-zA-Z0-9-_]+:(\d+.\d+[A-Z]+):' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Volume_UID = ($TD_VDisk|Select-String -Pattern '(many|\d+|):([0-9a-zA-Z-_]+|):(\d+|):([0-9a-zA-Z-_]+|):(yes|no):([0-9A-F]+):\d+:\d+' -AllMatches).Matches.Groups[6].Value
            $TD_VDiskinfo.PreferredNodeID = ($TD_VDisk|Select-String -Pattern ':(balanced|active|inactive|measured):(\d+|):([0-9a-zA-Z-_]+|)::(\d+):' -AllMatches).Matches.Groups[4].Value
            $TD_VDiskinfo.PreferredNodeName = ($TD_VDisk|Select-String -Pattern ':([0-9A-F]{16,32}):(no|yes):(\d+|):(\d+|):([0-9a-zA-Z-_]+):' -AllMatches).Matches.Groups[5].Value
            $TD_VDiskinfo.VolFunc = ($TD_VDisk|Select-String -Pattern ':(master_change|master|aux_change|aux):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.HAType = ($TD_VDisk|Select-String -Pattern ':(master_change|master|aux_change|aux):(hyperswap|)' -AllMatches).Matches.Groups[2].Value
            
            If([String]::IsNullOrEmpty($TD_VDiskinfo.VolFunc)){
                $TD_VDiskinfo.VolFunc="none"
            }
            $TD_VDiskinfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_VDiskInformation.Count) * 100)
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
                $TD_VDiskFuncResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_VDiskFuncResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_VDiskFuncResault
        }
        return $TD_VDiskFuncResault
    }
}