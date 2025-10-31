<#
.SYNOPSIS
    Sign all .ps1 and .psm1 files of the module recursively with a code signing certificate.
.DESCRIPTION
    This script automatically signs all function files from the known module folders:
    DBFunc, DashBoard, TOOLFunc, USER, Server\IBMPower, Storage\IBM, SAN\Brocade, HealthCheck, GUI.
    The main file (.psm1) is also signed.

.PARAMETER CertificateName
    Optional filter for the certificate name (part of the subject).
.EXAMPLE
    .\Sign-Module.ps1 -CertificateName "MyCodeSigningCert"
#>

param(
    
    [string]$CertificateName = "",  # Part of the certificate name
    [string]$ModuleRoot = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
)

Write-Host "Searching for code signing certificate..." -ForegroundColor Cyan

# ZSearch for certificate
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert |
        Where-Object { $_.Subject -match $CertificateName } |
        Select-Object -First 1

if (-not $cert) {
    Write-Host "No code signing certificate named ‘$CertificateName’ found." -ForegroundColor Red
    Write-Host "If necessary, create a new certificate with:"
    Write-Host "New-SelfSignedCertificate -DnsName 'MyCodeSigningCert' -Type CodeSigningCert -CertStoreLocation Cert:\CurrentUser\My"
    exit 1
}

Write-Host " Certificate found: $($cert.Subject)" -ForegroundColor Green
Write-Host "`n Sign module files in:" $ModuleRoot -ForegroundColor Yellow

# Folders to be signed
$ModulePaths = @(
    "$ModuleRoot\TOOLFunc\DBFunc",
    "$ModuleRoot\TOOLFunc\DashBoard",
    "$ModuleRoot\TOOLFunc",
    "$ModuleRoot\USER",
    "$ModuleRoot\Server\IBMPower",
    "$ModuleRoot\Storage\IBM",
    "$ModuleRoot\SAN\Brocade",
    "$ModuleRoot\HealthCheck",
    "$ModuleRoot\GUI",
    $ModuleRoot
)

# Collect all .ps1 and .psm1 files from the module folders.
$ModuleFiles = @()
foreach ($path in $ModulePaths) {
    if (Test-Path $path) {
        $ModuleFiles += Get-ChildItem -Path $path -Include *.ps1, *.psm1 -Recurse -ErrorAction SilentlyContinue
    }
}

if (-not $ModuleFiles) {
    Write-Host "No files found to sign." -ForegroundColor Yellow
    exit
}

# Sign each file
foreach ($file in $ModuleFiles) {
    try {
        Write-Host "Sign: $($file.FullName)" -ForegroundColor Gray
        [void](Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $cert)
    }
    catch {
        Write-Warning "Error signing $($file.FullName): $_"
    }
}

Write-Host "`n Module successfully signed!" -ForegroundColor Green

# Optional: Signature verification at the end
Write-Host "`n Check signatures..." -ForegroundColor Cyan
foreach ($file in $ModuleFiles) {
    $sig = Get-AuthenticodeSignature $file.FullName
    $color = if ($sig.Status -eq 'Valid') { 'Green' } else { 'Red' }
    Write-Host "$($file.Name): $($sig.Status)" -ForegroundColor $color
}

Write-Host "`n Done! All validly signed files are now ready for systems with an ‘AllSigned’ policy." -ForegroundColor Cyan