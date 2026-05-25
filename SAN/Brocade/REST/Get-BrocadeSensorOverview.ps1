function Get-BrocadeSensorOverview {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $TemperatureInfo = Get-BrocadeTemperatureInfo -Device $Device
    $Fans = @(Get-BrocadeFanInfo -Device $Device)
    $PowerSupplies = @(Get-BrocadePowerSupplyInfo -Device $Device)

    $FailedFans = @(
        $Fans | Where-Object { -not $_.IsHealthy }
    ).Count

    $FailedPowerSupplies = @(
        $PowerSupplies | Where-Object { -not $_.IsHealthy }
    ).Count

    $HotSensors = if($TemperatureInfo){
        [int]$TemperatureInfo.HotSensors
    }
    else{
        0
    }
    <# This is needed because WinPW 5.1 #>
    $OverallHealth = if($FailedFans -gt 0 -or $FailedPowerSupplies -gt 0 -or $HotSensors -gt 0 ){'Warning'}else{'OK'}
    
    [PSCustomObject]@{
        TemperatureInfo = $TemperatureInfo
        TemperatureAverage = $TemperatureInfo.AverageTemp
        TemperatureMax = $TemperatureInfo.MaxTemp
        TemperatureMin = $TemperatureInfo.MinTemp
        TemperatureHealth = $TemperatureInfo.HealthState
        Fans = $Fans
        PowerSupplies = $PowerSupplies

        FanCount = $Fans.Count
        PSUCount = $PowerSupplies.Count

        FailedFans = $FailedFans
        FailedPowerSupplies = $FailedPowerSupplies
        HotSensors = $HotSensors

        OverallHealth = $OverallHealth
    }
}