function Get-BrocadeEffectiveZoneShow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $EffectiveResBase = Get-BrocadeEffectiveZoneConfig -Device $Device
    $EffectiveRes = @($EffectiveResBase.'enabled-zone')

    $Aliases = @(Get-BrocadeAliases -Device $Device)

    foreach($Zone in $EffectiveRes){

        $ZoneName       = $Zone.'zone-name'
        $ZoneType       = $Zone.'zone-type'
        $ZoneTypeString = $Zone.'zone-type-string'

        $ZoneTypeDisplay = switch($ZoneTypeString){
            'zone'                   { 'Standard' }
            'user-created-peer-zone' { 'Peer Zone' }
            default                  { $ZoneTypeString }
        }

        $RegularMembers = @(
            @($Zone.'member-entry'.'entry-name') | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
        )

        $PrincipalMembers = @()

        if($ZoneTypeString -like '*peer*'){
            $PrincipalMembers = @(
                @($Zone.'member-entry'.'principal-entry-name') | Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_)
                }
            )
        }

        foreach($WWPN in $PrincipalMembers){

            $AliasInfo = $Aliases | Where-Object {
                $_.WWPN -eq $WWPN
            } | Select-Object -First 1

            [PSCustomObject]@{
                ZoneName        = $ZoneName
                ZoneType        = $ZoneType
                ZoneTypeString  = $ZoneTypeString
                ZoneTypeDisplay = $ZoneTypeDisplay
                MemberRole      = 'Principal'
                Alias           = if($AliasInfo){ $AliasInfo.Alias } else { '<NoAlias>' }
                WWPN            = $WWPN
                Member          = if($AliasInfo){ "$($AliasInfo.Alias) [$WWPN]" } else { "<NoAlias> [$WWPN]" }
            }
        }

        foreach($WWPN in $RegularMembers){

            $AliasInfo = $Aliases | Where-Object {
                $_.WWPN -eq $WWPN
            } | Select-Object -First 1

            [PSCustomObject]@{
                ZoneName        = $ZoneName
                ZoneType        = $ZoneType
                ZoneTypeString  = $ZoneTypeString
                ZoneTypeDisplay = $ZoneTypeDisplay
                MemberRole      = if($ZoneTypeString -like '*peer*'){ 'Peer' } else { 'Member' }
                Alias           = if($AliasInfo){ $AliasInfo.Alias } else { '<NoAlias>' }
                WWPN            = $WWPN
                Member          = if($AliasInfo){ "$($AliasInfo.Alias) [$WWPN]" } else { "<NoAlias> [$WWPN]" }
            }
        }
    }
}