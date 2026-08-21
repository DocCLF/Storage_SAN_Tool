function Get-BrocadeSwitchShow {
    # IMPORTANT:
    # port-index is only unique within a switch.
    # In fabrics with multiple switches the same port-index exists on remote switches.
    # Therefore always correlate NameServer entries using BOTH:
    #   FC Port WWN            == NameServer.fabric-port-name
    #   FC Port Index          == NameServer.port-index
    # This guarantees that only locally connected devices are returned.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $RowCounter = 0
    )
    $PB = New-ProgressBar
    $FCPorts    = Get-BrocadeFcPorts -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeFcPorts completed" -PercentComplete 5
    $SFP        = Get-BrocadeSfp -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeSfp completed" -PercentComplete 18
    $NameServer = Get-BrocadeNameServer -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeNameServer completed" -PercentComplete 36
    $Aliases    = Get-BrocadeAliases -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeAliases completed" -PercentComplete 40
    <# needed for DB #>
    $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeSwitchInfo completed" -PercentComplete 52
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeChassisInfo completed" -PercentComplete 59
    $SwitchWWNN = $SwitchInfo.name
    $SerialNumber = $ChassisInfo.'vendor-serial-number'
    
    <# needed for VFID #>
    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}
    Write-ProgressBar -ProgressBar $PB -Activity "Build the Object, start" -PercentComplete 68
    $FOS_SwitchShowInfo = foreach($Port in $FCPorts){
        $RowCounter++
        $RowID = "$($FCPorts.Count)|$($Device.ID)|$RowCounter"

        $SFPInfo = $SFP | Where-Object {
            ($_.name -replace '^fc/') -eq $Port.name
        }

        # Local WWPNs of the physical switch port
        $LocalPortWWPN = ([string]$Port.wwn).Trim()

        # Only consider name server logins that are actually 
        # logged in via this port on the switch currently being queried.
        $NameServerInfo = $NameServer | Where-Object {
            $NameServerPortWWPN = ([string]$_.'fabric-port-name').Trim()

            $_.'port-index' -eq $Port.index -and
            $NameServerPortWWPN -eq $LocalPortWWPN
        }

        $AliasList = foreach($NS in @($NameServerInfo)){
            $Aliases |
                Where-Object {
                    $_.WWPN -eq $NS.'port-name'
                } |
                Select-Object -ExpandProperty Alias
        }

        $PortConnectList = foreach($NS in @($NameServerInfo)){

            $AliasMatch = $Aliases | Where-Object {
                $_.WWPN -eq $NS.'port-name'
            }

            if($AliasMatch){
                "$($AliasMatch.Alias) [$($NS.'port-name')]"
            }
            elseif($NS.'port-symbolic-name'){
                $CleanName = $NS.'port-symbolic-name' `
                    -replace '^\[\d+\]\s*"', '' `
                    -replace '"$', ''

                "$CleanName [$($NS.'port-name')]"
            }
            else{
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
    Write-ProgressBar -ProgressBar $PB -Activity "Build the Object, end" -PercentComplete 80
        try {
            SST_CustomerSANDBInsertTable -SST_InfoType "SANPortInfo" -SST_CollectedInformations $FOS_SwitchShowInfo
            $FOS_SwitchShowInfo | Export-Csv -Path "$($TD_TB_ExportPath.Text)\FOS_SwitchShowInfo_$($SerialNumber)_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation -Append
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SwitchShowInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
        }finally{
            Close-ProgressBar -ProgressBar $PB
        }
        return $FOS_SwitchShowInfo
}