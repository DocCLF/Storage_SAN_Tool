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
                $FunResult = & $RESTFunc -Device $Device -TD_Exportpath $ExportPath
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
        if(!([string]::IsNullOrWhiteSpace([string]$FunResult.ClusterName))){
            $LabelName = $FunResult.ClusterName
        }
        #else {
        #    $LabelName = $FunResult.SerialNumber[0]
        #}
    }
    $DeviceIdent.Label = "$($Device.IPAddress)"
    Write-Host $LabelName -ForegroundColor Green
    $DeviceIdent.DeviceTitle = if ([string]::IsNullOrWhiteSpace([string]$LabelName)) { "$($Device.IPAddress)" } else { $LabelName }
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
        [AllowEmptyCollection()]
        [object[]]$Devices,
    
        [Parameter()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Events = @()
    )
    # If no devices are provided → return empty result structure
    if (@($Devices).Count -eq 0) {
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
        $FirstValue = $countCmd.ExecuteScalar()
        return ($null -ne $FirstValue)
    }catch {
        Write-Warning ( "Could not check table '{0}' for data: {1}" -f $TableName, $_.Exception.Message )
        return $false
    
    }finally {
        if ($cmd) { $cmd.Dispose() }
        if ($countCmd) {$countCmd.Dispose()}
    }
}
# Converts a capacity value with unit into bytes.
function ConvertTo-ByteValue {
    <#
    .SYNOPSIS
        Converts a capacity value with unit into bytes.

    .DESCRIPTION
        Converts capacity strings such as B, KB, MB, GB, TB or PB
        into an Int64 byte value.

        The function is independent of Storage, SAN or any specific
        data source.

    .PARAMETER Value
        Capacity value to convert.

        Examples:

            19.99TB
            850GB
            512MB
            1024B

    .OUTPUTS
        System.Int64

        Returns $null for null or empty input.

    .EXAMPLE
        ConvertTo-ByteValue -Value '19.99TB'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AllowNull()]
        $Value
    )

    if (
        $null -eq $Value -or
        $Value -is [DBNull] -or
        [string]::IsNullOrWhiteSpace([string]$Value)
    ) {
        return $null
    }

    $CapacityText = ([string]$Value).Trim()

    if (
        $CapacityText -notmatch
        '^(?<Number>[0-9]+(?:[\.,][0-9]+)?)\s*(?<Unit>B|KB|MB|GB|TB|PB)$'
    ) {
        throw "Capacity value '$Value' has an unsupported format."
    }

    $NumberText = $Matches.Number -replace ',', '.'

    $Number = [decimal]::Parse(
        $NumberText,
        [System.Globalization.CultureInfo]::InvariantCulture
    )

    $Multiplier = switch ($Matches.Unit.ToUpperInvariant()) {
        'B'  { [decimal]1 }
        'KB' { [decimal]1024 }
        'MB' { [decimal]1048576 }
        'GB' { [decimal]1073741824 }
        'TB' { [decimal]1099511627776 }
        'PB' { [decimal]1125899906842624 }

        default {
            throw "Unsupported capacity unit '$($Matches.Unit)'."
        }
    }

    return [int64]($Number * $Multiplier)
}
# Helper Func to Save Vdisk an VdiskAnalysis at one point
function Save-StorageVolumeHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet(
            'Volume',
            'Analysis'
        )]
        [string]$SourceType,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$InputObject
    )

    switch ($SourceType) {

        'Volume' {
        
            # -------------------------------------------------------------
            # Only real volumes with a valid VdiskUID are relevant for
            # the current volume inventory.
            # -------------------------------------------------------------
        
            $CurrentVolumes = @(
                $InputObject |
                    Where-Object {
                        $null -ne $_ -and
                        $_.RowType -eq 'Volume' -and
                        -not [string]::IsNullOrWhiteSpace(
                            [string]$_.VdiskUID
                        )
                    }
            )
                
            if ($CurrentVolumes.Count -eq 0) {
            
                Write-Warning (
                    'Save-StorageVolumeHistory: ' +
                    'No valid volumes with VdiskUID were supplied. ' +
                    'Inventory synchronization was skipped.'
                )
            
                return
            }
        
            # -------------------------------------------------------------
            # Build normalized inventory objects.
            # -------------------------------------------------------------
        
            $InventoryData = @(
                foreach ($Volume in $CurrentVolumes) {
                
                    [PSCustomObject]@{
                        RowID        = [string]$Volume.RowID
                        VolumeID     = [int]$Volume.ID
                        VdiskUID     = [string]$Volume.VdiskUID
                        VolumeName   = [string]$Volume.Name
                    
                        WWNN         = [string]$Volume.WWNN
                        SerialNumber = [string]$Volume.SerialNumber
                    }
                }
            )
            
            # -------------------------------------------------------------
            # Hand normalized inventory data over to the DB layer.
            # -------------------------------------------------------------
            
            $null = SST_CustomerSTODBInsertTable -SST_InfoType 'VolumeInventory' -SST_CollectedInformations $InventoryData
        }

        'Analysis' {

            $CustomerNbr =
                if (-not [string]::IsNullOrWhiteSpace($TD_TB_CustomerInfoName.Text)) {
                    $TD_TB_CustomerInfoName.Text
                }
                else {
                    $SST_NewDBObject.CustomerNumber
                }
            
            $VolumeInventory = @(
                Get-StorageVolumeInventory `
                    -CustomerNbr $CustomerNbr `
                    -OnlyActive
            )
            
            $InventoryLookup = @{}
            
            foreach ($InventoryItem in $VolumeInventory) {
            
                $Key = '{0}|{1}' -f
                    [string]$InventoryItem.SerialNumber,
                    [string]$InventoryItem.VolumeID
            
                $InventoryLookup[$Key] = $InventoryItem
            }

            $HistoryData = @(
                foreach ($Item in $InputObject) {
                
                    if ($null -eq $Item) {
                        continue
                    }
                
                    # -------------------------------------------------------------
                    # Match current lsvdiskanalysis entry against the current
                    # volume inventory.
                    #
                    # VolumeID is only used as a temporary join key together with
                    # SerialNumber. The durable identity stored in history is
                    # VdiskUID.
                    # -------------------------------------------------------------
                
                    $LookupKey = '{0}|{1}' -f
                        [string]$Item.SerialNumber,
                        [string]$Item.ID
                
                    $InventoryItem =
                        $InventoryLookup[$LookupKey]
                
                    if ($null -eq $InventoryItem) {
                    
                        Write-Warning (
                            "No active volume inventory entry was found for " +
                            "SerialNumber '$($Item.SerialNumber)' and " +
                            "VolumeID '$($Item.ID)'. Analysis entry was skipped."
                        )
                    
                        continue
                    }
                
                    [PSCustomObject]@{
                        RowID                   = [string]$InventoryItem.RowID
                        VolumeID                = [string]$Item.ID
                        VdiskUID                = [string]$InventoryItem.VdiskUID
                        VolumeName              = [string]$InventoryItem.VolumeName
                        State                   = [string]$Item.State
                        AnalysisTime            = [string]$Item.AnalysisTime
                    
                        Capacity                = ConvertTo-ByteValue -Value $Item.Capacity
                        ThinSize                = ConvertTo-ByteValue -Value $Item.ThinSize
                        ThinSavings             = ConvertTo-ByteValue -Value $Item.ThinSavings
                        ThinSavingsRatio        = [double]$Item.ThinSavingsRatio
                    
                        CompressedSize          = ConvertTo-ByteValue -Value $Item.CompressedSize
                        CompressionSavings      = ConvertTo-ByteValue -Value $Item.CompressionSavings
                        CompressionSavingsRatio = [double]$Item.CompressionSavingsRatio
                    
                        TotalSavings            = ConvertTo-ByteValue -Value $Item.TotalSavings
                        TotalSavingsRatio       = [double]$Item.TotalSavingsRatio
                    
                        MarginOfError           = [double]$Item.MarginOfError
                    
                        WWNN                    = [string]$InventoryItem.WWNN
                        SerialNumber            = [string]$InventoryItem.SerialNumber
                    }
                }
            )

            if ($HistoryData.Count -eq 0) {
                return
            }else {
                $null = SST_CustomerSTODBInsertTable -SST_InfoType "VDiskAnalysis" -SST_CollectedInformations $HistoryData
            }
        
            # DB writer comes next
        }
    }
}
#temp für alte kunden umgebungen
function Update-IBMSTOFCPortStatsTableSchema {
    <#
    .SYNOPSIS
        Creates or upgrades IBMSTOFCPortStatsTable to the current schema.

    .DESCRIPTION
        Handles three cases:

        1. Table does not exist
           -> Creates the current table.

        2. Table exists and already contains RowID
           -> Assumes the current schema and ensures the required index.

        3. Legacy table exists without RowID
           -> Creates a new table, migrates the existing data,
              converts legacy TEXT values to INTEGER / REAL,
              creates RowID from SerialNumber|WWNN|WWPN,
              replaces the old table and creates the index.

        The migration is executed inside a transaction.

    .PARAMETER SQLiteDBConnection
        Open System.Data.SQLite connection.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SQLiteDBConnection
    )

    $TableName =
        'IBMSTOFCPortStatsTable'

    $NewTableName =
        'IBMSTOFCPortStatsTable_New'

    # ---------------------------------------------------------------------
    # Check whether table exists
    # ---------------------------------------------------------------------

    $CheckCommand =
        $SQLiteDBConnection.CreateCommand()

    try {
        $CheckCommand.CommandText = @"
SELECT COUNT(*)
FROM sqlite_master
WHERE type = 'table'
  AND name = @TableName;
"@

        $null =
            $CheckCommand.Parameters.AddWithValue(
                '@TableName',
                $TableName
            )

        $TableExists =
            ([int]$CheckCommand.ExecuteScalar() -gt 0)
    }
    finally {
        $CheckCommand.Dispose()
    }

    # ---------------------------------------------------------------------
    # Table does not exist
    #
    # Create current schema directly.
    # ---------------------------------------------------------------------

    if (-not $TableExists) {

        $CreateCommand =
            $SQLiteDBConnection.CreateCommand()

        try {
            $CreateCommand.CommandText = @"
CREATE TABLE IBMSTOFCPortStatsTable (
    ID              INTEGER PRIMARY KEY AUTOINCREMENT,
    CustomerNbr     TEXT NOT NULL,
    RowID           TEXT NOT NULL,
    NodeID          INTEGER,
    NodeName        TEXT,
    CardType        TEXT,
    CardID          INTEGER,
    PortID          INTEGER,
    WWPN            TEXT NOT NULL,
    LinkFailure     INTEGER,
    LoseSync        INTEGER,
    LoseSig         INTEGER,
    PSErrCount      INTEGER,
    InvTransErr     INTEGER,
    CRCErr          INTEGER,
    ZeroBtB         INTEGER,
    SFPTemp         REAL,
    TXPwr           REAL,
    TXPwrLow        REAL,
    RXPwr           REAL,
    RXPwrLow        REAL,
    SerialNumber    TEXT NOT NULL,
    WWNN            TEXT NOT NULL,
    TimeStamp       TEXT NOT NULL
);
"@

            $CreateCommand.ExecuteNonQuery() |
                Out-Null

            $CreateCommand.CommandText = @"
CREATE INDEX IF NOT EXISTS
    IX_IBMSTOFCPortStats_RowID_TimeStamp
ON IBMSTOFCPortStatsTable (
    CustomerNbr,
    RowID,
    TimeStamp
);
"@

            $CreateCommand.ExecuteNonQuery() |
                Out-Null
        }
        finally {
            $CreateCommand.Dispose()
        }

        Write-Verbose (
            "Table '$TableName' was created using the current schema."
        )

        return
    }

    # ---------------------------------------------------------------------
    # Read existing table columns
    # ---------------------------------------------------------------------

    $ColumnCommand =
        $SQLiteDBConnection.CreateCommand()

    try {
        $ColumnCommand.CommandText =
            "PRAGMA table_info($TableName);"

        $Reader =
            $ColumnCommand.ExecuteReader()

        $ExistingColumns =
            [System.Collections.Generic.List[string]]::new()

        try {
            while ($Reader.Read()) {

                $ExistingColumns.Add(
                    [string]$Reader['name']
                )
            }
        }
        finally {
            $Reader.Close()
            $Reader.Dispose()
        }
    }
    finally {
        $ColumnCommand.Dispose()
    }

    # ---------------------------------------------------------------------
    # RowID exists
    #
    # This is our marker for the current FCPortStats schema.
    # Only make sure that the index exists.
    # ---------------------------------------------------------------------

    if ($ExistingColumns -contains 'RowID') {

        $IndexCommand =
            $SQLiteDBConnection.CreateCommand()

        try {
            $IndexCommand.CommandText = @"
CREATE INDEX IF NOT EXISTS
    IX_IBMSTOFCPortStats_RowID_TimeStamp
ON IBMSTOFCPortStatsTable (
    CustomerNbr,
    RowID,
    TimeStamp
);
"@

            $IndexCommand.ExecuteNonQuery() |
                Out-Null
        }
        finally {
            $IndexCommand.Dispose()
        }

        Write-Verbose (
            "Table '$TableName' already uses the current schema."
        )

        return
    }

    # ---------------------------------------------------------------------
    # Legacy table detected
    # ---------------------------------------------------------------------

    Write-Verbose (
        "Legacy '$TableName' schema detected. Starting migration."
    )

    # ---------------------------------------------------------------------
    # Check for legacy rows that cannot be migrated.
    #
    # These columns are required to build the new NOT NULL fields and RowID.
    # ---------------------------------------------------------------------

    $InvalidCommand =
        $SQLiteDBConnection.CreateCommand()

    try {
        $InvalidCommand.CommandText = @"
SELECT COUNT(*)
FROM IBMSTOFCPortStatsTable
WHERE SerialNumber IS NULL
   OR TRIM(SerialNumber) = ''
   OR WWNN IS NULL
   OR TRIM(WWNN) = ''
   OR WWPN IS NULL
   OR TRIM(WWPN) = ''
   OR CustomerNbr IS NULL
   OR TRIM(CustomerNbr) = ''
   OR TimeStamp IS NULL
   OR TRIM(TimeStamp) = '';
"@

        $InvalidRowCount =
            [int]$InvalidCommand.ExecuteScalar()
    }
    finally {
        $InvalidCommand.Dispose()
    }

    if ($InvalidRowCount -gt 0) {
        throw (
            "Migration of '$TableName' cannot continue because " +
            "$InvalidRowCount legacy row(s) contain empty values in " +
            'CustomerNbr, SerialNumber, WWNN, WWPN or TimeStamp.'
        )
    }

    # ---------------------------------------------------------------------
    # Migration transaction
    # ---------------------------------------------------------------------

    $Transaction =
        $SQLiteDBConnection.BeginTransaction()

    try {

        $MigrationCommand =
            $SQLiteDBConnection.CreateCommand()

        $MigrationCommand.Transaction =
            $Transaction

        try {

            # -------------------------------------------------------------
            # Remove an abandoned temporary table from a previous failed
            # migration if one exists.
            # -------------------------------------------------------------

            $MigrationCommand.CommandText =
                "DROP TABLE IF EXISTS $NewTableName;"

            $MigrationCommand.ExecuteNonQuery() |
                Out-Null

            # -------------------------------------------------------------
            # Create current table structure under temporary name
            # -------------------------------------------------------------

            $MigrationCommand.CommandText = @"
CREATE TABLE $NewTableName (
    ID              INTEGER PRIMARY KEY AUTOINCREMENT,
    CustomerNbr     TEXT NOT NULL,
    RowID           TEXT NOT NULL,
    NodeID          INTEGER,
    NodeName        TEXT,
    CardType        TEXT,
    CardID          INTEGER,
    PortID          INTEGER,
    WWPN            TEXT NOT NULL,
    LinkFailure     INTEGER,
    LoseSync        INTEGER,
    LoseSig         INTEGER,
    PSErrCount      INTEGER,
    InvTransErr     INTEGER,
    CRCErr           INTEGER,
    ZeroBtB         INTEGER,
    SFPTemp         REAL,
    TXPwr           REAL,
    TXPwrLow        REAL,
    RXPwr           REAL,
    RXPwrLow        REAL,
    SerialNumber    TEXT NOT NULL,
    WWNN            TEXT NOT NULL,
    TimeStamp       TEXT NOT NULL
);
"@

            $MigrationCommand.ExecuteNonQuery() |
                Out-Null

            # -------------------------------------------------------------
            # Copy legacy data
            #
            # RowID:
            #
            #   SerialNumber|WWNN|WWPN
            #
            # New fields for which the legacy database has no source:
            #
            #   NodeID
            #   NodeName
            #   TXPwrLow
            #   RXPwrLow
            #
            # remain NULL for migrated history.
            #
            # Empty legacy TEXT values are converted to NULL rather than
            # becoming numeric zero.
            # -------------------------------------------------------------

            $MigrationCommand.CommandText = @"
INSERT INTO $NewTableName (
    ID,
    CustomerNbr,
    RowID,
    NodeID,
    NodeName,
    CardType,
    CardID,
    PortID,
    WWPN,
    LinkFailure,
    LoseSync,
    LoseSig,
    PSErrCount,
    InvTransErr,
    CRCErr,
    ZeroBtB,
    SFPTemp,
    TXPwr,
    TXPwrLow,
    RXPwr,
    RXPwrLow,
    SerialNumber,
    WWNN,
    TimeStamp
)
SELECT
    ID,
    CustomerNbr,

    SerialNumber || '|' || WWNN || '|' || WWPN,

    NULL,
    NULL,

    CardType,

    CASE
        WHEN CardID IS NULL OR TRIM(CardID) = ''
            THEN NULL
        ELSE CAST(CardID AS INTEGER)
    END,

    CASE
        WHEN PortID IS NULL OR TRIM(PortID) = ''
            THEN NULL
        ELSE CAST(PortID AS INTEGER)
    END,

    WWPN,

    CASE
        WHEN LinkFailure IS NULL OR TRIM(LinkFailure) = ''
            THEN NULL
        ELSE CAST(LinkFailure AS INTEGER)
    END,

    CASE
        WHEN LoseSync IS NULL OR TRIM(LoseSync) = ''
            THEN NULL
        ELSE CAST(LoseSync AS INTEGER)
    END,

    CASE
        WHEN LoseSig IS NULL OR TRIM(LoseSig) = ''
            THEN NULL
        ELSE CAST(LoseSig AS INTEGER)
    END,

    CASE
        WHEN PSErrCount IS NULL OR TRIM(PSErrCount) = ''
            THEN NULL
        ELSE CAST(PSErrCount AS INTEGER)
    END,

    CASE
        WHEN InvTransErr IS NULL OR TRIM(InvTransErr) = ''
            THEN NULL
        ELSE CAST(InvTransErr AS INTEGER)
    END,

    CASE
        WHEN CRCErr IS NULL OR TRIM(CRCErr) = ''
            THEN NULL
        ELSE CAST(CRCErr AS INTEGER)
    END,

    CASE
        WHEN ZeroBtB IS NULL OR TRIM(ZeroBtB) = ''
            THEN NULL
        ELSE CAST(ZeroBtB AS INTEGER)
    END,

    CASE
        WHEN SFPTemp IS NULL OR TRIM(SFPTemp) = ''
            THEN NULL
        ELSE CAST(SFPTemp AS REAL)
    END,

    CASE
        WHEN TXPwr IS NULL OR TRIM(TXPwr) = ''
            THEN NULL
        ELSE CAST(TXPwr AS REAL)
    END,

    NULL,

    CASE
        WHEN RXPwr IS NULL OR TRIM(RXPwr) = ''
            THEN NULL
        ELSE CAST(RXPwr AS REAL)
    END,

    NULL,

    SerialNumber,
    WWNN,
    TimeStamp

FROM IBMSTOFCPortStatsTable;
"@

            $MigrationCommand.ExecuteNonQuery() |
                Out-Null

            # -------------------------------------------------------------
            # Verify that every old row reached the new table
            # -------------------------------------------------------------

            $MigrationCommand.CommandText =
                'SELECT COUNT(*) FROM IBMSTOFCPortStatsTable;'

            $OldRowCount =
                [int]$MigrationCommand.ExecuteScalar()

            $MigrationCommand.CommandText =
                "SELECT COUNT(*) FROM $NewTableName;"

            $NewRowCount =
                [int]$MigrationCommand.ExecuteScalar()

            if ($OldRowCount -ne $NewRowCount) {
                throw (
                    'FCPortStats migration row count mismatch. ' +
                    "Old: $OldRowCount, New: $NewRowCount."
                )
            }

            # -------------------------------------------------------------
            # Replace legacy table
            # -------------------------------------------------------------

            $MigrationCommand.CommandText =
                'DROP TABLE IBMSTOFCPortStatsTable;'

            $MigrationCommand.ExecuteNonQuery() |
                Out-Null

            $MigrationCommand.CommandText =
                "ALTER TABLE $NewTableName " +
                'RENAME TO IBMSTOFCPortStatsTable;'

            $MigrationCommand.ExecuteNonQuery() |
                Out-Null

            # -------------------------------------------------------------
            # Create current index
            # -------------------------------------------------------------

            $MigrationCommand.CommandText = @"
CREATE INDEX IF NOT EXISTS
    IX_IBMSTOFCPortStats_RowID_TimeStamp
ON IBMSTOFCPortStatsTable (
    CustomerNbr,
    RowID,
    TimeStamp
);
"@

            $MigrationCommand.ExecuteNonQuery() |
                Out-Null
        }
        finally {
            $MigrationCommand.Dispose()
        }

        $Transaction.Commit()

        Write-Verbose (
            "Migration of '$TableName' completed successfully."
        )
    }
    catch {

        try {
            $Transaction.Rollback()
        }
        catch {
            # Do not hide the original migration error.
        }

        throw
    }
    finally {
        $Transaction.Dispose()
    }
}

