function Get-BrocadeSFPShow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $FCPorts = Get-BrocadeFcPorts -Device $Device
    $SFPs    = Get-BrocadeSfp -Device $Device

    foreach($Port in $FCPorts){

        $SFPInfo = $SFPs | Where-Object {
            ($_.name -replace '^fc/') -eq $Port.name
        }

        $RxPowerValue = if($SFPInfo){
            [double]($SFPInfo.'rx-power'.ToString() -replace ',', '.')
        }

        $TempValue = if($SFPInfo){
            [int]$SFPInfo.temperature
        }

        [PSCustomObject]@{
            Port = $Port.name
            State = $Port.'operational-status-string'
            SFPUsed = [bool]$SFPInfo

            SFPTyp = if($SFPInfo){ $SFPInfo.identifier }
            Connector = if($SFPInfo){ $SFPInfo.connector }
            Media = if($SFPInfo){ $SFPInfo.'transmission-type' } else { 'No SFP' }

            Vendor = if($SFPInfo){ $SFPInfo.'vendor-name' }
            PartNumber = if($SFPInfo){ $SFPInfo.'part-number' }
            SerialNo = if($SFPInfo){ $SFPInfo.'serial-number' }

            SpeedRange = if($SFPInfo){ $Port.'protocol-speed' }

            Temperature = if($SFPInfo){ $TempValue }
            TempState = if($SFPInfo -and $TempValue -ge 70){ 'HOT' } elseif($SFPInfo){ 'OK' }

            RxPower = if($SFPInfo){ $SFPInfo.'rx-power' }
            OpticalState = if($SFPInfo){
                switch($RxPowerValue){
                    {$_ -le 0}   { 'No Light'; break }
                    {$_ -lt 100} { 'Low Signal'; break }
                    default      { 'OK' }
                }
            }

            TxPower = if($SFPInfo){ $SFPInfo.'tx-power' }
            Voltage = if($SFPInfo){ $SFPInfo.voltage }
            Wavelength = if($SFPInfo){ "$($SFPInfo.wavelength) nm" }
            PowerOnTime = if($SFPInfo){ $SFPInfo.'power-on-time' }
        }
    }
}