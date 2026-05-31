function Get-BrocadeLicenseOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    $FCPorts = Get-BrocadeFcPorts -Device $Device
    $Licenses = @(Get-BrocadeLicenseInfo -Device $Device)

    $LicensedPorts = @(
        $FCPorts | Where-Object {
            $_.'pod-license-status' -eq $true
        }
    ).Count

    $ReservedPorts = @(
        $FCPorts | Where-Object {
            $_.'pod-license-state' -eq 'reserved'
        }
    ).Count

    $FreePorts = @(
        $FCPorts | Where-Object {
            $_.'pod-license-status' -eq $false
        }
    ).Count

    $LicenseInfo = [PSCustomObject]@{
        LicenseID = $ChassisInfo.'license-id'
        Licenses = $Licenses
        LicenseNames = @($Licenses.LicenseName)
        LicenseName = @($Licenses.LicenseName) -join ', '
        LicenseCount = @($Licenses).Count
        LicensedPorts = $LicensedPorts
        ReservedPorts = $ReservedPorts
        FreePorts = $FreePorts
    }
    try {
        Out-File -FilePath "$($TD_TB_ExportPath.Text)\PortLicenseShow_$($ChassisInfo.'vendor-serial-number')_$(Get-Date -Format "yyyy-MM-dd").csv" -InputObject $LicenseInfo
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "LicenseInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
    }
    return $LicenseInfo
}