function Get-BrocadeLicenseOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )
    $PB = New-ProgressBar

    $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-ChassisInfo completed" -PercentComplete 20
    $FCPorts = Get-BrocadeFcPorts -Device $Device
    Write-ProgressBar -ProgressBar $PB -Activity "Get-FcPorts completed" -PercentComplete 40
    $Licenses = @(Get-BrocadeLicenseInfo -Device $Device)
    Write-ProgressBar -ProgressBar $PB -Activity "Get-LicenseInfo completed" -PercentComplete 60

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
    Write-ProgressBar -ProgressBar $PB -Activity "Create Obj completed" -PercentComplete 85
    try {
        Out-File -FilePath "$($TD_TB_ExportPath.Text)\PortLicenseShow_$($ChassisInfo.'vendor-serial-number')_$(Get-Date -Format "yyyy-MM-dd").csv" -InputObject $LicenseInfo
    }
    catch {
        SST_ToolMessageCollector -TD_ToolMSGCollector "LicenseInfo: $($_.Exception.Message)" -TD_ToolMSGType "Warning" -TD_Shown "no"
    }finally{
        Close-ProgressBar -ProgressBar $PB
    }
    return $LicenseInfo
}