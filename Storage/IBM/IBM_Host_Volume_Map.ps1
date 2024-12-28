function IBM_Host_Volume_Map {
    <#
    .SYNOPSIS
        Displays a list of host/cluster and there volume relationships
    .NOTES
        v1.0.2
        * fix: TD_* Wildcard at Username, DeviceIP and Export

        v1.0.1
        This function displays a list of volume IDs, names and more. 
        These volumes are the volumes that are mapped to the specified host or hostcluster.  
    .NOTES
        Tested with version IBM Spectrum Virtualize Software 7.8.x to 8.6.x
    .LINK
        https://github.com/DocCLF/ps_collection/blob/main/IBM_Host_Volume_Map.ps1
    .EXAMPLE
        IBM_Host_Volume_Map -UserName monitor_user -DeviceIP 8.8.8.8
        HostID      : 91                                                                                                        
        HostName    : powervc-614b137d-0000005c-54486154                                                                        
        HostCluster :                                                                                                           
        VolumeID    : 188                                                                                                       
        VolumeName  : volume-powervc-614b137d-0000005c-boot-0-5a6ca77e-307a                                                     
        UID         : 60050763808102F40C000000000003D0                                                                          
        Capacity    : 200.00GB  
    .EXAMPLE
        IBM_Host_Volume_Map -UserName monitor_user -DeviceIP 8.8.8.8 -FilterType Host -Export yes
        Result filtered by host and exported to .\Host_Volume_Map_Result_(current date).csv
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
    begin{
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        <# create a array #>
        $TD_Mappingresault = @()
        <# int for the progressbar #>
        [int]$ProgCounter=0
        <# Connection to the system via ssh and filtering and provision of data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CollectVolInfo = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP "lshostvdiskmap -delim : && lsvdisk -delim :"
        }else {
            $TD_CollectVolInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "lshostvdiskmap -delim : && lsvdisk -delim :"
        }
        <# next line one for testing #>
        
        $TD_CollectVolInfo = $TD_CollectVolInfo |Select-Object -Skip 1
        $i = $TD_CollectVolInfo.Count

        0..$i |ForEach-Object {
            if($TD_CollectVolInfo[$_] -match '^id'){
                $TD_Resaults = $TD_CollectVolInfo | Select-Object -Skip ($_ +1)
                $i = $_
            }
        }       
        $TD_HostInfos = $TD_CollectVolInfo | Select-Object -First (($TD_CollectVolInfo.count)-($TD_Resaults.Count)-1)
    }
    process{
        $ProgressBar = New-ProgressBar
        $TD_Mappingresault = foreach($line in $TD_HostInfos){
            <# creates the objects for the array #>
            $TD_SplitInfos = "" | Select-Object HostID,HostName,HostClusterID,HostCluster,VolumeID,VolumeName,UID,Capacity
            if($i -ge 1){
                $TD_SplitInfos.HostID = ($line | Select-String -Pattern '^(\d+):([a-zA-Z0-9_-]+)' -AllMatches).Matches.Groups[1].Value
                $TD_SplitInfos.HostName = ($line | Select-String -Pattern '^(\d+):([a-zA-Z0-9_-]+)' -AllMatches).Matches.Groups[2].Value
                $TD_SplitInfos.VolumeID = ($line | Select-String -Pattern '(\d+):([a-zA-Z0-9_-]+):([0-9A-F]{32}):' -AllMatches).Matches.Groups[1].Value
                $TD_SplitInfos.VolumeName = ($line | Select-String -Pattern '(\d+):([a-zA-Z0-9_-]+):([0-9A-F]{32}):' -AllMatches).Matches.Groups[2].Value
                $TD_SplitInfos.UID = ($line | Select-String -Pattern ':([0-9A-F]{32}):' -AllMatches).Matches.Groups[1].Value
                $TD_SplitInfos.HostClusterID = ($line | Select-String -Pattern ':(\d+|):([a-zA-Z0-9_-]+|):(scsi|fcnvme|tcpnvme|rdmanvme|)$' -AllMatches).Matches.Groups[1].Value
                $TD_SplitInfos.HostCluster = ($line | Select-String -Pattern ':(\d+|):([a-zA-Z0-9_-]+|):(scsi|fcnvme|tcpnvme|rdmanvme|)$' -AllMatches).Matches.Groups[2].Value
                
                $TD_Resaults | ForEach-Object {
                    if(($TD_SplitInfos.UID) -eq (($_ | Select-String -Pattern '([0-9A-F]{32})' -AllMatches).Matches.Groups[1].Value)){
                        $TD_SplitInfos.Capacity = ($_ | Select-String -Pattern '(\d+\.\d+[B-T]+)' -AllMatches).Matches.Groups[1].Value
                    }
                }
                <#
                    Is required to avoid empty lines and to ensure that only the required data is made available.
                    A better option is currently being tested 
                #>
                $i--
            }
            $TD_SplitInfos
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_HostInfos.Count) * 100)
        
        }
        
    }
        
    end{
        <# if update is clicked update the right list #>
        if($TD_RefreshView -eq "Update"){
            if($TD_Line_ID -eq 1){
                $TD_lb_HostVolInfo.ItemsSource = $TD_Host_Volume_Map
            }elseif($TD_Line_ID -eq 2){
                $TD_lb_HostVolInfoTwo.ItemsSource = $TD_Host_Volume_Map
            }
        }
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_Mappingresault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_Mappingresault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_Mappingresault
        }
        return $TD_Mappingresault 
    }
}