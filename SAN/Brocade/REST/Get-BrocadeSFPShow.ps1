function Get-BrocadeSFPShow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $RowCounter = 0
    )

    $FCPorts = Get-BrocadeFcPorts -Device $Device
    $SFPs    = Get-BrocadeSfp -Device $Device

    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}
    
    foreach($Port in $FCPorts){
        $RowCounter++
        $RowID = "$($FCPorts.count)|$($Device.ID)|$RowCounter)"

        $SFPInfo = $SFPs | Where-Object {
            ($_.name -replace '^fc/') -eq $Port.name
        }

        $RxPowerValue = if($SFPInfo){
            [double]($SFPInfo.'rx-power'.ToString() -replace ',', '.')
        }

        $TempValue = if($SFPInfo){
            [int]$SFPInfo.temperature
        }
        <# This is needed because WinPW 5.1 #>
        $SFPTyp = if($SFPInfo){ $SFPInfo.identifier } else { $null }
        $Connector = if($SFPInfo){ $SFPInfo.connector } else { $null }
        $Media = if($SFPInfo){ $SFPInfo.'transmission-type' } else { 'No SFP' }
        $Vendor = if($SFPInfo){ $SFPInfo.'vendor-name' } else { $null }
        $PartNumber = if($SFPInfo){ $SFPInfo.'part-number' } else { $null }
        $SerialNo = if($SFPInfo){ $SFPInfo.'serial-number' } else { $null }
        $Speed = $Port.'protocol-speed'
        if($Speed){$SpeedRange = $Speed -replace '-gfc$',' G'}
        $Temperature = if($SFPInfo){ $TempValue } else { $null }
        $TempState = if($SFPInfo -and $TempValue -ge 70){ 'HOT' } elseif($SFPInfo){ 'OK' } else { $null }
        $RxPower = if($SFPInfo){ $SFPInfo.'rx-power' } else { $null }
        $OpticalState = if($SFPInfo){
            switch($RxPowerValue){
                {$_ -le 0}   { 'No Light'; break }
                {$_ -lt 100} { 'Low Signal'; break }
                default      { 'OK' }
            }
        } else { $null }
        $TxPower = if($SFPInfo){ $SFPInfo.'tx-power' } else { $null }
        $Voltage = if($SFPInfo){ $SFPInfo.voltage } else { $null }
        $Wavelength = if($SFPInfo){ "$($SFPInfo.wavelength) nm" } else { $null }
        $PowerOnTime = if($SFPInfo){ $SFPInfo.'power-on-time' } else { $null }



        [PSCustomObject]@{
            VFID = $VFID 
            VFIDDisplay = $VFIDDisplay
            Port = $Port.name
            State = $Port.'operational-status-string'
            SFPUsed = [bool]$SFPInfo

            SFPTyp = $SFPTyp
            Connector = $Connector
            Media = $Media

            Vendor = $Vendor
            PartNumber = $PartNumber
            SerialNo = $SerialNo

            SpeedRange = $SpeedRange

            Temperature = $Temperature
            TempState = $TempState

            RxPower = $RxPower
            OpticalState = $OpticalState

            TxPower = $TxPower
            Voltage = $Voltage
            Wavelength = $Wavelength
            PowerOnTime = $PowerOnTime
            RowID = $RowID
        }
    }
}