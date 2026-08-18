function New-LiveChartsSourceSelectorModel {
    <#
    .SYNOPSIS
        Creates a generic source selector model for LiveCharts.

    .DESCRIPTION
        Builds selectable source entries from arbitrary source objects.

        The function is independent of Storage, SAN, Tape or any
        specific data source.

        Each source must provide a stable key and a display name.
        An optional source group can be used to group sources by
        Storage system or another higher-level origin.

    .PARAMETER Sources
        Source objects used to build the selector.

    .PARAMETER KeyProperty
        Name of the property that uniquely identifies a source.

        Example:
            RowID

    .PARAMETER DisplayNameProperty
        Name of the property used for display.

        Example:
            DisplayName

    .PARAMETER GroupProperty
        Optional property used to identify the higher-level source group.

        Example:
            SerialNumber

    .PARAMETER SelectedKeys
        Optional list of source keys that should initially be selected.

        If no key is supplied, the first available source is selected.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$Sources,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyProperty,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayNameProperty,

        [Parameter()]
        [string]$GroupProperty,

        [Parameter()]
        [string[]]$SelectedKeys
    )

    if ($Sources.Count -eq 0) {
        throw 'No source objects were supplied.'
    }

    # ---------------------------------------------------------------------
    # Normalize initial selection
    # ---------------------------------------------------------------------

    $RequestedSelectedKeys = @(
        $SelectedKeys |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace(
                    [string]$_
                )
            } |
            ForEach-Object {
                [string]$_
            } |
            Select-Object -Unique
    )

    # ---------------------------------------------------------------------
    # Build selector entries
    # ---------------------------------------------------------------------

    $SourceItems = @(
        foreach ($Source in $Sources) {

            if ($null -eq $Source) {
                continue
            }

            $KeyPropertyInfo =
                $Source.PSObject.Properties[
                    $KeyProperty
                ]

            if ($null -eq $KeyPropertyInfo) {
                throw (
                    "Source object does not contain key property " +
                    "'$KeyProperty'."
                )
            }

            $DisplayPropertyInfo =
                $Source.PSObject.Properties[
                    $DisplayNameProperty
                ]

            if ($null -eq $DisplayPropertyInfo) {
                throw (
                    "Source object does not contain display property " +
                    "'$DisplayNameProperty'."
                )
            }

            $SourceKey =
                [string]$KeyPropertyInfo.Value

            if (
                [string]::IsNullOrWhiteSpace(
                    $SourceKey
                )
            ) {
                throw (
                    "Source key property '$KeyProperty' contains " +
                    'an empty value.'
                )
            }

            $DisplayName =
                [string]$DisplayPropertyInfo.Value

            if (
                [string]::IsNullOrWhiteSpace(
                    $DisplayName
                )
            ) {
                $DisplayName =
                    $SourceKey
            }

            $SourceGroup = $null

            if (
                -not [string]::IsNullOrWhiteSpace(
                    $GroupProperty
                )
            ) {
                $GroupPropertyInfo =
                    $Source.PSObject.Properties[
                        $GroupProperty
                    ]

                if ($null -ne $GroupPropertyInfo) {
                    $SourceGroup =
                        [string]$GroupPropertyInfo.Value
                }
            }

            [PSCustomObject]@{
                SourceKey   = $SourceKey
                DisplayName = $DisplayName
                SourceGroup = $SourceGroup

                IsSelected  = (
                    $SourceKey -in
                    $RequestedSelectedKeys
                )

                IsEnabled   = $true

                # Keep the original source object.
                Source      = $Source
            }
        }
    )

    if ($SourceItems.Count -eq 0) {
        throw 'No usable source objects were found.'
    }

    # ---------------------------------------------------------------------
    # Default selection
    #
    # If nothing was explicitly selected, select the first source.
    # ---------------------------------------------------------------------

    $SelectedSources = @(
        $SourceItems |
            Where-Object {
                $_.IsSelected -eq $true
            }
    )

    if ($SelectedSources.Count -eq 0) {
        $SourceItems[0].IsSelected =
            $true
    }

    # ---------------------------------------------------------------------
    # Build common selector model
    # ---------------------------------------------------------------------

    return [PSCustomObject]@{
        Sources     = $SourceItems
        SourceCount = $SourceItems.Count
    }
}
function Get-LiveChartsSelectedSources {
    <#
    .SYNOPSIS
        Returns all currently selected source definitions.

    .DESCRIPTION
        Reads a source selector model created by
        New-LiveChartsSourceSelectorModel.

        The original source objects are returned.

    .OUTPUTS
        Object[]
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SelectorModel
    )

    if (
        -not $SelectorModel.PSObject.Properties[
            'Sources'
        ]
    ) {
        throw (
            "SelectorModel property 'Sources' is missing."
        )
    }

    return @(
        $SelectorModel.Sources |
            Where-Object {
                $_.IsSelected -eq $true
            } |
            ForEach-Object {
                $_.Source
            }
    )
}

