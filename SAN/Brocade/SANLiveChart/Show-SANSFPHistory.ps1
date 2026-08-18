function Show-SANSFPHistory {
    <#
    .SYNOPSIS
        Opens the SAN SFP history viewer.

    .DESCRIPTION
        Opens the shared LiveCharts history viewer for Brocade SAN SFPs.

        The viewer uses the generic selector architecture:

            SAN Switch
                -> Port
                    -> Metric / Series

        Multiple ports and multiple compatible metrics may be displayed
        simultaneously.

        The shared history viewer XAML is provided by
        Get-LiveChartsHistoryViewXaml.

    .PARAMETER CustomerNbr
        Customer number whose SQLite database should be used.

    .EXAMPLE
        Show-SANSFPHistory -CustomerNbr '349872'
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
            -WindowTitle 'SAN SFP History' `
            -SourceLabel 'SAN-SFP-Port'`
            -SourceGroupLabel 'SAN Switches'

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

    $SP_SourceGroupSelector =
        $Window.FindName(
            'SP_SourceGroupSelector'
        )

    $LB_SourceGroupSelector =
        $Window.FindName(
            'LB_SourceGroupSelector'
        )

    $LB_SourceSelector =
        $Window.FindName(
            'LB_SourceSelector'
        )

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
    # ---------------------------------------------------------------------

    $RequiredControls = @{
        CB_Source              = $CB_Source
        CHK_ComparisonMode     = $CHK_ComparisonMode
        LB_ComparisonSources   = $LB_ComparisonSources

        SP_SourceGroupSelector = $SP_SourceGroupSelector
        LB_SourceGroupSelector = $LB_SourceGroupSelector
        LB_SourceSelector      = $LB_SourceSelector
        LB_SeriesSelector      = $LB_SeriesSelector

        CB_Metric              = $CB_Metric
        CB_TimeRange           = $CB_TimeRange
        BTN_Refresh            = $BTN_Refresh
        TB_Status              = $TB_Status
        Chart                  = $Chart
    }

    foreach ($ControlName in $RequiredControls.Keys) {

        if ($null -eq $RequiredControls[$ControlName]) {

            throw (
                "Das benötigte Control '$ControlName' " +
                'wurde im XAML nicht gefunden.'
            )
        }
    }

    # ---------------------------------------------------------------------
    # Initialize SAN SFP viewer
    # ---------------------------------------------------------------------

    $Initialized =
        Initialize-SANSFPHistoryView `
            -CustomerNbr $CustomerNbr `
            -ViewRoot $Window `
            -PortComboBox $CB_Source `
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
            'SAN SFP History ShowDialog Fehler: ' +
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