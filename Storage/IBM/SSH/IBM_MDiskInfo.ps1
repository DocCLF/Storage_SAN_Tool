function IBM_MDiskInfo {
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
                $TD_MDiskInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lsmdiskgrp -gui -delim : -nohdr'
        }else {
                $TD_MDiskInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsmdiskgrp -gui -delim : -nohdr'
        }
    }
    
    process {
        $TD_MDiskInfoResault = foreach ($TD_MDisk in $TD_MDiskInformation){
            $TD_MDiskInfo = "" | Select-Object MDiskID,Name,Status,MDiskCount,VDiskCount,Capacity,ExtentSize,FreeCapacity,VirtualCapacity,UsedCapacity,RealCapacity,Overallocation
            $TD_MDiskInfo.MDiskID = ($TD_MDisk|Select-String -Pattern '^(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.Name = ($TD_MDisk|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.Status = ($TD_MDisk|Select-String -Pattern '\d+:([a-zA-Z0-9-_]+):(online|offline|excluded|degraded|degraded_paths|degraded_ports):' -AllMatches).Matches.Groups[2].Value
            $TD_MDiskInfo.MDiskCount = ($TD_MDisk|Select-String -Pattern ':(\d+):\d+:[\d.]+[GB|TB]+:' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.VDiskCount = ($TD_MDisk|Select-String -Pattern ':\d+:(\d+):[\d.]+[GB|TB]+:' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.Capacity = ($TD_MDisk|Select-String -Pattern ':\d+:\d+:([\d.]+[GB|TB]+)' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.ExtentSize = ($TD_MDisk|Select-String -Pattern ':[\d.]+[GB|TB]+:(16|32|64|128|256|512|1024|2048|4096|8192):' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.FreeCapacity = ($TD_MDisk|Select-String -Pattern '\d+:([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):\d+' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.VirtualCapacity = ($TD_MDisk|Select-String -Pattern '\d+:([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):\d+' -AllMatches).Matches.Groups[2].Value
            $TD_MDiskInfo.UsedCapacity = ($TD_MDisk|Select-String -Pattern '\d+:([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):\d+' -AllMatches).Matches.Groups[3].Value
            $TD_MDiskInfo.RealCapacity = ($TD_MDisk|Select-String -Pattern '\d+:([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):([\d.]+[MB|GB|TB]+):\d+' -AllMatches).Matches.Groups[4].Value
            $TD_MDiskInfo.Overallocation = ($TD_MDisk|Select-String -Pattern '\d+:[\d.]+[MB|GB|TB]+:[\d.]+[MB|GB|TB]+:[\d.]+[MB|GB|TB]+:[\d.]+[MB|GB|TB]+:(\d+)' -AllMatches).Matches.Groups[1].Value

            $TD_MDiskInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_MDiskInformation.Count) * 100)
            Start-Sleep -Seconds 0.5
        }
    }
    
    end {
        if($TD_Line_ID -eq 1){$TD_CB_STO_DG1.IsChecked="true";$TD_CB_STO_DG1.Visibility="visible";$TD_LB_STO_DG1.Visibility="visible"; $TD_LB_STO_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_CB_STO_DG2.IsChecked="true";$TD_CB_STO_DG2.Visibility="visible";$TD_LB_STO_DG2.Visibility="visible"; $TD_LB_STO_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_CB_STO_DG3.IsChecked="true";$TD_CB_STO_DG3.Visibility="visible";$TD_LB_STO_DG3.Visibility="visible"; $TD_LB_STO_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_CB_STO_DG4.IsChecked="true";$TD_CB_STO_DG4.Visibility="visible";$TD_LB_STO_DG4.Visibility="visible"; $TD_LB_STO_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_CB_STO_DG5.IsChecked="true";$TD_CB_STO_DG5.Visibility="visible";$TD_LB_STO_DG5.Visibility="visible"; $TD_LB_STO_DG5.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 6){$TD_CB_STO_DG6.IsChecked="true";$TD_CB_STO_DG6.Visibility="visible";$TD_LB_STO_DG6.Visibility="visible"; $TD_LB_STO_DG6.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 7){$TD_CB_STO_DG7.IsChecked="true";$TD_CB_STO_DG7.Visibility="visible";$TD_LB_STO_DG7.Visibility="visible"; $TD_LB_STO_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_CB_STO_DG8.IsChecked="true";$TD_CB_STO_DG8.Visibility="visible";$TD_LB_STO_DG8.Visibility="visible"; $TD_LB_STO_DG8.Content=$TD_Device_DeviceName}
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_MDiskInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_MDiskInfoResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_MDiskInfoResault
        }
        return $TD_MDiskInfoResault
    }
}