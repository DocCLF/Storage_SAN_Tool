function Get-BrocadePortBufferStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $RowCounter = 0
    )
    $PB = New-ProgressBar
    $FCPorts = Get-BrocadeFcPorts -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-FcPorts completed" -PercentComplete 20
    $FCStats = Get-BrocadeFCstatistics -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-FCstatistics completed" -PercentComplete 40
    <# only needed for the SN #>
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-ChassisInfo completed" -PercentComplete 60

    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}

    $FOS_PortBufferInfo = foreach($Port in $FCPorts){
        $StatsInfo = $FCStats | Where-Object {
            $_.name -eq $Port.name
        }
        $RowCounter++
        $RowID = "$($FCPorts.count)|$($Device.ID)|$RowCounter)"

        <# is required to display the other FIDs in the DG in a different color, for example #>
        $IsVirtualFabricPort = if($VFID -and $VFID -ne 128){ $true } else { $false }

        [PSCustomObject]@{
            IsVirtualFabricPort = $IsVirtualFabricPort
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
    Write-ProgressBar -ProgressBar $PB -Activity "Create Obj completed" -PercentComplete 80
    try {
        $FOS_PortBufferInfo | Export-Csv -Path "$($TD_TB_ExportPath.Text)\PortBufferShow_$($ChassisInfo.'vendor-serial-number')_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation -Append
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "PortBufferShow: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
    }finally{
        Close-ProgressBar -ProgressBar $PB
    }

    return $FOS_PortBufferInfo
}