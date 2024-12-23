function IBM_VolumeInfo {
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
        [string]$TD_Exportpath
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_VDiskInformation = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP 'lsvdisk -gui -delim : -nohdr'
        }else {
            $TD_VDiskInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsvdisk -gui -delim : -nohdr'
        }
    }
    
    process {
        $TD_VDiskFuncResault = foreach($TD_VDisk in $TD_VDiskInformation){
            $TD_VDiskinfo = "" | Select-Object Volume_Name,IO_Group,Status,Pool,Volume_UID,PreferredNodeID,PreferredNodeName,VolFunc,HAType
            $TD_VDiskinfo.Volume_Name = ($TD_VDisk|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.IO_Group = ($TD_VDisk|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Status = ($TD_VDisk|Select-String -Pattern ':(online|offline|deleting|degraded):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.Pool = ($TD_VDisk|Select-String -Pattern ':(online|offline|deleting|degraded):\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Volume_UID = ($TD_VDisk|Select-String -Pattern '(many|\d+|):([0-9a-zA-Z-_]+):(\d+|):([0-9a-zA-Z-_]+|):(yes|no):([0-9A-F]+):\d+:\d+' -AllMatches).Matches.Groups[6].Value
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
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_VDiskInformation.Count) * 100)
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){

            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_VDiskFuncResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_VDiskFuncResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
        }else {
            <# output on the promt #>
            return $TD_VDiskFuncResault
        }
        return $TD_VDiskFuncResault
    }
}