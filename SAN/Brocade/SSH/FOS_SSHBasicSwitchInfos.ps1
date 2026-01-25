function FOS_SSHBasicSwitchInfos {
    <#
    .SYNOPSIS
        Creates a hashtable with Basic information about the switch.
    .DESCRIPTION
        Use this Function to display basic information about the switch. 
        This function uses various FOS commands to provide the required information.
        FOS Commands are firmwareshow, ipaddrshow, lscfg --show -n, switchshow 
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        GET_BasicSwitchInfos -FOS_MainInformation $yourvarobject 
    #>
    
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    
    begin {

        Write-Debug -Message "Start Func GET_BasicSwitchInfos |$(Get-Date)` "
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $FOS_MainInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'firmwareshow && ipaddrshow && chassisshow && switchshow'
        }else {
            $FOS_MainInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'firmwareshow && ipaddrshow && chassisshow && switchshow'
        }

        <# Hashtable for BasicSwitch Info #>
        $FOS_SwGeneralInfos =[ordered]@{}
        
        <# collect the information with the help of regex pattern and remove the blanks with the help of replace and trim #>
        $FOS_LoSw_CFG = ($FOS_MainInformation | Select-String -Pattern 'switchName:\s+(.*)$','switchDomain:\s+(\d+)$','switchWwn:\s+(.*)$','\D\((\w+)\)$','^Serial\sNum\:\s+(.*)' |ForEach-Object {$_.Matches.Groups[1].Value})

        switch (($FOS_MainInformation | Select-String -Pattern 'switchType:\s+(\d.*)$' |ForEach-Object {$_.Matches.Groups[1].Value})) {
            {$_ -like "109*"}  { $FOS_SwHw = "Brocade 6510" }
            {$_ -like "118*"}  { $FOS_SwHw = "Brocade 6505" }
            {$_ -like "170*"}  { $FOS_SwHw = "Brocade G610" }
            {$_ -like "162*"}  { $FOS_SwHw = "Brocade G620" }
            {$_ -like "183*"}  { $FOS_SwHw = "Brocade G620" }
            {$_ -like "173*"}  { $FOS_SwHw = "Brocade G630" }
            {$_ -like "184*"}  { $FOS_SwHw = "Brocade G630" }
            {$_ -like "178*"}  { $FOS_SwHw = "Brocade 7810 Ext. Switch" }
            {$_ -like "181*"}  { $FOS_SwHw = "Brocade G720" }
            {$_ -like "189*"}  { $FOS_SwHw = "Brocade G730" }
            {$_ -like "190*"}  { $FOS_SwHw = "Brocade 7850 Ext. Switch" }
            {$_ -like "191*"}  { $FOS_SwHw = "Brocade G710" }
            Default {$FOS_SwHw = "Unknown Type"}
        }

        switch (($FOS_MainInformation | Select-String -Pattern 'Part\sNum:\s+(\w+)$' |ForEach-Object {$_.Matches.Groups[1].Value})) {
            {$_ -like "*8960*P64"}  { $FOS_HWMTM = "8960-P64" }
            {$_ -like "*8960*R64"}  { $FOS_HWMTM = "8960-R64" }
            {$_ -like "*8960*P96"}  { $FOS_HWMTM = "8960-P96" }
            {$_ -like "*8960*R96"}  { $FOS_HWMTM = "8960-R96" }
            {$_ -like "*8969*F24"}  { $FOS_HWMTM = "8969-F24" }
            {$_ -like "*8960*F64"}  { $FOS_HWMTM = "8960-F64 V1" }
            {$_ -like "*8960*N64"}  { $FOS_HWMTM = "8960-N64 V1" }
            {$_ -like "*8960*F65"}  { $FOS_HWMTM = "8960-F65 V2" }
            {$_ -like "*8960*N65"}  { $FOS_HWMTM = "8960-N65 V2" }
            {$_ -like "*8960*F97"}  { $FOS_HWMTM = "8960-F97" }
            {$_ -like "*8960*N97"}  { $FOS_HWMTM = "8960-N97" }
            {$_ -like "*8960*F96"}  { $FOS_HWMTM = "8960-F96" }
            {$_ -like "*8960*N96"}  { $FOS_HWMTM = "8960-N96" }
            {$_ -like "*2498*F48"}  { $FOS_HWMTM = "2498-F48" }
            {$_ -like "*2498*F24"}  { $FOS_HWMTM = "2498-F24" }
            Default {$FOS_HWMTM = "Unknown Type"}
        }
    }
    
    process {
        Write-Debug -Message "Process Func GET_BasicSwitchInfos |$(Get-Date)` "

        <# add the values to the hashtable #>
        $FOS_SwGeneralInfos.Add('Swicht Name',$FOS_LoSw_CFG[1])
        $FOS_SwGeneralInfos.Add('Active ZonenCFG',$FOS_LoSw_CFG[4])
        $FOS_SwGeneralInfos.Add('DomainID',$FOS_LoSw_CFG[2])
        $FOS_SwGeneralInfos.Add('Switch WWN',$FOS_LoSw_CFG[3])

        <# Workaround if VF is not enabled #>
        $FOS_LoSw_Temp = (($FOS_MainInformation | Select-String -Pattern 'SwitchType:\s+(\w+)$' -AllMatches).Matches.groups[1].Value)
        if(!($FOS_LoSw_Temp)) {
            $FOS_SwGeneralInfos.Add('SwitchType','DS')
        }else {
            $FOS_SwGeneralInfos.Add('SwitchType',(($FOS_MainInformation | Select-String -Pattern 'SwitchType:\s+(\w+)$' -AllMatches).Matches.groups[1].Value))
        }
        if(($FOS_MainInformation | Select-String -Pattern '\[FID:\s(\d+)' |ForEach-Object {$_.Matches.Groups[1].Value}).count -eq 1) {
            $FOS_SwGeneralInfos.Add('Fabric ID',($FOS_MainInformation | Select-String -Pattern '\[FID:\s(\d+)' |ForEach-Object {$_.Matches.Groups[1].Value}))
        }else{
            $FOS_SwGeneralInfos.Add('Fabric ID','unknown')
        }
        <# need to creat a RowID #>
        $SANSwitchRowID = "$($FOS_LoSw_CFG[0])|$($FOS_LoSw_CFG[2])"
        $FOS_SwGeneralInfos.Add('Brocade Product Name',$FOS_SwHw)
        $FOS_SwGeneralInfos.Add('MTM',$FOS_HWMTM)
        $FOS_SwGeneralInfos.Add('SerialNumber',$FOS_LoSw_CFG[0])
        $FOS_SwGeneralInfos.Add('RowID',$SANSwitchRowID)
                 
        $FOS_SwitchOSVersion= FOS_SwitchFW -SwitchData $FOS_MainInformation

        foreach ($lineUp in $FOS_MainInformation) {
            if($lineUp -match '^Index'){break}
            $FOS_SwGeneralInfos.Add('Fabric OS',(($lineUp| Select-String -Pattern 'FOS\s+([v?][\d+]\.[\d+]\.[\d].*)$').Matches.Groups[1].Value))
            $FOS_SwGeneralInfos.Add('Fabric OSLV',$FOS_SwitchOSVersion)
            $FOS_SwGeneralInfos.Add('Ethernet IP Address',(($lineUp| Select-String -Pattern 'Ethernet IP Address:\s+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})').Matches.Groups[1].Value))
            $FOS_SwGeneralInfos.Add('Ethernet Subnet mask',(($lineUp| Select-String -Pattern 'Ethernet Subnet mask:\s+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})').Matches.Groups[1].Value))
            $FOS_SwGeneralInfos.Add('Gateway IP Address',(($lineUp| Select-String -Pattern 'Gateway IP Address:\s+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})').Matches.Groups[1].Value))
            $FOS_SwGeneralInfos.Add('DHCP',((($lineUp| Select-String -Pattern '^DHCP:\s(\w+)$' -AllMatches).Matches.Groups[1].Value)))
            $FOS_SwGeneralInfos.Add('Switch State',(($lineUp| Select-String -Pattern 'switchState:\s+(.*)$').Matches.Groups[1].Value))
            $FOS_SwGeneralInfos.Add('Switch Role',(($lineUp| Select-String -Pattern 'switchRole:\s+(.*)$').Matches.Groups[1].Value))

            <# Progressbar  #>
            $ProgCounter++
            #$Completed = ($ProgCounter/$TD_HostInfos.Count) * 100
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($FOS_SwGeneralInfos.'Swicht Name')" -PercentComplete (($ProgCounter/$FOS_MainInformation.Count) * 100)
        }
        
    }
    
    end {
        
        if([string]::IsNullOrEmpty($TD_Device_DeviceName)){$TD_Device_DeviceName = $($FOS_SwGeneralInfos.'Swicht Name')}
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                Out-File -FilePath $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_BasicSwitchInfo_Result_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $FOS_SwGeneralInfos
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_BasicSwitchInfo_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                Out-File -FilePath $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_BasicSwitchInfo_Result_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $FOS_SwGeneralInfos
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_BasicSwitchInfo_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_SwGeneralInfos
        }

        return $FOS_SwGeneralInfos
        
    }
}