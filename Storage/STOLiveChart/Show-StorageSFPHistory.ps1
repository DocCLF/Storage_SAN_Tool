function Show-StorageSFPHistory {
    <#
    .SYNOPSIS
        Opens a Storage SFP history viewer.

    .DESCRIPTION
        Opens the shared LiveCharts history viewer for Storage FC ports.

        The viewer uses the generic selector architecture:

            Storage System
                -> FC Port / SFP
                    -> Metric / Series

        Multiple ports and multiple compatible metrics may be displayed
        simultaneously.

        The shared history viewer XAML is provided by
        Get-LiveChartsHistoryViewXaml.

    .PARAMETER CustomerNbr
        Customer number whose SQLite database should be used.

    .EXAMPLE
        Show-StorageSFPHistory -CustomerNbr '123456'
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
    $Xaml = Get-LiveChartsHistoryViewXaml -WindowTitle 'Storage SFP History' -SourceLabel 'Storage-Port'

    $XmlReader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($Xaml)))

    try {
        $Window = [System.Windows.Markup.XamlReader]::Load($XmlReader)
    }finally {
        if ($null -ne $XmlReader) {$XmlReader.Dispose()}
    }

    # ---------------------------------------------------------------------
    # Load application styles
    # ---------------------------------------------------------------------
    $StyleFiles = @(
        (
            Join-Path $PSRootPath 'Resources\Styles\ColorStyle.xaml'
        ),
        (
            Join-Path $PSRootPath 'Resources\Styles\OtherControlStyle.xaml'
        ),
        (
            Join-Path $PSRootPath 'Resources\Styles\TextBoxStyle.xaml'
        ),
        (
            Join-Path $PSRootPath 'Resources\Styles\ButtonStyle.xaml'
        )
    )

    Import-WpfResourceDictionaries -Target $Window -Path $StyleFiles

    # ---------------------------------------------------------------------
    # Resolve legacy controls
    #
    # These still exist in the shared XAML because other viewers may use
    # them. Initialize-StorageSFPHistoryView collapses them for SFP.
    # ---------------------------------------------------------------------
    $CB_Source = $Window.FindName('CB_Source')
    $CHK_ComparisonMode = $Window.FindName('CHK_ComparisonMode')
    $LB_ComparisonSources = $Window.FindName('LB_ComparisonSources')

    # ---------------------------------------------------------------------
    # Resolve generic selector controls
    # ---------------------------------------------------------------------
    # Storage Systems / Source Groups
    $SP_SourceGroupSelector = $Window.FindName('SP_SourceGroupSelector')
    $LB_SourceGroupSelector = $Window.FindName('LB_SourceGroupSelector')

    # FC Ports / Sources
    $LB_SourceSelector = $Window.FindName('LB_SourceSelector')

    # Metrics / Series
    $LB_SeriesSelector = $Window.FindName('LB_SeriesSelector')

    # ---------------------------------------------------------------------
    # Resolve common viewer controls
    # ---------------------------------------------------------------------
    $CB_Metric = $Window.FindName('CB_Metric')
    $CB_TimeRange = $Window.FindName('CB_TimeRange')
    $BTN_Refresh = $Window.FindName('BTN_Refresh')
    $TB_Status = $Window.FindName('TB_Status')
    $Chart = $Window.FindName('Chart')

    # ---------------------------------------------------------------------
    # Validate required controls
    #
    # This catches mismatches between shared XAML and viewer code before
    # Initialize-StorageSFPHistoryView is called.
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
            SST_ToolMessageCollector -TD_ToolMSGCollector ("Das benötigte Control $ControlName" +  "wurde im XAML nicht gefunden.") -TD_ToolMSGType Error -TD_Shown yes
        }
    }

    # ---------------------------------------------------------------------
    # Initialize SFP viewer
    #
    # Important:
    #
    # The generic Initialize parameters are intentionally named GroupSelectorListBox / GroupSelectorPanel.
    #
    # Here they receive the actual XAML controls:
    #
    #   GroupSelectorListBox -> LB_SourceGroupSelector
    #   GroupSelectorPanel   -> SP_SourceGroupSelector
    # ---------------------------------------------------------------------
    $Initialized = Initialize-StorageSFPHistoryView `
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

    if (-not $Initialized) {return}

    # ---------------------------------------------------------------------
    # Show viewer
    # ---------------------------------------------------------------------
    try {
        $Window.ShowDialog() | Out-Null
    }catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector ("Storage SFP History ShowDialog Fehler:" + "$($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown yes
        Write-Host $_.InvocationInfo.PositionMessage
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        throw
    }
}