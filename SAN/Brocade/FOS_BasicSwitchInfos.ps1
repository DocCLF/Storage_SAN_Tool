function FOS_BasicSwitchInfos {
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
        [string]$TD_Device_SSHKeyPath,
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
        <# next line is for tests #>
        #[System.Object]$FOS_MainInformation = Get-Content -Path "C:\Users\mailt\Documents\182.txt"

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
            {$_ -like "178*"}  { $FOS_SwHw = "Brocade 7810 Extension Switch" }
            {$_ -like "181*"}  { $FOS_SwHw = "Brocade G720" }
            {$_ -like "189*"}  { $FOS_SwHw = "Brocade G730" }
            Default {$FOS_SwHw = "Unknown Type"}
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

        $FOS_SwGeneralInfos.Add('Brocade Product Name',$FOS_SwHw)
        $FOS_SwGeneralInfos.Add('Serial Num',$FOS_LoSw_CFG[0])

        foreach ($lineUp in $FOS_MainInformation) {
            if($lineUp -match '^Index'){break}
            $FOS_SwGeneralInfos.Add('Fabric OS',(($lineUp| Select-String -Pattern 'FOS\s+([v?][\d]\.[\d+]\.[\d].*)$').Matches.Groups[1].Value))
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
        if($TD_Line_ID -eq 1){$TD_LB_sanBasicSwitchInfoOne.Visibility = "Visible";  $TD_LB_sanBasicSwitchInfoOne.Content = "$($FOS_SwGeneralInfos.'Swicht Name')"  ;$TD_CB_SAN_DG1.IsChecked="true";$TD_CB_SAN_DG1.Visibility="visible";$TD_LB_SAN_DG1.Visibility="visible"; $TD_LB_SAN_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_LB_sanBasicSwitchInfoTwo.Visibility = "Visible";  $TD_LB_sanBasicSwitchInfoTwo.Content = "$($FOS_SwGeneralInfos.'Swicht Name')"  ;$TD_CB_SAN_DG2.IsChecked="true";$TD_CB_SAN_DG2.Visibility="visible";$TD_LB_SAN_DG2.Visibility="visible"; $TD_LB_SAN_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_LB_sanBasicSwitchInfoThree.Visibility = "Visible";$TD_LB_sanBasicSwitchInfoThree.Content = "$($FOS_SwGeneralInfos.'Swicht Name')";$TD_CB_SAN_DG3.IsChecked="true";$TD_CB_SAN_DG3.Visibility="visible";$TD_LB_SAN_DG3.Visibility="visible"; $TD_LB_SAN_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_LB_sanBasicSwitchInfoFour.Visibility = "Visible"; $TD_LB_sanBasicSwitchInfoFour.Content = "$($FOS_SwGeneralInfos.'Swicht Name')" ;$TD_CB_SAN_DG4.IsChecked="true";$TD_CB_SAN_DG4.Visibility="visible";$TD_LB_SAN_DG4.Visibility="visible"; $TD_LB_SAN_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_LB_sanBasicSwitchInfoFive.Visibility = "Visible"; $TD_LB_sanBasicSwitchInfoFive.Content = "$($FOS_SwGeneralInfos.'Swicht Name')" ;$TD_CB_SAN_DG5.IsChecked="true";$TD_CB_SAN_DG5.Visibility="visible";$TD_LB_SAN_DG5.Visibility="visible"; $TD_LB_SAN_DG5.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 6){$TD_LB_sanBasicSwitchInfoSix.Visibility = "Visible";  $TD_LB_sanBasicSwitchInfoSix.Content = "$($FOS_SwGeneralInfos.'Swicht Name')"  ;$TD_CB_SAN_DG6.IsChecked="true";$TD_CB_SAN_DG6.Visibility="visible";$TD_LB_SAN_DG6.Visibility="visible"; $TD_LB_SAN_DG6.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 7){$TD_LB_sanBasicSwitchInfoSeven.Visibility = "Visible";$TD_LB_sanBasicSwitchInfoSeven.Content = "$($FOS_SwGeneralInfos.'Swicht Name')";$TD_CB_SAN_DG7.IsChecked="true";$TD_CB_SAN_DG7.Visibility="visible";$TD_LB_SAN_DG7.Visibility="visible"; $TD_LB_SAN_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_LB_sanBasicSwitchInfoEight.Visibility = "Visible";$TD_LB_sanBasicSwitchInfoEight.Content = "$($FOS_SwGeneralInfos.'Swicht Name')";$TD_CB_SAN_DG8.IsChecked="true";$TD_CB_SAN_DG8.Visibility="visible";$TD_LB_SAN_DG8.Visibility="visible"; $TD_LB_SAN_DG8.Content=$TD_Device_DeviceName}
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