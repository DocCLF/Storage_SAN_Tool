function Get-BrocadePortBufferStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $RowCounter = 0
    )

    $FCPorts = Get-BrocadeFcPorts -Device $Device
    $FCStats = Get-BrocadeFCstatistics -Device $Device

    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}

    foreach($Port in $FCPorts){
        $StatsInfo = $FCStats | Where-Object {
            $_.name -eq $Port.name
        }
        $RowCounter++
        $RowID = "$($FCPorts.count)|$($Device.ID)|$RowCounter)"
        [PSCustomObject]@{
            VFID = $VFID 
            VFIDDisplay = $VFIDDisplay
            Port = $Port.name
            PortType = $Port.'port-type-string'
            State = $Port.'operational-status-string'
            Speed = $Port.'protocol-speed'
            ReservedBuffers = $Port.'reserved-buffers'
            CurrentBufferUsage = $Port.'current-buffer-usage'
            RecommendedBuffers = $Port.'recommended-buffers'
            AvgTxBufferUsage = $Port.'average-transmit-buffer-usage'
            AvgRxBufferUsage = $Port.'average-receive-buffer-usage'
            AvgTxFrameSize = $Port.'average-transmit-frame-size'
            AvgRxFrameSize = $Port.'average-receive-frame-size'
            ChipBuffersAvailable = $Port.'chip-buffers-available'
            CreditRecoveryEnabled = $Port.'credit-recovery-enabled-v2'
            CreditRecoveryActive = $Port.'credit-recovery-active-v2'
            CongestionSignalEnabled = $Port.'congestion-signal-enabled'
            FportBuffers = $Port.'f-port-buffers'
            BBzero = $StatsInfo.'bb-credit-zero'
            RowID = $RowID
        }
    }
}