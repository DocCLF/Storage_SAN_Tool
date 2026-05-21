function Get-BrocadeSwitchShow {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $FCPorts    = Get-BrocadeFcPorts -Device $Device
    $SFP        = Get-BrocadeSfp -Device $Device
    $NameServer = Get-BrocadeNameServer -Device $Device
    $Aliases    = Get-BrocadeAliases -Device $Device

    foreach($Port in $FCPorts){
    
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

        [PSCustomObject]@{
            Index = $Port.index
            Port = $Port.name
            Address = $Port.'fcid-hex'
            Media = if($SFPInfo){
                switch($SFPInfo.'transmission-type'){
                    'shortwave' { 'SWL' }
                    'longwave'  { 'LWL' }
                default     { $SFPInfo.'transmission-type' }
                }
            }
            Speed = $Port.'protocol-speed'
            State = $Port.'operational-status-string'
            $PortStateInfo = SAN_PortStateInfo -SANSwitchWWNN $Device.WWNN -SANSerialNumber $Device.SerialNumber -SANPort $Port.name -SANState $Port.'operational-status-string'
            Proto = $Port.'port-type-string'
            WWPNs = @($NameServerInfo.'port-name') | Where-Object {$_}
            WWPN = @($NameServerInfo.'port-name') -join ', '
            SymbolicNames = @($CleanSymbolicNames) | Where-Object {$_}
            SymbolicName = @($CleanSymbolicNames) -join ', '
            Aliases = @($AliasList) | Where-Object {$_}
            Alias = @($AliasList) -join ', '
            PortConnectList = if($PortConnectList){
                @($PortConnectList)
            }else{
                $null
            }
            PortConnect = @($PortConnectList) -join "`n"
            RowID = $Port.index
        }
    }
}