function SST_DashBoardRefreshData {
    [CmdletBinding()]
    param (
        $Device,
        $ExportPath
    )
    $TD_TB_ALLHostCount.Text = "0"
    $TD_TB_ALLHostCount.Foreground = "red"

    <# for the first Time we use the JobMode func #>
    try {
        SST_JobMode -SecData $Device
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning -TD_Shown yes
    }
    
    try {
        Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc HMC_RESTHMCConsole
    }
    catch {
        <#Do this if a terminating exception happens#>
        SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning -TD_Shown yes
    }
}