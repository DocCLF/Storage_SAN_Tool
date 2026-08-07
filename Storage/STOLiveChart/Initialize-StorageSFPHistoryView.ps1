function Initialize-StorageSFPHistoryView {
    <#
    .SYNOPSIS
        Initializes the Storage SFP history viewer.

    .DESCRIPTION
        Loads the available Storage ports, metrics and time ranges.

        The viewer starts in single-port mode. The optional comparison
        mode allows selecting up to four Storage FC ports.

        This function only initializes the controls and their events.
        The actual request and chart creation remain in
        Update-StorageSFPHistoryViewer.

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER ViewRoot
        Root Window or UserControl of the viewer.

    .PARAMETER PortComboBox
        ComboBox used for the single-port selection.

    .PARAMETER ComparisonCheckBox
        CheckBox used to enable or disable comparison mode.

    .PARAMETER ComparisonListBox
        ListBox used to select up to four comparison ports.

    .PARAMETER MetricComboBox
        ComboBox containing the available metrics.

    .PARAMETER TimeRangeComboBox
        ComboBox containing the available time ranges.

    .PARAMETER StatusTextBlock
        TextBlock used for viewer status messages.

    .PARAMETER RefreshButton
        Optional refresh button.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ViewRoot,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $PortComboBox,

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

    $Ports = @(
        Get-StorageSFPHistoryPorts `
            -CustomerNbr $CustomerNbr
    )

    if ($Ports.Count -eq 0) {
        $StatusTextBlock.Text =
            "Keine Storage-SFP-History-Daten für Kunde $CustomerNbr gefunden."

        return $false
    }

    $Metrics = @(
        Get-StorageLiveChartsMetricInfo -All
    )

    $TimeRanges = @(
        Get-LiveChartsTimeRanges
    )
    $DefaultTimeRange = $TimeRanges | Where-Object Default
    if ($DefaultTimeRange.Count -ne 1) {throw ("Exactly one default time range must be defined.")}

    if ($Metrics.Count -eq 0) {
        $StatusTextBlock.Text =
            'Es wurden keine Storage-Metriken gefunden.'

        return $false
    }

    if ($TimeRanges.Count -eq 0) {
        $StatusTextBlock.Text =
            'Es wurden keine LiveCharts-Zeiträume gefunden.'

        return $false
    }

    # Dieselben Portobjekte für Einzel- und Vergleichsauswahl verwenden.
    $PortComboBox.ItemsSource      = $Ports
    $ComparisonListBox.ItemsSource = $Ports

    $MetricComboBox.ItemsSource    = $Metrics
    $TimeRangeComboBox.ItemsSource = $TimeRanges

    # Standardmäßig bleibt die bisherige Einzelansicht aktiv.
    $ComparisonCheckBox.IsChecked    = $false
    $PortComboBox.Visibility          =
        [System.Windows.Visibility]::Visible
    $ComparisonListBox.Visibility     =
        [System.Windows.Visibility]::Collapsed

    # Standard-Port.
    $PortComboBox.SelectedIndex = 0

    # Standard-Metrik.
    $DefaultMetric = $Metrics |
        Where-Object { $_.Metric -eq 'SFPTemp' } |
        Select-Object -First 1

    if ($null -ne $DefaultMetric) {
        $MetricComboBox.SelectedItem = $DefaultMetric
    }
    else {
        $MetricComboBox.SelectedIndex = 0
    }

    # Standard-Zeitraum.
    $DefaultTimeRange = $TimeRanges |
        Where-Object { $_.Key -eq 'Last24Hours' } |
        Select-Object -First 1

    if ($null -ne $DefaultTimeRange) {
        $TimeRangeComboBox.SelectedItem = $DefaultTimeRange
    }
    else {
        $TimeRangeComboBox.SelectedIndex = 0
    }

    # Bestehender Einzelport-Chartaufruf.
    # Die Comparison-Controls werden im nächsten Schritt zusätzlich an
    # Update-StorageSFPHistoryViewer übergeben.
$UpdateChart = {
    Update-StorageSFPHistoryViewer `
        -Window $ViewRoot `
        -CustomerNbr $CustomerNbr `
        -PortComboBox $PortComboBox `
        -ComparisonCheckBox $ComparisonCheckBox `
        -ComparisonListBox $ComparisonListBox `
        -MetricComboBox $MetricComboBox `
        -TimeRangeComboBox $TimeRangeComboBox `
        -StatusTextBlock $StatusTextBlock `
        -RefreshButton $RefreshButton |
        Out-Null
}.GetNewClosure()

    # Umschaltung der sichtbaren Portauswahl.
    $SetComparisonMode = {
        $ComparisonEnabled =
            ($ComparisonCheckBox.IsChecked -eq $true)

if ($ComparisonEnabled) {
    $PortComboBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    $ComparisonListBox.Visibility =
        [System.Windows.Visibility]::Visible

    # Ist noch kein Vergleichsport gewählt, den aktuellen Einzelport
    # als erste Auswahl übernehmen.
    if (
        $ComparisonListBox.SelectedItems.Count -eq 0 -and
        $null -ne $PortComboBox.SelectedItem
    ) {
        $ComparisonListBox.SelectedItems.Add(
            $PortComboBox.SelectedItem
        )
    }

    $SelectedCount =
        $ComparisonListBox.SelectedItems.Count

    if ($SelectedCount -ge 2) {
        # Bereits vorhandene Auswahl direkt wieder als Vergleich anzeigen.
        & $UpdateChart
    }
    else {
        $StatusTextBlock.Text = (
            'Vergleich aktiviert: Bitte mindestens zwei Ports auswählen.'
        )
    }
}
        else {
            # Beim Verlassen des Vergleichs den ersten Vergleichsport wieder
            # als Einzelport übernehmen.
            if ($ComparisonListBox.SelectedItems.Count -gt 0) {
                $PortComboBox.SelectedItem =
                    $ComparisonListBox.SelectedItems[0]
            }

            $ComparisonListBox.Visibility =
                [System.Windows.Visibility]::Collapsed

            $PortComboBox.Visibility =
                [System.Windows.Visibility]::Visible

            & $UpdateChart
        }
    }.GetNewClosure()

    # Maximal vier Vergleichsports erlauben.
$ComparisonSelectionChanged = {
    param (
        $Sender,
        $EventArgs
    )

    if ($ComparisonListBox.SelectedItems.Count -gt 4) {
        foreach ($AddedItem in @($EventArgs.AddedItems)) {
            if ($ComparisonListBox.SelectedItems.Contains($AddedItem)) {
                $ComparisonListBox.SelectedItems.Remove($AddedItem)
            }
        }

        $StatusTextBlock.Text =
            'Es können maximal vier Storage-Ports verglichen werden.'

        return
    }

    if ($ComparisonCheckBox.IsChecked -eq $true) {
        $SelectedCount =
            $ComparisonListBox.SelectedItems.Count

        if ($SelectedCount -lt 2) {
            $StatusTextBlock.Text = (
                'Vergleich aktiviert: Bitte mindestens zwei Ports auswählen.'
            )
        }
        else {
            $StatusTextBlock.Text = (
                '{0} Ports für den Vergleich ausgewählt.' -f
                $SelectedCount
            )

            & $UpdateChart
        }
    }
}.GetNewClosure()

    if ($null -ne $RefreshButton) {
        $RefreshButton.Add_Click($UpdateChart)
    }

    $PortComboBox.Add_SelectionChanged($UpdateChart)
    $MetricComboBox.Add_SelectionChanged($UpdateChart)
    $TimeRangeComboBox.Add_SelectionChanged($UpdateChart)

    $ComparisonCheckBox.Add_Checked($SetComparisonMode)
    $ComparisonCheckBox.Add_Unchecked($SetComparisonMode)

    $ComparisonListBox.Add_SelectionChanged(
        $ComparisonSelectionChanged
    )

    # Initial weiterhin den bisherigen Einzelport-Chart laden.
    & $UpdateChart

    return $true
}