
function FOS_SSHSwitchShowInfo {
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

        $SANSwitchIdent = FOS_SSHSwitchIdent -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
        
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
        $SwitchShowRowID = "$($SANSwitchIdent.SwitchWWNN)|$($TD_Line_ID)"
    }
    
    process {

        Write-Debug -Message "Process Func GET_SwitchShowInfo |$(Get-Date)`n "
        <# fill the var with a dummy #>
        $FOS_PortConnect = "empty"
        <# get Switch wwn for DB and PortCheck #>
        $FOS_switchWwn = ($FOS_MainInformation |Select-String -Pattern '^switchWwn:\s+([\w\:]{20,24})' -AllMatches).Matches.Groups.Value[1]
        foreach($FOS_linebyLine in $FOS_SwShowArry_temp){

            <# Only collect data up to the next section, marked by frames #>
            if ($FOS_linebyLine -match '^\s+frames') { break }

            if ([string]::IsNullOrWhiteSpace($FOS_linebyLine)) { continue }
            if ($FOS_linebyLine -notmatch '^\s+\d+') { continue } # (\d+\.\d\w|\d+)
    
            # Build the Portsection of switchshow
            $PortStateInfo = $null
            $FOS_SWsh = "" | Select-Object Index,Port,Address,Media,Speed,State,Proto,PortConnect,SwitchWWN,PortStateInfo,SwitchWWNN,SerialNumber,RowID
            $FOS_SWsh.SwitchWWNN = $SANSwitchIdent.SwitchWWNN
            $FOS_SWsh.SerialNumber = $SANSwitchIdent.SerialNumber
            $FOS_SWsh.RowID = $SwitchShowRowID
            #$FOS_SWsh.SwitchWWN = $FOS_switchWwn
            <# Port index is a number between 0 and the maximum number of supported ports on the platform. The port index identifies the port number relative to the switch. #>
            $m = $FOS_linebyLine | Select-String -Pattern '^\s+(\d+)'
            if ($m) {$FOS_SWsh.Index = $m.Matches[0].Groups[1].Value } else {continue }
            $FOS_SWshIndex = $FOS_SWsh.Index
            $m = $FOS_linebyLine | Select-String -Pattern '^\s+\d+\s+(\d+)'
            if ($m) {$FOS_SWsh.Port = $m.Matches[0].Groups[1].Value}
            $FOS_SWshPort = $FOS_SWsh.Port
            $m = $FOS_linebyLine | Select-String -Pattern '([\w]+)\s+(id|--|cu)\s+'
            if ($m) {$FOS_SWsh.Address = $m.Matches[0].Groups[1].Value}
            $m = $FOS_linebyLine | Select-String -Pattern '\s+(id|--|cu)\s+'
            if ($m) {$FOS_SWsh.Media = $m.Matches[0].Groups[1].Value}
            $m = $FOS_linebyLine | Select-String -Pattern '\s+(id|--|cu)\s+(N\d+|\d+G|AN|UN)'
            if ($m) {$FOS_SWsh.Speed = $m.Matches[0].Groups[2].Value}
            $m = $FOS_linebyLine | Select-String -Pattern '(\w+_\w+|\w+)\s+(FC)'
            if ($m) {
                $FOS_SWsh.State = $m.Matches[0].Groups[1].Value
                $FOS_SWsh.Proto = $m.Matches[0].Groups[2].Value
            }
            $FOS_SWshState = $FOS_SWsh.State
            $m = $FOS_linebyLine | Select-String -Pattern '(E-Port\s+([0-9a-f]{2}:){7}[0-9a-f]{2}\s+.*\))'
            if ($m) {
                $FOS_SWsh.PortConnect = $m.Matches[0].Groups[1].Value
            }else {
                $m = $FOS_linebyLine | Select-String -Pattern '\s+(FC)\s+([A-Za-z-]+\s+([0-9a-f]{2}:){7}[0-9a-f]{2}|\(.*\)|[A-Za-z-]+.*)'
                if ($m) {
                    $FOS_SWsh.PortConnect = $m.Matches[0].Groups[2].Value
                }
            }
                
            if($FOS_SWsh.PortConnect -like "*NPIV*"){
                $FOS_SwBasicPortDetails += $FOS_SWsh
                <# need a better way to connect #>
                $FOS_PortConnect_Infos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "portshow $($FOS_SWsh.Port)"
                foreach($FOS_PortConnect_Info in $FOS_PortConnect_Infos){
                    $m = $FOS_PortConnect_Info | Select-String -Pattern '^\s+(([0-9a-f]{2}:){7}[0-9a-f]{2})'
                    if ($m) {$FOS_NPIV_Info = $m.Matches[0].Groups[1].Value}else {continue}
                    if($FOS_NPIV_Info -ne $FOS_NPIV_Info_temp){
                        $FOS_SWsh = "" | Select-Object Index,Port,Address,Media,Speed,State,Proto,PortConnect,RowID
                        $FOS_SWsh.RowID = $SwitchShowRowID
                        $FOS_SWsh.Index = $FOS_SWshIndex
                        $FOS_SWsh.Port = $FOS_SWshPort
                        $FOS_SWsh.Address = "virtuell"
                        $FOS_SWsh.State = $FOS_SWshState
                        $FOS_SWsh.PortConnect = $FOS_NPIV_Info
                        $FOS_NPIV_Info_temp = $FOS_NPIV_Info
                        $FOS_SwBasicPortDetails += $FOS_SWsh
                    }
                }
                
            }else{
               $FOS_SwBasicPortDetails += $FOS_SWsh
            }
            # if the Portnumber is not empty and there is a SFP pluged in, push the Port in the FOS_usedPorts array
            if ($FOS_SWsh.Port -and $FOS_SWsh.Media -eq "id") {$FOS_usedPorts += $FOS_SWsh.Port}

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$FOS_SwShowArry_temp.Count) * 100)
        }

    }
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        #SST_CustomerSANDBInsertTable -SST_InfoType "SANPortInfo" -SST_CollectedInformations $FOS_SwBasicPortDetails

        <# returns the hashtable for further processing, not mandatory but the safe way #>
        Write-Debug -Message "End Func GET_SwitchShowInfo |$(Get-Date)`n "
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $FOS_SwBasicPortDetails | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                #SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $FOS_SwBasicPortDetails | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                #SST_ToolMessageCollector -TD_ToolMSGCollector "Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_SwitchShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
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