# Universal psm file
# Requires -Version 5.0
# Get functions files
<# 
The Unblock-File cmdlet lets you open files that were downloaded from the internet. 
It unblocks PowerShell script files that were downloaded from the internet so you can run them, even when the PowerShell execution policy is RemoteSigned. 
By default, these files are blocked to protect the computer from untrusted files.
#>
    Unblock-File -Path $PSScriptRoot\TOOLFunc\DBFunc\*.ps1 -Confirm:$false
    $DBFunc_Functions = @(Get-ChildItem -Path $PSScriptRoot\TOOLFunc\DBFunc\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\TOOLFunc\DashBoard\*.ps1 -Confirm:$false
    $DashBoard_Functions = @(Get-ChildItem -Path $PSScriptRoot\TOOLFunc\DashBoard\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\TOOLFunc\*.ps1 -Confirm:$false
    $TOOL_Functions = @(Get-ChildItem -Path $PSScriptRoot\TOOLFunc\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\USER\*.ps1 -Confirm:$false
    $USER_Functions = @(Get-ChildItem -Path $PSScriptRoot\USER\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\Server\IBMPower\*.ps1 -Confirm:$false
    $IBMPower_Functions = @(Get-ChildItem -Path $PSScriptRoot\Server\IBMPower\*.ps1 -ErrorAction SilentlyContinue)
<<<<<<< Updated upstream
    Unblock-File -Path $PSScriptRoot\Storage\IBM\*.ps1 -Confirm:$false
    $IBMStorage_Functions = @(Get-ChildItem -Path $PSScriptRoot\Storage\IBM\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\SAN\Brocade\*.ps1 -Confirm:$false
    $FOSBrocade_Functions = @(Get-ChildItem -Path $PSScriptRoot\SAN\Brocade\*.ps1 -ErrorAction SilentlyContinue)
=======
    Unblock-File -Path $PSScriptRoot\Storage\IBM\REST\*.ps1 -Confirm:$false
    $IBMStorage_RESTFunctions = @(Get-ChildItem -Path $PSScriptRoot\Storage\IBM\REST\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\Storage\IBM\SSH\*.ps1 -Confirm:$false
    $IBMStorage_SSHFunctions = @(Get-ChildItem -Path $PSScriptRoot\Storage\STOLiveChart\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\Storage\IBM\SSH\*.ps1 -Confirm:$false
    $IBMStorage_STOLCFunctions = @(Get-ChildItem -Path $PSScriptRoot\Storage\STOLiveChart\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\SAN\Brocade\SSH\*.ps1 -Confirm:$false
    $FOSBrocade_SSHFunctions = @(Get-ChildItem -Path $PSScriptRoot\SAN\Brocade\SSH\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\SAN\Brocade\REST\*.ps1 -Confirm:$false
    $FOSBrocade_RESTFunctions = @(Get-ChildItem -Path $PSScriptRoot\SAN\Brocade\REST\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\Tape\*.ps1 -Confirm:$false
    $IBMTape_Functions = @(Get-ChildItem -Path $PSScriptRoot\Tape\*.ps1 -ErrorAction SilentlyContinue)
>>>>>>> Stashed changes
    Unblock-File -Path $PSScriptRoot\HealthCheck\*.ps1 -Confirm:$false
    $HealthCheck_Functions = @(Get-ChildItem -Path $PSScriptRoot\HealthCheck\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\TOOLFunc\LiveCharts\*.ps1 -Confirm:$false
    $LiveCharts_Functions = @(Get-ChildItem -Path $PSScriptRoot\TOOLFunc\LiveCharts\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSScriptRoot\GUI\*.ps1 -Confirm:$false
    $GUI_Functions = @(Get-ChildItem -Path $PSScriptRoot\GUI\*.ps1 -ErrorAction SilentlyContinue)

    $FoundErrors = @(

<<<<<<< Updated upstream
        foreach($import in @($DBFunc_Functions + $DashBoard_Functions + $TOOL_Functions + $USER_Functions + $IBMPower_Functions + $IBMStorage_Functions + $FOSBrocade_Functions + $HealthCheck_Functions + $GUI_Functions)) {
=======
        foreach($import in @($REST_Functions + $LiveCharts_Functions + $GUIBasics_Functions + $DBFunc_Functions + $IBMTape_Functions +$PRISIMFunc_Functions + $DashBoard_Functions + $TOOL_Functions + $IBMPower_Functions + $IBMStorage_STOLCFunctions + $IBMStorage_SSHFunctions + $IBMStorage_RESTFunctions + $FOSBrocade_SSHFunctions + $FOSBrocade_RESTFunctions + $HealthCheck_Functions + $GUI_Functions)) {
>>>>>>> Stashed changes
            try {
               . $import.fullname
            }
            catch {
                Write-Error -Message "Failed to import function $($import.fullname): $_"
            }
        }

    )

    if ($FoundErrors.Count -gt 0) {
        $ModuleName = (Get-ChildItem $PSScriptRoot\*.psd1).BaseName
        Write-Warning "Importing module $ModuleName failed. Fix errors before continuing."
        break
    }
# Export everything in the public folder
Export-ModuleMember -Function * -Cmdlet * -Alias *