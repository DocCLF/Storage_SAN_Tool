function Update-LiveChartsSeriesSelectorState {
    <#
    .SYNOPSIS
        Updates the selectable state of a LiveCharts series selector.

    .DESCRIPTION
        Ensures that only metrics from one UnitGroup can be selected
        at the same time.

        If no series is selected, all unit groups become available again.

        The function is independent of Storage, SAN, Tape or any
        specific data source.

    .PARAMETER SelectorModel
        Model created by New-LiveChartsSeriesSelectorModel.

    .OUTPUTS
        The updated selector model.
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

    $SelectedSeries = @(
        $SelectorModel.Series |
            Where-Object {
                $_.IsSelected -eq $true
            }
    )

    # ---------------------------------------------------------------------
    # No selected series
    #
    # All unit groups become available again.
    # ---------------------------------------------------------------------

    if ($SelectedSeries.Count -eq 0) {

        $SelectorModel.ActiveUnitGroup = $null

        foreach ($SeriesItem in $SelectorModel.Series) {
            $SeriesItem.IsEnabled = $true
        }

        return $SelectorModel
    }

    # ---------------------------------------------------------------------
    # Determine active unit group
    # ---------------------------------------------------------------------

    $ActiveUnitGroup =
        [string]$SelectedSeries[0].UnitGroup

    $SelectorModel.ActiveUnitGroup =
        $ActiveUnitGroup

    # ---------------------------------------------------------------------
    # Enable only compatible series
    # ---------------------------------------------------------------------

    foreach ($SeriesItem in $SelectorModel.Series) {

        $SeriesItem.IsEnabled = (
            [string]$SeriesItem.UnitGroup -eq
            $ActiveUnitGroup
        )
    }

    return $SelectorModel
}