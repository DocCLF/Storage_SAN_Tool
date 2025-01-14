function SST_FileCleanUp {
    <#
    .SYNOPSIS

    .NOTES

    .LINK
        https://github.com/DocCLF
    .EXAMPLE
        
    .EXAMPLE
        tbt
    #>
    [CmdletBinding()]
    param (
        [string]$TD_PSRootPath = (Split-Path -Path $PSScriptRoot -Parent),
        [Int16]$TD_KeepFilesForDays = 90
    )
    
    begin {
        <# tbt #>
    }
    
    process {
        try {
            Get-ChildItem -Path $TD_PSRootPath | Where-Object LastWriteTime -LT $(Get-Date).AddDays(-$TD_KeepFilesForDays) | Remove-Item -Confirm $false -Force -InformationAction Stop
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning
        }
        
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "All files older than $TD_KeepFilesForDays days were deleted!" -TD_ToolMSGType Message no
    }
}