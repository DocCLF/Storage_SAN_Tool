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

    $FOS_SwitchShowInfo = foreach($Port in $FCPorts){
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
        $Proto = switch($Port.'port-type-string'){
            'e-port'         { 'E-Port' }
            'f-port'         { 'F-Port' }
            'n-port'         { 'N-Port' }
            'universal-port' { 'U-Port' }
            default          { $Port.'port-type-string' }
        }

        $Speed = $Port.'protocol-speed'
        if($Speed){$Speed = $Speed -replace '-gfc$',' G'}

        $EPortConnect = $null

        if($Port.'port-type-string' -eq 'e-port'){
        
            $NeighborName = $Port.'neighbor-switch-user-friendly-name'
            $NeighborWWN  = $Port.'neighbor-node-wwn'
            $NeighborPort = $Port.'neighbor-slot-port'
        
            if($NeighborName -or $NeighborWWN){
                $EPortConnect = "$NeighborName [$NeighborWWN] ($NeighborPort)"
            
                if($NeighborPort){
                    $EPortConnect = "$EPortConnect Port $NeighborPort"
                }
            
                if($Port.'trunk-port-enabled-v2'){
                    $EPortConnect = "$EPortConnect (Trunk)"
                }
            }
        }

        $PortConnectText = if($EPortConnect){
            $EPortConnect
        }
        elseif($PortConnectList){
            @($PortConnectList) -join "`n"
        }
        else{
            ""
        }
        <# is required to display the other FIDs in the DG in a different color, for example #>
        $IsVirtualFabricPort = if($VFID -and $VFID -ne 128){ $true } else { $false }
        <# ask db for the last Portstatus #>
        $PortStateInfo = SAN_PortStateInfo -SANSwitchWWNN $SwitchWWNN -SANSerialNumber $SerialNumber -SANPort $Port.name -SANState $Port.'operational-status-string'

        [PSCustomObject]@{
            IsVirtualFabricPort = $IsVirtualFabricPort
            VFID = $VFID 
            VFIDDisplay = $VFIDDisplay
            Index = $Port.index
            Port = $Port.name
            Address = $Port.'fcid-hex'
            Media = $Media
            Speed = $Speed
            State = $Port.'operational-status-string'
            PortStateInfo = $PortStateInfo.CheckResult
            Proto = $Proto
            WWPNs = @(@($NameServerInfo.'port-name') | Where-Object {$_})
            WWPN = @($NameServerInfo.'port-name') -join ', '
            SymbolicNames = @(@($CleanSymbolicNames) | Where-Object {$_})
            SymbolicName = @($CleanSymbolicNames) -join ', '
            Aliases = @(@($AliasList) | Where-Object {$_})
            Alias = @($AliasList) -join ', '
            PortConnectList = $PortConnectLists
            PortConnect = $PortConnectText
            SerialNumber = $SerialNumber
            SwitchWWNN   = $SwitchWWNN
            RowID = $RowID
        }
    }
        try {
            SST_CustomerSANDBInsertTable -SST_InfoType "SANPortInfo" -SST_CollectedInformations $FOS_SwitchShowInfo
            $FOS_SwitchShowInfo | Export-Csv -Path "$($TD_TB_ExportPath.Text)\FOS_SwitchShowInfo_$($SerialNumber)_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation -Append
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SwitchShowInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
        }
        return $FOS_SwitchShowInfo
}