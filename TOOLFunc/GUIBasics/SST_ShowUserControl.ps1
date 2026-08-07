function SST_ShowUserControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$MainWindowArea,
        [Parameter(Mandatory)]$ShowUserControl,
        [Parameter(Mandatory)]$AllUserControls,
        $SST_UCOBJChild = $null
    )

    if (-not $ShowUserControl.IsLoaded) {
        $MainWindowArea.Children.Add($ShowUserControl)
        #SST_ShowDeviceSelection -SST_UCOBJ $ShowUserControl
    }

    foreach ($UserControl in $AllUserControls) {
        if ($UserControl -ne $ShowUserControl) {
            $MainWindowArea.Children.Remove($UserControl) | Out-Null
            #$SST_STPinUCOBJ = Get-VisualDescendants -Root $UserControl | Where-Object { $_ -is [System.Windows.Controls.StackPanel] }
            #$SST_UCOBJChild = $SST_STPinUCOBJ.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "CB_SelectAll*CB" }
            #if(!($null -eq $SST_UCOBJChild)){
            #    $SST_UCOBJChild.IsChecked = $false
            #}
        }
    }
}
