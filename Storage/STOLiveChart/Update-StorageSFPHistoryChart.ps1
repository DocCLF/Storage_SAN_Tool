function Update-StorageSFPHistoryChart {
    <#
    .SYNOPSIS
        Builds the LiveCharts data model for one or multiple IBM Storage FC ports.

    .DESCRIPTION
        Loads historical data for one or multiple Storage FC ports and
        creates the LiveCharts series, axes and statistics for the selected
        metric.

        A single-port request creates the normal Storage history view,
        including optional reference series.

        A multi-port request creates a comparison view for up to four
        Storage FC ports using the same metric.

        Counter metrics can be converted from cumulative values to delta
        values depending on the configured ValueMode.

        The function does not open a window and does not directly modify
        a CartesianChart control.

    .PARAMETER Request
        Request object created by New-StorageSFPHistoryRequest.

        The request may contain:

            RowID
                One Storage FC port.

            RowIDs
                One to four Storage FC ports.

    .PARAMETER CustomerNbr
        Customer number used to locate the SQLite database.

    .PARAMETER RowID
        Stable Storage FC-port identifier:

            SerialNumber|WWNN|WWPN

        Direct parameter calls currently support one port.

    .PARAMETER Metric
        Storage metric to display.

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range.

    .PARAMETER DateTimeLabelFormat
        Format used for labels on the X axis.

    .PARAMETER DateTimeStep
        Minimum distance between labels on the X axis.

    .OUTPUTS
        PSCustomObject created by New-LiveChartsChartModel.

    .EXAMPLE
        $ChartData = Update-StorageSFPHistoryChart `
            -CustomerNbr '123456' `
            -RowID '78F27FR|5005076815000ADC|5005076815110adc' `
            -Metric 'SFPTemp' `
            -StartTime (Get-Date).AddDays(-7)

    .EXAMPLE
        $ChartData = Update-StorageSFPHistoryChart `
            -Request $Request
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByParameters')]
    param (
        [Parameter(
            Mandatory,
            ParameterSetName = 'ByRequest'
        )]
        [ValidateNotNull()]
        [object]$Request,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ByParameters'
        )]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ByParameters'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$RowID,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ByParameters'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Metric,

        [Parameter(ParameterSetName = 'ByParameters')]
        [datetime]$StartTime = (Get-Date).AddDays(-30),

        [Parameter(ParameterSetName = 'ByParameters')]
        [datetime]$EndTime = (Get-Date),

        [Parameter(ParameterSetName = 'ByParameters')]
        [ValidateNotNullOrEmpty()]
        [string]$DateTimeLabelFormat = 'dd.MM. HH:mm',

        [Parameter(ParameterSetName = 'ByParameters')]
        [TimeSpan]$DateTimeStep = ([TimeSpan]::FromHours(1))
    )

    # ---------------------------------------------------------------------
    # Request normalisieren
    # ---------------------------------------------------------------------

    if ($PSCmdlet.ParameterSetName -eq 'ByRequest') {

        $RequiredProperties = @(
            'CustomerNbr'
            'Metric'
            'StartTime'
            'EndTime'
            'DateTimeLabelFormat'
            'DateTimeStep'
        )

        foreach ($PropertyName in $RequiredProperties) {
            if (-not $Request.PSObject.Properties[$PropertyName]) {
                throw "Request property '$PropertyName' is missing."
            }
        }

        $CustomerNbr         = [string]$Request.CustomerNbr
        $Metric              = [string]$Request.Metric
        $StartTime           = [datetime]$Request.StartTime
        $EndTime             = [datetime]$Request.EndTime
        $DateTimeLabelFormat = [string]$Request.DateTimeLabelFormat
        $DateTimeStep        = [TimeSpan]$Request.DateTimeStep

        # Neue Requests verwenden RowIDs.
        # RowID bleibt als Fallback für ältere Requests erhalten.
        if (
            $Request.PSObject.Properties['RowIDs'] -and
            $null -ne $Request.RowIDs
        ) {
            $RequestedRowIDs = @(
                $Request.RowIDs |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace(
                            [string]$_
                        )
                    } |
                    ForEach-Object {
                        [string]$_
                    }
            )
        }
        elseif (
            $Request.PSObject.Properties['RowID'] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$Request.RowID
            )
        ) {
            $RequestedRowIDs = @(
                [string]$Request.RowID
            )
        }
        else {
            throw "Request property 'RowID' or 'RowIDs' is missing."
        }
    }
    else {
        # Direkter Parameteraufruf bleibt zunächst ein Single-Port-Aufruf.
        $RequestedRowIDs = @(
            [string]$RowID
        )
    }

    # Doppelte Ports entfernen.
    $RequestedRowIDs = @(
        $RequestedRowIDs |
            Select-Object -Unique
    )

    if ($RequestedRowIDs.Count -eq 0) {
        throw 'At least one valid RowID is required.'
    }

    if ($RequestedRowIDs.Count -gt 4) {
        throw (
            'A maximum of four Storage FC ports can be compared. ' +
            "$($RequestedRowIDs.Count) RowIDs were supplied."
        )
    }

    # RowID bleibt für das bestehende ChartModel erhalten.
    # Bei einem Vergleich enthält es den ersten Port.
    $RowID = [string]$RequestedRowIDs[0]

    $IsComparison = (
        $RequestedRowIDs.Count -gt 1
    )

    # ---------------------------------------------------------------------
    # LiveCharts und Request prüfen
    # ---------------------------------------------------------------------

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    if ($StartTime -gt $EndTime) {
        throw 'StartTime must not be later than EndTime.'
    }

    if ($DateTimeStep -le [TimeSpan]::Zero) {
        throw 'DateTimeStep must be greater than zero.'
    }

    # Storage-spezifische Metrikdefinition laden.
    $MetricInfo = Get-StorageLiveChartsMetricInfo `
        -Metric $Metric

    if ($null -eq $MetricInfo) {
        throw (
            "No metric information was found for Storage metric " +
            "'$Metric'."
        )
    }

    # ---------------------------------------------------------------------
    # Bekannte Ports laden
    #
    # Die Daten werden lediglich verwendet, um lesbare Seriennamen für
    # die Vergleichsansicht zu erzeugen.
    # ---------------------------------------------------------------------

    $AvailablePorts = @(
        Get-StorageSFPHistoryPorts `
            -CustomerNbr $CustomerNbr
    )

    # Enthält eine Definition pro tatsächlich nutzbarem Port.
    $SeriesDefinitions = @()

    # Gesamte dargestellte Historie.
    $AllChartHistory = @()

    # Alle Werte aller tatsächlich dargestellten Ports.
    # Wird für Y-Achse und Vergleichsstatistik verwendet.
    $MetricValues = @()

    # ---------------------------------------------------------------------
    # Historien der angeforderten Ports laden
    # ---------------------------------------------------------------------

    foreach ($CurrentRowID in $RequestedRowIDs) {

        $RawHistory = @(
            Get-SFPHistory `
                -CustomerNbr $CustomerNbr `
                -RowID $CurrentRowID `
                -StartTime $StartTime `
                -EndTime $EndTime
        )

        if ($RawHistory.Count -eq 0) {

            # Im Vergleich darf ein einzelner Port ohne Daten übersprungen
            # werden. Die übrigen Ports können weiterhin dargestellt werden.
            if ($IsComparison) {
                Write-Warning (
                    "No Storage SFP history was found for RowID " +
                    "'$CurrentRowID'. The port was skipped."
                )

                continue
            }

            throw (
                "No Storage SFP history was found for RowID " +
                "'$CurrentRowID' between '$StartTime' and '$EndTime'."
            )
        }

        # Standardmäßig werden die unveränderten DB-Werte dargestellt.
        $CurrentChartHistory = $RawHistory

        # Kumulative Counter für die Anzeige in Änderungen pro Messung
        # umwandeln.
        if (
            $MetricInfo.PSObject.Properties['ValueMode'] -and
            [string]$MetricInfo.ValueMode -eq 'Delta'
        ) {
            $CurrentChartHistory = @(
                ConvertTo-LiveChartsDeltaHistory `
                    -History $RawHistory `
                    -Metric $Metric
            )
        }

        # -----------------------------------------------------------------
        # Numerische Werte der aktuellen Metrik extrahieren
        # -----------------------------------------------------------------

        $CurrentMetricValues = @(
            foreach ($HistoryItem in $CurrentChartHistory) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                $MetricProperty =
                    $HistoryItem.PSObject.Properties[$Metric]

                if ($null -eq $MetricProperty) {
                    continue
                }

                $RawValue = $MetricProperty.Value

                if (
                    $null -eq $RawValue -or
                    $RawValue -is [DBNull] -or
                    [string]::IsNullOrWhiteSpace(
                        [string]$RawValue
                    )
                ) {
                    continue
                }

                try {
                    [double]$RawValue
                }
                catch {
                    Write-Warning (
                        "Value '$RawValue' of metric '$Metric' for " +
                        "RowID '$CurrentRowID' could not be converted " +
                        'to Double and was skipped.'
                    )
                }
            }
        )

        if ($CurrentMetricValues.Count -eq 0) {

            if ($IsComparison) {
                Write-Warning (
                    "RowID '$CurrentRowID' contains no usable values " +
                    "for metric '$Metric'. The port was skipped."
                )

                continue
            }

            throw (
                "The Storage history contains no usable values for " +
                "metric '$Metric'."
            )
        }

        # -----------------------------------------------------------------
        # Lesbaren Namen für die Vergleichsserie erzeugen
        # -----------------------------------------------------------------

        $PortInfo = $AvailablePorts |
            Where-Object {
                [string]$_.RowID -eq [string]$CurrentRowID
            } |
            Select-Object -First 1

        if (
            $null -ne $PortInfo -and
            $PortInfo.PSObject.Properties['NodeID'] -and
            $PortInfo.PSObject.Properties['PortID'] -and
            $null -ne $PortInfo.NodeID -and
            $null -ne $PortInfo.PortID
        ) {
            # Systemunabhängige Kurzbezeichnung:
            #
            #   Node1 P1
            #   Node2 P4
            #
            $SeriesName = 'Node{0} P{1}' -f
                $PortInfo.NodeID,
                $PortInfo.PortID
        }
        elseif (
            $null -ne $PortInfo -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$PortInfo.DisplayName
            )
        ) {
            # Fallback auf den vollständigen Portnamen.
            $SeriesName =
                [string]$PortInfo.DisplayName
        }
        else {
            # Letzter Fallback: WWPN aus der RowID verwenden.
            $RowIDParts =
                [string]$CurrentRowID -split '\|'

            if ($RowIDParts.Count -ge 3) {
                $SeriesName =
                    [string]$RowIDParts[2]
            }
            else {
                $SeriesName =
                    [string]$CurrentRowID
            }
        }

        # Eine Definition pro Port für die MultiSeries-Funktion erzeugen.
        $SeriesDefinitions += [PSCustomObject]@{
            RowID   = [string]$CurrentRowID
            Name    = $SeriesName
            History = $CurrentChartHistory
        }

        $AllChartHistory += $CurrentChartHistory
        $MetricValues    += $CurrentMetricValues
    }

    # ---------------------------------------------------------------------
    # Ergebnis der History-Aufbereitung prüfen
    # ---------------------------------------------------------------------

    if ($SeriesDefinitions.Count -eq 0) {
        throw (
            "No usable Storage SFP histories were found for metric " +
            "'$Metric'."
        )
    }

    if ($MetricValues.Count -eq 0) {
        throw (
            "The Storage history contains no usable values for " +
            "metric '$Metric'."
        )
    }

    # Der bisherige Single-Port-Code arbeitet weiterhin mit ChartHistory.
    # Bei einem Vergleich entspricht diese Variable nur dem ersten Port.
    $ChartHistory = @(
        $SeriesDefinitions[0].History
    )

    # ---------------------------------------------------------------------
    # Optionale Referenzwerte
    #
    # Referenzlinien werden momentan bewusst nur in der Einzelansicht
    # dargestellt. In einer Vergleichsansicht würden identische Grenzlinien
    # pro Port keinen zusätzlichen Nutzen bringen.
    # ---------------------------------------------------------------------

    $ReferenceMetricValues = @()

    if (
        -not $IsComparison -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$MetricInfo.ReferenceMetric
        )
    ) {
        $ReferenceMetric =
            [string]$MetricInfo.ReferenceMetric

        $ReferenceMetricValues = @(
            foreach ($HistoryItem in $ChartHistory) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                $ReferenceProperty =
                    $HistoryItem.PSObject.Properties[
                        $ReferenceMetric
                    ]

                if ($null -eq $ReferenceProperty) {
                    continue
                }

                $RawValue =
                    $ReferenceProperty.Value

                if (
                    $null -eq $RawValue -or
                    $RawValue -is [DBNull] -or
                    [string]::IsNullOrWhiteSpace(
                        [string]$RawValue
                    )
                ) {
                    continue
                }

                try {
                    [double]$RawValue
                }
                catch {
                    Write-Warning (
                        "Value '$RawValue' of reference metric " +
                        "'$ReferenceMetric' could not be converted " +
                        'to Double and was skipped.'
                    )
                }
            }
        )
    }

    # ---------------------------------------------------------------------
    # Gemeinsame Wertebasis für die Y-Achse erzeugen
    # ---------------------------------------------------------------------

    $AxisValues = @(
        $MetricValues

        if ($ReferenceMetricValues.Count -gt 0) {
            $ReferenceMetricValues
        }
    )

    # ---------------------------------------------------------------------
    # Serien erzeugen
    # ---------------------------------------------------------------------

    if ($IsComparison) {
        $SeriesCollection =
            New-LiveChartsMultiSeriesCollection `
                -SeriesDefinitions $SeriesDefinitions `
                -MetricInfo $MetricInfo `
                -MaximumSeries 4
    }
    else {
        $SeriesCollection =
            New-LiveChartsSeriesCollection `
                -History $ChartHistory `
                -MetricInfo $MetricInfo
    }

    # ---------------------------------------------------------------------
    # X-Achse erzeugen
    # ---------------------------------------------------------------------

    $XAxis = New-LiveChartsDateTimeAxis `
        -Name 'Zeit' `
        -LabelFormat $DateTimeLabelFormat `
        -MinStep $DateTimeStep

    # ---------------------------------------------------------------------
    # Y-Achse erzeugen
    # ---------------------------------------------------------------------

    $MinimumPadding = 1

    if (
        $MetricInfo.PSObject.Properties.Match(
            'MinimumPadding'
        ).Count -gt 0 -and
        $null -ne $MetricInfo.MinimumPadding
    ) {
        $MinimumPadding =
            [double]$MetricInfo.MinimumPadding
    }

    $YAxis = New-LiveChartsValueAxis `
        -Name $MetricInfo.DisplayName `
        -Unit $MetricInfo.Unit `
        -Values $AxisValues `
        -MinimumPadding $MinimumPadding

    # LiveCharts erwartet Collections für die Achsen.
    $XAxisCollection =
        [System.Collections.Generic.List[
            LiveChartsCore.SkiaSharpView.Axis
        ]]::new()

    $YAxisCollection =
        [System.Collections.Generic.List[
            LiveChartsCore.SkiaSharpView.Axis
        ]]::new()

    $XAxisCollection.Add($XAxis)
    $YAxisCollection.Add($YAxis)

    # ---------------------------------------------------------------------
    # Statistik erzeugen
    # ---------------------------------------------------------------------

    if ($IsComparison) {

        # Bei mehreren Ports existiert kein eindeutiger einzelner
        # "aktueller Wert".
        #
        # Minimum, Maximum und Durchschnitt beziehen sich deshalb auf
        # sämtliche dargestellten Messpunkte.
        $Measurement = $MetricValues |
            Measure-Object `
                -Minimum `
                -Maximum `
                -Average

        $Statistics = [PSCustomObject]@{
            CurrentValue = $null
            MinimumValue = [double]$Measurement.Minimum
            MaximumValue = [double]$Measurement.Maximum
            AverageValue = [double]$Measurement.Average
            PointCount   = $MetricValues.Count
        }
    }
    else {
        $Statistics = New-LiveChartsStatistics `
            -History $ChartHistory `
            -Metric $Metric `
            -Values $MetricValues
    }

    # ---------------------------------------------------------------------
    # History für das ChartModel festlegen
    #
    # Single:
    #   Historie des ausgewählten Ports
    #
    # Comparison:
    #   Historien sämtlicher tatsächlich dargestellter Ports
    # ---------------------------------------------------------------------

    if ($IsComparison) {
        $ModelHistory = $AllChartHistory
    }
    else {
        $ModelHistory = $ChartHistory
    }

    # ---------------------------------------------------------------------
    # Gemeinsames Chart-Modell erzeugen
    # ---------------------------------------------------------------------

    $ChartModel = New-LiveChartsChartModel `
        -Series $SeriesCollection `
        -XAxes $XAxisCollection `
        -YAxes $YAxisCollection `
        -History $ModelHistory `
        -MetricInfo $MetricInfo `
        -Statistics $Statistics `
        -CustomerNbr $CustomerNbr `
        -RowID $RowID `
        -Metric $Metric `
        -StartTime $StartTime `
        -EndTime $EndTime

    # Zusätzliche Informationen für Single-/Vergleichsansicht.
    $ChartModel |
        Add-Member `
            -MemberType NoteProperty `
            -Name RowIDs `
            -Value ([string[]]$RequestedRowIDs) `
            -Force

    $ChartModel |
        Add-Member `
            -MemberType NoteProperty `
            -Name IsComparison `
            -Value $IsComparison `
            -Force

    # Tatsächlich dargestellte Ports zählen.
    #
    # Das kann kleiner als RequestedRowIDs.Count sein, wenn einzelne
    # Vergleichsports im gewählten Zeitraum keine nutzbaren Daten besitzen.
    $ChartModel |
        Add-Member `
            -MemberType NoteProperty `
            -Name PortCount `
            -Value $SeriesDefinitions.Count `
            -Force

    return $ChartModel
}