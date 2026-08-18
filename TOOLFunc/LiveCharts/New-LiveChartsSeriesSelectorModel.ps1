function New-LiveChartsSeriesSelectorModel {
    <#
    .SYNOPSIS
        Creates a generic series selector model for LiveCharts.

    .DESCRIPTION
        Builds selectable series entries from metric definitions.

        An optional preset defines the initial selection.
        Metrics outside the preset remain available for later manual
        selection.

        The function is independent of Storage, SAN, Tape or any
        other specific data source.

    .PARAMETER MetricDefinitions
        Available metric definitions.

        Each definition must contain:

            Metric
            DisplayName
            Unit
            UnitGroup

    .PARAMETER Preset
        Optional preset defining:

            Metrics
            UnitGroup

        The preset only controls the initial selection.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$MetricDefinitions,

        [Parameter()]
        $Preset
    )

    if ($MetricDefinitions.Count -eq 0) {
        throw 'No metric definitions were supplied.'
    }

    $SelectedMetricNames = @()

    if (
        $null -ne $Preset -and
        $Preset.PSObject.Properties['Metrics']
    ) {
        $SelectedMetricNames = @(
            $Preset.Metrics |
                ForEach-Object {
                    [string]$_
                }
        )
    }

    $ActiveUnitGroup = $null

    if (
        $null -ne $Preset -and
        $Preset.PSObject.Properties['UnitGroup'] -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Preset.UnitGroup
        )
    ) {
        $ActiveUnitGroup =
            [string]$Preset.UnitGroup
    }

    $Series = @(
        foreach ($Definition in $MetricDefinitions) {

            if ($null -eq $Definition) {
                continue
            }

            foreach ($PropertyName in @(
                'Metric',
                'DisplayName',
                'Unit',
                'UnitGroup'
            )) {
                if (
                    -not $Definition.PSObject.Properties[
                        $PropertyName
                    ]
                ) {
                    throw (
                        "Metric definition does not contain " +
                        "property '$PropertyName'."
                    )
                }
            }

            $MetricName =
                [string]$Definition.Metric

            $UnitGroup =
                [string]$Definition.UnitGroup

            $IsSelected =
                $MetricName -in $SelectedMetricNames

            # When a preset is active, metrics from another unit group
            # cannot initially be combined with the selected series.
            $IsEnabled = $true

            if (
                -not [string]::IsNullOrWhiteSpace(
                    $ActiveUnitGroup
                ) -and
                $UnitGroup -ne $ActiveUnitGroup
            ) {
                $IsEnabled = $false
            }

            [PSCustomObject]@{
                MetricInfo   = $Definition

                Metric       = $MetricName
                DisplayName  = [string]$Definition.DisplayName
                Unit         = [string]$Definition.Unit
                UnitGroup    = $UnitGroup

                IsSelected   = $IsSelected
                IsEnabled    = $IsEnabled
            }
        }
    )

    [PSCustomObject]@{
        Series          = $Series
        ActiveUnitGroup = $ActiveUnitGroup
        Preset          = $Preset
    }
}