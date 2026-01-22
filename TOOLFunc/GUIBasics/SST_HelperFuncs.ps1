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

# REST/SSH-Fallback + DeviceBlock-Erstellung zentralisieren
# Helper-Funktion, die pro Device die Daten holt (REST, sonst SSH) und dir direkt einen DeviceToggle zurückgibt.
function New-DeviceBlock {
    param(
        [Parameter(Mandatory)]
        $Device,
        [string]$ExportPath,
        [object]$RESTFunc,
        [object]$SSHFunc
    )

    $FunResult = $null
    [bool]$FallbacktoSSH = $false
    # 1) Daten holen (REST -> wenn leer -> SSH) StorageInfo
    $pw = [Net.NetworkCredential]::new('', $Device.Password).Password
    if($RESTFunc){
        $FunResult = & $RESTFunc -TD_Line_ID $Device.ID -TD_Device_UserName $Device.UserName -TD_Device_DeviceIP $Device.IPAddress -TD_Device_PW $pw -TD_Exportpath $ExportPath

        $items = @($FunResult)  # normalisiert null/single/multi

        if ($items.Count -eq 0) {
            $FallbacktoSSH = $true
        }
        # optional: wenn es wirklich ein "Einzelobjekt mit StorageInfo" ist:
        elseif ($items.Count -eq 1 -and ($items[0].PSObject.Properties.Name -contains 'StorageInfo')) {
            if ($null -eq $items[0].StorageInfo -or [string]::IsNullOrWhiteSpace([string]$items[0].StorageInfo.ID)) {
                $FallbacktoSSH = $true
            }
        }
    }else{
        $FallbacktoSSH = $true
    }
     
    if ($FallbacktoSSH) {
        $FunResult = & $SSHFunc -TD_Line_ID $Device.ID -TD_Device_ConnectionTyp $Device.ConnectionTyp -TD_Device_UserName $Device.UserName -TD_Device_DeviceIP $Device.IPAddress -TD_Device_PW $pw -TD_Exportpath $ExportPath
    }
    # 2) DeviceToggle bauen
    $DeviceIdent = [DeviceToggle]::new()
    $DeviceIdent.Id = "DeviceBlock$($Device.ID)"
    # Label robust: ClusterName kann je nach Result-Shape anders sein
    $cluster = $FunResult.ClusterName
    $DeviceIdent.Label = if ([string]::IsNullOrWhiteSpace([string]$cluster)) { "$($Device.IPAddress)" } else { "$cluster" }
    $DeviceIdent.IsChecked = $false
    return @{ DeviceIdent = $DeviceIdent; FuncResult = $FunResult }
}

#c&p need for doubel view, is a bit diff as New-devBlock
function RestThenSshForCombiView {
    param(
        [Parameter(Mandatory)]
        $Device,
        [string]$ExportPath,
        [Parameter(Mandatory)]
        [object]$RESTFunc,
        [Parameter(Mandatory)]
        [object]$SSHFunc
    )

    [bool]$FallbacktoSSH = $false
    # 1) Daten holen (REST -> wenn leer -> SSH) StorageInfo
    $pw = [Net.NetworkCredential]::new('', $Device.Password).Password
    
    $FunResult = & $RESTFunc -TD_Line_ID $Device.ID -TD_Device_UserName $Device.UserName -TD_Device_DeviceIP $Device.IPAddress -TD_Device_PW $pw -TD_Exportpath $ExportPath
    
    $items = @($FunResult)  # normalisiert null/single/multi

    if ($items.Count -eq 0) {
        $FallbacktoSSH = $true
    }
    # optional: wenn es wirklich ein "Einzelobjekt mit StorageInfo" ist:
    elseif ($items.Count -eq 1 -and ($items[0].PSObject.Properties.Name -contains 'StorageInfo')) {
        if ($null -eq $items[0].StorageInfo -or [string]::IsNullOrWhiteSpace([string]$items[0].StorageInfo.ID)) {
            $FallbacktoSSH = $true
        }
    }
   
    if ($FallbacktoSSH) {
        $FunResult = & $SSHFunc -TD_Line_ID $Device.ID -TD_Device_ConnectionTyp $Device.ConnectionTyp -TD_Device_UserName $Device.UserName -TD_Device_DeviceIP $Device.IPAddress -TD_Device_PW $pw -TD_Exportpath $ExportPath
    }
    
    return $FunResult
}

# Generischer Mapper: Add-Rows
function Add-MappedRows {
    param(
        [Parameter(Mandatory)] $Collection,
        [Parameter(Mandatory)] $Source,
        [Parameter(Mandatory)] [string] $IdProperty,
        [Parameter(Mandatory)] [hashtable] $Map
    )

    foreach ($s in @($Source)) {
        $id = $s.$IdProperty
        if ([string]::IsNullOrWhiteSpace([string]$id)) { continue }
        
        $h = @{}
        foreach ($k in $Map.Keys) {
            $h[$k] = [string]$s.($Map[$k])
        }
        $Collection.Add([pscustomobject]$h) | Out-Null
    }
}

# SpectrumTimestamp
function Convert-SpectrumTimestamp {
    param(
        [Parameter(Mandatory)]
        [string]$Timestamp
    )

    return [datetime]::ParseExact(
        $Timestamp,
        "yyMMddHHmmss",
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}