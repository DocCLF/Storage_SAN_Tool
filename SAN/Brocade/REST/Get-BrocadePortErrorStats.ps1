function Get-BrocadePortErrorStats {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $RowCounter = 0
    )

    $FCstatistics = Get-BrocadeFCstatistics -Device $Device
    <# only needed for the SN #>
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device

    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}

    $FOS_PortErrorInfo = foreach($FCstatistic in $FCstatistics){
        $RowCounter++
        $RowID = "$($FCPorts.count)|$($Device.ID)|$RowCounter)"

        <# is required to display the other FIDs in the DG in a different color, for example #>
        $IsVirtualFabricPort = if($VFID -and $VFID -ne 128){ $true } else { $false }

        [PSCustomObject]@{
            IsVirtualFabricPort = $IsVirtualFabricPort
            VFID = $VFID 
            VFIDDisplay = $VFIDDisplay
            Port = $FCstatistic.name
            EncIn = $FCstatistic.'encoding-error-in'
            CrcErr = $FCstatistic.'crc-errors'
            TooShort = $FCstatistic.'truncated-frames'
            TooLong = $FCstatistic.'frames-too-long'
            BadEOF = $FCstatistic.'bad-eofs-received'
            EncOut = $FCstatistic.'encoding-errors-outside-frame'
            DiscC3 = $FCstatistic.'class-3-discards'
            LinkFail = $FCstatistic.'link-failures'
            LossSync = $FCstatistic.'loss-of-sync'
            LossSig = $FCstatistic.'loss-of-signal'
            StateTransitions = $FCstatistic.'state-transition-count'
            BBZero = $FCstatistic.'bb-credit-zero'
            FECuncorrected = $FCstatistic.'fec-uncorrected'
            RowID = $RowID
        }
    }
    try {
        $FOS_PortErrorInfo | Export-Csv -Path $($TD_TB_ExportPath.Text)\FOS_PortErrorInfo_$($ChassisInfo.'vendor-serial-number')_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortErrorInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
    }

    return $FOS_PortErrorInfo
}