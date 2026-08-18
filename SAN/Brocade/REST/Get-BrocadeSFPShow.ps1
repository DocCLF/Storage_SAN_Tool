function Get-BrocadeSFPShow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $TD_Exportpath = $null
    )
    $PB = New-ProgressBar

    $FCPorts = Get-BrocadeFcPorts -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-FcPorts completed" -PercentComplete 20
    $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeSwitchInfo completed" -PercentComplete 33
    $SFPs = Get-BrocadeSfp -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-Sfp completed" -PercentComplete 45
    <# only needed for the SN #>
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-ChassisInfo completed" -PercentComplete 65

    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}
    $ChassisSN = $($ChassisInfo.'vendor-serial-number')
    $SwitchName = $SwitchInfo.'user-friendly-name'
    if ([string]::IsNullOrWhiteSpace($SwitchName)) {
        $SwitchName = "Unknown_$($ChassisInfo.'vendor-serial-number')"
    }
    $SwitchWWNN = $SwitchInfo.name
    
    $FOS_SFPHealthInfo = foreach($Port in $FCPorts){

        $VFIDKey = if ($VFID) {[string]$VFID}else {'BASE'}
        $PortName = [string]$Port.name
        $RowID = '{0}|{1}|{2}' -f $ChassisSN,$VFIDKey,$PortName
        
        $SFPInfo = $SFPs | Where-Object {
            ($_.name -replace '^fc/') -eq $PortName
        } | Select-Object -First 1

        $RxPowerValue = $null
        if($SFPInfo -and $null -ne $SFPInfo.'rx-power'){
            $RxPowerValue = [double]($($SFPInfo.'rx-power').ToString() -replace ',', '.')
        }
        $TxPowerValue = $null
        if($SFPInfo -and $null -ne $SFPInfo.'tx-power'){
            $TxPowerValue = [double]($($SFPInfo.'tx-power').ToString() -replace ',', '.')
        }

        $VoltageValue = $null
        if ($SFPInfo -and $null -ne $SFPInfo.voltage) {
            $VoltageValue = [double]($($SFPInfo.voltage).ToString().Replace(',', '.'))
        }

        $TempValue = $null
        if ($SFPInfo -and $null -ne $SFPInfo.temperature) {
            $TempValue = [double]($($SFPInfo.temperature).ToString().Replace(',', '.'))
        }

        <# This is needed because WinPW 5.1 #>
        $SFPTyp = if($SFPInfo){ $SFPInfo.identifier } else { $null }
        $Connector = if($SFPInfo){ $SFPInfo.connector } else { $null }
        $Media = if($SFPInfo){ $SFPInfo.'transmission-type' } else { 'No SFP' }
        $Vendor = if($SFPInfo){ $SFPInfo.'vendor-name' } else { $null }
        $PartNumber = if($SFPInfo){ $SFPInfo.'part-number' } else { $null }
        $SerialNo = if($SFPInfo){ $SFPInfo.'serial-number' } else { $null }
        $Speed = $Port.'protocol-speed'
        $SpeedRange = $null
        if($Speed){$SpeedRange = $Speed -replace '-gfc$',' G'}
        $Temperature = if($SFPInfo){ $TempValue } else { $null }
        $TempState = if($SFPInfo -and $TempValue -ge 70){ 'HOT' } elseif($SFPInfo){ 'OK' } else { $null }
        $RxPower = if($SFPInfo){ $RxPowerValue } else { $null }
        $OpticalState = if($SFPInfo -and $null -ne $RxPowerValue){
            switch($RxPowerValue){
                {$_ -le 0}   { 'No Light'; break }
                {$_ -lt 100} { 'Low Signal'; break }
                default      { 'OK' }
            }
        }elseif($SFPInfo){
            'Unknown'
        }else{
            $null
        }
        $TxPower = if($SFPInfo){ $TxPowerValue } else { $null }
        $Voltage = if($SFPInfo){ $VoltageValue } else { $null }
        $Wavelength = $null
        if ($SFPInfo -and $null -ne $SFPInfo.wavelength) {
            $Wavelength = [double]($($SFPInfo.wavelength).ToString().Replace(',', '.'))
        }
        $PowerOnTime = if($SFPInfo){ $SFPInfo.'power-on-time' } else { $null }
        <# is required to display the other FIDs in the DG in a different color, for example #>
        $IsVirtualFabricPort = if($VFID -and $VFID -ne 128){ $true } else { $false }


        [PSCustomObject]@{
            IsVirtualFabricPort = $IsVirtualFabricPort
            VFID = $VFID 
            VFIDDisplay = $VFIDDisplay
            Port = $PortName
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
            SwitchName   = $SwitchName
            SerialNumber = $ChassisSN
            SwitchWWNN   = $SwitchWWNN
        }
    }
    Write-ProgressBar -ProgressBar $PB -Activity "Create Obj completed" -PercentComplete 90
    try {
        SST_CustomerSANDBInsertTable -SST_InfoType "SANSFPStats" -SST_CollectedInformations $FOS_SFPHealthInfo
        if(-not [string]::IsNullOrWhiteSpace($TD_Exportpath)){
            $FOS_SFPHealthInfo | Export-Csv -Path "$($TD_Exportpath)\FOS_SFPHealthInfo_$($ChassisInfo.'vendor-serial-number')_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation -Append
        }
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SFPHealthInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
    }finally{
        Close-ProgressBar -ProgressBar $PB
    }

    return $FOS_SFPHealthInfo
}