function Get-LiveChartsSourceGroups {
    <#
    .SYNOPSIS
        Returns the unique source groups of a LiveCharts source selector.

    .DESCRIPTION
        Creates one group object for every unique SourceGroup contained
        in a SourceSelectorModel.

        The function is independent of Storage, SAN, Tape or any
        specific source type.

        The first available group is selected by default.

    .OUTPUTS
        PSCustomObject[]
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SelectorModel
    )

    if (
        -not $SelectorModel.PSObject.Properties[
            'Sources'
        ]
    ) {
        throw "SelectorModel property 'Sources' is missing."
    }

    $GroupNames = @(
        $SelectorModel.Sources |
            ForEach-Object {
                [string]$_.SourceGroup
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Select-Object -Unique
    )

    $Groups = @(
        for ($i = 0; $i -lt $GroupNames.Count; $i++) {

            $GroupName =
                [string]$GroupNames[$i]

            $SourceCount = @(
                $SelectorModel.Sources |
                    Where-Object {
                        [string]$_.SourceGroup -eq
                        $GroupName
                    }
            ).Count

            [PSCustomObject]@{
                GroupKey    = $GroupName
                DisplayName = $GroupName
                SourceCount = $SourceCount
                IsSelected  = ($i -eq 0)
            }
        }
    )

    return $Groups
}

