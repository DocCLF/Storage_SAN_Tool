function Update-StoragePoolHistoryViewer {
    <#
    .SYNOPSIS
        Updates the Storage pool history viewer.

    .DESCRIPTION
        Reads the selected pool, metric and time range from the supplied
        WPF controls, builds the corresponding Storage pool chart model
        and updates the Window DataContext.

        The function contains only viewer orchestration. Database access
        and chart creation remain in their corresponding helper functions.

    .PARAMETER Window
        WPF Window or UserControl whose DataContext should be updated.

    .PARAMETER CustomerNbr
        Customer number used to select the corresponding SQLite database.

    .PARAMETER PoolComboBox
        ComboBox containing the available Storage pools.

    .PARAMETER ComparisonCheckBox
        CheckBox used to enable or disable comparison mode.

    .PARAMETER ComparisonListBox
        ListBox containing the available comparison pools.

    .PARAMETER MetricComboBox
        ComboBox containing the available Storage pool metrics.

    .PARAMETER TimeRangeComboBox
        ComboBox containing the available history time ranges.

    .PARAMETER StatusTextBlock
        TextBlock used to display status and error messages.

    .PARAMETER RefreshButton
        Optional refresh button. It is disabled while the chart is updated.

    .OUTPUTS
        PSCustomObject

        Returns the created ChartData object when the update succeeds.
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
        $PoolComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ComparisonCheckBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ComparisonListBox,

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

    # SelectionChanged may fire while controls are still being initialized.
    if (
        $null -eq $MetricComboBox.SelectedItem -or
        $null -eq $TimeRangeComboBox.SelectedItem
    ) {
        return
    }

    $ComparisonEnabled =
        ($ComparisonCheckBox.IsChecked -eq $true)

    if (
        -not $ComparisonEnabled -and
        $null -eq $PoolComboBox.SelectedItem
    ) {
        return
    }

    if (
        $ComparisonEnabled -and
        $ComparisonListBox.SelectedItems.Count -lt 2
    ) {
        return
    }

    try {
        if ($null -ne $RefreshButton) {
            $RefreshButton.IsEnabled = $false
        }

        $StatusTextBlock.Text =
            'History wird geladen …'

        $SelectedMetric =
            $MetricComboBox.SelectedItem

        $SelectedTimeRange =
            $TimeRangeComboBox.SelectedItem

        # -------------------------------------------------------------
        # Validate selected objects
        # -------------------------------------------------------------

        foreach ($PropertyName in @(
            'Metric',
            'DisplayName'
        )) {
            if (
                -not $SelectedMetric.PSObject.Properties[
                    $PropertyName
                ]
            ) {
                throw (
                    "Selected metric property '$PropertyName' " +
                    'is missing.'
                )
            }
        }

        foreach ($PropertyName in @(
            'Duration',
            'LabelFormat',
            'DateTimeStep',
            'DisplayName'
        )) {
            if (
                -not $SelectedTimeRange.PSObject.Properties[
                    $PropertyName
                ]
            ) {
                throw (
                    "Selected time-range property '$PropertyName' " +
                    'is missing.'
                )
            }
        }

        $EndTime =
            Get-Date

        $StartTime =
            $EndTime.Subtract(
                [TimeSpan]$SelectedTimeRange.Duration
            )

        # -------------------------------------------------------------
        # Build chart
        # -------------------------------------------------------------

        if ($ComparisonEnabled) {

            $SelectedPools =
                @($ComparisonListBox.SelectedItems)

            $RequestedRowIDs = @(
                foreach ($Pool in $SelectedPools) {

                    if (
                        $null -eq $Pool -or
                        -not $Pool.PSObject.Properties['RowID']
                    ) {
                        continue
                    }

                    if (
                        -not [string]::IsNullOrWhiteSpace(
                            [string]$Pool.RowID
                        )
                    ) {
                        [string]$Pool.RowID
                    }
                }
            )

            if ($RequestedRowIDs.Count -lt 2) {
                throw (
                    'At least two valid Storage pools are required ' +
                    'for comparison mode.'
                )
            }

            $ChartData =
                Update-StoragePoolCapacityChart `
                    -CustomerNbr $CustomerNbr `
                    -RowIDs $RequestedRowIDs `
                    -Metric ([string]$SelectedMetric.Metric) `
                    -StartTime $StartTime `
                    -EndTime $EndTime `
                    -DateTimeLabelFormat (
                        [string]$SelectedTimeRange.LabelFormat
                    ) `
                    -DateTimeStep (
                        [TimeSpan]$SelectedTimeRange.DateTimeStep
                    )
        }
        else {
            $SelectedPool =
                $PoolComboBox.SelectedItem

            if (
                -not $SelectedPool.PSObject.Properties['RowID']
            ) {
                throw "Selected pool property 'RowID' is missing."
            }

            $ChartData =
                Update-StoragePoolCapacityChart `
                    -CustomerNbr $CustomerNbr `
                    -RowID ([string]$SelectedPool.RowID) `
                    -Metric ([string]$SelectedMetric.Metric) `
                    -StartTime $StartTime `
                    -EndTime $EndTime `
                    -DateTimeLabelFormat (
                        [string]$SelectedTimeRange.LabelFormat
                    ) `
                    -DateTimeStep (
                        [TimeSpan]$SelectedTimeRange.DateTimeStep
                    )
        }

        # -------------------------------------------------------------
        # Format statistic values for the GUI
        # -------------------------------------------------------------

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

        # -------------------------------------------------------------
        # Store selection information
        # -------------------------------------------------------------

        if ($ComparisonEnabled) {
            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name SelectedPools `
                    -Value @($ComparisonListBox.SelectedItems) `
                    -Force
        }
        else {
            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name SelectedPool `
                    -Value $PoolComboBox.SelectedItem `
                    -Force
        }

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

        # -------------------------------------------------------------
        # Update GUI
        # -------------------------------------------------------------

        $Window.DataContext =
            $ChartData

        if ($ComparisonEnabled) {
            $StatusTextBlock.Text = (
                '{0} Pools | {1} | {2} Messpunkte | ' +
                '{3:dd.MM.yyyy HH:mm:ss} bis ' +
                '{4:dd.MM.yyyy HH:mm:ss}' -f
                $ChartData.SourceCount,
                $SelectedMetric.DisplayName,
                $ChartData.PointCount,
                $StartTime,
                $EndTime
            )
        }
        else {
            $SelectedPool =
                $PoolComboBox.SelectedItem

            $StatusTextBlock.Text = (
                '{0} | {1} | {2} Messpunkte | ' +
                '{3:dd.MM.yyyy HH:mm:ss} bis ' +
                '{4:dd.MM.yyyy HH:mm:ss}' -f
                $SelectedPool.DisplayName,
                $SelectedMetric.DisplayName,
                $ChartData.PointCount,
                $StartTime,
                $EndTime
            )
        }

        return $ChartData
    }
    catch {
        $ErrorMessage =
            [string]$_.Exception.Message

        # -------------------------------------------------------------
        # No history in selected range is a normal viewer state
        # -------------------------------------------------------------

        if (
            $ErrorMessage -like
            'No Storage pool capacity history was found*'
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

        # -------------------------------------------------------------
        # Technical error
        # -------------------------------------------------------------

        $StatusTextBlock.Text =
            "Fehler: $ErrorMessage"

        Write-Host (
            "Storage Pool History Fehler: $ErrorMessage"
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