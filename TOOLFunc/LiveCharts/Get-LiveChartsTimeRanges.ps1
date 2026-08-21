function Get-LiveChartsTimeRanges {
    <#
    .SYNOPSIS
        Returns predefined time ranges for LiveCharts history views.

    .DESCRIPTION
        Provides reusable time-range definitions including duration,
        date-time label format and minimum axis step.

        Provides reusable time-range definitions for LiveCharts history
        views.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        $TimeRanges = Get-LiveChartsTimeRanges
    #>

    [CmdletBinding()]
    param()

    # Marks the default time range.
    @(
        [PSCustomObject]@{
            Key          = 'LastHour'
            DisplayName  = 'Letzte Stunde'
            Duration     = [TimeSpan]::FromHours(1)
            LabelFormat  = 'HH:mm:ss'
            DateTimeStep = [TimeSpan]::FromMinutes(10)
            Default      = $false
        }

        [PSCustomObject]@{
            Key          = 'Last6Hours'
            DisplayName  = 'Letzte 6 Stunden'
            Duration     = [TimeSpan]::FromHours(6)
            LabelFormat  = 'HH:mm'
            DateTimeStep = [TimeSpan]::FromHours(1)
            Default      = $false
        }

        [PSCustomObject]@{
            Key          = 'Last12Hours'
            DisplayName  = 'Letzte 12 Stunden'
            Duration     = [TimeSpan]::FromHours(12)
            LabelFormat  = 'HH:mm'
            DateTimeStep = [TimeSpan]::FromHours(1)
            Default      = $false
        }

        [PSCustomObject]@{
            Key          = 'Last24Hours'
            DisplayName  = 'Letzte 24 Stunden'
            Duration     = [TimeSpan]::FromHours(24)
            LabelFormat  = 'HH:mm'
            DateTimeStep = [TimeSpan]::FromHours(2)
            Default      = $true
        }

        [PSCustomObject]@{
            Key          = 'Last7Days'
            DisplayName  = 'Letzte 7 Tage'
            Duration     = [TimeSpan]::FromDays(7)
            LabelFormat  = 'dd.MM. HH:mm'
            DateTimeStep = [TimeSpan]::FromDays(1)
            Default      = $false
        }

        [PSCustomObject]@{
            Key          = 'Last30Days'
            DisplayName  = 'Letzte 30 Tage'
            Duration     = [TimeSpan]::FromDays(30)
            LabelFormat  = 'dd.MM.'
            DateTimeStep = [TimeSpan]::FromDays(5)
            Default      = $false
        }

        [PSCustomObject]@{
            Key          = 'Last365Days'
            DisplayName  = 'Letzte 365 Tage'
            Duration     = [TimeSpan]::FromDays(365)
            LabelFormat  = 'MM.yyyy'
            DateTimeStep = [TimeSpan]::FromDays(30)
            Default      = $false
        }
    )
}