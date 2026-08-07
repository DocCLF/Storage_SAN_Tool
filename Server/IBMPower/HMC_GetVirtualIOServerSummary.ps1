function HMC_GetVirtualIOServerSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $HmcSession,

        [Parameter(Mandatory)]
        [string]$ManagedSystemUuid,

        [string]$ManagedSystemName = $ManagedSystemUuid,

        [string]$ManagedSystemMTMS,

        [string]$ManagedSystemSerial,

        [switch]$IgnoreCertificate
    )

    if (
        (-not $ManagedSystemSerial) -and
        $ManagedSystemMTMS -and
        $ManagedSystemMTMS.Length -ge 7
    ) {
        $ManagedSystemSerial =
            $ManagedSystemMTMS.Substring($ManagedSystemMTMS.Length - 7)
    }

    $feedPath =
        "ManagedSystem/$ManagedSystemUuid/VirtualIOServer?group=Advanced"

    $feed = Invoke-HmcUomGet `
        -HmcSession $HmcSession `
        -Path $feedPath `
        -Type "VirtualIOServer" `
        -IgnoreCertificate:$IgnoreCertificate

    if (-not $feed) {
        return
    }

    $viosUrls = Get-AtomSelfLinks -AtomXml $feed

    foreach ($url in $viosUrls) {
        try {
            $entry = HMC_GetUomXml `
                -HmcSession $HmcSession `
                -Url $url `
                -Type "VirtualIOServer" `
                -IgnoreCertificate:$IgnoreCertificate

            if (-not $entry) {
                continue
            }

            $uom = $null

            try {
                $uom = Convert-AtomEntryToUomXml -AtomEntryXml $entry
            }
            catch {
                [xml]$uom = $entry
            }

            $viosUuid = ($url.TrimEnd("/") -split "/")[-1]

            if ($viosUuid -match '\?') {
                $viosUuid = $viosUuid -replace '\?.*$', ''
            }

            $currentProfileHref = $null

            $profileNode = $uom.SelectSingleNode(
                "//*[local-name()='AssociatedPartitionProfile']/@href"
            )

            if ($profileNode) {
                $currentProfileHref = $profileNode.Value
            }

            [pscustomobject]@{
                ManagedSystemName       = $ManagedSystemName
                ManagedSystemUUID       = $ManagedSystemUuid
                ManagedSystemMTMS       = $ManagedSystemMTMS
                ManagedSystemSerial     = $ManagedSystemSerial

                # Einheitliches Schema mit LogicalPartition
                LparName                = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @("PartitionName", "Name")

                LparUUID                = $viosUuid

                PartitionId             = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @("PartitionID", "PartitionId")

                State                   = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @("PartitionState", "State")

                Environment             = "VIOS"

                OsVersion               = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @(
                        "OperatingSystemVersion",
                        "OSVersion",
                        "VirtualIOServerVersion"
                    )

                RmcIp                   = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @(
                        "ResourceMonitoringIPAddress",
                        "RMCIPAddress",
                        "RmcIpAddress"
                    )

                RmcState                = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @(
                        "ResourceMonitoringControlState",
                        "RMCState",
                        "RmcState"
                    )

                DefaultProfile          = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @(
                        "DefaultProfileName",
                        "DefaultProfile"
                    )

                CurrentProfileHref      = $currentProfileHref

                CurrentProcessingUnits  = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @(
                        "CurrentProcessingUnits",
                        "DesiredProcessingUnits"
                    )

                CurrentMemoryMB         = Get-FirstXmlValue `
                    -Xml $uom `
                    -Names @(
                        "CurrentMemory",
                        "DesiredMemory"
                    )

                PartitionRole           = "VIOS"
            }
        }
        catch {
            Write-Warning (
                "VIOS detail failed for {0}: {1}" -f
                $url,
                $_.Exception.Message
            )
        }
    }
}