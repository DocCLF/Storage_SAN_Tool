function Get-BrocadeEffectiveZoneShow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $RowCounter = 0
    )

    $EffectiveResBase = Get-BrocadeEffectiveZoneConfig -Device $Device
    $EffectiveRes = @($EffectiveResBase.'enabled-zone')
    $Aliases = @(Get-BrocadeAliases -Device $Device)

    $VFID = if($Device.PSObject.Properties['VFID']){ $Device.VFID } else { $null }
    $VFIDDisplay = if($Device.PSObject.Properties['VFID']){"FID $($Device.VFID)"}else{""}

    $FOS_ZoneCollection = foreach($Zone in $EffectiveRes){

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
            <# This is needed because WinPW 5.1 #>
            $Alias = if($AliasInfo){ $AliasInfo.Alias } else { '<NoAlias>' }
            $Member = if($AliasInfo){ "$($AliasInfo.Alias) [$WWPN]" } else { "<NoAlias> [$WWPN]" }
            $RowCounter++
            $RowID = "$($Device.ID)|$WWPN|$RowCounter"
            $ZoneGroup = if($VFIDDisplay){
                "$VFIDDisplay | $ZoneName ($ZoneTypeDisplay)"
            }
            else{
                "$ZoneName ($ZoneTypeDisplay)"
            }
            [PSCustomObject]@{
                VFID            = $VFID 
                VFIDDisplay     = $VFIDDisplay
                ZoneGroup       = $ZoneGroup
                ZoneName        = $ZoneName
                ZoneType        = $ZoneType
                ZoneTypeString  = $ZoneTypeString
                ZoneTypeDisplay = $ZoneTypeDisplay
                MemberRole      = 'Principal'
                Alias           = $Alias
                WWPN            = $WWPN
                Member          = $Member
                RowID           = $RowID
            }
        }

        foreach($WWPN in $RegularMembers){

            $AliasInfo = $Aliases | Where-Object {
                $_.WWPN -eq $WWPN
            } | Select-Object -First 1
            <# This is needed because WinPW 5.1 #>
            $MemberRole = if($ZoneTypeString -like '*peer*'){ 'Peer' } else { 'Member' }
            $Alias = if($AliasInfo){ $AliasInfo.Alias } else { '<NoAlias>' }
            $Member = if($AliasInfo){ "$($AliasInfo.Alias) [$WWPN]" } else { "<NoAlias> [$WWPN]" }
            $RowCounter++
            $RowID = "$($Device.ID)|$WWPN|$RowCounter"

            $ZoneGroup = if($VFIDDisplay){
                "$VFIDDisplay | $ZoneName ($ZoneTypeDisplay)"
            }
            else{
                "$ZoneName ($ZoneTypeDisplay)"
            }
            [PSCustomObject]@{
                VFID            = $VFID 
                VFIDDisplay     = $VFIDDisplay
                ZoneGroup       = $ZoneGroup
                ZoneName        = $ZoneName
                ZoneType        = $ZoneType
                ZoneTypeString  = $ZoneTypeString
                ZoneTypeDisplay = $ZoneTypeDisplay
                MemberRole      = $MemberRole
                Alias           = $Alias
                WWPN            = $WWPN
                Member          = $Member
                RowID           = $RowID
            }
        }
    }
    try {
        $FOS_ZoneCollection | Export-Csv -Path "$($TD_TB_ExportPath.Text)\ZoneShow_$($EffectiveResBase.'cfg-name')_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "ZoneShow: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
    }

    return $FOS_ZoneCollection
}