function Get-BrocadePortErrorStats {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $FCstatistics = Get-BrocadeFCstatistics -Device $Device

    foreach($FCstatistic in $FCstatistics){

        [PSCustomObject]@{
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
        }
    }
}