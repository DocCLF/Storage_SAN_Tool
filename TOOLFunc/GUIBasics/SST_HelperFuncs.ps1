function Get-ParentUserControl {
    param([System.Windows.DependencyObject]$control)

    $parent = $control
    while ($parent) {
        if ($parent -is [System.Windows.Controls.UserControl]) {
            
            return $parent
        }
        $parent = [System.Windows.Media.VisualTreeHelper]::GetParent($parent)
    }

    return $null  
}

function Get-VisualDescendants {
    param(
        [Parameter(Mandatory)]
        [System.Windows.DependencyObject]$Root
    )

    $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Root)
    for ($i = 0; $i -lt $count; $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Root, $i)
        if ($child) {
            $child
            foreach ($d in Get-VisualDescendants -Root $child) { $d }
        }
    }
}