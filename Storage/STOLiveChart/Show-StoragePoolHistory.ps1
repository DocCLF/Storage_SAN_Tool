function Show-StoragePoolHistory {
    <#
    .SYNOPSIS
        Opens a Storage pool capacity history viewer.

    .DESCRIPTION
        Opens the shared LiveCharts history viewer for Storage pools.

        The viewer uses the generic selector architecture:

            Storage System
                -> Storage Pool
                    -> Metric / Series

        Multiple pools and multiple compatible metrics may be displayed
        simultaneously.

        CapacityOverview remains available as a Quick-Preset.

        The shared history viewer XAML is provided by
        Get-LiveChartsHistoryViewXaml.

    .PARAMETER CustomerNbr
        Customer number whose SQLite database should be used.

    .EXAMPLE
        Show-StoragePoolHistory -CustomerNbr '123456'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr
    )

    # ---------------------------------------------------------------------
    # Initialize LiveCharts
    # ---------------------------------------------------------------------

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    # ---------------------------------------------------------------------
    # Load required WPF assemblies
    # ---------------------------------------------------------------------

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # ---------------------------------------------------------------------
    # Load shared History Viewer XAML
    # ---------------------------------------------------------------------

    $Xaml =
        Get-LiveChartsHistoryViewXaml `
            -WindowTitle 'Storage Pool Capacity History' `
            -SourceLabel 'Storage-Pool'

    $XmlReader =
        [System.Xml.XmlReader]::Create(
            (
                New-Object System.IO.StringReader(
                    $Xaml
                )
            )
        )

    try {

        $Window =
            [System.Windows.Markup.XamlReader]::Load(
                $XmlReader
            )
    }
    finally {

        if ($null -ne $XmlReader) {
            $XmlReader.Dispose()
        }
    }

    # ---------------------------------------------------------------------
    # Load application styles
    # ---------------------------------------------------------------------

    $StyleFiles = @(
        (
            Join-Path `
                $PSRootPath `
                'Resources\Styles\ColorStyle.xaml'
        ),
        (
            Join-Path `
                $PSRootPath `
                'Resources\Styles\OtherControlStyle.xaml'
        ),
        (
            Join-Path `
                $PSRootPath `
                'Resources\Styles\TextBoxStyle.xaml'
        ),
        (
            Join-Path `
                $PSRootPath `
                'Resources\Styles\ButtonStyle.xaml'
        )
    )

    Import-WpfResourceDictionaries `
        -Target $Window `
        -Path $StyleFiles

    # ---------------------------------------------------------------------
    # Resolve legacy controls
    #
    # These controls still exist in the shared XAML but are hidden by
    # Initialize-StoragePoolHistoryView.
    # ---------------------------------------------------------------------

    $CB_Source =
        $Window.FindName(
            'CB_Source'
        )

    $CHK_ComparisonMode =
        $Window.FindName(
            'CHK_ComparisonMode'
        )

    $LB_ComparisonSources =
        $Window.FindName(
            'LB_ComparisonSources'
        )

    # ---------------------------------------------------------------------
    # Resolve generic selector controls
    # ---------------------------------------------------------------------

    # Storage Systems
    $SP_SourceGroupSelector =
        $Window.FindName(
            'SP_SourceGroupSelector'
        )

    $LB_SourceGroupSelector =
        $Window.FindName(
            'LB_SourceGroupSelector'
        )

    # Storage Pools
    $LB_SourceSelector =
        $Window.FindName(
            'LB_SourceSelector'
        )

    # Metrics / Series
    $LB_SeriesSelector =
        $Window.FindName(
            'LB_SeriesSelector'
        )

    # ---------------------------------------------------------------------
    # Resolve common viewer controls
    # ---------------------------------------------------------------------

    $CB_Metric =
        $Window.FindName(
            'CB_Metric'
        )

    $CB_TimeRange =
        $Window.FindName(
            'CB_TimeRange'
        )

    $BTN_Refresh =
        $Window.FindName(
            'BTN_Refresh'
        )

    $TB_Status =
        $Window.FindName(
            'TB_Status'
        )

    $Chart =
        $Window.FindName(
            'Chart'
        )

    # ---------------------------------------------------------------------
    # Validate required controls
    #
    # This catches mismatches between the shared XAML and the Pool viewer
    # immediately instead of failing later during initialization.
    # ---------------------------------------------------------------------

    $RequiredControls = @{

        # Legacy controls
        CB_Source =
            $CB_Source

        CHK_ComparisonMode =
            $CHK_ComparisonMode

        LB_ComparisonSources =
            $LB_ComparisonSources

        # Generic selectors
        SP_SourceGroupSelector =
            $SP_SourceGroupSelector

        LB_SourceGroupSelector =
            $LB_SourceGroupSelector

        LB_SourceSelector =
            $LB_SourceSelector

        LB_SeriesSelector =
            $LB_SeriesSelector

        # Common controls
        CB_Metric =
            $CB_Metric

        CB_TimeRange =
            $CB_TimeRange

        BTN_Refresh =
            $BTN_Refresh

        TB_Status =
            $TB_Status

        Chart =
            $Chart
    }

    foreach ($ControlName in $RequiredControls.Keys) {

        if (
            $null -eq
            $RequiredControls[$ControlName]
        ) {

            throw (
                "Required control '$ControlName' " +
                'was not found in XAML.'
            )
        }
    }

    # ---------------------------------------------------------------------
    # Initialize Pool viewer
    #
    # Mapping between generic initializer parameters and actual XAML:
    #
    #   GroupSelectorPanel
    #       -> SP_SourceGroupSelector
    #
    #   GroupSelectorListBox
    #       -> LB_SourceGroupSelector
    #
    #   SourceSelectorListBox
    #       -> LB_SourceSelector
    #
    #   SeriesSelectorListBox
    #       -> LB_SeriesSelector
    # ---------------------------------------------------------------------

    $Initialized =
        Initialize-StoragePoolHistoryView `
            -CustomerNbr $CustomerNbr `
            -ViewRoot $Window `
            -PoolComboBox $CB_Source `
            -ComparisonCheckBox $CHK_ComparisonMode `
            -ComparisonListBox $LB_ComparisonSources `
            -SourceSelectorListBox $LB_SourceSelector `
            -SeriesSelectorListBox $LB_SeriesSelector `
            -GroupSelectorListBox $LB_SourceGroupSelector `
            -GroupSelectorPanel $SP_SourceGroupSelector `
            -MetricComboBox $CB_Metric `
            -TimeRangeComboBox $CB_TimeRange `
            -StatusTextBlock $TB_Status `
            -RefreshButton $BTN_Refresh

    if (-not $Initialized) {
        return
    }

    # ---------------------------------------------------------------------
    # Show viewer
    # ---------------------------------------------------------------------

    try {

        $Window.ShowDialog() |
            Out-Null
    }
    catch {

        Write-Host (
            'Storage Pool History ShowDialog Fehler: ' +
            $_.Exception.Message
        ) -ForegroundColor Red

        Write-Host `
            $_.InvocationInfo.PositionMessage

        Write-Host `
            $_.ScriptStackTrace `
            -ForegroundColor DarkGray

        throw
    }
}