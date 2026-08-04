function SST_PRISMLocalDataCheck {
     [CmdletBinding()]
    param (
        $PSRootPath
    )
    try {
        return [bool](
            SST_ToolAdvSaveDB -SST_InfoType 'HasData'
        )
    }catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "Checking local PRISM settings failed: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown no

        return $false
    }
}