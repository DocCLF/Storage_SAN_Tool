# Universal psm file
# Requires -Version 5.0
# Get functions files

    Unblock-File -Path $PSRootPath\TOOLFunc\*.ps1
    $TOOL_Functions = @(Get-ChildItem -Path $PSScriptRoot\TOOLFunc\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSRootPath\USER\*.ps1
    $USER_Functions = @(Get-ChildItem -Path $PSScriptRoot\USER\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSRootPath\Storage\IBM\*.ps1
    $IBMStorage_Functions = @(Get-ChildItem -Path $PSScriptRoot\Storage\IBM\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSRootPath\SAN\Brocade\*.ps1
    $FOSBrocade_Functions = @(Get-ChildItem -Path $PSScriptRoot\SAN\Brocade\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSRootPath\HealthCheck\*.ps1
    $HealthCheck_Functions = @(Get-ChildItem -Path $PSScriptRoot\HealthCheck\*.ps1 -ErrorAction SilentlyContinue)
    Unblock-File -Path $PSRootPath\GUI\*.ps1
    $GUI_Functions = @(Get-ChildItem -Path $PSScriptRoot\GUI\*.ps1 -ErrorAction SilentlyContinue)

    $FoundErrors = @(

        foreach($import in @($TOOL_Functions + $USER_Functions + $IBMStorage_Functions + $FOSBrocade_Functions + $HealthCheck_Functions + $GUI_Functions)) {
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