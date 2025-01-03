
function FOS_SwitchShowInfo {
    <#
    .SYNOPSIS
        Get switch and port status.
    .DESCRIPTION
        Use this command to display switch, blade, and port status information. Output may vary depending on the switch model.
    .NOTES
        Need infos to be added   
    .LINK
        BrocadeÂ® Fabric OSÂ® Command Reference Manual, 9.2.x
        https://techdocs.broadcom.com/us/en/fibre-channel-networking/fabric-os/fabric-os-commands/9-2-x/Fabric-OS-Commands/switchShow_921.html
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
        [string]$TD_Exportpath,
        [string]$TD_RefreshView
    )
    
    begin {
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        Write-Debug -Message "Start Func GET_SwitchShowInfo |$(Get-Date)`n "
        <#----- Array for information of the switchports ----#>
        $FOS_SwBasicPortDetails=@()
        <#----- Array for information of the used switchports ----#>
        $FOS_usedPorts =@()
        <# int for the progressbar #>
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connection to the system via ssh and filtering and provision of data #>
        <# Action when all if and elseif conditions are false #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $FOS_MainInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP "switchshow"
        }else {
            $FOS_MainInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "switchshow"
        }
        <# next line one for testing #>
        #$FOS_MainInformation = Get-Content -Path "C:\Users\mailt\Documents\swsh.txt"
        #Out-File -FilePath $Env:TEMP\$($TD_Line_ID)_SwitchShow_Temp.txt -InputObject $FOS_MainInformation
        
        $FOS_InfoCount = $FOS_MainInformation.count
        Write-Debug -Message "Number of Lines: $FOS_InfoCount "
        0..$FOS_InfoCount |ForEach-Object {
            # Pull only the effective ZoneCFG back into ZoneList
            if($FOS_MainInformation[$_] -match '^Index'){
                if($FOS_MainInformation[$_] -match '^\s+frames'){break}
                $FOS_SWShowTemp = $FOS_MainInformation |Select-Object -Skip $_
                $FOS_SwShowArry_temp = $FOS_SWShowTemp |Select-Object -Skip 2   
            }
        }
    }
    
    process {

        Write-Debug -Message "Process Func GET_SwitchShowInfo |$(Get-Date)`n "
        <# fill the var with a dummy #>
        $FOS_PortConnect = "empty"

        foreach($FOS_linebyLine in $FOS_SwShowArry_temp){

            <# Only collect data up to the next section, marked by frames #>
            if($FOS_linebyLine -match '^\s+frames'){break}
    
            # Build the Portsection of switchshow
            if($FOS_linebyLine -match '^\s+\d+'){   # (\d+\.\d\w|\d+)
                $FOS_SWsh = "" | Select-Object Index,Port,Address,Media,Speed,State,Proto,PortConnect
                <# Port index is a number between 0 and the maximum number of supported ports on the platform. The port index identifies the port number relative to the switch. #>
                $FOS_SWsh.Index = ($FOS_linebyLine |Select-String -Pattern '^\s+(\d+)' -AllMatches).Matches.Groups.Value[1]
                $FOS_SWshIndex = $FOS_SWsh.Index
                <# Port number; 0-15, 0-31, or 0-63. #>
                $FOS_SWsh.Port = ($FOS_linebyLine |Select-String -Pattern '^\s+\d+\s+(\d+)' -AllMatches).Matches.Groups.Value[1]
                $FOS_SWshPort = $FOS_SWsh.Port
                <# The 24-bit Address Identifier. #>
                $FOS_SWsh.Address = ($FOS_linebyLine |Select-String -Pattern '([0-9a-z]+)\s+(id|--|cu)\s+' -AllMatches).Matches.Groups.Value[1]
                <# Media types means module types #>
                $FOS_SWsh.Media = ($FOS_linebyLine |Select-String -Pattern '\s+(id|--|cu)\s+' -AllMatches).Matches.Groups.Value[1]
                <# The speed of the port. #>
                $FOS_SWsh.Speed = ($FOS_linebyLine |Select-String -Pattern '\s+(id|--|cu)\s+(N\d+|\d+G|AN|UN)' -AllMatches).Matches.Groups.Value[2]
                <# Port state information #>
                $FOS_SWsh.State = ($FOS_linebyLine |Select-String -Pattern '(\w+_\w+|\w+)\s+(FC)' -AllMatches).Matches.Groups.Value[1]
                $FOS_SWshState = $FOS_SWsh.State
                <# Protocol support by GbE port. #>
                $FOS_SWsh.Proto = ($FOS_linebyLine |Select-String -Pattern '(\w+_\w+|\w+)\s+(FC)' -AllMatches).Matches.Groups.Value[2]
                <# WWPN or other Infos #>
                $FOS_PortConnect = ($FOS_linebyLine |Select-String -Pattern '(E-Port\s+([0-9a-f]{2}:){7}[0-9a-f]{2}\s+.*\))' -AllMatches).Matches.Groups.Value[1]
                If($FOS_PortConnect -ne "empty"){
                    $FOS_SWsh.PortConnect =$FOS_PortConnect
                    $FOS_PortConnect = "empty"
                }else{
                    $FOS_SWsh.PortConnect = ($FOS_linebyLine |Select-String -Pattern '\s+(FC)\s+([A-Za-z-]+\s+([0-9a-f]{2}:){7}[0-9a-f]{2}|\(.*\)|[A-Za-z-]+.*)' -AllMatches).Matches.Groups.Value[2]
                }
                
                if($FOS_SWsh.PortConnect -like "*NPIV*"){
                    <# need a better way to connect #>
                    if($TD_Device_ConnectionTyp -eq "ssh"){
                        $FOS_MainInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP "portshow $($FOS_SWsh.Port)"
                        foreach($FOS_PortConnect_Info in $FOS_PortConnect_Infos){
                            $FOS_NPIV_Info = ($FOS_PortConnect_Info |Select-String -Pattern '^\s+(([0-9a-f]{2}:){7}[0-9a-f]{2})' -AllMatches).Matches.Groups.Value[1]
                            if($FOS_NPIV_Info -ne $FOS_NPIV_Info_temp){
                                $FOS_SwBasicPortDetails += $FOS_SWsh
                                $FOS_SWsh = "" | Select-Object Index,Port,Address,Media,Speed,State,Proto,PortConnect
                                $FOS_SWsh.Index = $FOS_SWshIndex
                                $FOS_SWsh.Port = $FOS_SWshPort
                                $FOS_SWsh.Address = "virtuell"
                                $FOS_SWsh.State = $FOS_SWshState
                                $FOS_SWsh.PortConnect = $FOS_NPIV_Info
                                $FOS_NPIV_Info_temp = $FOS_NPIV_Info
                                }
                        }
                    }else {
                        $FOS_PortConnect_Infos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "portshow $($FOS_SWsh.Port)"
                        foreach($FOS_PortConnect_Info in $FOS_PortConnect_Infos){
                            $FOS_NPIV_Info = ($FOS_PortConnect_Info |Select-String -Pattern '^\s+(([0-9a-f]{2}:){7}[0-9a-f]{2})' -AllMatches).Matches.Groups.Value[1]
                            if($FOS_NPIV_Info -ne $FOS_NPIV_Info_temp){
                                $FOS_SwBasicPortDetails += $FOS_SWsh
                                $FOS_SWsh = "" | Select-Object Index,Port,Address,Media,Speed,State,Proto,PortConnect
                                $FOS_SWsh.Index = $FOS_SWshIndex
                                $FOS_SWsh.Port = $FOS_SWshPort
                                $FOS_SWsh.Address = "virtuell"
                                $FOS_SWsh.State = $FOS_SWshState
                                $FOS_SWsh.PortConnect = $FOS_NPIV_Info
                                $FOS_NPIV_Info_temp = $FOS_NPIV_Info
                                }
                        }
                    }
                }else{
                   $FOS_SwBasicPortDetails += $FOS_SWsh
                }
                
            }
            # if the Portnumber is not empty and there is a SFP pluged in, push the Port in the FOS_usedPorts array
            if(($FOS_SWsh.Port -ne "") -and ($FOS_SWsh.Media -eq "id")){$FOS_usedPorts += $FOS_SWsh.Port}

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$FOS_SwShowArry_temp.Count) * 100)
        }

    }
    
    end {
        if($TD_Line_ID -eq 1){$TD_CB_SAN_DG1.Visibility="visible";$TD_LB_SAN_DG1.Visibility="visible"; $TD_LB_SAN_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_CB_SAN_DG2.Visibility="visible";$TD_LB_SAN_DG2.Visibility="visible"; $TD_LB_SAN_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_CB_SAN_DG3.Visibility="visible";$TD_LB_SAN_DG3.Visibility="visible"; $TD_LB_SAN_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_CB_SAN_DG4.Visibility="visible";$TD_LB_SAN_DG4.Visibility="visible"; $TD_LB_SAN_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_CB_SAN_DG5.Visibility="visible";$TD_LB_SAN_DG5.Visibility="visible"; $TD_LB_SAN_DG5.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 6){$TD_CB_SAN_DG6.Visibility="visible";$TD_LB_SAN_DG6.Visibility="visible"; $TD_LB_SAN_DG6.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 7){$TD_CB_SAN_DG7.Visibility="visible";$TD_LB_SAN_DG7.Visibility="visible"; $TD_LB_SAN_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_CB_SAN_DG8.Visibility="visible";$TD_LB_SAN_DG8.Visibility="visible"; $TD_LB_SAN_DG8.Content=$TD_Device_DeviceName}
        Close-ProgressBar -ProgressBar $ProgressBar
        <# returns the hashtable for further processing, not mandatory but the safe way #>
        Write-Debug -Message "End Func GET_SwitchShowInfo |$(Get-Date)`n "
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $FOS_SwBasicPortDetails | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $FOS_SwBasicPortDetails | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_SwBasicPortDetails
        }

        <# FOS_usedPorts commented out can be used later via filter option if necessary #>
        return $FOS_SwBasicPortDetails #, $FOS_usedPorts 

        <# Cleanup all TD* Vars #>
        Clear-Variable FOS* -Scope Global
    }
}