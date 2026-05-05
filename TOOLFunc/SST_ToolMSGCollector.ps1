function SST_ToolMessageCollector {
    <#
    .SYNOPSIS
        Collects all essential information and presents it in the log window and/or in the respective log files.
    .NOTES
        v1.0
        Release Version
        Currently only usable with wpf and a textbox with the name $TD_tb_ToolWindowForDebug
    .LINK
        https://github.com/DocCLF/ps_collection/blob/main/SSK_ToolMessageCollector.ps1
    .EXAMPLE
        TD_ToolMessageCollector -TD_ToolMSGCollector $("IP in row $STP_ID is not validate or set.")
    .EXAMPLE
        tbt
    #>
    [CmdletBinding()]
    param (
        $TD_ToolMSGCollector,
        [Parameter(ValueFromPipeline,HelpMessage="Enter Error, Warning or Message to be able to categorize the message correctly in the GUI and in the log files.")]
        [ValidateSet("Error","Warning","Message","Debug")]
        $TD_ToolMSGType ="Message",
        [Parameter(ValueFromPipeline,HelpMessage="Some displays may be too complex to be displayed in a meaningful way.")]
        [ValidateSet("yes","no")]
        [string]$TD_Shown ="yes"
    )
    <# Create a DateTime for each entry #>
    $TD_GetMSGDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    $PSRootPath = Split-Path -Path $PSScriptRoot -Parent

    $TD_MSGpresenter = [PSCustomObject]@{
        TimeStamp = $TD_GetMSGDate
        Type      = $TD_ToolMSGType
        Message   = $TD_ToolMSGCollector
    }

    $TD_OldMSG = @()

    if ($null -ne $TD_DG_ToolEventsWindow.ItemsSource) {
        $TD_OldMSG = @($TD_DG_ToolEventsWindow.ItemsSource) |
            Where-Object { $null -ne $_ }
    }

    $TD_MSG_GUIpresenter = @($TD_MSGpresenter) + @($TD_OldMSG)

    $TD_DG_ToolEventsWindow.ItemsSource = $TD_MSG_GUIpresenter
    <#present all msg #> 
    switch ($TD_Shown) {
        "no" { Write-Debug -Message "$TD_ToolMSGCollector $TD_ToolMSGType" }
        "yes" { $TD_DG_ToolEventsWindow.ItemsSource = $TD_MSG_GUIpresenter }
        Default {$TD_DG_ToolEventsWindow.ItemsSource = $TD_MSG_GUIpresenter}
    }

    <# Example: Get-Date -UFormat "%d%m%Y" - Res: 14012025 #>
    Out-File -FilePath $PSRootPath\ToolLog\SST_$(Get-Date -UFormat "%d%m%Y").log -InputObject $TD_MSGpresenter -Append -Width 1000
 

}