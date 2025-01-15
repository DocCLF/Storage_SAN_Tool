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
        [string]$TD_UserInputLogPath = $null,
        [string]$TD_UsedLogPath,
        [Parameter(ValueFromPipeline,HelpMessage="The default value for deleting files is 90 days, a range between 7-360 is possible.")]
        [Int16]$TD_KeepFilesForDays = 90
    )
    
    begin {
        <# tbt #>
        Write-Host $TD_PSRootPath -ForegroundColor Magenta
        if([string]::IsNullOrWhiteSpace($TD_UserInputLogPath)){
            $TD_UsedLogPath = "$TD_PSRootPath\ToolLog\"
        }esle{
            $TD_UsedLogPath = $TD_UserInputLogPath
        }
    }
    
    process {
        try {
            Get-ChildItem -Path $TD_UsedLogPath | Where-Object {LastWriteTime -LT $(Get-Date).AddDays(-$TD_KeepFilesForDays)} | Remove-Item -Confirm $false -Force -ErrorAction Continue
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning -TD_Shown yes
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "All files older than $TD_KeepFilesForDays days were deleted from Ptah $TD_UsedLogPath!" -TD_ToolMSGType Message -TD_Shown yes
    }
}