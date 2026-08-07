function Test-LiveCharts {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Series,

        [Parameter()]
        $YAxes,

        [Parameter()]
        $XAxes
    )

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # Falls keine eigene Serie übergeben wurde,
    # wird weiterhin eine einfache Testserie erzeugt.
    if ($null -eq $Series) {
        $Values = [System.Collections.Generic.List[double]]::new()

        foreach ($Value in 10, 14, 12, 18, 16, 21) {
            $Values.Add([double]$Value)
        }

        $OpenGenericType = [LiveChartsCore.SkiaSharpView.LineSeries``1]

        $ClosedSeriesType = $OpenGenericType.MakeGenericType(
            [double]
        )

        $Series = [Activator]::CreateInstance($ClosedSeriesType)

        $Series.Name           = 'Testreihe'
        $Series.Values         = $Values
        $Series.LineSmoothness = 0
    }

    # Das Chart erwartet eine Collection von ISeries.
    $SeriesCollection =
        [System.Collections.Generic.List[
            LiveChartsCore.ISeries
        ]]::new()

    $SeriesCollection.Add($Series)

    # Falls keine Achsen übergeben wurden, bleiben die Werte $null.
    # LiveCharts erzeugt dann seine Standardachsen.
    $ChartViewModel = [PSCustomObject]@{
        Series = $SeriesCollection
        XAxes  = $XAxes
        YAxes  = $YAxes
    }

    $Xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:lvc="clr-namespace:LiveChartsCore.SkiaSharpView.WPF;assembly=LiveChartsCore.SkiaSharpView.WPF"
    Title="LiveCharts Test"
    Width="900"
    Height="500"
    WindowStartupLocation="CenterScreen">

    <Grid Margin="20">
        <lvc:CartesianChart
            Series="{Binding Series}"
            XAxes="{Binding XAxes}"
            YAxes="{Binding YAxes}" />
    </Grid>
</Window>
"@

    $XmlReader = [System.Xml.XmlReader]::Create(
        [System.IO.StringReader]::new($Xaml)
    )

    try {
        $Window = [Windows.Markup.XamlReader]::Load($XmlReader)
    }
    finally {
        $XmlReader.Dispose()
    }

    $Window.DataContext = $ChartViewModel

    $Window.ShowDialog() | Out-Null
}