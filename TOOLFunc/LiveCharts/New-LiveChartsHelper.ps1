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

    .PARAMETER MinStep
        Minimum step between labels as TimeSpan.

    .PARAMETER ForceStepToMin
        Forces LiveCharts to use the configured minimum step instead of
        automatically selecting a larger label interval.
    #>

    [CmdletBinding()]
    param (
        [string]$Name = 'Time',

        [string]$LabelFormat = 'HH:mm:ss',

        [TimeSpan]$MinStep = ([TimeSpan]::FromMinutes(1)),

        [bool]$ForceStepToMin = $true
    )

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    if ($MinStep -le [TimeSpan]::Zero) {
        throw 'MinStep must be greater than zero.'
    }

    $Axis = [LiveChartsCore.SkiaSharpView.Axis]::new()

    $Axis.Name = $Name

    # DateTimePoint stores the X-coordinate as DateTime.Ticks.
$Axis.Labeler = {
    param([double]$Value)

    # LiveCharts can request labels outside the currently valid
    # DateTime range while recalculating or animating an axis.
    if (
        [double]::IsNaN($Value) -or
        [double]::IsInfinity($Value)
    ) {
        return ''
    }

    $MinimumTicks =
        [double][datetime]::MinValue.Ticks

    $MaximumTicks =
        [double][datetime]::MaxValue.Ticks

    if (
        $Value -lt $MinimumTicks -or
        $Value -gt $MaximumTicks
    ) {
        return ''
    }

    try {
        $Ticks =
            [long][Math]::Round($Value)

        $Date =
            [datetime]::new($Ticks)

        return $Date.ToString(
            $LabelFormat,
            [System.Globalization.CultureInfo]::CurrentCulture
        )
    }
    catch {
        return ''
    }
}.GetNewClosure()
    # DateTimePoint uses DateTime ticks as the X coordinate.
    $Axis.MinStep = [double]$MinStep.Ticks

    # When enabled, LiveCharts uses the supplied step instead of
    # automatically increasing the label interval.
    $Axis.ForceStepToMin = $ForceStepToMin

    return $Axis
}

