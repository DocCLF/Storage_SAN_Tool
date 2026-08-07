function Initialize-LiveCharts {
    <#
    .SYNOPSIS
        Loads the required LiveChartsCore and SkiaSharp assemblies.

    .DESCRIPTION
        Selects the correct assembly folder depending on whether the tool
        runs in Windows PowerShell 5.1 or PowerShell 7.

        The function also adds the selected directory to the process PATH
        so that the native SkiaSharp and HarfBuzz DLLs can be resolved.

    .OUTPUTS
        System.Boolean

        Returns $true when the LiveCharts assemblies are available.

    .EXAMPLE
        Initialize-LiveCharts

    .NOTES
        Expected folder structure:

        Resources\LiveChartsCore\PWSH5
        Resources\LiveChartsCore\PWSH7
    #>

    [CmdletBinding()]
    param (
        # Optional explicit module root.
        # Normally $PSRootPath from the Storage_SAN_Tool is used.
        [string]$ModuleRoot = $PSRootPath
    )

    try {
        # If the WPF chart type is already available, no second load is needed.
        if ('LiveChartsCore.SkiaSharpView.WPF.CartesianChart' -as [type]) {
            return $true
        }

        if ([string]::IsNullOrWhiteSpace($ModuleRoot)) {
            throw 'The module root path is empty.'
        }

        if (-not (Test-Path -LiteralPath $ModuleRoot -PathType Container)) {
            throw "The module root path does not exist: $ModuleRoot"
        }

        # Windows PowerShell 5.1 uses the .NET Framework assemblies.
        # PowerShell 7 uses the modern .NET assemblies.
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $RuntimeFolder = 'PWSH5'
        }
        elseif ($PSVersionTable.PSEdition -eq 'Core') {
            $RuntimeFolder = 'PWSH7'
        }
        else {
            throw "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
        }

        $LiveChartsPath = Join-Path -Path $ModuleRoot -ChildPath "Resources\LiveChartsCore\$RuntimeFolder"

        if (-not (Test-Path -LiteralPath $LiveChartsPath -PathType Container)) {
            throw "The LiveCharts directory does not exist: $LiveChartsPath"
        }

        # LiveCharts/SkiaSharp native assets are currently provided only for x64.
        if (-not [Environment]::Is64BitProcess) {
            throw 'LiveCharts requires a 64-bit PowerShell process because only the x64 native DLLs are included.'
        }

        # Native DLLs such as libSkiaSharp.dll and libHarfBuzzSharp.dll
        # must be discoverable by the Windows DLL loader.
        $PathEntries = $env:PATH -split ';'

        if ($PathEntries -notcontains $LiveChartsPath) {
            $env:PATH = "$LiveChartsPath;$env:PATH"
        }

        # All expected files are checked before the first assembly is loaded.
        # This avoids partially loading the dependency chain.
        $RequiredFiles = @(
            'OpenTK.dll'
            'GLWpfControl.dll'
            'HarfBuzzSharp.dll'
            'SkiaSharp.dll'
            'SkiaSharp.HarfBuzz.dll'
            'SkiaSharp.Views.Desktop.Common.dll'
            'SkiaSharp.Views.WPF.dll'
            'LiveChartsCore.dll'
            'LiveChartsCore.SkiaSharpView.dll'
            'LiveChartsCore.SkiaSharpView.WPF.dll'
            'libSkiaSharp.dll'
            'libHarfBuzzSharp.dll'
        )

        $MissingFiles = foreach ($RequiredFile in $RequiredFiles) {
            $RequiredPath = Join-Path -Path $LiveChartsPath -ChildPath $RequiredFile

            if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
                $RequiredPath
            }
        }

        if ($MissingFiles) {
            throw @"
The following LiveCharts dependencies are missing:

$($MissingFiles -join [Environment]::NewLine)
"@
        }

        # Managed assemblies are loaded from the lowest-level dependencies
        # up to the WPF-specific LiveCharts assembly.
        #
        # Native DLLs are not loaded through Assembly.LoadFrom().
        # They are resolved automatically through the process PATH.
        $ManagedAssemblies = @(
            'OpenTK.dll'
            'GLWpfControl.dll'
            'HarfBuzzSharp.dll'
            'SkiaSharp.dll'
            'SkiaSharp.HarfBuzz.dll'
            'SkiaSharp.Views.Desktop.Common.dll'
            'SkiaSharp.Views.WPF.dll'
            'LiveChartsCore.dll'
            'LiveChartsCore.SkiaSharpView.dll'
            'LiveChartsCore.SkiaSharpView.WPF.dll'
        )

        foreach ($AssemblyName in $ManagedAssemblies) {
            $AssemblyPath = Join-Path -Path $LiveChartsPath -ChildPath $AssemblyName

            # Avoid loading an assembly again when it already exists
            # in the current AppDomain.
            $ExistingAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
                Where-Object {
                    $_.GetName().Name -eq
                    [System.IO.Path]::GetFileNameWithoutExtension($AssemblyName)
                } |
                Select-Object -First 1

            if ($ExistingAssembly) {
                continue
            }

            [System.Reflection.Assembly]::LoadFrom($AssemblyPath) | Out-Null
        }

        # Final validation of the type needed by the XAML parser.
        if (-not ('LiveChartsCore.SkiaSharpView.WPF.CartesianChart' -as [type])) {
            throw 'The LiveCharts assemblies were loaded, but CartesianChart is still unavailable.'
        }

        Write-Verbose "LiveCharts successfully loaded from: $LiveChartsPath"

        return $true
    }
    catch {
        Write-Host "LiveCharts initialization failed: $($_.Exception.Message)" -ForegroundColor Red

        Write-Host $_.Exception.ToString()

        return $false
    }
}