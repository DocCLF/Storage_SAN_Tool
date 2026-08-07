function Get-BrocadeUserCFGOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $PB = New-ProgressBar

    try {
        $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
        $ChassisInfo = Get-BrocadeChassisInfo -Device $Device

        $SwitchName = $SwitchInfo.'user-friendly-name'
        if ([string]::IsNullOrWhiteSpace($SwitchName)) {
            $SwitchName = "Unknown_$($ChassisInfo.'vendor-serial-number')"
        }
        Write-ProgressBar -ProgressBar $PB -Activity 'Get-BrocadeSecurity completed' -PercentComplete 20

        
        $IsRestError = $true
        if ($IsRestError) {
            if ($SwitchUsercfgInfo.StatusCode -in 401, 403 -or $SwitchUsercfgInfo.Error -match '\(400\)' -or $IsRestError) {
                $Message = @"
The currently logged-in user does not have the necessary permissions to
read the security configuration of the Brocade switch.

Please enter a user with sufficient permissions.
"@

                $PrivilegedCredential = Get-Credential -Message $Message

                if ($null -eq $PrivilegedCredential) {
                    return [PSCustomObject]@{
                        Success    = $false
                        Uri        = $SwitchUsercfgInfo.Uri
                        Data       = $null
                        Error      = 'The entry of privileged credentials was canceled.'
                        StatusCode = $SwitchUsercfgInfo.StatusCode
                    }
                }

                Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 40

                $SwitchUsercfgInfo = Get-BrocadeUsercfg -Device $Device -Credential $PrivilegedCredential

                $PrivilegedCredential = $null

                if ($SwitchUsercfgInfo.PSObject.Properties['Success'] -and -not $SwitchUsercfgInfo.Success) {
                    return $SwitchUsercfgInfo
                }
            }else {
                return $SwitchUsercfgInfo
            }
        }
        Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 60

        $RowID = "$($SwitchUsercfgInfo.count)|$($Device.ID)"
        $CreationTime = Get-Date -Format "yyyy/MM/dd HH:mm"
        $i=60
        $UserConfiguration = foreach ($User in $SwitchUsercfgInfo) {
            if($i -le 95){$i = $i + 5}
            Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete $i
            
            $VirtualFabricRoles = @($User.'virtual-fabric-role-id-list' | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) } )
                
            [PSCustomObject]@{
                UserName                = [string]$User.name
                Description             = [string]$User.'account-description'
                IsEnabled               = [bool]$User.'account-enabled'
                UsesDefaultPassword     = [bool]$User.'default-password-configured'
                PasswordChangeEnforced  = [bool]$User.'password-change-enforced'
                IsLocked                = [bool]$User.'account-locked'
                HomeVirtualFabric       = $User.'home-virtual-fabric'
                VirtualFabricRoles      = $VirtualFabricRoles
                VirtualFabricRolesText  = $VirtualFabricRoles -join ', '
                ChassisAccessRole       = [string]$User.'chassis-access-role'
                AccessStartTime         = $User.'access-start-time'
                AccessEndTime           = $User.'access-end-time'
                AuthTokenPresent        = [bool]$User.'auth-token-present'
                CreationTime            = $CreationTime
                RawData                 = $User
                RowID                   = $RowID
            }
        }

        Write-ProgressBar -ProgressBar $PB -Activity 'Security information collected' -PercentComplete 100
        Out-File -FilePath "$($TD_TB_ExportPath.Text)\UserConfiguration_$($SwitchName)_$(Get-Date -Format "yyyy-MM-dd").csv" -InputObject $UserConfiguration
        
    }
    finally {
        Close-ProgressBar -ProgressBar $PB
    }
    return $UserConfiguration
}