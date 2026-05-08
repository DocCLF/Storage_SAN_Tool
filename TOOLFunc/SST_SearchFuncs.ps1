function Get-VisualChildren {
    param(
        [Parameter(Mandatory)] $Parent,
        [type] $Type = [System.Windows.Controls.DataGrid]
    )

    $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent)

    for ($i = 0; $i -lt $count; $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $i)

        if ($child -is $Type) {
            $child
        }

        Get-VisualChildren -Parent $child -Type $Type
    }
}

function Get-SearchableRowText {
    param($Item)

    if ($null -eq $Item) { return "" }

    $values = New-Object System.Collections.Generic.List[string]

    $psObj = [System.Management.Automation.PSObject]::AsPSObject($Item)

    foreach ($prop in $psObj.Properties) {
        if ($prop.MemberType -in 'NoteProperty','Property','AliasProperty') {
            if ($null -ne $prop.Value) {
                [void]$values.Add([string]$prop.Value)
            }
        }
    }

    return ($values -join " ")
}

function Set-DataGridSearchFilter {
    param(
        [Parameter(Mandatory)] [System.Windows.Controls.DataGrid] $DataGrid,
        [Parameter(Mandatory)] [System.Windows.Controls.TextBox] $SearchBox
    )

    if ($null -eq $DataGrid.ItemsSource) { return }

    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($DataGrid.ItemsSource)
    if ($null -eq $view) { return }

    $view.Filter = [Predicate[object]] {
        param($row)

        $search = $SearchBox.Text

        if ([string]::IsNullOrWhiteSpace($search)) {
            return $true
        }

        $rowText = (Get-SearchableRowText -Item $row).ToLowerInvariant()
        $terms = $search.ToLowerInvariant().Split(
            [char[]]" `t`r`n",
            [System.StringSplitOptions]::RemoveEmptyEntries
        )

        foreach ($term in $terms) {
            if (-not $rowText.Contains($term)) {
                return $false
            }
        }

        return $true
    }
}

function Initialize-GlobalDataGridSearch {
    param(
        [Parameter(Mandatory)] $RootControl,
        [Parameter(Mandatory)] [System.Windows.Controls.TextBox] $SearchBox
    )

    $applyFilter = {
        $dataGrids = Get-VisualChildren -Parent $RootControl -Type ([System.Windows.Controls.DataGrid])

        foreach ($dg in $dataGrids) {
            Set-DataGridSearchFilter -DataGrid $dg -SearchBox $SearchBox

            if ($null -ne $dg.ItemsSource) {
                $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($dg.ItemsSource)
                if ($null -ne $view) {
                    $view.Refresh()
                }
            }
        }
    }.GetNewClosure()

    $RootControl.Add_Loaded({
        & $applyFilter
    }.GetNewClosure())

    $SearchBox.Add_TextChanged({
        & $applyFilter
    }.GetNewClosure())
}