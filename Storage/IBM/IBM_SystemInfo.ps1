function IBM_SystemInfo {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [Parameter(Mandatory)]
        [string]$TD_Device_ConnectionTyp,
        [Parameter(Mandatory)]
        [string]$TD_Device_UserName,
        [Parameter(Mandatory)]
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW
    )
    
    begin {
        #<# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"

        

        #if($TD_Device_ConnectionTyp -eq "ssh"){
        #    $TD_DeviceInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'lssystem -delim :'
        #}else {
            $TD_DeviceInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lssystem -delim :'
        #}
        
    }
    
    process {
        $TD_DeviceName = (($TD_DeviceInformation | Select-String -Pattern 'name:(\w+)' -AllMatches).Matches.groups[1].Value)
        $IBM_STOSysInfos =[ordered]@{}
        $IBM_STOSysInfos.Add('MDiskTotalCapacity',(($TD_DeviceInformation | Select-String -Pattern 'total_mdisk_capacity:([\w\.]+)' -AllMatches).Matches.groups[1].Value))
        $IBM_STOSysInfos.Add('MDiskFreeCapacity',(($TD_DeviceInformation | Select-String -Pattern 'total_free_space:([\w\.]+)' -AllMatches).Matches.groups[1].Value))
        $IBM_STOSysInfos.Add('MDiskUsedCapacity',(($TD_DeviceInformation | Select-String -Pattern 'space_allocated_to_vdisks:([\w\.]+)' -AllMatches).Matches.groups[1].Value))
        $IBM_STOSysInfos.Add('PhysicalTotalCapacity',(($TD_DeviceInformation | Select-String -Pattern 'physical_capacity:([\w\.]+)' -AllMatches).Matches.groups[1].Value))
        $IBM_STOSysInfos.Add('PhysicalFreeCapacity',(($TD_DeviceInformation | Select-String -Pattern 'physical_free_capacity:([\w\.]+)' -AllMatches).Matches.groups[1].Value))
        $IBM_STOSysInfos.Add('HostUnmap',(($TD_DeviceInformation | Select-String -Pattern 'host_unmap:(on|off)' -AllMatches).Matches.groups[1].Value))
        $IBM_STOSysInfos.Add('BackendUnmap',(($TD_DeviceInformation | Select-String -Pattern 'backend_unmap:(on|off)' -AllMatches).Matches.groups[1].Value))

        <# Progressbar  #>
        
        
    }
    
    end {
        
        return $IBM_STOSysInfos
    }
}