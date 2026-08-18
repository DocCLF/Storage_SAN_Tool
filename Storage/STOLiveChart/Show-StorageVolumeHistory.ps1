function Show-StorageVolumeHistory {
    <#
    .SYNOPSIS
        Opens a Storage volume analysis history viewer.

    .DESCRIPTION
        Loads the available Storage volumes and analysis metrics for a
        customer and displays the selected historical metrics in a
        LiveCharts chart.

        The viewer supports:

            Source Groups
                Storage systems

            Sources
                One or multiple Volumes

            Series
                One or multiple analysis metrics

        The shared history viewer XAML is provided by
        Get-LiveChartsHistoryViewXaml.

    .PARAMETER CustomerNbr
        Customer number whose SQLite database should be used.

    .EXAMPLE
        Show-StorageVolumeHistory -CustomerNbr '123456'
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
    # Load shared history viewer XAML
    # ---------------------------------------------------------------------

    $Xaml =
        Get-LiveChartsHistoryViewXaml `
            -WindowTitle 'Storage Volume Analysis History' `
            -SourceLabel 'Storage-Volume'

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
    # Load common WPF resource dictionaries
    # ---------------------------------------------------------------------

    $StyleFiles = @(
        (
            Join-Path `
                $PSRootPath `
                'Resources\Styles\ColorStyle.xaml'
        )

        (
            Join-Path `
                $PSRootPath `
                'Resources\Styles\OtherControlStyle.xaml'
        )

        (
            Join-Path `
                $PSRootPath `
                'Resources\Styles\TextBoxStyle.xaml'
        )

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
    # Resolve generic SourceGroup controls
    # ---------------------------------------------------------------------

    $SP_SourceGroupSelector =
        $Window.FindName(
            'SP_SourceGroupSelector'
        )

    $LB_SourceGroupSelector =
        $Window.FindName(
            'LB_SourceGroupSelector'
        )

    # ---------------------------------------------------------------------
    # Resolve generic Source selector
    # ---------------------------------------------------------------------

    $LB_SourceSelector =
        $Window.FindName(
            'LB_SourceSelector'
        )

    # ---------------------------------------------------------------------
    # Resolve generic Series selector
    # ---------------------------------------------------------------------

    $LB_SeriesSelector =
        $Window.FindName(
            'LB_SeriesSelector'
        )

    # ---------------------------------------------------------------------
    # Resolve legacy source / comparison controls
    #
    # These controls are currently kept in the shared XAML for backwards
    # compatibility with other history viewers.
    #
    # The Volume viewer hides them in its initializer.
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
    # Resolve preset / time controls
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

    # ---------------------------------------------------------------------
    # Resolve status and chart controls
    # ---------------------------------------------------------------------

    $TB_Status =
        $Window.FindName(
            'TB_Status'
        )

    $Chart =
        $Window.FindName(
            'Chart'
        )

    # ---------------------------------------------------------------------
    # Validate all required XAML controls
    # ---------------------------------------------------------------------

    $RequiredControls = @{
        SP_SourceGroupSelector = $SP_SourceGroupSelector
        LB_SourceGroupSelector = $LB_SourceGroupSelector
        LB_SourceSelector      = $LB_SourceSelector
        LB_SeriesSelector      = $LB_SeriesSelector

        CB_Source              = $CB_Source
        CHK_ComparisonMode     = $CHK_ComparisonMode
        LB_ComparisonSources   = $LB_ComparisonSources

        CB_Metric              = $CB_Metric
        CB_TimeRange           = $CB_TimeRange
        BTN_Refresh            = $BTN_Refresh
        TB_Status              = $TB_Status
        Chart                  = $Chart
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
    # Initialize Storage Volume history viewer
    # ---------------------------------------------------------------------

    $Initialized =
        Initialize-StorageVolumeHistoryView `
            -CustomerNbr $CustomerNbr `
            -ViewRoot $Window `
            -VolumeComboBox $CB_Source `
            -ComparisonCheckBox $CHK_ComparisonMode `
            -ComparisonListBox $LB_ComparisonSources `
            -SourceGroupPanel $SP_SourceGroupSelector `
            -SourceGroupSelectorListBox $LB_SourceGroupSelector `
            -SourceSelectorListBox $LB_SourceSelector `
            -SeriesSelectorListBox $LB_SeriesSelector `
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
            "Storage Volume History ShowDialog ERROR"
        ) -ForegroundColor Red

        Write-Host `
            "`nMessage:" `
            -ForegroundColor Yellow

        Write-Host `
            $_.Exception.Message

        Write-Host `
            "`nException Type:" `
            -ForegroundColor Yellow

        Write-Host `
            $_.Exception.GetType().FullName

        Write-Host `
            "`nFull Exception:" `
            -ForegroundColor Yellow

        Write-Host `
            $_.Exception.ToString()

        # -------------------------------------------------------------
        # Walk through all InnerExceptions.
        # -------------------------------------------------------------

        $InnerException =
            $_.Exception.InnerException

        $Level =
            1

        while ($null -ne $InnerException) {

            Write-Host (
                "`nInnerException $Level"
            ) -ForegroundColor Cyan

            Write-Host 'Type:'

            Write-Host `
                $InnerException.GetType().FullName

            Write-Host 'Message:'

            Write-Host `
                $InnerException.Message

            Write-Host 'Full:'

            Write-Host `
                $InnerException.ToString()

            $InnerException =
                $InnerException.InnerException

            $Level++
        }

        Write-Host `
            "`nScriptStackTrace:" `
            -ForegroundColor Yellow

        Write-Host `
            $_.ScriptStackTrace

        throw
    }
}