function ConvertTo-LiveChartsDisplayHistory {
    <#
    .SYNOPSIS
        Creates chart-ready history values for a selected metric.

    .DESCRIPTION
        Copies historical objects and optionally scales the selected metric
        and its reference metric according to MetricInfo.ValueDivisor.

        The original history objects are not modified.

    .PARAMETER History
        Historical source objects.

    .PARAMETER MetricInfo
        Metric metadata.

        Required:
            Metric

        Optional:
            ReferenceMetric
            ValueDivisor
            Precision

    .OUTPUTS
        PSCustomObject[]
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$History,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $MetricInfo
    )

    if (-not $MetricInfo.PSObject.Properties['Metric']) {
        throw "MetricInfo property 'Metric' is missing."
    }

    $Metric = [string]$MetricInfo.Metric

    $MetricsToConvert = @()

    if (
        $MetricInfo.PSObject.Properties['Metrics'] -and
        $null -ne $MetricInfo.Metrics
    ) {
        $MetricsToConvert = @(
            foreach ($MetricDefinition in @($MetricInfo.Metrics)) {

                if ($null -eq $MetricDefinition) {
                    continue
                }

                # Older/simple definitions may still contain strings.
                if ($MetricDefinition -is [string]) {
                    if (
                        -not [string]::IsNullOrWhiteSpace(
                            [string]$MetricDefinition
                        )
                    ) {
                        [string]$MetricDefinition
                    }

                    continue
                }

                # Full metric definitions expose the Metric property.
                if (
                    $MetricDefinition.PSObject.Properties['Metric'] -and
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$MetricDefinition.Metric
                    )
                ) {
                    [string]$MetricDefinition.Metric
                }
            }
        )
    }
    else {
        $MetricsToConvert = @(
            $Metric
        )
    }

    $ValueDivisor = [double]1

    if (
        $MetricInfo.PSObject.Properties['ValueDivisor'] -and
        $null -ne $MetricInfo.ValueDivisor
    ) {
        $ValueDivisor = [double]$MetricInfo.ValueDivisor
    }

    if ($ValueDivisor -eq 0) {
        throw 'MetricInfo.ValueDivisor must not be zero.'
    }

    $Precision = $null

    if (
        $MetricInfo.PSObject.Properties['Precision'] -and
        $null -ne $MetricInfo.Precision
    ) {
        $Precision = [int]$MetricInfo.Precision
    }

    $ReferenceMetric = $null

    if (
        $MetricInfo.PSObject.Properties['ReferenceMetric'] -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$MetricInfo.ReferenceMetric
        )
    ) {
        $ReferenceMetric = [string]$MetricInfo.ReferenceMetric
    }

    $Result = foreach ($HistoryItem in $History) {

        if ($null -eq $HistoryItem) {
            continue
        }

        # Create a copy so the source history remains unchanged.
        $Copy = [PSCustomObject]@{}

        foreach ($Property in $HistoryItem.PSObject.Properties) {
            $Copy |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name $Property.Name `
                    -Value $Property.Value
        }

        # Build the list of metrics that must be converted.
        #
        # Single metric:
        #   Metric
        #
        # Multi metric:
        #   Metrics[]
        #
        # Optional reference metric is added as well.
        $MetricNames = @(
            $MetricsToConvert

            if (
                -not [string]::IsNullOrWhiteSpace(
                    $ReferenceMetric
                )
            ) {
                $ReferenceMetric
            }
        ) | Select-Object -Unique

        foreach ($MetricName in $MetricNames) {

            if ([string]::IsNullOrWhiteSpace($MetricName)) {
                continue
            }

            $Property =
                $Copy.PSObject.Properties[$MetricName]

            if ($null -eq $Property) {
                continue
            }

            $RawValue =
                $Property.Value

            if (
                $null -eq $RawValue -or
                $RawValue -is [DBNull] -or
                [string]::IsNullOrWhiteSpace(
                    [string]$RawValue
                )
            ) {
                continue
            }

            try {
                $DisplayValue =
                    [double]$RawValue / $ValueDivisor

                if ($null -ne $Precision) {
                    $DisplayValue = [Math]::Round(
                        $DisplayValue,
                        $Precision
                    )
                }

                $Property.Value =
                    $DisplayValue
            }
            catch {
                throw (
                    "Metric '$MetricName' value '$RawValue' could not " +
                    "be converted to a chart display value."
                )
            }
        }

        $Copy
    }

    return $Result

}

function Import-WpfResourceDictionaries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $Target,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$Path
    )

    foreach ($ResourcePath in $Path) {

        if (-not (Test-Path -LiteralPath $ResourcePath -PathType Leaf)) {
            Write-Warning "ResourceDictionary not found: $ResourcePath"
            continue
        }

        $Stream = $null

        try {
            $Stream = [System.IO.File]::OpenRead(
                $ResourcePath
            )

            $Dictionary =
                [System.Windows.Markup.XamlReader]::Load(
                    $Stream
                )

            $Target.Resources.MergedDictionaries.Add(
                $Dictionary
            )
        }
        finally {
            if ($null -ne $Stream) {
                $Stream.Dispose()
            }
        }
    }
}
function Get-LiveChartsSelectedMetricDefinitions {
    <#
    .SYNOPSIS
        Returns all currently selected metric definitions.

    .DESCRIPTION
        Reads a selector model created by
        New-LiveChartsSeriesSelectorModel and returns the complete
        MetricInfo objects of all selected series.

        The function is independent of Storage, SAN or Tape.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SelectorModel
    )

    if (-not $SelectorModel.PSObject.Properties['Series']) {
        throw "SelectorModel property 'Series' is missing."
    }

    return @(
        $SelectorModel.Series |
            Where-Object {
                $_.IsSelected -eq $true
            } |
            ForEach-Object {
                $_.MetricInfo
            }
    )
}