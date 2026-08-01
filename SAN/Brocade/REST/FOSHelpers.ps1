<# Brocade FOS HelperFuncEndpoints or in other words FOS - Library #>
function Get-BrocadeSwitchInfo {
    [CmdletBinding()]
    param($Device)

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fibrechannel-switch/fibrechannel-switch"

    if(-not $res.Success){
        return $res
    }

    $res.Data.'fibrechannel-switch'
}
function Get-BrocadeChassisInfo {
    [CmdletBinding()]
    param($Device)

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-chassis/chassis"

    if(-not $res.Success){
        return $res
    }

    $res.Data.chassis
}
function Get-BrocadeLogicalSwitches {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fibrechannel-logical-switch/fibrechannel-logical-switch"

    if(-not $res.Success){ 
        return $res 
    }

    $res.Data.'fibrechannel-logical-switch'
}
function Get-BrocadeManagementIPInterface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-management-ip-interface/management-ip-interface"

    if(-not $res.Success){
        return $res
    }

    $res.Data.'management-ip-interface'
}
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
function Get-BrocadeSecurity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        [PSCredential]$Credential
    )

    $InvokeParams = @{
        Device        = $Device
        FOSOperation  = "running/brocade-security/sec-crypto-cfg"
        IgnoreVFID    = $true
    }

    if ($Credential) {
        $InvokeParams.Credential = $Credential
    }

    $res = Invoke-BrocadeRest @InvokeParams

    if (-not $res.Success) {
        return $res
    }

    $res.Data.'sec-crypto-cfg'
}
function Get-BrocadePasswdcfg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        [PSCredential]$Credential
    )

    $InvokeParams = @{
        Device        = $Device
        FOSOperation  = "running/brocade-security/password-cfg"
        IgnoreVFID    = $true
    }

    if ($Credential) {
        $InvokeParams.Credential = $Credential
    }

    $res = Invoke-BrocadeRest @InvokeParams

    if (-not $res.Success) {
        return $res
    }

    $res.Data.'password-cfg'
}
function Get-BrocadeIPfilter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,

        [PSCredential]$Credential
    )

    $InvokeParams = @{
        Device       = $Device
        FOSOperation = 'running/brocade-security/ipfilter-policy'
        IgnoreVFID   = $true
    }

    if ($Credential) {
        $InvokeParams.Credential = $Credential
    }

    $res = Invoke-BrocadeRest @InvokeParams

    if (-not $res.Success) {
        return $res
    }

    $IPFilterPolicies = @(
        $res.Data.'ipfilter-policy'
    )

    foreach ($Policy in $IPFilterPolicies) {
        [PSCustomObject]@{
            PolicyName = $Policy.name
            IPVersion  = $Policy.'ip-version'
            IsActive   = [bool]$Policy.'is-policy-active'
            IsDefault  = [bool]$Policy.'is-default-policy'
            RawData    = $Policy
        }
    }
}
function Get-BrocadeUsercfg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        [PSCredential]$Credential
    )

    $InvokeParams = @{
        Device        = $Device
        FOSOperation  = "running/brocade-security/user-config"
        IgnoreVFID    = $true
    }

    if ($Credential) {
        $InvokeParams.Credential = $Credential
    }

    $res = Invoke-BrocadeRest @InvokeParams

    if (-not $res.Success) {
        return $res
    }

    $res.Data.'user-config'
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
function Get-BrocadeFCstatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-interface/fibrechannel-statistics"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.'fibrechannel-statistics'
}
function Get-BrocadeEffectiveZoneConfig {
    param($Device)

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-zone/effective-configuration"

    if(-not $res.Success){
        return $res
    }
    $res.Data.'effective-configuration'
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
function Get-BrocadeLicenseRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )
    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-license/license"

    if(-not $res.Success){
        return $res
    }
    <# This is needed because WinPW 5.1 #>
    $Features = if($License.features.feature){@($License.features.feature)}else{@()}
    $Licenses = foreach($License in @($res.Data.license)){
        [PSCustomObject]@{
            LicenseName = $License.name
            Features = $Features
            FeatureString = @($License.features.feature) -join ', '
            ExpirationDate = $License.'expiration-date'
            GenerationDate = $License.'generation-date'
            LicenseFormat = $License.'license-format'
        }
    }

    [PSCustomObject]@{
        Success = $true
        Data = $Licenses
        Uri = $res.Uri
        Error = $null
    }
}
function Get-BrocadeLicenseInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )
    $LicenseRes = Get-BrocadeLicenseRaw -Device $Device

    return $LicenseRes.Data
}
function Get-BrocadeFruSensorRaw{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fru/sensor"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.sensor
}
function Get-BrocadeTemperatureInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $Sensor = Get-BrocadeFruSensorRaw -Device $Device

    # REST-Fehler unverändert nach oben weitergeben.
    if (
        $null -ne $Sensor -and
        $null -ne $Sensor.PSObject.Properties['Success'] -and
        -not [bool]$Sensor.Success
    ) {
        return $Sensor
    }

    $TempSensors = @(
        $Sensor |
            Where-Object { $_.category -eq 'temperature' }
    )

    $TemperatureInfo = @($TempSensors.temperature)

    # Keine Temperatursensoren gefunden.
    if ($TemperatureInfo.Count -eq 0) {
        return
    }

    $MaxTemp = ($TemperatureInfo |
        Measure-Object -Maximum).Maximum

    $MinTemp = ($TemperatureInfo |
        Measure-Object -Minimum).Minimum

    $AverageTemp = [math]::Round(
        (($TemperatureInfo |
            Measure-Object -Average).Average),
        1
    )

    $HealthState = switch ($MaxTemp) {
        { $_ -ge 60 } { 'Critical'; break }
        { $_ -ge 50 } { 'Warning';  break }
        default       { 'OK' }
    }

    $HotSensors = @(
        $TempSensors |
            Where-Object { $_.temperature -ge 40 }
    ).Count

    $FaultySensors = @(
        $TempSensors |
            Where-Object { $_.state -ne 'ok' }
    ).Count

    [PSCustomObject]@{
        SensorCount  = $TemperatureInfo.Count
        AverageTemp  = $AverageTemp
        MaxTemp      = $MaxTemp
        MinTemp      = $MinTemp
        HotSensors   = $HotSensors
        HealthState  = $HealthState
        FaultySensors = $FaultySensors
    }
}
function Get-BrocadeFruFanRaw{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fru/fan"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.fan
}
function Get-BrocadeFanInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $Fans = Get-BrocadeFruFanRaw -Device $Device

    # REST-Fehler unverändert zurückgeben.
    if (
        $null -ne $Fans -and
        $null -ne $Fans.PSObject.Properties['Success'] -and
        -not [bool]$Fans.Success
    ) {
        return $Fans
    }

    foreach ($Fan in @($Fans)) {
        [PSCustomObject]@{
            Fan            = "Fan$($Fan.'unit-number')"
            State          = $Fan.'operational-state'
            SpeedRPM       = $Fan.speed
            Airflow        = $Fan.'airflow-direction'
            TimeAwakeHours = $Fan.'time-awake'
            SerialNumber   = $Fan.'serial-number'
            PartNumber     = $Fan.'part-number'
            IsHealthy      = $Fan.'operational-state' -eq 'ok'
        }
    }
}
function Get-BrocadeFruPowerSupplyRaw{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fru/power-supply"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.'power-supply'
}
function Get-BrocadePowerSupplyInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $PowerSupplies = Get-BrocadeFruPowerSupplyRaw -Device $Device

    # REST-Fehler unverändert zurückgeben.
    if (
        $null -ne $PowerSupplies -and
        $null -ne $PowerSupplies.PSObject.Properties['Success'] -and
        -not [bool]$PowerSupplies.Success
    ) {
        return $PowerSupplies
    }

    foreach ($PSU in @($PowerSupplies)) {
        $State = $PSU.'operational-state'

        $Severity = switch ($State) {
            'ok'      { 'OK';       break }
            'warning' { 'Warning';  break }
            'faulty'  { 'Critical'; break }
            default   { 'Unknown' }
        }

        $InputVoltage = if ($null -ne $PSU.'input-voltage') {
            "$($PSU.'input-voltage') V"
        }

        $PowerUsage = if ($null -ne $PSU.'power-usage') {
            "$($PSU.'power-usage') W"
        }

        [PSCustomObject]@{
            PowerSupply                = "PSU$($PSU.'unit-number')"
            UnitNumber                 = $PSU.'unit-number'
            State                      = $State
            IsHealthy                  = $State -eq 'ok'
            Severity                   = $Severity
            PowerSource                = $PSU.'power-source'
            InputVoltage               = $InputVoltage
            PowerUsage                 = $PowerUsage
            Airflow                    = $PSU.'airflow-direction'
            TemperatureSensorSupported = $PSU.'temperature-sensor-supported'
            TimeAwakeHours             = $PSU.'time-awake'
            SerialNumber               = $PSU.'serial-number'
            PartNumber                 = $PSU.'part-number'
        }
    }
}
# Get-BrocadeFCdiagnostics needs more study
#function Get-BrocadeFCdiagnostics {
#    [CmdletBinding()]
#    param(
#        [Parameter(Mandatory)]
#        $Device
#    )
#
#    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fibrechannel-diagnostics"
#    Write-Host $res
#    if(-not $res.Success){
#        return $res
#    }
#    
#    $res.Data.'brocade-fibrechannel-diagnostics'
#}
