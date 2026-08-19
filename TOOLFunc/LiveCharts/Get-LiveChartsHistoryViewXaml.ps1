function Get-LiveChartsHistoryViewXaml {
    <#
    .SYNOPSIS
        Returns the common XAML layout for LiveCharts history viewers.

    .DESCRIPTION
        Creates the shared WPF layout used by history viewers.

        The XAML is independent of the underlying data source.

        The right selector area supports three generic selection levels:

            Source Groups
                e.g. Storage systems

            Sources
                e.g. Volumes, Pools or Ports

            Series
                e.g. Capacity, RX Power or Temperature

        Application-specific text such as the window title and source label
        is supplied through parameters.

    .PARAMETER WindowTitle
        Title of the history window.

    .PARAMETER SourceLabel
        Label shown above the legacy source selection control.

    .OUTPUTS
        System.String
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$WindowTitle,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceLabel,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SourceGroupLabel = 'Storage Systems'
    )

    return @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:lvc="clr-namespace:LiveChartsCore.SkiaSharpView.WPF;assembly=LiveChartsCore.SkiaSharpView.WPF"
    Title="$WindowTitle"
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

        <!-- ============================================================= -->
        <!-- Top selection area                                            -->
        <!-- ============================================================= -->

        <Grid
            Grid.Row="0"
            Margin="0,0,0,15">

            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="2*"/>
                <ColumnDefinition Width="1.3*"/>
                <ColumnDefinition Width="1.2*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <!-- Legacy source selection.
                 Still present for viewers that currently use it.
                 The new Volume viewer collapses these controls. -->

            <StackPanel
                Grid.Column="0"
                Margin="0,0,10,0">

                <Grid Margin="0,0,0,4">

                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <TextBlock
                        Grid.Column="0"
                        Text="$SourceLabel"
                        Style="{DynamicResource DashBoardTB1}"
                        VerticalAlignment="Center"
                        FontWeight="SemiBold"/>

                    <CheckBox
                        Grid.Column="1"
                        x:Name="CHK_ComparisonMode"
                        Style="{DynamicResource MainCheckBoxStyle}"
                        Content="Vergleich"
                        Margin="12,0,0,0"
                        VerticalAlignment="Center"/>
                </Grid>

                <ComboBox
                    x:Name="CB_Source"
                    Style="{DynamicResource MainComboBoxStyle}"
                    MinWidth="300"
                    DisplayMemberPath="DisplayName"/>

                <ListBox
                    x:Name="LB_ComparisonSources"
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

            <!-- Preset -->

            <StackPanel
                Grid.Column="1"
                Margin="0,0,10,0">

                <TextBlock
                    Text="Messwert"
                    Style="{DynamicResource DashBoardTB1}"
                    Margin="0,0,0,4"
                    FontWeight="SemiBold"/>

                <ComboBox
                    x:Name="CB_Metric"
                    Style="{DynamicResource MainComboBoxStyle}"
                    MinWidth="180"
                    DisplayMemberPath="DisplayName"/>

            </StackPanel>

            <!-- Time range -->

            <StackPanel
                Grid.Column="2"
                Margin="0,0,10,0">

                <TextBlock
                    Text="Zeitraum"
                    Style="{DynamicResource DashBoardTB1}"
                    Margin="0,0,0,4"
                    FontWeight="SemiBold"/>

                <ComboBox
                    x:Name="CB_TimeRange"
                    Style="{DynamicResource MainComboBoxStyle}"
                    MinWidth="160"
                    DisplayMemberPath="DisplayName"/>

            </StackPanel>

            <!-- Refresh -->

            <ToggleButton
                x:Name="BTN_Refresh"
                Style="{DynamicResource MainBtnStyle}"
                Grid.Column="3"
                Content="Refresh"
                MinWidth="120"
                Height="30"
                Margin="0,21,0,0"
                Padding="12,4"/>

        </Grid>

        <!-- ============================================================= -->
        <!-- Chart + generic selectors                                     -->
        <!-- ============================================================= -->

        <Grid Grid.Row="1">

            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="auto"/>
            </Grid.ColumnDefinitions>

            <!-- ========================================================= -->
            <!-- Chart                                                     -->
            <!-- ========================================================= -->

            <Border
                Grid.Column="0"
                BorderBrush="#FFD0D0D0"
                BorderThickness="1"
                CornerRadius="3"
                Padding="10"
                Margin="0,0,10,0">

                <lvc:CartesianChart
                    x:Name="Chart"
                    Series="{Binding Series}"
                    XAxes="{Binding XAxes}"
                    YAxes="{Binding YAxes}"
                    LegendPosition="Bottom"
                    ZoomMode="X"
                    ZoomingSpeed="0.2"/>

            </Border>

            <!-- ========================================================= -->
            <!-- Generic selectors                                         -->
            <!-- ========================================================= -->

            <Border
                Grid.Column="1"
                BorderBrush="#FFD0D0D0"
                BorderThickness="1"
                CornerRadius="3"
                Padding="10">

                <Grid>

                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <!-- ================================================= -->
                    <!-- Source Groups / Storage Systems                   -->
                    <!-- ================================================= -->

                    <StackPanel
                        x:Name="SP_SourceGroupSelector"
                        Grid.Row="0"
                        Margin="0,0,0,8">

                        <TextBlock
                            Text="$SourceGroupLabel"
                            FontWeight="SemiBold"
                            FontSize="14"
                            Margin="0,0,0,8"/>

                        <ListBox
                            x:Name="LB_SourceGroupSelector"
                            BorderThickness="0"
                            Background="Transparent"
                            MaxHeight="100"
                            ScrollViewer.VerticalScrollBarVisibility="Auto"
                            ScrollViewer.HorizontalScrollBarVisibility="Disabled">

                            <ListBox.ItemTemplate>
                                <DataTemplate>

                                    <CheckBox
                                        Content="{Binding DisplayName}"
                                        IsChecked="{Binding IsSelected, Mode=TwoWay}"
                                        IsEnabled="{Binding IsEnabled}"
                                        Margin="2,3"/>

                                </DataTemplate>
                            </ListBox.ItemTemplate>

                        </ListBox>

                        <Separator
                            Margin="0,8,0,0"/>

                    </StackPanel>

                    <!-- ================================================= -->
                    <!-- Sources                                           -->
                    <!-- ================================================= -->

                    <Grid Grid.Row="1">

                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock
                            Grid.Row="0"
                            Text="Sources"
                            FontWeight="SemiBold"
                            FontSize="14"
                            Margin="0,0,0,8"/>

                        <ListBox
                            x:Name="LB_SourceSelector"
                            Grid.Row="1"
                            BorderThickness="0"
                            Background="Transparent"
                            ScrollViewer.VerticalScrollBarVisibility="Auto"
                            ScrollViewer.HorizontalScrollBarVisibility="Auto">

                            <ListBox.ItemTemplate>
                                <DataTemplate>

                                    <CheckBox
                                        Content="{Binding DisplayName}"
                                        IsChecked="{Binding IsSelected, Mode=TwoWay}"
                                        IsEnabled="{Binding IsEnabled}"
                                        Margin="2,3"/>

                                </DataTemplate>
                            </ListBox.ItemTemplate>

                        </ListBox>

                    </Grid>

                    <!-- ================================================= -->
                    <!-- Separator between Sources and Series              -->
                    <!-- ================================================= -->

                    <Separator
                        Grid.Row="2"
                        Margin="0,8"/>

                    <!-- ================================================= -->
                    <!-- Series                                            -->
                    <!-- ================================================= -->

                    <Grid Grid.Row="3">

                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock
                            Grid.Row="0"
                            Text="Series"
                            FontWeight="SemiBold"
                            FontSize="14"
                            Margin="0,0,0,8"/>

                        <ListBox
                            x:Name="LB_SeriesSelector"
                            Grid.Row="1"
                            BorderThickness="0"
                            Background="Transparent"
                            ScrollViewer.VerticalScrollBarVisibility="Auto">

                            <ListBox.ItemTemplate>
                                <DataTemplate>

                                    <CheckBox
                                        Content="{Binding DisplayName}"
                                        IsChecked="{Binding IsSelected, Mode=TwoWay}"
                                        IsEnabled="{Binding IsEnabled}"
                                        Margin="2,3"/>

                                </DataTemplate>
                            </ListBox.ItemTemplate>

                        </ListBox>

                    </Grid>

                </Grid>
            </Border>

        </Grid>

        <!-- ============================================================= -->
        <!-- Statistics                                                    -->
        <!-- ============================================================= -->

        <Grid
            Grid.Row="2"
            Margin="0,15,0,0">

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
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding CurrentValueText}"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>

            </StackPanel>

            <StackPanel Grid.Column="1">

                <TextBlock
                    Text="Minimum"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding MinimumValueText}"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>

            </StackPanel>

            <StackPanel Grid.Column="2">

                <TextBlock
                    Text="Maximum"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding MaximumValueText}"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>

            </StackPanel>

            <StackPanel Grid.Column="3">

                <TextBlock
                    Text="Durchschnitt"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding AverageValueText}"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>

            </StackPanel>

            <StackPanel Grid.Column="4">

                <TextBlock
                    Text="Messpunkte"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    FontWeight="SemiBold"/>

                <TextBlock
                    Text="{Binding PointCountText}"
                    Style="{DynamicResource DashBoardTB1}"
                    HorizontalAlignment="Center"
                    Margin="0,4,0,0"
                    FontSize="16"/>

            </StackPanel>

        </Grid>

        <!-- ============================================================= -->
        <!-- Status                                                        -->
        <!-- ============================================================= -->

        <TextBlock
            x:Name="TB_Status"
            Grid.Row="3"
            Margin="0,12,0,0"
            Foreground="DarkSlateGray"
            TextWrapping="Wrap"/>

    </Grid>
</Window>
"@
}