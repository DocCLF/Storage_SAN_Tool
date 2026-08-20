function Initialize-LiveCharts {
    <#
    .SYNOPSIS
        Loads the required LiveChartsCore and SkiaSharp assemblies.

    .DESCRIPTION
        Selects the correct assembly folder depending on whether the tool
        runs in Windows PowerShell 5.1 or PowerShell 7.

        The function also adds the selected directory to the process PATH
        so that the native SkiaSharp and HarfBuzz DLLs can be resolved.

        Windows PowerShell 5.1 additionally registers an assembly resolver.
        This is required because LiveChartsCore 2.0.5 contains dependencies
        referencing different SkiaSharp assembly versions.

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

        if ([string]::IsNullOrWhiteSpace($ModuleRoot)) {
            throw 'The module root path is empty.'
        }

        if (-not (Test-Path -LiteralPath $ModuleRoot -PathType Container)) {
            throw "The module root path does not exist: $ModuleRoot"
        }

        # -----------------------------------------------------------------
        # Select runtime-specific dependency folder
        # -----------------------------------------------------------------

        if ($PSVersionTable.PSEdition -eq 'Desktop') {

            # Windows PowerShell 5.1 / .NET Framework
            $RuntimeFolder = 'PWSH5'
        }
        elseif ($PSVersionTable.PSEdition -eq 'Core') {

            # PowerShell 7 / modern .NET
            $RuntimeFolder = 'PWSH7'
        }
        else {
            throw (
                "Unsupported PowerShell edition: " +
                "$($PSVersionTable.PSEdition)"
            )
        }

        $LiveChartsPath =
            Join-Path `
                -Path $ModuleRoot `
                -ChildPath "Resources\LiveChartsCore\$RuntimeFolder"

        if (
            -not (
                Test-Path `
                    -LiteralPath $LiveChartsPath `
                    -PathType Container
            )
        ) {
            throw (
                "The LiveCharts directory does not exist: " +
                $LiveChartsPath
            )
        }

        # -----------------------------------------------------------------
        # x64 validation
        # -----------------------------------------------------------------

        # LiveCharts/SkiaSharp native assets are currently provided only
        # for x64.
        if (-not [Environment]::Is64BitProcess) {
            throw (
                'LiveCharts requires a 64-bit PowerShell process because ' +
                'only the x64 native DLLs are included.'
            )
        }

        # -----------------------------------------------------------------
        # Native DLL search path
        # -----------------------------------------------------------------

        # Native DLLs such as libSkiaSharp.dll and libHarfBuzzSharp.dll
        # must be discoverable by the Windows DLL loader.
        $PathEntries =
            $env:PATH -split ';'

        if ($PathEntries -notcontains $LiveChartsPath) {
            $env:PATH =
                "$LiveChartsPath;$env:PATH"
        }

        # -----------------------------------------------------------------
        # Windows PowerShell 5.1 assembly resolver
        #
        # LiveChartsCore.SkiaSharpView 2.0.5 references older SkiaSharp
        # assembly versions internally, while the WPF package uses the
        # newer SkiaSharp 3.119 assemblies.
        #
        # A normal .NET application resolves this through NuGet / binding
        # redirects. A PowerShell module has no module-specific app.config,
        # therefore Windows PowerShell 5.1 resolves these assemblies
        # explicitly from the PWSH5 folder.
        #
        # PowerShell 7 does NOT use this resolver.
        # -----------------------------------------------------------------

        if ($PSVersionTable.PSEdition -eq 'Desktop') {

            if (-not ('SST.LiveChartsAssemblyResolver' -as [type])) {

                Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Linq;
using System.Reflection;

namespace SST
{
    public static class LiveChartsAssemblyResolver
    {
        private static string assemblyPath;
        private static bool registered = false;

        public static void Register(string path)
        {
            assemblyPath = path;

            if (registered)
                return;

            AppDomain.CurrentDomain.AssemblyResolve += ResolveAssembly;
            registered = true;
        }

        private static Assembly ResolveAssembly(
            object sender,
            ResolveEventArgs args)
        {
            AssemblyName requested =
                new AssemblyName(args.Name);

            // Reuse an assembly which is already loaded with the same
            // simple assembly name. The version may intentionally differ.
            Assembly loaded =
                AppDomain.CurrentDomain
                    .GetAssemblies()
                    .FirstOrDefault(
                        a => a.GetName().Name == requested.Name
                    );

            if (loaded != null)
                return loaded;

            string file =
                Path.Combine(
                    assemblyPath,
                    requested.Name + ".dll"
                );

            if (!File.Exists(file))
                return null;

            return Assembly.LoadFrom(file);
        }
    }
}
"@
            }

            [SST.LiveChartsAssemblyResolver]::Register(
                $LiveChartsPath
            )
        }

        # -----------------------------------------------------------------
        # Common dependencies for PowerShell 5.1 and PowerShell 7
        # -----------------------------------------------------------------

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

        # -----------------------------------------------------------------
        # Additional .NET Framework dependencies required only by
        # Windows PowerShell 5.1.
        # -----------------------------------------------------------------

        if ($PSVersionTable.PSEdition -eq 'Desktop') {
        
            $RequiredFiles += @(
                'System.Runtime.CompilerServices.Unsafe.dll'
                'System.Memory.dll'
            )
        }

        $MissingFiles = @(
            foreach ($RequiredFile in $RequiredFiles) {

                $RequiredPath =
                    Join-Path `
                        -Path $LiveChartsPath `
                        -ChildPath $RequiredFile

                if (
                    -not (
                        Test-Path `
                            -LiteralPath $RequiredPath `
                            -PathType Leaf
                    )
                ) {
                    $RequiredPath
                }
            }
        )

        if ($MissingFiles.Count -gt 0) {

            throw @"
The following LiveCharts dependencies are missing:

$($MissingFiles -join [Environment]::NewLine)
"@
        }

        # -----------------------------------------------------------------
        # If the final WPF chart type is already available, all required
        # assemblies have already been loaded in this process.
        #
        # This check is intentionally performed AFTER the PS5 resolver has
        # been registered.
        # -----------------------------------------------------------------

        if (
            'LiveChartsCore.SkiaSharpView.WPF.CartesianChart' -as [type]
        ) {
            return $true
        }

        # -----------------------------------------------------------------
        # Managed assemblies used by both PowerShell editions
        # -----------------------------------------------------------------
            
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
            
        # -----------------------------------------------------------------
        # Additional managed dependencies for Windows PowerShell 5.1
        #
        # These are required by SkiaSharp 3.119 when running on the
        # .NET Framework hosted by Windows PowerShell 5.1.
        #
        # PowerShell 7 resolves these through its modern .NET runtime and
        # must not require private copies in the PWSH7 directory.
        # -----------------------------------------------------------------
            
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
        
            # Insert the framework dependencies before SkiaSharp is loaded.
            $ManagedAssemblies = @(
                'OpenTK.dll'
                'GLWpfControl.dll'
                'System.Runtime.CompilerServices.Unsafe.dll'
                'System.Memory.dll'
                'HarfBuzzSharp.dll'
                'SkiaSharp.dll'
                'SkiaSharp.HarfBuzz.dll'
                'SkiaSharp.Views.Desktop.Common.dll'
                'SkiaSharp.Views.WPF.dll'
                'LiveChartsCore.dll'
                'LiveChartsCore.SkiaSharpView.dll'
                'LiveChartsCore.SkiaSharpView.WPF.dll'
            )
        }

        foreach ($AssemblyName in $ManagedAssemblies) {

            $AssemblyPath =
                Join-Path `
                    -Path $LiveChartsPath `
                    -ChildPath $AssemblyName

            $ExpectedAssemblyName =
                [System.IO.Path]::GetFileNameWithoutExtension(
                    $AssemblyName
                )

            # Avoid loading the same assembly more than once.
            $ExistingAssembly =
                [AppDomain]::CurrentDomain.GetAssemblies() |
                    Where-Object {
                        $_.GetName().Name -eq
                        $ExpectedAssemblyName
                    } |
                    Select-Object -First 1

            if ($null -ne $ExistingAssembly) {
                continue
            }

            [System.Reflection.Assembly]::LoadFrom(
                $AssemblyPath
            ) |
                Out-Null
        }

        # -----------------------------------------------------------------
        # Final validation
        # -----------------------------------------------------------------

        if (
            -not (
                'LiveChartsCore.SkiaSharpView.WPF.CartesianChart' -as [type]
            )
        ) {
            throw (
                'The LiveCharts assemblies were loaded, but ' +
                'CartesianChart is still unavailable.'
            )
        }

        Write-Verbose (
            "LiveCharts successfully loaded from: $LiveChartsPath"
        )

        return $true
    }
    catch {

        Write-Host (
            "LiveCharts initialization failed: " +
            "$($_.Exception.Message)"
        ) -ForegroundColor Red

        Write-Host $_.Exception.ToString()

        return $false
    }
}