function HMC_GetLogicalPartitionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$HmcSession,

        # Transfer as in your loop: Uuid/Name/MTMS/Serial come from the ManagedSystem
        [Parameter(Mandatory)][string]$ManagedSystemUuid,
        [string]$ManagedSystemName = $ManagedSystemUuid,
        [string]$ManagedSystemMTMS,
        [string]$ManagedSystemSerial,

        [switch]$IgnoreCertificate
    )
    # If ManagedSystemSerial is not specified (e.g., direct call), the summary function should derive this itself.
    if((-not $ManagedSystemSerial) -and $ManagedSystemMTMS -and $ManagedSystemMTMS.Length -ge 7){
        $ManagedSystemSerial = $ManagedSystemMTMS.Substring($ManagedSystemMTMS.Length - 7)
    }

    $feedPath = "ManagedSystem/$ManagedSystemUuid/LogicalPartition?group=Advanced"
    $feed = Invoke-HmcUomGet -HmcSession $HmcSession -Path $feedPath -Type "LogicalPartition" -IgnoreCertificate:$IgnoreCertificate
    if ([string]::IsNullOrWhiteSpace([string]$feed)) {
        Write-Verbose (
            "No LogicalPartition feed returned for Managed System '{0}' ({1})." -f
            $ManagedSystemName,
            $ManagedSystemUuid
        )

        return
    }
    $lparUrls = @(Get-AtomSelfLinks -AtomXml $feed)
    if ($lparUrls.Count -eq 0) {
        Write-Host (
            "No LogicalPartition SELF links found for Managed System '{0}' ({1})." -f
            $ManagedSystemName,
            $ManagedSystemUuid
        )
    
        return
    }

    foreach($u in $lparUrls){
        try{
        # Get details
        $entry = HMC_GetUomXml -HmcSession $HmcSession -Url $u -Type "LogicalPartition" -IgnoreCertificate:$IgnoreCertificate
        if ([string]::IsNullOrWhiteSpace([string]$entry)) {
            Write-Verbose "Empty LogicalPartition response for '$u'."
            continue
        }
        # Atom->UOM (if atom entry), otherwise directly UOM
        $uom = $null
        try { $uom = Convert-AtomEntryToUomXml -AtomEntryXml $entry }
        catch { 
            try{
                [xml]$uom = $entry 
            }catch{
                Write-Warning (
                    "LogicalPartition XML could not be parsed for '{0}': {1}" -f
                    $u,
                    $_.Exception.Message
                )

                continue
            }
        }

        $lparUuid = ($u.TrimEnd("/") -split "/")[-1]
        # There's a chance that an invalid UUID might be generated, so here's the check again
        if ($lparUuid -match '\?') {
            $lparUuid = $lparUuid -replace '\?.*$', ''
        }
        # robust: OSVersion often has different names (OperatingSystemVersion vs. OSVersion, etc.)
        $os = Get-FirstXmlValue -Xml $uom -Names @(
            "OperatingSystemVersion",
            "OSVersion",
            "OperatingSystem",
            "OperatingSystemType"
        )

        # The environment is usually “AIX/Linux” or “OS400.”
        $env = Get-FirstXmlValue -Xml $uom -Names @(
            "PartitionEnvironment",
            "Environment",
            "PartitionType"
        )

        # State is usually “running” / “not activated” / “not available”
        $state = Get-FirstXmlValue -Xml $uom -Names @(
            "PartitionState",
            "State"
        )

        # RMC
        $rmcState = Get-FirstXmlValue -Xml $uom -Names @("RMCState","RmcState")
        $rmcIp    = Get-FirstXmlValue -Xml $uom -Names @("RMCIPAddress","RmcIpAddress","IPAddress")

        # Profiles: in your console run, you had CurrentProfileHref.
        # In UOM, this varies depending on the version. We do two things:
        # (A) Link rel SELF of the CurrentProfile (if available)
        # (B) Search for LogicalPartitionProfile href (CURRENT)
        $currentProfileHref = $null

        try {
            $node = $uom.SelectSingleNode("//*[local-name()='CurrentLogicalPartitionProfile']/@href")
            if($node){ $currentProfileHref = $node.Value }
        } catch {}

        if(-not $currentProfileHref){
            try {
                $node = $uom.SelectSingleNode("//*[local-name()='LogicalPartitionProfile'][translate(@rel,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')='CURRENT']/@href") 
                if($node){ $currentProfileHref = $node.Value }
            } catch {}
        }

        # DefaultProfile Name
        $defaultProfile = Get-FirstXmlValue -Xml $uom -Names @("DefaultProfile","DefaultProfileName")

        # CPU/Mem (currently)
        $curCpu = Get-FirstXmlValue -Xml $uom -Names @("CurrentProcessingUnits","CurrentProcUnits","CurrentProcessingUnit")
        $curMem = Get-FirstXmlValue -Xml $uom -Names @("CurrentMemoryMB","CurrentMemory","CurrentMemorySize")
        $LparName = Get-FirstXmlValue -Xml $uom -Names @("PartitionName","LogicalPartitionName","Name")
        $PartitionId = Get-FirstXmlValue -Xml $uom -Names @("PartitionID","PartitionId")

        [pscustomobject]@{
            DeviceTitle         = $ManagedSystemName
            ManagedSystemName   = $ManagedSystemName
            ManagedSystemUUID   = $ManagedSystemUUID
            ManagedSystemMTMS   = $ManagedSystemMTMS
            ManagedSystemSerial = $ManagedSystemSerial

            LparName            = $LparName
            LparUUID            = $lparUuid
            PartitionId         = $PartitionId

            State                   = $state
            Environment             = $env
            OsVersion               = $os
            RmcIp                   = $rmcIp
            RmcState                = $rmcState
            DefaultProfile          = $defaultProfile
            CurrentProfileHref      = $currentProfileHref
            CurrentProcessingUnits  = $curCpu
            CurrentMemoryMB         = $curMem

            PartitionRole           = "LPAR"
        }
    }catch {
        Write-Warning (
            "LogicalPartition query failed for '{0}': {1}" -f
            $u,
            $_.Exception.Message
        )

        continue
    }
    }
}