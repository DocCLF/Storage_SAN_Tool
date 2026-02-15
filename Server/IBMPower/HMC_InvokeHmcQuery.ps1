function HMC_InvokeHmcQuery {
    <#
      .SYNOPSIS
        High-Level Wrapper: Login -> Query (ManagedSystems/LPARs/Both) -> Logout (always).
      .DESCRIPTION
        Designed for tools/GUI usage: everything runs in one scope and cleans up the session in finally.
      .PARAMETER HMCIP
        HMC IP/Hostname
      .PARAMETER HMCPort
        HMC port (default 12443)
      .PARAMETER CredentialUN
        Username (if -Credential not supplied)
      .PARAMETER CredentialPW
        Password (if -Credential not supplied)
      .PARAMETER Credential
        PSCredential (preferred in scripts/tools)
      .PARAMETER Query
        HMC | ManagedSystems | LPARs
      .PARAMETER ManagedSystemUuid
        If Query=LPARs: optional filter for one ManagedSystem UUID
      .PARAMETER IgnoreCertificate
        Ignore TLS cert validation (PS5.1 via callback, PS7 via SkipCertificateCheck in lower funcs)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HMCIP,
        [Parameter()][int]$HMCPort = 12443,

        [Parameter(Mandatory=$false)]$CredentialUN,
        [Parameter(Mandatory=$false)]$CredentialPW,
        [Parameter(Mandatory=$false)][pscredential]$Credential,

        [ValidateSet('HMC','ManagedSystems','LPARs','Both')]
        [string]$Query = 'ManagedSystems',

        [Parameter(Mandatory=$false)][string]$ManagedSystemUuid,

        [switch]$IgnoreCertificate
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Resolve credentials
    if ($Credential) {
        $user = $Credential.UserName
        $pass = $Credential.GetNetworkCredential().Password
    }
    else {
        if ([string]::IsNullOrWhiteSpace($CredentialUN) -or [string]::IsNullOrWhiteSpace([string]$CredentialPW)) {
            throw "No credentials supplied. Use -Credential or (-CredentialUN and -CredentialPW)."
        }
        $user = [string]$CredentialUN
        $pass = [string]$CredentialPW
    }

    $session = $null
    try {
        # 1) Login / Token
        $session = SST_GetHMCPowerToken `
            -HMCIP $HMCIP `
            -HMCPort $HMCPort `
            -CredentialUN $user `
            -CredentialPW $pass `
            -IgnoreCertificate:$IgnoreCertificate

        if (-not $session -or -not $session.Session) {
            throw "Login failed: session token is empty."
        }

        # 2) Query
        switch ($Query) {

            'HMC' {
                return (HMC_GetManagementConsole -HmcSession $session -IgnoreCertificate:$IgnoreCertificate)
            }

            'ManagedSystems' {
                return (HMC_GetManagedSystems -HmcSession $session -IgnoreCertificate:$IgnoreCertificate)
            }

            'LPARs' {
                $msList = HMC_GetManagedSystems -HmcSession $session -IgnoreCertificate:$IgnoreCertificate

                if ($ManagedSystemUuid) {
                    $m = $msList | Where-Object { $_.Uuid -eq $ManagedSystemUuid -or $_.UUID -eq $ManagedSystemUuid } | Select-Object -First 1
                    if (-not $m) {
                        throw "ManagedSystemUuid not found: $ManagedSystemUuid"
                    }

                    return (HMC_GetLogicalPartitionSummary `
                        -HmcSession $session `
                        -ManagedSystemUuid $m.UUID `
                        -ManagedSystemName $m.SystemName `
                        -ManagedSystemMTMS $m.MachineTypeModel `
                        -ManagedSystemSerial $m.SerialNumber `
                        -IgnoreCertificate:$IgnoreCertificate)
                }

                $all = foreach ($m in $msList) {
                    if (-not $m.UUID) { continue }
                    HMC_GetLogicalPartitionSummary `
                        -HmcSession $session `
                        -ManagedSystemUuid $m.UUID `
                        -ManagedSystemName $m.SystemName `
                        -ManagedSystemMTMS $m.MachineTypeModel `
                        -ManagedSystemSerial $m.SerialNumber `
                        -IgnoreCertificate:$IgnoreCertificate
                }
                return $all
            }
        }
    }
    finally {
        # 3) Logout always
        if ($session) {
            SST_RemoveHMCPowerToken -HmcSession $session -IgnoreCertificate:$IgnoreCertificate | Out-Null
        }
    }
}
