function HMC_GetManagedSystems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$HmcSession,
        [switch]$IgnoreCertificate
    )

    $feed = Invoke-HmcUomGet -HmcSession $HmcSession -Path "ManagedSystem" -Type "ManagedSystem" -IgnoreCertificate:$IgnoreCertificate
    $urls = Get-AtomSelfLinks -AtomXml $feed

    Write-Verbose ("ManagedSystem URLs: {0}" -f $urls.Count)

    $out = New-Object System.Collections.Generic.List[object]

    foreach($u in $urls){
        try {
            $detail = HMC_GetUomXml -HmcSession $HmcSession -Url $u -Type "ManagedSystem" -IgnoreCertificate:$IgnoreCertificate
            if(-not $detail){ continue }

            # Atom->UOM (if atom entry), otherwise directly UOM
            $uom = $null
            try { $uom = Convert-AtomEntryToUomXml -AtomEntryXml $detail }
            catch { [xml]$uom = $detail }

            $uuid = ($u.TrimEnd("/") -split "/")[-1]

            # --- Identity basics ---
            $name = Get-FirstXmlValue -Xml $uom -Names @("SystemName","ManagedSystemName","Name")
            $state = Get-FirstXmlValue -Xml $uom -Names @("State","SystemState")

            # --- MTMS / MTM / Serial (your existing logic, kept) ---
            $mtms = Get-FirstXmlValue -Xml $uom -Names @(
                "MachineTypeModelAndSerialNumber",
                "MachineTypeModelSerialNumber",
                "MTMS"
            )

            # SN recognition can be wrong if picking generic SerialNumber nodes; derive from MTMS
            $serial = $null
            $mtm    = Get-FirstXmlValue -Xml $uom -Names @("MachineTypeModel","MachineType","Model")

            if(-not $serial -and $mtms -and $mtms.Length -ge 7){
                $serial = $mtms.Substring($mtms.Length - 7)
            }
            if(-not $mtms){ $mtms = $mtm }
            
            #need omly the MTM 
            $MachineTypeModel = $mtms -replace $serial,""

            # --- Firmware / Levels (no CLI, UOM only) ---
            $activatedLevel = Get-FirstXmlValue -Xml $uom -Names @("ActivatedLevel")
            $activatedSP    = Get-FirstXmlValue -Xml $uom -Names @("ActivatedServicePackNameAndLevel","ActivatedServicePack","ActivatedServicePackName")
            $systemFirmware = Get-FirstXmlValue -Xml $uom -Names @("SystemFirmware","CurrentSystemFirmware","RunningSystemFirmware")
            $installedLevel = Get-FirstXmlValue -Xml $uom -Names @("InstalledLevel","InstalledFirmwareLevel","InstalledServicePackNameAndLevel")
            $pendingLevel   = Get-FirstXmlValue -Xml $uom -Names @("PendingLevel","PendingFirmwareLevel","PendingServicePackNameAndLevel","PendingSystemFirmware")
            $deferredLevel  = Get-FirstXmlValue -Xml $uom -Names @("DeferredLevel","DeferredFirmwareLevel","DeferredServicePackNameAndLevel")

            # EC Number: derive from firmware strings (e.g. VL940)
            $ecNumber = $null
            $ecSource = @($systemFirmware, $activatedSP, $installedLevel, $pendingLevel, $deferredLevel) | Where-Object { $_ }
            foreach($s in $ecSource){
                if($s -match '([A-Z]{2}\d{3})'){
                    $ecNumber = $Matches[1]
                    break
                }
            }

            # IPL-Level: in practice the running/activated firmware identifier is what you want
            # Prefer SystemFirmware; fallback to ActivatedServicePackNameAndLevel
            $iplLevel = $null
            if($systemFirmware){ $iplLevel = $systemFirmware }
            elseif($activatedSP){ $iplLevel = $activatedSP }
            elseif($installedLevel){ $iplLevel = $installedLevel }

            # If DeferredLevel is not present, use PendingLevel as the "next boot" level
            if(-not $deferredLevel -and $pendingLevel){
                $deferredLevel = $pendingLevel
            }

            # For backward compatibility, we retain old property names,
            # but also deliver the “new” module-friendly ones.
            $obj = [pscustomobject]@{
                UUID                = $uuid
                SystemName          = $name
                MachineTypeModel    = $MachineTypeModel
                SerialNumber        = $serial
                State               = $state
                Url                 = $u

                # Requested additions
                ECNumber            = $ecNumber
                IPLLevel            = $iplLevel
                ActivatedLevel      = $activatedLevel
                DeferredLevel       = $deferredLevel

                # Helpful extra firmware context (often useful in tools)
                SystemFirmware                  = $systemFirmware
                ActivatedServicePackNameAndLevel= $activatedSP
                InstalledLevel                  = $installedLevel
                PendingLevel                    = $pendingLevel
            }

            $out.Add($obj) | Out-Null
        }
        catch {
            Write-Warning ("ManagedSystem Detail FAILED for {0}: {1}" -f $u, $_.Exception.Message)
        }
    }

    return $out.ToArray()
}
