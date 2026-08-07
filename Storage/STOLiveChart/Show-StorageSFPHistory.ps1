function Show-StorageSFPHistory {
    <#
    .SYNOPSIS
        Opens a Storage SFP history viewer.

    .DESCRIPTION
        Loads the available Storage FC ports and metrics for a customer
        and displays the selected historical metric in a LiveCharts chart.

        This function contains only GUI orchestration. Database access,
        metric definitions and chart creation remain in their respective
        helper functions.

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

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $Xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:lvc="clr-namespace:LiveChartsCore.SkiaSharpView.WPF;assembly=LiveChartsCore.SkiaSharpView.WPF"
    Title="Storage SFP History"
    Width="1100"
    Height="700"
    MinWidth="850"
    MinHeight="550"
    WindowStartupLocation="CenterScreen">

    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Auswahlbereich -->
        <Grid Grid.Row="0" Margin="0,0,0,15">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="2*"/>
                <ColumnDefinition Width="1.3*"/>
                <ColumnDefinition Width="1.2*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

<StackPanel Grid.Column="0"
            Margin="0,0,10,0">

    <Grid Margin="0,0,0,4">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Column="0"
                   Text="Storage-Port"
                   VerticalAlignment="Center"
                   FontWeight="SemiBold"/>

        <CheckBox Grid.Column="1"
                  x:Name="CHK_ComparisonMode"
                  Content="Vergleich"
                  Margin="12,0,0,0"
                  VerticalAlignment="Center"/>
    </Grid>

    <ComboBox x:Name="CB_Port"
              MinWidth="300"
              DisplayMemberPath="DisplayName"/>

    <ListBox x:Name="LB_ComparisonPorts"
             MinWidth="300"
             MaxHeight="145"
             Margin="0,6,0,0"
             Visibility="Collapsed"
             SelectionMode="Multiple"
             ScrollViewer.VerticalScrollBarVisibility="Auto"
             BorderBrush="#FFD0D0D0"
             BorderThickness="1">

        <ListBox.ItemTemplate>
            <DataTemplate>
                <CheckBox
                    Content="{Binding DisplayName}"
                    Padding="2"
                    IsHitTestVisible="False"
                    IsChecked="{Binding
                        RelativeSource={RelativeSource AncestorType={x:Type ListBoxItem}},
                        Path=IsSelected,
                        Mode=OneWay}"/>
            </DataTemplate>
        </ListBox.ItemTemplate>
    </ListBox>
</StackPanel>

            <StackPanel Grid.Column="1" Margin="0,0,10,0">
                <TextBlock
                    Text="Messwert"
                    Margin="0,0,0,4"
                    FontWeight="SemiBold"/>

                <ComboBox
                    x:Name="CB_Metric"
                    MinWidth="180"
                    DisplayMemberPath="DisplayName"/>
            </StackPanel>

            <StackPanel Grid.Column="2" Margin="0,0,10,0">
                <TextBlock
                    Text="Zeitraum"
                    Margin="0,0,0,4"
                    FontWeight="SemiBold"/>

                <ComboBox
                    x:Name="CB_TimeRange"
                    MinWidth="160"
                    DisplayMemberPath="DisplayName"/>
            </StackPanel>

            <Button
                x:Name="BTN_Refresh"
                Grid.Column="3"
                Content="Aktualisieren"
                MinWidth="120"
                Height="30"
                Margin="0,21,0,0"
                Padding="12,4"/>
        </Grid>

        <!-- Chart -->
        <Border
            Grid.Row="1"
            BorderBrush="#FFD0D0D0"
            BorderThickness="1"
            CornerRadius="3"
            Padding="10">

            <lvc:CartesianChart
                x:Name="Chart"
                Series="{Binding Series}"
                XAxes="{Binding XAxes}"
                YAxes="{Binding YAxes}"
                LegendPosition="Bottom"/>
        </Border>

        <!-- Kennzahlen -->
        <Grid Grid.Row="2" Margin="0,15,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
<StackPanel Grid.Column="0">
    <TextBlock
        Text="Aktuell"
        HorizontalAlignment="Center"
        FontWeight="SemiBold"/>

    <TextBlock
        Text="{Binding CurrentValueText}"
        HorizontalAlignment="Center"
        Margin="0,4,0,0"
        FontSize="16"/>
</StackPanel>
            <StackPanel Grid.Column="1">
                <TextBlock
                    Text="Minimum"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding MinimumValueText}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>
            </StackPanel>

            <StackPanel Grid.Column="2">
                <TextBlock
                    Text="Maximum"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding MaximumValueText}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>
            </StackPanel>

            <StackPanel Grid.Column="3">
                <TextBlock
                    Text="Durchschnitt"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding AverageValueText}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>
            </StackPanel>

            <StackPanel Grid.Column="4">
                <TextBlock
                    Text="Messpunkte"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding PointCountText}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>
            </StackPanel>
        </Grid>

        <!-- Status -->
        <TextBlock
            x:Name="TB_Status"
            Grid.Row="3"
            Margin="0,12,0,0"
            Foreground="DarkSlateGray"
            TextWrapping="Wrap"/>
    </Grid>
</Window>
"@

    $XmlReader = [System.Xml.XmlReader]::Create(
        (New-Object System.IO.StringReader($Xaml))
    )

    try {
        $Window = [System.Windows.Markup.XamlReader]::Load($XmlReader)
        $Chart = $Window.FindName("Chart")
    }
    finally {
        if ($null -ne $XmlReader) {
            $XmlReader.Dispose()
        }
    }

$CB_Port            = $Window.FindName('CB_Port')
$CHK_ComparisonMode = $Window.FindName('CHK_ComparisonMode')
$LB_ComparisonPorts = $Window.FindName('LB_ComparisonPorts')

$CB_Metric          = $Window.FindName('CB_Metric')
$CB_TimeRange       = $Window.FindName('CB_TimeRange')
$BTN_Refresh        = $Window.FindName('BTN_Refresh')
$TB_Status          = $Window.FindName('TB_Status')

$RequiredControls = @{
    CB_Port            = $CB_Port
    CHK_ComparisonMode = $CHK_ComparisonMode
    LB_ComparisonPorts = $LB_ComparisonPorts
    CB_Metric          = $CB_Metric
    CB_TimeRange       = $CB_TimeRange
    BTN_Refresh        = $BTN_Refresh
    TB_Status          = $TB_Status
}

    foreach ($ControlName in $RequiredControls.Keys) {
        if ($null -eq $RequiredControls[$ControlName]) {
            throw "Das benötigte Control '$ControlName' wurde im XAML nicht gefunden."
        }
    }

$Initialized = Initialize-StorageSFPHistoryView `
    -CustomerNbr $CustomerNbr `
    -ViewRoot $Window `
    -PortComboBox $CB_Port `
    -ComparisonCheckBox $CHK_ComparisonMode `
    -ComparisonListBox $LB_ComparisonPorts `
    -MetricComboBox $CB_Metric `
    -TimeRangeComboBox $CB_TimeRange `
    -StatusTextBlock $TB_Status `
    -RefreshButton $BTN_Refresh

    if (-not $Initialized) {
        return
    }

    $Window.ShowDialog() | Out-Null
}