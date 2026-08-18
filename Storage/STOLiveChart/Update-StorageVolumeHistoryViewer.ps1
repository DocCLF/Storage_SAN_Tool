function Update-StorageVolumeHistoryViewer {
    <#
    .SYNOPSIS
        Updates the Storage volume analysis history viewer.

    .DESCRIPTION
        Reads the currently selected volume, metric and time range,
        builds the corresponding LiveCharts chart model and updates the
        viewer DataContext.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $Window,

        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $VolumeComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $MetricComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $TimeRangeComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $StatusTextBlock,

        [Parameter()]
        $RefreshButton
    )

    # SelectionChanged can fire while the controls are still initialized.
    if (
        $null -eq $VolumeComboBox.SelectedItem -or
        $null -eq $MetricComboBox.SelectedItem -or
        $null -eq $TimeRangeComboBox.SelectedItem
    ) {
        return
    }

    try {
        if ($null -ne $RefreshButton) {
            $RefreshButton.IsEnabled =
                $false
        }

        $StatusTextBlock.Text =
            'History wird geladen …'

        $SelectedVolume =
            $VolumeComboBox.SelectedItem

        $SelectedMetric =
            $MetricComboBox.SelectedItem

        $SelectedTimeRange =
            $TimeRangeComboBox.SelectedItem

        $EndTime =
            Get-Date

        $StartTime =
            $EndTime.Subtract(
                [TimeSpan]$SelectedTimeRange.Duration
            )

        $ChartData =
            Update-StorageVolumeAnalysisChart `
                -CustomerNbr $CustomerNbr `
                -RowID ([string]$SelectedVolume.RowID) `
                -Metric ([string]$SelectedMetric.Metric) `
                -StartTime $StartTime `
                -EndTime $EndTime `
                -DateTimeLabelFormat (
                    [string]$SelectedTimeRange.LabelFormat
                ) `
                -DateTimeStep (
                    [TimeSpan]$SelectedTimeRange.DateTimeStep
                )

        # -----------------------------------------------------------------
        # Format statistics
        # -----------------------------------------------------------------

        $Unit =
            [string]$ChartData.MetricInfo.Unit

        $Precision =
            [int]$ChartData.MetricInfo.Precision

        $NumberFormat = switch ($Precision) {
            0       { '0' }
            1       { '0.0' }
            2       { '0.00' }
            3       { '0.000' }
            default { '0.##' }
        }

        $FormatValue = {
            param (
                $Value
            )

            if (
                $null -eq $Value -or
                $Value -is [DBNull]
            ) {
                return '-'
            }

            $FormattedValue =
                ([double]$Value).ToString(
                    $NumberFormat,
                    [System.Globalization.CultureInfo]::CurrentCulture
                )

            if (
                [string]::IsNullOrWhiteSpace(
                    $Unit
                )
            ) {
                return $FormattedValue
            }

            return "$FormattedValue $Unit"
        }

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name CurrentValueText `
                -Value (
                    & $FormatValue $ChartData.CurrentValue
                ) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name MinimumValueText `
                -Value (
                    & $FormatValue $ChartData.MinimumValue
                ) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name MaximumValueText `
                -Value (
                    & $FormatValue $ChartData.MaximumValue
                ) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name AverageValueText `
                -Value (
                    & $FormatValue $ChartData.AverageValue
                ) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name PointCountText `
                -Value (
                    [string]$ChartData.PointCount
                ) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name SelectedVolume `
                -Value $SelectedVolume `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name SelectedMetric `
                -Value $SelectedMetric `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name SelectedTimeRange `
                -Value $SelectedTimeRange `
                -Force

        $Window.DataContext =
            $ChartData

        $StatusTextBlock.Text = (
            '{0} | {1} | {2} Messpunkte | ' +
            '{3:dd.MM.yyyy HH:mm:ss} bis ' +
            '{4:dd.MM.yyyy HH:mm:ss}' -f
            $SelectedVolume.DisplayName,
            $SelectedMetric.DisplayName,
            $ChartData.PointCount,
            $StartTime,
            $EndTime
        )

        return $ChartData
    }
    catch {
        $ErrorMessage =
            [string]$_.Exception.Message

        if (
            $ErrorMessage -like
            'No Storage volume analysis history was found*'
        ) {
            $EmptySeries =
                [System.Collections.Generic.List[
                    LiveChartsCore.ISeries
                ]]::new()

            $EmptyXAxes =
                [System.Collections.Generic.List[
                    LiveChartsCore.SkiaSharpView.Axis
                ]]::new()

            $EmptyYAxes =
                [System.Collections.Generic.List[
                    LiveChartsCore.SkiaSharpView.Axis
                ]]::new()

            $Window.DataContext = [PSCustomObject]@{
                Series           = $EmptySeries
                XAxes            = $EmptyXAxes
                YAxes            = $EmptyYAxes

                CurrentValueText = '-'
                MinimumValueText = '-'
                MaximumValueText = '-'
                AverageValueText = '-'
                PointCountText   = '0'
                PointCount       = 0
            }

            $StatusTextBlock.Text =
                'Für die aktuelle Auswahl liegen im gewählten ' +
                'Zeitraum keine Messwerte vor.'

            return
        }

        $StatusTextBlock.Text =
            "Fehler: $ErrorMessage"

        Write-Host (
            "Storage Volume History Fehler: $ErrorMessage"
        ) -ForegroundColor Red

        Write-Host ''

        Write-Host (
            "Fehlertyp: $($_.Exception.GetType().FullName)"
        ) -ForegroundColor Yellow

        Write-Host 'Position:' `
            -ForegroundColor Yellow

        Write-Host `
            $_.InvocationInfo.PositionMessage

        Write-Host ''

        Write-Host `
            $_.ScriptStackTrace `
            -ForegroundColor DarkGray
    }
    finally {
        if ($null -ne $RefreshButton) {
            $RefreshButton.IsEnabled =
                $true
        }
    }
}