function Set-LiveChartsSourceGroup {
    <#
    .SYNOPSIS
        Activates one source group in a LiveCharts source selector.

    .DESCRIPTION
        Enables sources belonging to the selected group and disables
        all sources belonging to other groups.

        Sources outside the active group are automatically deselected.

        If the active group contains no selected source, its first
        available source is selected automatically.

    .OUTPUTS
        The updated selector model.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SelectorModel,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupKey
    )

    if (
        -not $SelectorModel.PSObject.Properties[
            'Sources'
        ]
    ) {
        throw "SelectorModel property 'Sources' is missing."
    }

    $MatchingSources = @(
        $SelectorModel.Sources |
            Where-Object {
                [string]$_.SourceGroup -eq
                $GroupKey
            }
    )

    if ($MatchingSources.Count -eq 0) {
        throw "Unknown source group '$GroupKey'."
    }

    foreach ($SourceItem in $SelectorModel.Sources) {

        $IsActiveGroup = (
            [string]$SourceItem.SourceGroup -eq
            $GroupKey
        )

        $SourceItem.IsEnabled =
            $IsActiveGroup

        # A source from another Storage system must no longer
        # participate in the current chart.
        if (-not $IsActiveGroup) {
            $SourceItem.IsSelected =
                $false
        }
    }

    # Make sure at least one source of the active group remains selected.
    $SelectedSources = @(
        $MatchingSources |
            Where-Object {
                $_.IsSelected -eq $true
            }
    )

    if ($SelectedSources.Count -eq 0) {
        $MatchingSources[0].IsSelected =
            $true
    }

    if (
        $SelectorModel.PSObject.Properties[
            'ActiveSourceGroup'
        ]
    ) {
        $SelectorModel.ActiveSourceGroup =
            $GroupKey
    }
    else {
        $SelectorModel |
            Add-Member `
                -MemberType NoteProperty `
                -Name ActiveSourceGroup `
                -Value $GroupKey
    }

    return $SelectorModel
}
function New-LiveChartsMultiSourceMultiMetricSeriesCollection {
    <#
    .SYNOPSIS
        Creates LiveCharts series for multiple sources and multiple metrics.

    .DESCRIPTION
        Builds exactly one line series for every combination of
        source and metric.

        Example:

            2 sources x 3 metrics = 6 series

        Reference metrics are intentionally not generated in this mode.

        This keeps the number of displayed lines predictable:

            Number of Sources x Number of Metrics

        Reference series remain available for the normal
        single-source / single-metric view.

        The function is independent of Storage, SAN, Tape or any
        specific data source.

    .PARAMETER SeriesDefinitions
        Prepared source definitions.

        Each definition must contain:

            Name
            History

    .PARAMETER MetricDefinitions
        Metric definitions used for each source.

        Each definition must contain at least:

            Metric
            DisplayName

        Optional properties:

            Color
            GeometrySize
            LineSmoothness
            ShowArea

    .PARAMETER MaximumSeries
        Maximum allowed total number of generated series.

    .OUTPUTS
        Generic List[LiveChartsCore.ISeries]
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$SeriesDefinitions,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$MetricDefinitions,

        [ValidateRange(1, 100)]
        [int]$MaximumSeries = 12
    )

    # ---------------------------------------------------------------------
    # Initialize LiveCharts
    # ---------------------------------------------------------------------

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    # ---------------------------------------------------------------------
    # Validate input
    # ---------------------------------------------------------------------

    if ($SeriesDefinitions.Count -eq 0) {
        throw 'No source series definitions were supplied.'
    }

    if ($MetricDefinitions.Count -eq 0) {
        throw 'No metric definitions were supplied.'
    }

    # ---------------------------------------------------------------------
    # Validate resulting number of series
    #
    # Exactly one series is created for every Source x Metric combination.
    # Reference metrics are intentionally excluded.
    # ---------------------------------------------------------------------

    $ExpectedSeriesCount =
        $SeriesDefinitions.Count *
        $MetricDefinitions.Count

    if ($ExpectedSeriesCount -gt $MaximumSeries) {
        throw (
            "The selected sources and metrics would create " +
            "$ExpectedSeriesCount series. Maximum allowed: " +
            "$MaximumSeries."
        )
    }

    # ---------------------------------------------------------------------
    # Result collection
    # ---------------------------------------------------------------------

    $Result =
        [System.Collections.Generic.List[
            LiveChartsCore.ISeries
        ]]::new()

    # ---------------------------------------------------------------------
    # Create one series per Source x Metric
    # ---------------------------------------------------------------------

    foreach ($SourceDefinition in $SeriesDefinitions) {

        if ($null -eq $SourceDefinition) {
            continue
        }

        if (
            -not $SourceDefinition.PSObject.Properties['History'] -or
            $null -eq $SourceDefinition.History
        ) {
            continue
        }

        # -----------------------------------------------------------------
        # Resolve source name
        # -----------------------------------------------------------------

        if (
            $SourceDefinition.PSObject.Properties['Name'] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$SourceDefinition.Name
            )
        ) {
            $SourceName =
                [string]$SourceDefinition.Name
        }
        else {
            $SourceName =
                'Source'
        }

        # -----------------------------------------------------------------
        # Resolve source history
        # -----------------------------------------------------------------

        $SourceHistory =
            @($SourceDefinition.History)

        if ($SourceHistory.Count -eq 0) {
            continue
        }

        # -----------------------------------------------------------------
        # Build one line for every selected metric
        # -----------------------------------------------------------------

        foreach ($MetricDefinition in $MetricDefinitions) {

            if ($null -eq $MetricDefinition) {
                continue
            }

            if (
                -not $MetricDefinition.PSObject.Properties[
                    'Metric'
                ]
            ) {
                continue
            }

            $MetricName =
                [string]$MetricDefinition.Metric

            if (
                [string]::IsNullOrWhiteSpace(
                    $MetricName
                )
            ) {
                continue
            }

            # -------------------------------------------------------------
            # Resolve readable metric name
            # -------------------------------------------------------------

            if (
                $MetricDefinition.PSObject.Properties[
                    'DisplayName'
                ] -and
                -not [string]::IsNullOrWhiteSpace(
                    [string]$MetricDefinition.DisplayName
                )
            ) {
                $MetricDisplayName =
                    [string]$MetricDefinition.DisplayName
            }
            else {
                $MetricDisplayName =
                    $MetricName
            }

            # -------------------------------------------------------------
            # Series defaults
            # -------------------------------------------------------------

            $LineSmoothness =
                [double]0

            $GeometrySize =
                [double]6

            $ShowArea =
                $false

            $Color =
                $null

            # -------------------------------------------------------------
            # Optional LineSmoothness
            # -------------------------------------------------------------

            if (
                $MetricDefinition.PSObject.Properties[
                    'LineSmoothness'
                ] -and
                $null -ne $MetricDefinition.LineSmoothness
            ) {
                $LineSmoothness =
                    [double]$MetricDefinition.LineSmoothness
            }

            # -------------------------------------------------------------
            # Optional GeometrySize
            # -------------------------------------------------------------

            if (
                $MetricDefinition.PSObject.Properties[
                    'GeometrySize'
                ] -and
                $null -ne $MetricDefinition.GeometrySize
            ) {
                $GeometrySize =
                    [double]$MetricDefinition.GeometrySize
            }

            # -------------------------------------------------------------
            # Optional ShowArea
            # -------------------------------------------------------------

            if (
                $MetricDefinition.PSObject.Properties[
                    'ShowArea'
                ] -and
                $null -ne $MetricDefinition.ShowArea
            ) {
                $ShowArea =
                    [bool]$MetricDefinition.ShowArea
            }

            # -------------------------------------------------------------
            # Optional Color
            # -------------------------------------------------------------

            if (
                $MetricDefinition.PSObject.Properties[
                    'Color'
                ] -and
                -not [string]::IsNullOrWhiteSpace(
                    [string]$MetricDefinition.Color
                )
            ) {
                $Color =
                    [string]$MetricDefinition.Color
            }

            # -------------------------------------------------------------
            # Unique legend name
            #
            # Example:
            #
            #   Node1 P1 – TX Power
            #   Node1 P1 – RX Power
            #   Node1 P2 – TX Power
            #   Node1 P2 – RX Power
            # -------------------------------------------------------------

            $SeriesName =
                '{0} – {1}' -f
                    $SourceName,
                    $MetricDisplayName

            # -------------------------------------------------------------
            # Build exactly ONE line series.
            #
            # Important:
            #
            # Do not use New-LiveChartsSeriesCollection here because that
            # function may additionally create ReferenceMetric series.
            #
            # MultiSource + MultiMetric must remain predictable:
            #
            #     Sources x Metrics = Number of Series
            # -------------------------------------------------------------

            $SeriesParameters = @{
                History        = $SourceHistory
                Metric         = $MetricName
                SeriesName     = $SeriesName
                LineSmoothness = $LineSmoothness
                GeometrySize   = $GeometrySize
                ShowArea       = $ShowArea
            }

            if (
                -not [string]::IsNullOrWhiteSpace(
                    $Color
                )
            ) {
                $SeriesParameters.Color =
                    $Color
            }

            $Series =
                New-LiveChartsLineSeries `
                    @SeriesParameters

            if ($null -eq $Series) {
                throw (
                    "Series for Source '$SourceName' and metric " +
                    "'$MetricName' could not be created."
                )
            }

            # -------------------------------------------------------------
            # Add exactly once
            # -------------------------------------------------------------

            $Result.Add(
                $Series
            )
        }
    }

    # ---------------------------------------------------------------------
    # Validate result
    # ---------------------------------------------------------------------

    if ($Result.Count -eq 0) {
        throw (
            'No usable multi-source multi-metric series ' +
            'could be created.'
        )
    }

    # ---------------------------------------------------------------------
    # Return typed collection without PowerShell enumeration
    # ---------------------------------------------------------------------

    Write-Output -NoEnumerate $Result
}
function New-LiveChartsSourceGroupSelectorModel {
    <#
    .SYNOPSIS
        Creates a generic source group selector model.

    .DESCRIPTION
        Builds selectable source-group entries from a SourceSelectorModel.

        Source groups can represent higher-level systems such as
        Storage arrays, SAN switches or other logical origins.

        All groups are selected by default because this selector acts
        as a filter, not as the actual chart source selection.

    .PARAMETER SourceSelectorModel
        Model created by New-LiveChartsSourceSelectorModel.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SourceSelectorModel
    )

    if (
        -not $SourceSelectorModel.PSObject.Properties['Sources']
    ) {
        throw "SourceSelectorModel property 'Sources' is missing."
    }

    $Groups = @(
        Get-LiveChartsSourceGroups `
            -SelectorModel $SourceSelectorModel
    )

    if ($Groups.Count -eq 0) {
        throw 'No source groups were found.'
    }

    $GroupItems = @(
        foreach ($Group in $Groups) {

            [PSCustomObject]@{
                GroupKey    = [string]$Group.GroupKey
                DisplayName = [string]$Group.DisplayName
                SourceCount = [int]$Group.SourceCount

                # Filter semantics:
                # all groups are visible by default.
                IsSelected  = $true
                IsEnabled   = $true
            }
        }
    )

    return [PSCustomObject]@{
        Groups     = $GroupItems
        GroupCount = $GroupItems.Count
    }
}
function Get-LiveChartsFilteredSources {
    <#
    .SYNOPSIS
        Returns all sources allowed by the current group filter.

    .DESCRIPTION
        Combines a SourceSelectorModel with a SourceGroupSelectorModel.

        Only sources whose SourceGroup is currently selected in the
        group selector are returned.

        The original source selector entries are returned so their
        IsSelected state is preserved.

    .OUTPUTS
        PSCustomObject[]
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SourceSelectorModel,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $GroupSelectorModel
    )

    $SelectedGroupKeys = @(
        $GroupSelectorModel.Groups |
            Where-Object {
                $_.IsSelected -eq $true
            } |
            ForEach-Object {
                [string]$_.GroupKey
            }
    )

    if ($SelectedGroupKeys.Count -eq 0) {
        return @()
    }

    return @(
        $SourceSelectorModel.Sources |
            Where-Object {
                [string]$_.SourceGroup -in
                $SelectedGroupKeys
            }
    )
}