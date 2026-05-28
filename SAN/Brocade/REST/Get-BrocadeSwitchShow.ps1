function Get-BrocadeSwitchShow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $RowCounter = 0
    )

    $FCPorts    = Get-BrocadeFcPorts -Device $Device
    $SFP        = Get-BrocadeSfp -Device $Device
    $NameServer = Get-BrocadeNameServer -Device $Device
    $Aliases    = Get-BrocadeAliases -Device $Device
    <# needed for DB #>
    $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    $SwitchWWNN = $SwitchInfo.name
    $SerialNumber = $ChassisInfo.'vendor-serial-number'
    
    <# needed for VFID #>
    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}

    foreach($Port in $FCPorts){
        $RowCounter++
        $RowID = "$($FCPorts.count)|$($Device.ID)|$RowCounter)"
        $SFPInfo = $SFP | Where-Object {
            ($_.name -replace '^fc/') -eq $Port.name
        }
    
        $NameServerInfo = $NameServer | Where-Object {
            $_.'port-index' -eq $Port.index
        }
            
        $AliasList = foreach($NS in @($NameServerInfo)){
            $Aliases | Where-Object {
                $_.WWPN -eq $NS.'port-name'
            } | Select-Object -ExpandProperty Alias
        }

        $PortConnectList = foreach($NS in @($NameServerInfo)){
            $AliasMatch = $Aliases | Where-Object {
                $_.WWPN -eq $NS.'port-name'
            }
            if($AliasMatch){
                "$($AliasMatch.Alias) [$($NS.'port-name')]"
            }elseif($NS.'port-symbolic-name'){
                $CleanName = $NS.'port-symbolic-name' -replace '^\[\d+\]\s*"', '' -replace '"$', ''
                "$CleanName [$($NS.'port-name')]"
            }else{
                "<NoAlias> [$($NS.'port-name')]"
            }
        }
        $CleanSymbolicNames = foreach($NS in @($NameServerInfo)){
            if($NS.'port-symbolic-name'){
                $NS.'port-symbolic-name' -replace '^\[\d+\]\s*"', '' -replace '"$', ''
            }
        }
        <# This is needed because WinPW 5.1 #>
        $Media = if($SFPInfo){
                switch($SFPInfo.'transmission-type'){
                    'shortwave' { 'SWL' }
                    'longwave'  { 'LWL' }
                default     { $SFPInfo.'transmission-type' }
                }
            }
        $PortConnectLists = if($PortConnectList){
                @($PortConnectList)
            }else{
                $null
            }

        $FOS_SwBasicPortDetails = [PSCustomObject]@{
            VFID = $VFID 
            VFIDDisplay = $VFIDDisplay
            Index = $Port.index
            Port = $Port.name
            Address = $Port.'fcid-hex'
            Media = $Media
            Speed = $Port.'protocol-speed'
            State = $Port.'operational-status-string'
            <# ask db for the last Portstatus #>
            $PortStateInfo = SAN_PortStateInfo -SANSwitchWWNN $SwitchWWNN -SANSerialNumber $SerialNumber -SANPort $Port.name -SANState $Port.'operational-status-string'
            PortStateInfo = $PortStateInfo
            Proto = $Port.'port-type-string'
            WWPNs = @(@($NameServerInfo.'port-name') | Where-Object {$_})
            WWPN = @($NameServerInfo.'port-name') -join ', '
            SymbolicNames = @(@($CleanSymbolicNames) | Where-Object {$_})
            SymbolicName = @($CleanSymbolicNames) -join ', '
            Aliases = @(@($AliasList) | Where-Object {$_})
            Alias = @($AliasList) -join ', '
            PortConnectList = $PortConnectLists
            PortConnect = @($PortConnectList) -join "`n"
            SerialNumber = $SwitchWWNN
            SwitchWWNN = $SerialNumber
            RowID = $RowID
        }
    }
        try {
            SST_CustomerSANDBInsertTable -SST_InfoType "SANPortInfo" -SST_CollectedInformations $FOS_SwBasicPortDetails
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host $_.Exception.Message
        }
        return $FOS_SwBasicPortDetails
}