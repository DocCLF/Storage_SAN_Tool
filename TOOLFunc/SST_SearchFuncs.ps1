function Get-VisualChildren {
    param(
        [Parameter(Mandatory)] $Parent,
        [type] $Type = [System.Windows.Controls.DataGrid]
    )

    if ($null -eq $Parent) {
        return
    }

    $GetVisualChildrenFunc = ${function:Get-VisualChildren}

    $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent)

    for ($i = 0; $i -lt $count; $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $i)

        if ($child -is $Type) {
            $child
        }

        & $GetVisualChildrenFunc -Parent $child -Type $Type
    }
}

function Get-ValueByBindingPath {
    param(
        [Parameter(Mandatory)] $Item,
        [Parameter(Mandatory)] [string] $Path
    )

    if ($null -eq $Item -or [string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $current = $Item

    foreach ($part in $Path.Split('.')) {
        if ($null -eq $current) {
            return $null
        }

        if ($current -is [System.Collections.IDictionary]) {
            if ($current.Contains($part)) {
                $current = $current[$part]
                continue
            }

            return $null
        }

        $psObj = [System.Management.Automation.PSObject]::AsPSObject($current)

        $prop = $null
        foreach ($p in $psObj.Properties) {
            if ($p.Name -eq $part) {
                $prop = $p
                break
            }
        }

        if ($null -ne $prop) {
            $current = $prop.Value
            continue
        }

        $descriptor = [System.ComponentModel.TypeDescriptor]::GetProperties($current)[$part]

        if ($null -ne $descriptor) {
            $current = $descriptor.GetValue($current)
            continue
        }

        $netProp = $current.GetType().GetProperty($part)

        if ($null -ne $netProp) {
            $current = $netProp.GetValue($current, $null)
            continue
        }

        return $null
    }

    return $current
}

function Get-SearchableRowText {
    param(
        [Parameter(Mandatory)] $Item,
        [Parameter(Mandatory)] [System.Windows.Controls.DataGrid] $DataGrid
    )

    $GetValueByBindingPathFunc = ${function:Get-ValueByBindingPath}

    $values = New-Object System.Collections.Generic.List[string]

    foreach ($col in $DataGrid.Columns) {
        if ($col -is [System.Windows.Controls.DataGridBoundColumn]) {
            $binding = $col.Binding

            if ($null -ne $binding -and $null -ne $binding.Path) {
                $path = $binding.Path.Path

                if (-not [string]::IsNullOrWhiteSpace($path)) {
                    $value = & $GetValueByBindingPathFunc -Item $Item -Path $path

                    if ($null -ne $value) {
                        [void]$values.Add([string]$value)
                    }
                }
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

    if ($null -eq $DataGrid.ItemsSource) {
        return
    }

    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($DataGrid.ItemsSource)

    if ($null -eq $view) {
        return
    }

    # Important for WPF/CollectionView scopes:
    # Include the helper function in the closure as a ScriptBlock reference.
    $GetSearchableRowTextFunc = ${function:Get-SearchableRowText}

    $dg = $DataGrid
    $tb = $SearchBox

    $view.Filter = [Predicate[object]] {
        param($row)

        $search = $tb.Text

        if ([string]::IsNullOrWhiteSpace($search)) {
            return $true
        }

        $rowText = & $GetSearchableRowTextFunc -Item $row -DataGrid $dg

        # Debug optional:
        # Write-Host "FILTER ROWTYPE: $($row.GetType().FullName)" -ForegroundColor Cyan
        # Write-Host "FILTER ROWTEXT: $rowText" -ForegroundColor Yellow

        if ([string]::IsNullOrWhiteSpace($rowText)) {
            return $false
        }

        $rowTextLower = $rowText.ToLowerInvariant()

        $terms = $search.ToLowerInvariant().Split(
            [char[]]" `t`r`n",
            [System.StringSplitOptions]::RemoveEmptyEntries
        )

        foreach ($term in $terms) {
            if (-not $rowTextLower.Contains($term)) {
                return $false
            }
        }

        return $true
    }.GetNewClosure()
}

function Update-GlobalDataGridSearchFilter {
    param(
        [Parameter(Mandatory)] $RootControl,
        [Parameter(Mandatory)] [System.Windows.Controls.TextBox] $SearchBox
    )

    # Important for WPF event scope:
    # Use these helper functions as ScriptBlock references as well.
    $GetVisualChildrenFunc       = ${function:Get-VisualChildren}
    $SetDataGridSearchFilterFunc = ${function:Set-DataGridSearchFilter}

    $dataGrids = & $GetVisualChildrenFunc -Parent $RootControl -Type ([System.Windows.Controls.DataGrid])

    foreach ($dg in $dataGrids) {
        if ($null -eq $dg.ItemsSource) {
            continue
        }

        & $SetDataGridSearchFilterFunc -DataGrid $dg -SearchBox $SearchBox

        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($dg.ItemsSource)

        if ($null -ne $view) {
            $view.Refresh()
        }
    }
}

function Initialize-GlobalDataGridSearch {
    param(
        [Parameter(Mandatory)] $RootControl,
        [Parameter(Mandatory)] [System.Windows.Controls.TextBox] $SearchBox
    )

    $SearchButton = $RootControl.FindName("BTN_GlobalGridSearch")
    $ClearButton  = $RootControl.FindName("BTN_GlobalGridSearchClear")

    # Important for WPF event scope:
    # Include the function as a ScriptBlock in the closure.
    $UpdateGlobalGridFilterFunc = ${function:Update-GlobalDataGridSearchFilter}

    $SearchBox.Add_KeyDown({
        param($sender, $e)

        if ($e.Key -eq [System.Windows.Input.Key]::Enter) {
            & $UpdateGlobalGridFilterFunc -RootControl $RootControl -SearchBox $SearchBox
        }
    }.GetNewClosure())

    if ($null -ne $SearchButton) {
        $SearchButton.Add_Click({
            & $UpdateGlobalGridFilterFunc -RootControl $RootControl -SearchBox $SearchBox
        }.GetNewClosure())
    }

    if ($null -ne $ClearButton) {
        $ClearButton.Add_Click({
            $SearchBox.Text = ""
            & $UpdateGlobalGridFilterFunc -RootControl $RootControl -SearchBox $SearchBox
        }.GetNewClosure())
    }
}
