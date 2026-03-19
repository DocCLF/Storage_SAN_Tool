function HMC_GetUomXml {
    param(
        [Parameter(Mandatory)]$HmcSession,
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Type,
        [switch]$IgnoreCertificate
    )

    # PS 7+ (stable)
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $headers = @{
            "X-API-Session" = $HmcSession.Session
            "Accept"        = "application/vnd.ibm.powervm.uom+xml; type=$Type"
        }

        $iwrParams = @{
            Method           = 'Get'
            Uri              = $Url
            Headers          = $headers
            DisableKeepAlive = $true
            ErrorAction      = 'Stop'
        }

        if ($IgnoreCertificate) { $iwrParams['SkipCertificateCheck'] = $true }
        return (Invoke-WebRequest @iwrParams).Content
    }

    # PS 5.1
    $OldCallback = $null
    $OldSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol

    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        if ($IgnoreCertificate) {
            $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }

        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.Method = "GET"
        $req.Accept = "application/vnd.ibm.powervm.uom+xml; type=$Type"
        $req.Headers.Add("X-API-Session", $HmcSession.Session)
        $req.KeepAlive = $false
        $req.ProtocolVersion = [Version]"1.1"
        $req.UserAgent = "PowerShell/5.1"
        $req.Timeout = 60000
        $req.ReadWriteTimeout = 60000

        $resp = $req.GetResponse()
        try {
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            return $reader.ReadToEnd()
        }
        finally { $resp.Close() }
    }
    finally {
        [Net.ServicePointManager]::SecurityProtocol = $OldSecurityProtocol

        if ($IgnoreCertificate) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
        }
    }
}

function Invoke-HmcUomGet {
    param(
        [Parameter(Mandatory)]$HmcSession,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Type,
        [switch]$IgnoreCertificate
    )

    $ip   = if ($HmcSession.HMCIP)   { $HmcSession.HMCIP }   else { $HmcSession.Ip }
    $port = if ($HmcSession.HMCPort) { $HmcSession.HMCPort } else { $HmcSession.Port }

    $base = "https://$ip`:$port/rest/api/uom"
    $url  = "$base/$Path".Replace("//","/").Replace("https:/","https://")

    HMC_GetUomXml -HmcSession $HmcSession -Url $url -Type $Type -IgnoreCertificate:$IgnoreCertificate
}

function Get-AtomSelfLinks {
    param([Parameter(Mandatory)][string]$AtomXml)

    [xml]$fx = $AtomXml
    $ns = New-Object System.Xml.XmlNamespaceManager -ArgumentList $fx.NameTable
    $ns.AddNamespace("a", "http://www.w3.org/2005/Atom")

    return $fx.SelectNodes("//a:entry/a:link[@rel='SELF']/@href", $ns) | ForEach-Object { $_.Value }
}
function Get-AtomEntryUoms {
    param([Parameter(Mandatory)][string]$AtomXml)

    [xml]$doc = $AtomXml
    $entries = $doc.SelectNodes("//*[local-name()='entry']")
    foreach ($e in $entries) {
        $content = $e.SelectSingleNode("./*[local-name()='content']")
        if ($content -and -not [string]::IsNullOrWhiteSpace($content.InnerXml)) {
            [xml]$uom = $content.InnerXml
            $uom
        }
    }
}

function Convert-AtomEntryToUomXml {
  <#
  .SYNOPSIS
    Takes an atom <entry> (LPAR detail, etc.) and returns the UOM XML from <content>.
  #>
    param([Parameter(Mandatory)][string]$AtomEntryXml)  
    [xml]$doc = $AtomEntryXml
    $content = $doc.SelectSingleNode("/*[local-name()='entry']/*[local-name()='content']")
    if (-not $content -or [string]::IsNullOrWhiteSpace($content.InnerXml)) {
        throw "Kein <content> im Atom entry gefunden."
    }
    [xml]$uom = $content.InnerXml
    $uom
}

function Get-XmlValue {
    param([Parameter(Mandatory)][xml]$Xml,[Parameter(Mandatory)][string]$LocalName)
    $n = $Xml.SelectSingleNode("//*[local-name()='$LocalName']")
    if ($n) { $n.InnerText.Trim() } else { $null }
}

function Get-FirstXmlValue {
    param([Parameter(Mandatory)][xml]$Xml,[Parameter(Mandatory)][string[]]$Names)
    foreach($name in $Names){
        $v = Get-XmlValue -Xml $Xml -LocalName $name
        if ($v) { return $v }
    }
    $null
}
function Get-FirstXmlText {
    param(
        [Parameter(Mandatory)][xml]$Xml,
        [Parameter(Mandatory)][string[]]$XPaths
    )
    foreach ($xp in $XPaths) {
        $n = $Xml.SelectSingleNode($xp)
        if ($n -and $n.InnerText) {
            $t = $n.InnerText.Trim()
            if ($t) { return $t }
        }
    }
    return $null
}
function Get-FirstXmlHref {
    param([Parameter(Mandatory)][xml]$Xml, [Parameter(Mandatory)][string[]]$XPaths)
    foreach ($xp in $XPaths) {
        $n = $Xml.SelectSingleNode($xp)
        if ($n -and $n.Value) { return $n.Value.Trim() }          # @href
        if ($n -and $n.InnerText) { return $n.InnerText.Trim() }  # fallback
    }
    $null
}

function Get_PropHelper {
    param($Obj, [string[]]$Names)
    foreach($n in $Names){
        if($Obj -and ($Obj.PSObject.Properties.Name -contains $n)){
            $v = $Obj.$n
            if($null -ne $v -and -not [string]::IsNullOrWhiteSpace([string]$v)){ return $v }
        }
    }
    return $null
}