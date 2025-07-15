function SST_FileCleanUp {
    <#
    .SYNOPSIS
        Deletes all files after 90 days in the specified directory.
    .DESCRIPTION
        This function is mainly used in my tool to delete the log files of the tool after 90 days (default) to keep the number limited.
        Another function in my tool is to delete the created *csv files of the individual functions after 30-60 days in order to limit their number.
        With a little skill you can also customize and modify this small function so that it can also be used for other things / files.
    .NOTES
        Beware, it is currently deleted without request and consideration of other files that may still be in the respective Versichniss.

    .EXAMPLE
        Use it with Default Settings, only usefull with SST-Tool 
        Default Values are TooLog Folder and 90 Days
        SST_FileCleanUp
    .EXAMPLE
        Change the Default Path and Days
        SST_FileCleanUp -TD_UserInputPath C:\MyOwnLogFolder\ -TD_KeepFilesForDays 28
    .LINK
        https://github.com/DocCLF
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline,HelpMessage="The default path goes to the ToolLog directory, if you want to change this then enter the full path here.")]
        [string]$TD_UserInputPath = $null,
        [Parameter(ValueFromPipeline,HelpMessage="The default value for deleting files is 90 days, a range between 7-360 is possible.")]
        [Int16]$TD_KeepFilesForDays = 90,
        [Parameter(ValueFromPipeline,HelpMessage="To delete files and/or folders with commonly used attributes, use the TD_DeleteWhat parameter. !Directory (delete files only (default)) or None (deletes all file and folders).")]
        [string]$TD_DeleteWhat = "!Directory" 
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [string]$TD_PSRootPath = (Split-Path -Path $PSScriptRoot -Parent)
        [string]$TD_UsedLogPath = $null
        [int]$TD_FilesToDelete = 0

        if([string]::IsNullOrWhiteSpace($TD_UserInputPath)){
            $TD_UsedLogPath = "$TD_PSRootPath\ToolLog\"
        }else {
            $TD_UsedLogPath = $TD_UserInputPath
        }
        $CutoffDate = (Get-Date).AddDays(-$TD_KeepFilesForDays)

    }
    
    process {
        
        if((Get-ChildItem -Path $TD_UsedLogPath -File).Count -lt 2){
            SST_ToolMessageCollector -TD_ToolMSGCollector "There are no files in the specified directory: $TD_UsedLogPath" -TD_ToolMSGType Message -TD_Shown yes    
        }else {
            try {
                $TD_FilesToDelete = (Get-ChildItem -Path $TD_UsedLogPath -Recurse -File | Where-Object { $_.LastWriteTime -lt $CutoffDate}).Count
                
                Get-ChildItem -Path $TD_UsedLogPath -Recurse -File | Where-Object { $_.LastWriteTime -lt $CutoffDate} | Remove-Item -Confirm:$false -Force -ErrorAction SilentlyContinue

                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_FilesToDelete files older than $TD_KeepFilesForDays days have been deleted from the directory: $TD_UsedLogPath " -TD_ToolMSGType Message -TD_Shown yes
            }
            catch {
                Write-Host $_.Exception.Message
                SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Warning -TD_Shown yes
            }
        }
    }
    
    end {
        Clear-Variable TD* -Scope Global
    }
}