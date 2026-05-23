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
<# The “diag” requires higher privileges than the “user” role, so this will not be pursued further for now. #>
<# The function returns the following with (user role): 
    Error=Response status code does not indicate success: 405 (Method Not Allowed)
#>
function Get-BrocadeFCdiagnostics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fibrechannel-diagnostics"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.'brocade-fibrechannel-diagnostics'
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

    $Licenses = foreach($License in @($res.Data.license)){
        [PSCustomObject]@{
            LicenseName = $License.name
            Features = if($License.features.feature){@($License.features.feature)}else{@()}
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

    $TempSensors = @($Sensor | Where-Object {$_.category -eq 'temperature'})
    $TemperatureInfo = @($TempSensors.temperature)
    $MaxTemp = if($TemperatureInfo){($TemperatureInfo | Measure-Object -Maximum).Maximum}
    $MinTemp = if($TemperatureInfo){($TemperatureInfo | Measure-Object -Minimum).Minimum}

    [PSCustomObject]@{
        SensorCount = $TemperatureInfo.Count
        AverageTemp = if($TemperatureInfo){
            [math]::Round((($TemperatureInfo | Measure-Object -Average).Average),1)
        }
        MaxTemp = $MaxTemp
        MinTemp = $MinTemp
        HotSensors = @($TempSensors | Where-Object {$_.temperature -ge 40}).Count
        HealthState = switch($MaxTemp){
            {$_ -ge 60} { 'Critical' }
            {$_ -ge 50} { 'Warning' }
            default { 'OK' }
        }
        FaultySensors = @($TempSensors | Where-Object {$_.state -ne 'ok'}).Count
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

    foreach($Fan in @($Fans)){

        [PSCustomObject]@{
            Fan = "Fan$($Fan.'unit-number')"
            State = $Fan.'operational-state'
            SpeedRPM = $Fan.speed
            Airflow = $Fan.'airflow-direction'
            TimeAwakeHours = $Fan.'time-awake'
            SerialNumber = $Fan.'serial-number'
            PartNumber = $Fan.'part-number'
            IsHealthy = $Fan.'operational-state' -eq 'ok'
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

    foreach($PSU in @($PowerSupplies)){
        $State = $PSU.'operational-state'
        [PSCustomObject]@{

            PowerSupply = "PSU$($PSU.'unit-number')"
            UnitNumber = $PSU.'unit-number'
            State = $State
            IsHealthy = $State -eq 'ok'
            Severity = switch($State){

                'ok'      { 'OK' }

                'warning' { 'Warning' }

                'faulty'  { 'Critical' }

                default   { 'Unknown' }
            }
            PowerSource = $PSU.'power-source'
            InputVoltage = if($PSU.'input-voltage'){
                "$($PSU.'input-voltage') V"
            }
            PowerUsage = if($PSU.'power-usage'){
                "$($PSU.'power-usage') W"
            }
            Airflow = $PSU.'airflow-direction'
            TemperatureSensorSupported = $PSU.'temperature-sensor-supported'
            TimeAwakeHours = $PSU.'time-awake'
            SerialNumber = $PSU.'serial-number'
            PartNumber = $PSU.'part-number'
            ManufactureDate = $PSU.'manufacture-date'
        }
    }
}
function Get-BrocadeFruWwnRaw{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $res = Invoke-BrocadeRest -Device $Device -FOSOperation "running/brocade-fru/wwn"

    if(-not $res.Success){
        return $res
    }
    
    $res.Data.'fibrechannel-statistics'
}

