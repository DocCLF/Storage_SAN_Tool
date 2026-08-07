function New-LiveChartsValueAxis {
    <#
    .SYNOPSIS
        Creates a numeric Y axis for LiveCharts.

    .PARAMETER Name
        Axis title, for example "Temperatur" or "RX-Leistung".

    .PARAMETER Unit
        Unit appended to the displayed values, for example "°C" or "µW".

    .PARAMETER Values
        Numeric values used to calculate a meaningful visible range.

    .PARAMETER PaddingPercent
        Additional space above and below the measured value range.

    .PARAMETER MinimumPadding
        Minimum absolute space above and below the values.

        This is especially important when all values are identical.
    #>

    [CmdletBinding()]
    param (
        [string]$Name,

        [string]$Unit,

        [Parameter(Mandatory)]
        [double[]]$Values,

        [ValidateRange(0, 100)]
        [double]$PaddingPercent = 10,

        [ValidateRange(0, [double]::MaxValue)]
        [double]$MinimumPadding = 1
    )

    if (-not (Initialize-LiveCharts)) {throw 'LiveCharts could not be initialized.'}
    if ($Values.Count -eq 0) {throw 'No numeric values were supplied for the Y axis.'}
    
    $ValidValues = @(
        $Values |
            Where-Object {
                $null -ne $_ -and
                -not [double]::IsNaN([double]$_) -and
                -not [double]::IsInfinity([double]$_)
            }
    )

    if ($ValidValues.Count -eq 0) {
        throw 'No valid numeric values were supplied for the Y axis.'
    }

    # Determine the minimum and maximum values in the data set.
    $Measurement = $ValidValues | Measure-Object -Minimum -Maximum

    $MinimumValue = [double]$Measurement.Minimum
    $MaximumValue = [double]$Measurement.Maximum

    $ValueRange = $MaximumValue - $MinimumValue

    if ($ValueRange -eq 0) {
        $Padding = $MinimumPadding
    }
    else {
        $PercentagePadding = $ValueRange * ($PaddingPercent / 100)

        $Padding = [Math]::Max(
            $PercentagePadding,
            $MinimumPadding
        )
    }

    $Axis = [LiveChartsCore.SkiaSharpView.Axis]::new()

    $Axis.Name     = $Name
    $Axis.MinLimit = $MinimumValue - $Padding
    $Axis.MaxLimit = $MaximumValue + $Padding

    if ([string]::IsNullOrWhiteSpace($Unit)) {
        $Axis.Labeler = {
            param($Value)

            return $Value.ToString(
                '0.##',
                [System.Globalization.CultureInfo]::CurrentCulture
            )
        }
    }
    else {
        $Axis.Labeler = {
            param($Value)

            return '{0} {1}' -f (
                $Value.ToString(
                    '0.##',
                    [System.Globalization.CultureInfo]::CurrentCulture
                )
            ), $Unit
        }.GetNewClosure()
    }

    return $Axis
}

function New-LiveChartsDateTimeAxis {
    <#
    .SYNOPSIS
        Creates a formatted DateTime X axis for LiveCharts.

    .PARAMETER LabelFormat
        .NET DateTime format used for axis labels.

        Examples:
            'HH:mm:ss'
            'dd.MM. HH:mm'
            'dd.MM.yyyy'

    .PARAMETER MinStep
        Minimum step between labels as TimeSpan.

        For example:
            [TimeSpan]::FromMinutes(1)
            [TimeSpan]::FromHours(1)
            [TimeSpan]::FromDays(1)
    #>

    [CmdletBinding()]
    param (
        [string]$Name = 'Time',

        [string]$LabelFormat = 'HH:mm:ss',

        [TimeSpan]$MinStep = ([TimeSpan]::FromMinutes(1))
    )

    if (-not (Initialize-LiveCharts)) {throw 'LiveCharts could not be initialized.'}
    if ($MinStep -le [TimeSpan]::Zero) {throw 'MinStep must be greater than zero.'}

    $Axis = [LiveChartsCore.SkiaSharpView.Axis]::new()

    $Axis.Name = $Name

    # DateTimePoint stores the X-coordinate as DateTime.Ticks.
    # That is why each axis value is converted back to DateTime here.
    $Axis.Labeler = {
        param([double]$Value)

        try {
            $Ticks = [long]$Value
            $Date  = [datetime]::new($Ticks)

            return $Date.ToString(
                $LabelFormat,
                [System.Globalization.CultureInfo]::CurrentCulture
            )
        }
        catch {
            return ''
        }
    }.GetNewClosure()

    # MinStep must also be specified in ticks for DateTimePoint.
    $Axis.MinStep = [double]$MinStep.Ticks

    # Do not force labels when space is limited.
    $Axis.ForceStepToMin = $false

    return $Axis
}