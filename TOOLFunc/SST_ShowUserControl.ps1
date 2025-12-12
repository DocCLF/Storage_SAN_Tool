function SST_ShowUserControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$MainWindowArea,
        [Parameter(Mandatory)]$ShowUserControl,
        [Parameter(Mandatory)]$AllUserControls
    )

    if (-not $ShowUserControl.IsLoaded) {
        $MainWindowArea.Children.Add($ShowUserControl)
    }

    foreach ($UserControl in $AllUserControls) {
        if ($UserControl -ne $ShowUserControl) {
            $MainWindowArea.Children.Remove($UserControl) | Out-Null
        }
    }
}
