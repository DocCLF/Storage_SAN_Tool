function Get-IBMHealthOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,

        [Parameter(Mandatory)]
        $DeviceIdent,

        [Parameter(Mandatory)]
        $UCOBJ,

        [Parameter(Mandatory)]
        $ExportPath,

        [Parameter(Mandatory)]
        [object[]]$HealthCheckSteps
    )

    $Result = [ordered]@{}

    $PrivilegedCredential    = $null
    $PrivilegePromptCanceled = $false

    foreach ($HealthCheckStep in $HealthCheckSteps) {

        $CommandName = [string]$HealthCheckStep.Command

        $RequiresPrivilege = ($HealthCheckStep.PSObject.Properties['RequiresPrivilege'] -and [bool]$HealthCheckStep.RequiresPrivilege)

        # First attempt using the standard device credentials
        $StepResult = Invoke-IBMStorageHealthStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -CommandName $CommandName -Device $Device -UCOBJ $UCOBJ -ExportPath $ExportPath

        # Only for marked steps and in the event of a
        # authorization error, prompt for privileged credentials.
        if ($RequiresPrivilege -and (Test-IBMStoragePrivilegeError -Result $StepResult)) {
            if ($null -eq $PrivilegedCredential -and-not $PrivilegePromptCanceled) {
                $Message = @"
The currently configured user does not have sufficient permissions to
collect one or more security-related IBM Storage information sets.

Please enter a user with sufficient permissions.

The credentials are used temporarily for this HealthCheck only.
"@

                $PrivilegedCredential = Get-Credential -Message $Message

                if ($null -eq $PrivilegedCredential) {
                    $PrivilegePromptCanceled = $true
                }
            }

            if ($null -ne $PrivilegedCredential) {
                Set-IBMStorageHealthCheckStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -Status Running -Details 'Retrying with privileged credentials.' -DataCount 0 | Out-Null

                $StepResult = Invoke-IBMStorageHealthStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -CommandName $CommandName -Device $Device -UCOBJ $UCOBJ -Credential $PrivilegedCredential -ExportPath $ExportPath
            }
            else {
                Set-IBMStorageHealthCheckStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -Status Error -Details 'Privileged credentials were required, but credential entry was canceled.' -DataCount 0 | Out-Null
            }
        }

        $Result[$HealthCheckStep.Id] = $StepResult
    }

    # Remove the reference after completion.
    $PrivilegedCredential = $null

    return [PSCustomObject]$Result
}