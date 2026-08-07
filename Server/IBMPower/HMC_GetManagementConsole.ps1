function HMC_GetManagementConsole {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$HmcSession,
        [switch]$IgnoreCertificate
    )

    # Management IP from session (fallback to host from BaseUrl)
    $mgmtIp = $null
    if ($HmcSession.PSObject.Properties.Match('HMCIP').Count -gt 0 -and $HmcSession.HMCIP) {
        $mgmtIp = [string]$HmcSession.HMCIP
    } elseif ($HmcSession.PSObject.Properties.Match('BaseUrl').Count -gt 0 -and $HmcSession.BaseUrl) {
        $mgmtIp = ([uri]$HmcSession.BaseUrl).Host
    }

    # Get feed (Atom)
    $feedXmlString = Invoke-HmcUomGet -HmcSession $HmcSession -Path "ManagementConsole" -Type "ManagementConsole" -IgnoreCertificate:$IgnoreCertificate
    [xml]$feed = $feedXmlString

    $out = New-Object System.Collections.Generic.List[object]

    $entries = $feed.SelectNodes("//*[local-name()='entry']")
    foreach($entry in $entries) {

        # Self URL from Atom link
        $selfHref = $entry.SelectSingleNode("./*[local-name()='link' and translate(@rel,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')='SELF']/@href")

        # Extract UOM from content (your feed contains the complete UOM in <content>)
        $contentNode = $entry.SelectSingleNode("./*[local-name()='content']")
        if (-not $contentNode) { continue }
        $uomRoot = $contentNode.SelectSingleNode("./*")
        if (-not $uomRoot) { continue }
        [xml]$uom = $uomRoot.OuterXml

        $uuid = Get-FirstXmlValue -Xml $uom -Names @('AtomID','UUID','Uuid','id')

        # iFixes
        $ifix = $uom.SelectNodes("//*[local-name()='IFix']") |
            ForEach-Object { $_.InnerText.Trim() } | Where-Object { $_ } | Select-Object -Unique

        # All IPs from XML (cleaned up), but PrimaryIP remains mgmtIp
        $allIps = $uom.SelectNodes("//*[local-name()='Ipv4Address' or local-name()='Ipv6Address']") |
            ForEach-Object { $_.InnerText.Trim() } | Where-Object { $_ } | Select-Object -Unique

        $filteredIps = $allIps | Where-Object {
            $_ -and $_ -ne '0.0.0.0' -and $_ -ne '127.0.0.1' -and $_ -ne '::1'
        } | Select-Object -Unique

        $ipsAll = (@($mgmtIp) + ($filteredIps | Where-Object { $_ -ne $mgmtIp })) | Where-Object { $_ } | Select-Object -Unique

        # BIOS
        $bios = Get-FirstXmlValue -Xml $uom -Names @('BIOS','Bios','BiosLevel')

        # ManagedSystems Links -> UUIDs
        $msLinks = $uom.SelectNodes("//*[local-name()='ManagedSystems']/*[local-name()='link']/@href") |
            ForEach-Object { $_.Value } | Where-Object { $_ }
        $msUuids = $msLinks | ForEach-Object { ($_ -split '/')[-1] } | Where-Object { $_ } | Select-Object -Unique

        # Versionen
        $baseVersion = Get-FirstXmlValue -Xml $uom -Names @('BaseVersion','Vrm','Version')
        $release     = Get-FirstXmlValue -Xml $uom -Names @('Release')
        $buildLevel  = Get-FirstXmlValue -Xml $uom -Names @('BuildLevel')
        $displayVersion = (@(
            $baseVersion
            if($release){ "R$release" }
            if($buildLevel){ "Build $buildLevel" }
        ) | Where-Object { $_ }) -join ' '

        #HMC MachineType & Model in one
        $HMCMachineType = Get-FirstXmlValue -Xml $uom -Names 'MachineType'
        $HMCModel = Get-FirstXmlValue -Xml $uom -Names 'Model'

        if ($HMCMachineType -and $HMCModel) {
            $HMCMTM = "$HMCMachineType$HMCModel"
        } else {
            $HMCMTM = $null  #Fallback
        }

        $out.Add([pscustomobject]@{
            HMCName             = Get-FirstXmlValue -Xml $uom -Names @('ManagementConsoleName','HostName','Hostname','Name')
            HMCMTM              = $HMCMTM
            SerialNumber        = Get-FirstXmlValue -Xml $uom -Names @('SerialNumber')
            BIOS                = $bios
            BaseVersion         = $baseVersion
            Release             = $release
            BuildLevel          = $buildLevel
            DisplayVersion      = $displayVersion
            IFix                = ($ifix -join '; ')
            PrimaryIP           = $mgmtIp
            IPsAll              = ($ipsAll -join '; ')
            ManagedSystemUUIDs  = ($msUuids -join '; ')
            ManagedSystemCount  = ($msUuids.Count)
            UUID                = $uuid
            Url                 = $selfHref
        }) | Out-Null
    }

    $out.ToArray()
}