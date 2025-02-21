function IBM_VDiskAnalysis {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Standalone="no",
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
        if($TD_Standalone -eq "no"){
            [int]$ProgCounter=0
            $ProgressBar = New-ProgressBar
        }
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_VDiskAnalysInformations = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lsvdiskanalysis -delim : -nohdr'
        }else {
            $TD_VDiskAnalysInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsvdiskanalysis -delim : -nohdr'
        }
    }
    
    process {
        $TD_VDiskAnalysInformation = foreach($TD_VDisk in $TD_VDiskAnalysInformations){
            $TD_VDiskinfo = "" | Select-Object ID,Name,State,AnalysisTime,Capacity,ThinSize,ThinSavings,ThinSavingsRatio,CompressedSize,CompressionSavings,CompressionSavingsRatio,TotalSavings,TotalSavingsRatio,MarginOfError
            $TD_VDiskinfo.ID = ($TD_VDisk|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.Name = ($TD_VDisk|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.State = ($TD_VDisk|Select-String -Pattern ':(idle|active|estimated|sparse|canceling|automatic|):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.AnalysisTime = ($TD_VDisk|Select-String -Pattern ':(idle|active|estimated|sparse|canceling|automatic|):(\d+):' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Capacity = ($TD_VDisk|Select-String -Pattern '(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+|\d):(\d+\.\d+|d):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.ThinSize = ($TD_VDisk|Select-String -Pattern '(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+|\d):(\d+\.\d+|d):' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.ThinSavings = ($TD_VDisk|Select-String -Pattern '(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+|\d):(\d+\.\d+|d):' -AllMatches).Matches.Groups[3].Value
            $TD_VDiskinfo.ThinSavingsRatio = ($TD_VDisk|Select-String -Pattern '(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+|\d):(\d+\.\d+|d):' -AllMatches).Matches.Groups[4].Value
            $TD_VDiskinfo.CompressedSize = ($TD_VDisk|Select-String -Pattern '(\d+\.\d+):(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+)' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.CompressionSavings = ($TD_VDisk|Select-String -Pattern '(\d+\.\d+):(\d+\.\d+[A-Z]+):(\d+\.\d+[A-Z]+)' -AllMatches).Matches.Groups[3].Value
            $TD_VDiskinfo.CompressionSavingsRatio = ($TD_VDisk|Select-String -Pattern ':(balanced|active|inactive|measured):(\d+|):([0-9a-zA-Z-_]+|)::(\d+):' -AllMatches).Matches.Groups[4].Value
            $TD_VDiskinfo.TotalSavings = ($TD_VDisk|Select-String -Pattern ':([0-9A-F]{16,32}):(no|yes):(\d+|):(\d+|):([0-9a-zA-Z-_]+):' -AllMatches).Matches.Groups[5].Value
            $TD_VDiskinfo.TotalSavingsRatio = ($TD_VDisk|Select-String -Pattern ':(master_change|master|aux_change|aux):' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.MarginOfError = ($TD_VDisk|Select-String -Pattern ':(master_change|master|aux_change|aux):(hyperswap|)' -AllMatches).Matches.Groups[2].Value
            
            If([String]::IsNullOrEmpty($TD_VDiskinfo.VolFunc)){
                $TD_VDiskinfo.VolFunc="none"
            }
            $TD_VDiskinfo
            if($TD_Standalone -eq "no"){
                <# Progressbar  #>
                $ProgCounter++
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_VDiskInformation.Count) * 100)
            }
        }
    }
    
    end {
        if($TD_Standalone -eq "no"){
            if($TD_Line_ID -eq 1){$TD_CB_STO_DG1.IsChecked="true";$TD_CB_STO_DG1.Visibility="visible";$TD_LB_STO_DG1.Visibility="visible"; $TD_LB_STO_DG1.Content=$TD_Device_DeviceName}
            if($TD_Line_ID -eq 2){$TD_CB_STO_DG2.IsChecked="true";$TD_CB_STO_DG2.Visibility="visible";$TD_LB_STO_DG2.Visibility="visible"; $TD_LB_STO_DG2.Content=$TD_Device_DeviceName}
            if($TD_Line_ID -eq 3){$TD_CB_STO_DG3.IsChecked="true";$TD_CB_STO_DG3.Visibility="visible";$TD_LB_STO_DG3.Visibility="visible"; $TD_LB_STO_DG3.Content=$TD_Device_DeviceName}
            if($TD_Line_ID -eq 4){$TD_CB_STO_DG4.IsChecked="true";$TD_CB_STO_DG4.Visibility="visible";$TD_LB_STO_DG4.Visibility="visible"; $TD_LB_STO_DG4.Content=$TD_Device_DeviceName}
            if($TD_Line_ID -eq 5){$TD_CB_STO_DG5.IsChecked="true";$TD_CB_STO_DG5.Visibility="visible";$TD_LB_STO_DG5.Visibility="visible"; $TD_LB_STO_DG5.Content=$TD_Device_DeviceName}  
            if($TD_Line_ID -eq 6){$TD_CB_STO_DG6.IsChecked="true";$TD_CB_STO_DG6.Visibility="visible";$TD_LB_STO_DG6.Visibility="visible"; $TD_LB_STO_DG6.Content=$TD_Device_DeviceName}  
            if($TD_Line_ID -eq 7){$TD_CB_STO_DG7.IsChecked="true";$TD_CB_STO_DG7.Visibility="visible";$TD_LB_STO_DG7.Visibility="visible"; $TD_LB_STO_DG7.Content=$TD_Device_DeviceName}
            if($TD_Line_ID -eq 8){$TD_CB_STO_DG8.IsChecked="true";$TD_CB_STO_DG8.Visibility="visible";$TD_LB_STO_DG8.Visibility="visible"; $TD_LB_STO_DG8.Content=$TD_Device_DeviceName}
            
            Close-ProgressBar -ProgressBar $ProgressBar
        }
        if($TD_Export -eq "yes"){
            if($TD_Standalone -eq "no"){
                $TD_VDiskFuncResault | Export-Csv -Path .\IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_VDiskFuncResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_VDiskFuncResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_VDiskFuncResault
        }
        return $TD_VDiskFuncResault
    }
}

