<# Brocade FOS HelperFuncEndpoints or in other words FOS - Library #>

function Get-BrocadeFcPorts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-interface/fibrechannel"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.fibrechannel
}

function Get-BrocadeSfp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-media/media-rdp"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.'media-rdp'
}

function Get-BrocadeNameServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-name-server/fibrechannel-name-server"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.'fibrechannel-name-server'
}

function Get-BrocadeEffectiveZoneConfig {
    param($Device)

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-zone/effective-configuration"
    return $res
}


function Get-BrocadeDefinedZoneConfig {
    param($Device)

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-zone/defined-configuration"
    return $res
}

function Get-BrocadeAliases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Get-BrocadeDefinedZoneConfig -Device $Device

    if(-not $res.Success){
        return $res
    }

    foreach($Alias in $res.Data.'defined-configuration'.alias){

        foreach($Member in @($Alias.'member-entry')){
            [PSCustomObject]@{
                Alias = $Alias.'alias-name'
                WWPN  = $Member.'alias-entry-name'
            }
        }
    }
}