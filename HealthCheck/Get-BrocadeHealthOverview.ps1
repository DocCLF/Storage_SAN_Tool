function Get-BrocadeHealthOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,

        [Parameter(Mandatory)]
        $DeviceIdent,

        [Parameter(Mandatory)]
        $UCOBJ,

        [Parameter(Mandatory)]
        [object[]]$HealthCheckSteps,

        [Parameter(Mandatory)]
        $ExportPath
    )

    $Result = [ordered]@{}

    $PrivilegedCredential   = $null
    $PrivilegePromptCanceled = $false

    foreach ($HealthCheckStep in $HealthCheckSteps) {
        $CommandName = [string]$HealthCheckStep.Command

        $RequiresPrivilege = $HealthCheckStep.PSObject.Properties['RequiresPrivilege'] -and [bool]$HealthCheckStep.RequiresPrivilege

        # --------------------------------------------------------
        # First attempt using the standard device credentials
        # --------------------------------------------------------
        $StepResult = Invoke-SANHealthStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -CommandName $CommandName -Device $Device -UCOBJ $UCOBJ -ExportPath $ExportPath

        # --------------------------------------------------------
        # For privileged steps and authorization errors:
        # Request credentials once and repeat the step
        # --------------------------------------------------------
        if ($RequiresPrivilege -and(Test-BrocadePrivilegeError -Result $StepResult)) {
            if ($null -eq $PrivilegedCredential -and -not $PrivilegePromptCanceled) {
                $Message = @"
The currently logged-in user does not have the necessary permissions to
read one or more security configurations of the Brocade switch.

Please enter a user with sufficient permissions.
The credentials are used temporarily for this HealthCheck only.
"@

                $PrivilegedCredential =
                    Get-Credential -Message $Message

                if ($null -eq $PrivilegedCredential) {
                    $PrivilegePromptCanceled = $true
                }
            }

            if ($null -ne $PrivilegedCredential) {
                Set-SANHealthCheckStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -Status Running -Details 'Retrying with privileged credentials.' -DataCount 0 | Out-Null

                $StepResult = Invoke-SANHealthStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -CommandName $CommandName -Device $Device -UCOBJ $UCOBJ -Credential $PrivilegedCredential -ExportPath $ExportPath
            }
            else {
                Set-SANHealthCheckStep -DeviceIdent $DeviceIdent -Id $HealthCheckStep.Id -Status Error -Details 'Privileged credentials were required, but credential entry was canceled.' -DataCount 0 | Out-Null
            }
        }

        $Result[$HealthCheckStep.Id] = $StepResult
    }

    # Do not retain credentials after completion.
    $PrivilegedCredential = $null

    return [PSCustomObject]$Result
}