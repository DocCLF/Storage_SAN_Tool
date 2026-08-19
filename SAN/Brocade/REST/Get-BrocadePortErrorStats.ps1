function Get-BrocadePortErrorStats {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $TD_Exportpath = $null
    )
    $PB = New-ProgressBar

    $FCstatistics = Get-BrocadeFCstatistics -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-FCstatistics completed" -PercentComplete 20
    $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeSwitchInfo completed" -PercentComplete 33
    <# only needed for the SN #>
    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-ChassisInfo completed" -PercentComplete 50

    $VFID = if($Device.VFID){$Device.VFID}else{""}
    $VFIDDisplay = if($VFID){ $VFID }else{""}
    $ChassisSN = $($ChassisInfo.'vendor-serial-number')
    $SwitchName = $SwitchInfo.'user-friendly-name'
    if ([string]::IsNullOrWhiteSpace($SwitchName)) {
        $SwitchName = "Unknown_$($ChassisInfo.'vendor-serial-number')"
    }
    $SwitchWWNN = $SwitchInfo.name

    $FOS_PortErrorInfo = foreach($FCstatistic in $FCstatistics){

        $VFIDKey = if ($VFID) {[string]$VFID}else {'BASE'}
        # Skip invalid FC statistic entries without a usable port name.
        # Without a port number no unique SAN port RowID can be created.
        if ([string]::IsNullOrWhiteSpace($Port)) {
            SST_ToolMessageCollector -TD_ToolMSGCollector ("Get-BrocadePortErrorStats: FC statistic entry without " + "a valid port name was skipped on switch '$SwitchName' " + "($ChassisSN).") -TD_ToolMSGType "Debug" -TD_Shown "no"
            continue
        }
        $Port = [string]$FCstatistic.name

        $RowID = '{0}|{1}|{2}' -f $ChassisSN,$VFIDKey,$Port
        [string]::IsNullOrWhiteSpace
        <# is required to display the other FIDs in the DG in a different color, for example #>
        $IsVirtualFabricPort = if($VFID -and $VFID -ne 128){ $true } else { $false }

        [PSCustomObject]@{
            IsVirtualFabricPort = $IsVirtualFabricPort
            VFID = $VFID 
            VFIDDisplay = $VFIDDisplay
            Port = $Port
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
            SwitchName   = $SwitchName
            SerialNumber = $ChassisSN
            SwitchWWNN   = $SwitchWWNN
        }
    }
    Write-ProgressBar -ProgressBar $PB -Activity "Create Obj completed" -PercentComplete 75
    try {
        SST_CustomerSANDBInsertTable -SST_InfoType "SANPortErrStats" -SST_CollectedInformations $FOS_PortErrorInfo
        if(-not [string]::IsNullOrWhiteSpace($TD_Exportpath)){
            $FOS_PortErrorInfo | Export-Csv -Path "$($TD_Exportpath)\FOS_PortErrorInfo_$($ChassisInfo.'vendor-serial-number')_$(Get-Date -Format "yyyy-MM-dd").csv" -NoTypeInformation -Append
        }
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortErrorInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
    }finally{
        Close-ProgressBar -ProgressBar $PB
    }

    return $FOS_PortErrorInfo
}