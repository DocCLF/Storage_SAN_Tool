function Get-BrocadeBaseInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )
    $PB = New-ProgressBar

    $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-SwitchInfo completed" -PercentComplete 20
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-ChassisInfo completed" -PercentComplete 40
    $EffectiveCFG = Get-BrocadeEffectiveZoneConfig -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-EffectiveZoneConfig completed" -PercentComplete 60
    $MgmtInfo = Get-BrocadeManagementIPInterface -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-ManagementIPInterface completed" -PercentComplete 80
    $LogicalSwitches = @(Get-BrocadeLogicalSwitches -Device $Device)

    $RawMTM = $ChassisInfo.'vendor-part-number'
    if($RawMTM -match '0*(\d{4})0*([A-Z0-9]{3})'){
        $MTM = "$($Matches[1])-$($Matches[2])"
    }else{
        $MTM = $RawMTM
    }
    <# This is needed because WinPW 5.1 #>
    $SwitchRole = if($SwitchInfo.'is-principal'){
            'Principal'
        }
        else{
            'Subordinate'
        }
    $SwitchName = $SwitchInfo.'user-friendly-name'
    if ([string]::IsNullOrWhiteSpace($SwitchName)) {
        $SwitchName = "Unknown_$($ChassisInfo.'vendor-serial-number')"
    }
    $FOS_SwGeneralInfos = [PSCustomObject]@{
        SwitchName = $SwitchName
        ActiveZoneCFG = $EffectiveCFG.'cfg-name'
        DomainID = $SwitchInfo.'domain-id'
        SwitchWWNN = $SwitchInfo.name
        FabricName = $SwitchInfo.'fabric-user-friendly-name'
        vFabricID = $SwitchInfo.'vf-id'
        VFID = @($LogicalSwitches.'fabric-id')
        VFIDString = @($LogicalSwitches.'fabric-id') -join ', '
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
        SwitchRole = $SwitchRole
        VFenabled = $ChassisInfo.'vf-enabled'
        VFsupported = $ChassisInfo.'vf-supported'
        RowID = $SwitchInfo.'domain-id'
    }
    Write-ProgressBar -ProgressBar $PB -Activity "Create Obj completed" -PercentComplete 90
    try {
        SST_CustomerSANDBInsertTable -SST_InfoType "SANBase" -SST_CollectedInformations $FOS_SwGeneralInfos
        Out-File -FilePath "$($TD_TB_ExportPath.Text)\BasicSwitchInfo_$($FOS_SwGeneralInfos.SwitchName)_$($FOS_SwGeneralInfos.ActiveZoneCFG)_$(Get-Date -Format "yyyy-MM-dd").csv" -InputObject $FOS_SwGeneralInfos
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message
        SST_ToolMessageCollector -TD_ToolMSGCollector "BasicSwitchInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning"
    }finally{
        Close-ProgressBar -ProgressBar $PB
    }
    
    return $FOS_SwGeneralInfos

}