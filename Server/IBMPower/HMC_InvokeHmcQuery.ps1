function HMC_InvokeHmcQuery {
    <#
    .SYNOPSIS
        High-level wrapper: Login -> Query -> Logout.

    .DESCRIPTION
        Opens one HMC session, performs the requested query and always
        closes the session in the finally block.

    .PARAMETER Query
        HMC            - Management Console information
        ManagedSystems - Managed System information
        LPARs          - Logical Partitions only
        VIOS           - Virtual I/O Servers only
        Partitions     - Logical Partitions and VIOS
        Both           - Managed Systems and all Partitions
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HMCIP,

        [int]$HMCPort = 12443,

        $CredentialUN,

        $CredentialPW,

        [pscredential]$Credential,

        [ValidateSet(
            'HMC',
            'ManagedSystems',
            'LPARs',
            'VIOS',
            'Partitions',
            'Both'
        )]
        [string]$Query = 'ManagedSystems',

        [string]$ManagedSystemUuid,

        [switch]$IgnoreCertificate
    )

    [Net.ServicePointManager]::SecurityProtocol =
        [Net.SecurityProtocolType]::Tls12

    # Resolve credentials
    if ($Credential) {
        $user = $Credential.UserName
        $pass = $Credential.GetNetworkCredential().Password
    }
    else {
        if (
            [string]::IsNullOrWhiteSpace([string]$CredentialUN) -or
            [string]::IsNullOrWhiteSpace([string]$CredentialPW)
        ) {
            throw 'No credentials supplied. Use -Credential or CredentialUN/CredentialPW.'
        }

        $user = [string]$CredentialUN
        $pass = [string]$CredentialPW
    }

    $session = $null

    try {
        # Login
        $session = SST_GetHMCPowerToken `
            -HMCIP $HMCIP `
            -HMCPort $HMCPort `
            -CredentialUN $user `
            -CredentialPW $pass `
            -IgnoreCertificate:$IgnoreCertificate

        if (-not $session -or -not $session.Session) {
            throw 'Login failed: session token is empty.'
        }

        # Managed-system data is required by all partition queries.
        $msList = $null

        if ($Query -in @('LPARs', 'VIOS', 'Partitions', 'Both')) {
            $msList = @(
                HMC_GetManagedSystems `
                    -HmcSession $session `
                    -IgnoreCertificate:$IgnoreCertificate
            )

            if ($ManagedSystemUuid) {
                $msList = @(
                    $msList | Where-Object {
                        $_.UUID -eq $ManagedSystemUuid -or
                        $_.Uuid -eq $ManagedSystemUuid
                    }
                )

                if ($msList.Count -eq 0) {
                    throw "ManagedSystemUuid not found: $ManagedSystemUuid"
                }
            }
        }

        switch ($Query) {
            'HMC' {
                return HMC_GetManagementConsole -HmcSession $session -IgnoreCertificate:$IgnoreCertificate
            }

            'ManagedSystems' {
                return HMC_GetManagedSystems -HmcSession $session -IgnoreCertificate:$IgnoreCertificate
            }

            'LPARs' {
                $all = foreach ($m in $msList) {
                    if (-not $m.UUID) {
                        continue
                    }
                    HMC_GetLogicalPartitionSummary -HmcSession $session -ManagedSystemUuid $m.UUID -ManagedSystemName $m.SystemName -ManagedSystemMTMS $m.MachineTypeModel -ManagedSystemSerial $m.SerialNumber -IgnoreCertificate:$IgnoreCertificate
                }

                return $all
            }

            'VIOS' {
                $all = foreach ($m in $msList) {
                    if (-not $m.UUID) {
                        continue
                    }

                    HMC_GetVirtualIOServerSummary -HmcSession $session -ManagedSystemUuid $m.UUID -ManagedSystemName $m.SystemName -ManagedSystemMTMS $m.MachineTypeModel -ManagedSystemSerial $m.SerialNumber -IgnoreCertificate:$IgnoreCertificate
                }

                return $all
            }

            'Partitions' {
                $all = foreach ($m in $msList) {
                    if (-not $m.UUID) {
                        continue
                    }
                
                    # Normale LPARs
                    try {
                        HMC_GetLogicalPartitionSummary -HmcSession $session -ManagedSystemUuid $m.UUID -ManagedSystemName $m.SystemName -ManagedSystemMTMS $m.MachineTypeModel -ManagedSystemSerial $m.SerialNumber -IgnoreCertificate:$IgnoreCertificate
                    }
                    catch {
                        Write-Warning (
                            "LPAR query failed for Managed System '{0}': {1}" -f
                            $m.SystemName,
                            $_.Exception.Message
                        )
                    }
                
                    # VIOS unabhängig davon abrufen
                    try {
                        HMC_GetVirtualIOServerSummary -HmcSession $session -ManagedSystemUuid $m.UUID -ManagedSystemName $m.SystemName -ManagedSystemMTMS $m.MachineTypeModel -ManagedSystemSerial $m.SerialNumber -IgnoreCertificate:$IgnoreCertificate
                    }
                    catch {
                        Write-Warning (
                            "VIOS query failed for Managed System '{0}': {1}" -f
                            $m.SystemName,
                            $_.Exception.Message
                        )
                    }
                }
            
                return @($all)
            }

            'Both' {
                $partitions = foreach ($m in $msList) {
                    if (-not $m.UUID) {
                        continue
                    }

                    HMC_GetLogicalPartitionSummary -HmcSession $session -ManagedSystemUuid $m.UUID -ManagedSystemName $m.SystemName -ManagedSystemMTMS $m.MachineTypeModel -ManagedSystemSerial $m.SerialNumber -IgnoreCertificate:$IgnoreCertificate

                    HMC_GetVirtualIOServerSummary -HmcSession $session -ManagedSystemUuid $m.UUID -ManagedSystemName $m.SystemName -ManagedSystemMTMS $m.MachineTypeModel -ManagedSystemSerial $m.SerialNumber -IgnoreCertificate:$IgnoreCertificate
                }

                return [pscustomobject]@{
                    ManagedSystems = $msList
                    Partitions     = $partitions
                }
            }
        }
    }
    finally {
        if ($session) {
            SST_RemoveHMCPowerToken -HmcSession $session -IgnoreCertificate:$IgnoreCertificate | Out-Null
        }
    }
}