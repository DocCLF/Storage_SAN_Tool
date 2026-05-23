function Get-BrocadeBaseInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )
    $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    $EffectiveCFG = Get-BrocadeEffectiveZoneConfig -Device $Device
    $MgmtInfo = Get-BrocadeManagementIPInterface -Device $Device

    $RawMTM = $ChassisInfo.'vendor-part-number'
    if($RawMTM -match '0*(\d{4})0*([A-Z0-9]{3})'){
        $MTM = "$($Matches[1])-$($Matches[2])"
    }else{
        $MTM = $RawMTM
    }


    [PSCustomObject]@{
        SwitchName = $SwitchInfo.'user-friendly-name'
        ActiveZoneCFG = $EffectiveCFG.Data.'cfg-name'
        DomainID = $SwitchInfo.'domain-id'
        SwitchWWNN = $SwitchInfo.name
        FabricName = $SwitchInfo.'fabric-user-friendly-name'
        vFabricID = $SwitchInfo.'vf-id'
        BrocadeProductName = $ChassisInfo.'product-name'
        SwitchType = $SwitchInfo.'model'
        MTM = $MTM
        SerialNumber = $ChassisInfo.'vendor-serial-number'
        FabricOS = $SwitchInfo.'firmware-version'
        EthernetIPAddress = @($SwitchInfo.'ip-address'.'ip-address') -join ', '
        EthernetSubnetMask = $SwitchInfo.'subnet-mask'
        GatewayIPAddress = @($SwitchInfo.'ip-static-gateway-list'.'ip-static-gateway') -join "`n"
        DNSServer = @($SwitchInfo.'dns-servers'.'dns-server') -join "`n"
        DHCP = $MgmtInfo.'dhcp-enabled'
        SwitchState = $SwitchInfo.'operational-status-string'
        SwitchRole = if($SwitchInfo.'is-principal'){
            'Principal'
        }
        else{
            'Subordinate'
        }
        VFenabled = $ChassisInfo.'vf-enabled'
        VFsupported = $ChassisInfo.'vf-supported'
        RowID = $SwitchInfo.'domain-id'
    }
}
<#Ausgabe 
@{SwitchName=FC01-RZ1; ActiveZoneCFG=WOEHNER_SAN1; DomainID=10; SwitchWWNN=10:00:38:ba:b0:4b:2a:f0; FabricName=Fabric01; vFabricID=128; BrocadeProductName=g720; 
    SwitchType=181.0; MTM=8960-P64; SerialNumber=786713E; FabricOS=v9.2.1a; EthernetIPAddress=192.168.107.40; EthernetSubnetMask=255.255.255.0; GatewayIPAddress=192.168.107.1; 
    DNSServer=; DHCP=False; SwitchState=enabled; SwitchRole=Subordinate; VFenabled=True; VFsupported=True; RowID=10}
    #>