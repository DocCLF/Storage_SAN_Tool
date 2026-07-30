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

#Fallback HelperFunc for using in DashBoard and New-DeviceBlock
function Invoke-DeviceDataFetch {
    param(
        [Parameter(Mandatory)] $Device,
        [string] $ExportPath,
        [object] $RESTFunc,
        [object] $SSHFunc
    )

    $FunResult = $null
    [bool]$FallbacktoSSH = $false
    $pw = [Net.NetworkCredential]::new('', $Device.Password).Password

    if($RESTFunc){
        try {
            <# It's okay for now, but we need a better solution #>
            if($Device.DeviceTyp -like "*SAN*"){
                $FunResult = & $RESTFunc -Device $Device
            }else{
                $FunResult = & $RESTFunc -TD_Line_ID $Device.ID -TD_Device_UserName $Device.UserName -TD_Device_DeviceIP $Device.IPAddress -TD_Device_PW $pw -TD_Exportpath $ExportPath
            }
        }
        catch {
            Write-Host $_.Exception.Message
        }

        $items = @($FunResult)

        if ($items.Count -eq 0) {
            $FallbacktoSSH = $true
        }
        elseif ($items.Count -eq 1 -and ($items[0].PSObject.Properties.Name -contains 'StorageInfo')) {
            if ($null -eq $items[0].StorageInfo -or [string]::IsNullOrWhiteSpace([string]$items[0].StorageInfo.ID)) {
                $FallbacktoSSH = $true
            }
        }
    }
    else {
        $FallbacktoSSH = $true
    }

    if ($FallbacktoSSH -and $SSHFunc) {
        try {
            $FunResult = & $SSHFunc -TD_Line_ID $Device.ID -TD_Device_ConnectionTyp $Device.ConnectionTyp -TD_Device_UserName $Device.UserName -TD_Device_DeviceIP $Device.IPAddress -TD_Device_PW $pw -TD_Exportpath $ExportPath
        }
        catch {
            Write-Host $_.Exception.Message
        }
    }
 
    return $FunResult
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

    $FunResult = @()

    try {
        $FunResult = Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc $RESTFunc -SSHFunc $SSHFunc
        if ($null -eq $FunResult) {$FunResult = @() }
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor DarkCyan
        SST_ToolMessageCollector -TD_ToolMSGCollector "Data fetch failed for $($Device.IPAddress): $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        $FunResult = @()
    }

    # 2) DeviceToggle bauen
    $DeviceIdent = [DeviceToggle]::new()
    $DeviceIdent.Id = "DeviceBlock$($Device.ID)"
    $LabelName = $null
    # Label robust: ClusterName kann je nach Result-Shape anders sein
    if ($RESTFunc -like "*Brocade*" -and $FunResult.PSObject.Properties.Name -contains 'SwitchName') {
        $LabelName = $FunResult.SwitchName
    }else {
        $LabelName = $FunResult.ClusterName
    }
    $DeviceIdent.Label = if ([string]::IsNullOrWhiteSpace([string]$LabelName)) { "$($Device.IPAddress)" } else { "$LabelName" }
    $DeviceIdent.IsChecked = $false

    return @{ DeviceIdent = $DeviceIdent; FuncResult = @($FunResult) }
}
# Helper Func for Reaad DB in GUi.ps1 Tape Area
function ReadDBandBuildDB{
    param(
        $Device,
        $SST_InfoType,
        $SST_Customer,
        $SST_AdditionalInformation,
        [object]$ReadDBFunc
    )
    
    $FunResult = & $ReadDBFunc -SST_InfoType $SST_InfoType -SST_Customer $SST_Customer -SST_NeededInformations $SST_AdditionalInformation
    $DeviceIdent = [DeviceToggle]::new()
    $DeviceIdent.Id = "DeviceBlock$($Device.ID)"
    $DeviceIdent.Label = if ([string]::IsNullOrWhiteSpace([string]$LabelName)) { "$($Device.IPAddress)" } else { "$LabelName" }
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
<#  same as Add-MappedRows but
    This turns the OrderedDictionary directly into key/value rows – without the “intermediate step” with the 1-object row.
#> 
function Add-MappedKeyValueRows {
    param(
        [Parameter(Mandatory)]
        $Collection,

        [Parameter(Mandatory)]
        $Source,

        [Parameter(Mandatory)]
        $Map
    )

    # If Source is an array: search for the IDictionary element
    if ($Source -is [object[]]) {
        $Source = @($Source) | Where-Object { $_ -is [System.Collections.IDictionary] } | Select-Object -First 1
    }

    # If it is still not an IDictionary, try PSCustomObject -> Hashtable
    if (-not ($Source -is [System.Collections.IDictionary])) {
        $ht = @{}
        $Source.PSObject.Properties | ForEach-Object { $ht[$_.Name] = $_.Value }
        $Source = $ht
    }

    # empty (if possible)
    try { $Collection.Clear() | Out-Null } catch {}

    foreach ($sourceKey in $Map.Keys) {
        $label = $Map[$sourceKey]
        $value = $null

        if ($Source.Contains($sourceKey)) {
            $value = $Source[$sourceKey]
        }

        $row = [pscustomobject]@{ Key = $label; Value = $value }

        try { $null = $Collection.Add($row) }
        catch { $Collection = @($Collection) + $row }
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

# get the saved cred back
function Convert-SecureStringToPlainText {
    param(
        [Parameter(Mandatory)]
        [System.Security.SecureString]$SecureString
    )

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    finally {
        if ($BSTR -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
}
#AZDBUSer
function Invoke-AzureSqlNonQuery {

    param(
        [string]$ConnectionString,
        [string]$Query
    )

    $conn = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
    $cmd  = $conn.CreateCommand()
    $cmd.CommandText = $Query

    try {

        $conn.Open()
        $cmd.ExecuteNonQuery()

    }
    finally {

        if ($conn.State -ne "Closed") {
            $conn.Close()
        }

        $conn.Dispose()
    }
}
#Random Password Generator
function Get-RandomPassword {
    param(
        [ValidateRange(4,256)]
        [int]$PasswordLength = 16
    )

    $lower   = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
    $upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
    $numeric = '0123456789'.ToCharArray()
    $special = '!$%&/()=?+#*-_.,:;'.ToCharArray()

    $all = $lower + $upper + $numeric + $special

    $passwordChars = @(
        $lower   | Get-Random -Count 1
        $upper   | Get-Random -Count 1
        $numeric | Get-Random -Count 1
        $special | Get-Random -Count 1
    )

    $passwordChars += 1..($PasswordLength - 4) | ForEach-Object {
        $all | Get-Random -Count 1
    }

    -join ($passwordChars | Get-Random -Count $passwordChars.Count)
}
#Utility-Function for Az und LocalDB
function Get-SqlParameterValue {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        $Value,

        [object]$Default = $null,

        [switch]$TreatEmptyStringAsNull
    )

    if ($TreatEmptyStringAsNull -and [string]::IsNullOrWhiteSpace($Value)) {
        $Value = $null
    }

    if ($null -eq $Value) {
        if ($PSBoundParameters.ContainsKey('Default')) {
            return $Default
        }
        return [DBNull]::Value
    }

    return $Value
}
# merge 2 PSCustomObject to one PSCustomObject
function Merge-PSCustomObject {
    param(
        [Parameter(Mandatory)]
        [object[]]$InputObject
    )

    $result = [ordered]@{}

    foreach ($obj in $InputObject) {
        if ($null -eq $obj) { continue }
        foreach ($prop in $obj.PSObject.Properties) {
            $cleanName = $prop.Name.Trim()
            $result[$cleanName] = $prop.Value
        }
    }

   [PSCustomObject]$result
}
# DBEventcounter for Devices
function Add-EventInfoToDevices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Devices,
    
        [Parameter()]
        [AllowNull()]
        [object[]]$Events = @()
    )
    # If no devices are provided → return empty result structure
    if ($null -eq $Devices) {
        return [PSCustomObject]@{
            Devices      = [System.Collections.Generic.List[object]]::new()
            OrphanEvents = [System.Collections.Generic.List[object]]::new()
        }
    }
    # If events are null → replace with empty array (prevents foreach errors)
    if ($null -eq $Events) {
        $Events = @()
    }
    # Hashtable to group events by SerialNumber
    $eventInfoBySerial = @{}
    # List for events that do not belong to any device
    $orphanEvents = [System.Collections.Generic.List[object]]::new()
    # Group events by SerialNumber and collect metadata
    foreach ($event in $Events) {
        # Skip events without SerialNumber
        if ([string]::IsNullOrWhiteSpace($event.SerialNumber)) {
            continue
        }
        # Initialize entry if SerialNumber not yet present
        if (-not $eventInfoBySerial.ContainsKey($event.SerialNumber)) {
            $eventInfoBySerial[$event.SerialNumber] = [PSCustomObject]@{
                Count        = 0
                Descriptions = [System.Collections.Generic.List[string]]::new()
                Events       = [System.Collections.Generic.List[object]]::new()
            }
        }
        # Increase count and store event object
        $eventInfoBySerial[$event.SerialNumber].Count++
        $eventInfoBySerial[$event.SerialNumber].Events.Add($event)
        # Store description if not empty
        if (-not [string]::IsNullOrWhiteSpace($event.Description)) {
            $eventInfoBySerial[$event.SerialNumber].Descriptions.Add($event.Description)
        }
    }
    # Hashtable of all device serial numbers for fast lookup
    $deviceSerials = @{}
    foreach ($device in $Devices) {
        if (-not [string]::IsNullOrWhiteSpace($device.SerialNumber)) {
            $deviceSerials[$device.SerialNumber] = $true
        }
    }
    # Attach event information to each device
    foreach ($device in $Devices) {
        $serial = $device.SerialNumber
        # If events exist for this device
        if (-not [string]::IsNullOrWhiteSpace($serial) -and $eventInfoBySerial.ContainsKey($serial)) {
            $info = $eventInfoBySerial[$serial]
            $uniqueDescriptions = $info.Descriptions | Select-Object -Unique
            Add-Member -InputObject $device -MemberType NoteProperty -Name Events -Value $info.Count -Force     # Number of events
            Add-Member -InputObject $device -MemberType NoteProperty -Name EventDescriptions -Value $uniqueDescriptions -Force     # Unique descriptions as array
            Add-Member -InputObject $device -MemberType NoteProperty -Name EventDescriptionsText -Value ($uniqueDescriptions -join "`n") -Force    # Unique descriptions as single string (for UI / tooltip)
            Add-Member -InputObject $device -MemberType NoteProperty -Name EventObjects -Value $info.Events -Force      # Original event objects
        }
        else {
            # No events found → assign default values
            Add-Member -InputObject $device -MemberType NoteProperty -Name Events -Value 0 -Force
            Add-Member -InputObject $device -MemberType NoteProperty -Name EventDescriptions -Value @() -Force
            Add-Member -InputObject $device -MemberType NoteProperty -Name EventDescriptionsText -Value "" -Force
            Add-Member -InputObject $device -MemberType NoteProperty -Name EventObjects -Value @() -Force
        }
    }
    # Identify orphan events (events without matching device)
    foreach ($event in $Events) {
        if ([string]::IsNullOrWhiteSpace($event.SerialNumber) -or -not $deviceSerials.ContainsKey($event.SerialNumber)) {
            $orphanEvents.Add($event)
        }
    }
    # Return result object
    [PSCustomObject]@{
        Devices      = $Devices
        OrphanEvents = $orphanEvents
    }
}
# DB Helper if $null is pos.
function Get-DbValue {
    param($Value)
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return [DBNull]::Value
    }
    return $Value
}
# DB Helper to Add Columns if they not exist
function Add-ColumnIfNotExists {
    param(
        $Connection,
        [string]$TableName,
        [string]$ColumnName,
        [string]$ColumnDefinition
    )
    try{
        $cmd = $Connection.CreateCommand()
        $cmd.CommandText = "PRAGMA table_info($TableName);"

        $reader = $cmd.ExecuteReader()

        $exists = $false
        while ($reader.Read()) {
            if ($reader["name"] -eq $ColumnName) {
                $exists = $true
                break
            }
        }
        $reader.Close()

        if (-not $exists) {
            $alterCmd = $Connection.CreateCommand()
            $alterCmd.CommandText = "ALTER TABLE $TableName ADD COLUMN $ColumnName $ColumnDefinition;"
            $alterCmd.ExecuteNonQuery() | Out-Null
        }
    }finally {
        if ($reader) { $reader.Close(); $reader.Dispose() }
        if ($cmd) { $cmd.Dispose() }
        if ($alterCmd) { $alterCmd.Dispose() }
    }
}
# DB Helper Check if Table contains Data
function Test-SQLiteHasAnyData {
    param(
        [Parameter(Mandatory)]
        $Connection,

        [Parameter(Mandatory)]
        [string]$TableName
    )
    try{
        # 1. Check if the table exists
        $cmd = $Connection.CreateCommand()
        $cmd.CommandText = "
            SELECT 1
            FROM sqlite_master
            WHERE type = 'table'
              AND name = @TableName
            LIMIT 1;
        "

        $param = $cmd.CreateParameter()
        $param.ParameterName = "@TableName"
        $param.Value = $TableName
        $cmd.Parameters.Add($param) | Out-Null

        if ($null -eq $cmd.ExecuteScalar()) {
            return $false
        }

        # 2. Check if data is available
        $countCmd = $Connection.CreateCommand()
        $countCmd.CommandText = "SELECT 1 FROM [$TableName] LIMIT 1;"
    }finally {
        if ($cmd) { $cmd.Dispose() }
    }
        return ($null -ne $countCmd.ExecuteScalar())
}