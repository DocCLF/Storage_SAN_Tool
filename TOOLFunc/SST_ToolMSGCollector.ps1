function SST_ToolMessageCollector {
    <#
    .SYNOPSIS
        Collects all essential information and presents it in the log window and/or in the respective log files.
    .NOTES
        v1.1
        Added automatic cleanup for log files older than 90 days.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, HelpMessage="Here you can enter the message you want to be displayed.")]
        $TD_ToolMSGCollector,

        [Parameter(ValueFromPipeline, HelpMessage="Enter Error, Warning or Message to be able to categorize the message correctly in the GUI and in the log files.")]
        [ValidateSet("Error","Warning","Message","Debug")]
        $TD_ToolMSGType = "Message",

        [Parameter(ValueFromPipeline, HelpMessage="Some displays may be too complex to be displayed in a meaningful way.")]
        [ValidateSet("yes","no")]
        [string]$TD_Shown = "yes"
    )

    $TD_GetMSGDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
    $LogFolder = Join-Path $PSRootPath "ToolLog"
    $LogFile = Join-Path $LogFolder "SST_$(Get-Date -UFormat '%d%m%Y').log"

    if(-not (Test-Path $LogFolder)){
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }

    <# Log cleanup only once per day #>
    $CleanupMarker = Join-Path $LogFolder "cleanup.marker"
    $DoCleanup = $true

    if(Test-Path $CleanupMarker){
        $LastCleanup = Get-Item $CleanupMarker

        if($LastCleanup.LastWriteTime.Date -eq (Get-Date).Date){
            $DoCleanup = $false
        }
    }

    if($DoCleanup){
        $DeletedLogs = @(Get-ChildItem -Path $LogFolder -Filter "SST_*.log" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) })

        $DeletedCount = $DeletedLogs.Count

        if($DeletedCount -gt 0){
            $DeletedLogs | Remove-Item -Force

            $CleanupMessage = [PSCustomObject]@{
                TimeStamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
                Type      = "Message"
                Message   = "Log cleanup completed. Deleted $DeletedCount log file(s) older than 90 days."
            }

            Out-File -FilePath $LogFile -InputObject $CleanupMessage -Append -Width 1000
        }

        New-Item -Path $CleanupMarker -ItemType File -Force | Out-Null
    }
    <# MSG Collector export and gui #>
    $TD_MSGpresenter = [PSCustomObject]@{
        TimeStamp = $TD_GetMSGDate
        Type      = $TD_ToolMSGType
        Message   = $TD_ToolMSGCollector
    }

    $TD_OldMSG = @()

    if($null -ne $TD_DG_ToolEventsWindow.ItemsSource){
        $TD_OldMSG = @($TD_DG_ToolEventsWindow.ItemsSource) |
            Where-Object { $null -ne $_ }
    }

    $TD_MSG_GUIpresenter = @($TD_MSGpresenter) + @($TD_OldMSG)

    switch ($TD_Shown) {
        "no" {
            Write-Debug -Message "$TD_ToolMSGCollector $TD_ToolMSGType"
        }
        "yes" {
            $TD_DG_ToolEventsWindow.ItemsSource = $TD_MSG_GUIpresenter
        }
        Default {
            $TD_DG_ToolEventsWindow.ItemsSource = $TD_MSG_GUIpresenter
        }
    }

    Out-File -FilePath $LogFile -InputObject $TD_MSGpresenter -Append -Width 1000
}