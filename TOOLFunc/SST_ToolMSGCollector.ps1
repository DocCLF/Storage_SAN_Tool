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
        [string]$TD_Shown 
    )
    <# Create a DateTime for each entry #>
    $TD_GetMSGDate = Get-Date -Format "dd/MM/yyy HH:mm:ss"
    $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
    <# Get to "old MSG" in a Var #>
    $TD_OldMSG = $TD_dg_ToolWindowForDebug.ItemsSource
    [array]$TD_MSG_GUIpresenter = $TD_OldMSG

    $TD_MSGpresenter = "" | Select-Object TimeStamp,Type,Message
    $TD_MSGpresenter.TimeStamp = $TD_GetMSGDate
    $TD_MSGpresenter.Type = $TD_ToolMSGType
    $TD_MSGpresenter.Message = $TD_ToolMSGCollector

    [array]$TD_MSG_GUIpresenter += $TD_MSGpresenter |Sort-Object
    <#present all msg #>
    switch ($TD_Shown) {
        "no" { Write-Debug -Message $TD_ToolMSGCollector `n$TD_ToolMSGType }
        "yes" { $TD_dg_ToolWindowForDebug.ItemsSource = $TD_MSG_GUIpresenter }
        #"export" { Out-File -FilePath $PSRootPath\ToolLog\SST_$($TD_GetMSGDate) -InputObject $TD_ToolMSGCollector -Append }
        Default {$TD_dg_ToolWindowForDebug.ItemsSource = $TD_MSG_GUIpresenter}
    }

    <# Example: Get-Date -UFormat "%d%m%Y" - Res: 14012025 #>
    Out-File -FilePath $PSRootPath\ToolLog\SST_$(Get-Date -UFormat "%d%m%Y") -InputObject $TD_MSGpresenter -Append
    
    #$TD_tb_ToolWindowForDebug.Text = $TD_MSG_GUIpresenter
    # the following line as switch case with the different options red,yellow etc.
    #$TD_tb_ToolWindowForDebug.Foreground="Red"
    <# refresh the gui #>
    $TD_UserControl4.Dispatcher.Invoke([System.Action]{},"Render")

}