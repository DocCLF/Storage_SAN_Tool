function IBM_DriveFirmwareCheck {
    <#
    .SYNOPSIS
        The function checks the firmware version of the individual drives.
    .DESCRIPTION
        The function checks the specified firmware version of a hard disk of an IBM storage system for its update 
        If the hard disk FW is unknown, it is sufficient to specify the product ID in connection with the storage system to get the latest firmware version.
        Furthermore, a file is created on first use that contains all firmware versions of the possible hard disks that are available for the respective storage system.
    .PARAMETER IBM_DriveProdID
        Specifies the product ID of the drive.
    .PARAMETER IBM_DriveCurrentFW
        (optional) Specifies the firmware level of the disk; blank if unknown.
    .PARAMETER IBM_ProdMTM
        Specifies the product machine type, like 2077, 2078 or 4680 for a FS5x00 etc.
    .NOTES
        Autor: Doc find me by https://github.com/DocCLF
        MIT license
        
        v1.2.0 Initial release
    .LINK
        https://github.com/DocCLF/Storage_SAN_Kit/blob/v1.2.0/IBM_DriveFirmwareCheck.ps1
    .EXAMPLE
        Without hard disk firmware and Debug
        IBM_DriveFirmwareCheck -IBM_DriveProdID KPM6XMUG400G -IBM_ProdMTM 2078 -ErrorAction SilentlyContinue
        -or with disk firmware and Debug-
        IBM_DriveFirmwareCheck -IBM_DriveCurrentFW C6S5 -IBM_DriveProdID 1014068D -IBM_ProdMTM 4666 -Debug -ErrorAction SilentlyContinue
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $IBM_DriveProdID,
        $IBM_DriveCurrentFW,
        [Parameter(Mandatory)]
        $IBM_ProdMTM
    )
    
    begin {
        <# nothing to do here #>
        $PSRootPath = ((([IO.DirectoryInfo] $PSScriptRoot).Parent).Parent).FullName
    }
    
    process {
        Write-Debug -Message " $IBM_DriveProdID ------------------------- $IBM_DriveCurrentFW ------------------------ $IBM_ProdMTM "
        switch ($IBM_ProdMTM) {
            <# FlashSystem 5x00 Software Levels #>
            {$_ -like "2077*" -or $_ -like "2078*" -or $_ -like "2072*" -or $_ -like "4680*" -or $_ -like "4662*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SSA/0cm9c/0/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSRootPath\Resources\IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSRootPath\Resources\IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*
                    
                }else{
                    Remove-Item -Path $PSRootPath\Resources\* -Filter 'IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SSA/0cm9c/0/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSRootPath\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*
                    
                }
                
            }
            <# FlashSystem 7x00 Software Levels #>
            {$_ -like "2076*" -or $_ -like "4664*" -or $_ -like "4657*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SDA/0cm74/1/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSRootPath\Resources\IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSRootPath\Resources\IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*
                    
                }else{
                    Remove-Item -Path $PSRootPath\Resources\* -Filter 'IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SDA/0cm74/1/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSRootPath\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*
                    
                }
            }
            <#  FlashSystem 9x00 Software Levels #>
            {$_ -like "4666*" -or $_ -like "4983*" -or $_ -like "9846*" -or $_ -like "9848*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SSA/0cm75/1/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSRootPath\Resources\IBM_FlashSystem9x00_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSRootPath\Resources\IBM_FlashSystem9x00_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_FlashSystem9x00_DRIVES_*
                }else{
                    Remove-Item -Path $PSRootPath\Resources\* -Filter 'IBM_FlashSystem9x00_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SSA//0cm75/1/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSRootPath\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_FlashSystem9x00_DRIVES_*
                    
                }
            }
            <#  FlashSystem 9x00 Software Levels #>
            {$_ -like "2145*" -or $_ -like "2147*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SSA/0cm78/1/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSScriptRoot\Resources\IBM_SVC_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSRootPath\Resources\IBM_SVC_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_SVC_DRIVES_*
                    
                }else{
                    Remove-Item -Path $PSRootPath\Resources\* -Filter 'IBM_SVC_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SSA//0cm78/1/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSRootPath\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                    $IBM_AllotherDrives = Get-Content -Path $PSRootPath\Resources\* -Filter IBM_SVC_DRIVES_*
                   
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "There is a problem with the online check of the drive software status for $IBM_ProdMTM" -TD_ToolMSGType Debug}
        }
        
        $IBM_LatestDriveFW = $null
        $IBM_LatestDriveFW = foreach($IBM_AllotherDrive in $IBM_AllotherDrives) {
            if(($IBM_DriveProdID) -eq (($IBM_AllotherDrive | Select-String -Pattern '^(([a-zA-Z0-9]+){5,})\s+.*\s+Firmware\sLevel:\s+([a-zA-Z0-9_]+)' -AllMatches).Matches.Groups[1].Value)){
                
                $IBM_DriveFWFile = ($IBM_AllotherDrive|Select-String -Pattern '^(([a-zA-Z0-9]+){5,})\s+.*\s+Firmware\sLevel:\s+([a-zA-Z0-9_]+)' -AllMatches).Matches.Groups[3].Value
                
                $IBM_DriveFWFile
                break
            }
            if (($IBM_DriveProdID) -eq (($IBM_AllotherDrive | Select-String -Pattern '^([0-9A-Z]+)\s+(\d+_\d+_\d+)' -AllMatches).Matches.Groups[1].Value)){

                $IBM_DriveFWFile = ($IBM_AllotherDrive|Select-String -Pattern '^([0-9A-Z]+)\s+(\d+_\d+_\d+)' -AllMatches).Matches.Groups[2].Value
                
                $IBM_DriveFWFile
                break
            }
            if (($IBM_DriveProdID) -eq (($IBM_AllotherDrive | Select-String -Pattern '^([0-9A-Z]+)\s+([0-9A-Z]+)$' -AllMatches).Matches.Groups[1].Value)){

                $IBM_DriveFWFile = ($IBM_AllotherDrive|Select-String -Pattern '^([0-9A-Z]+)\s+([0-9A-Z]+)$' -AllMatches).Matches.Groups[2].Value
                
                $IBM_DriveFWFile
                break
            }
            
        }
        Write-Debug -Message $IBM_LatestDriveFW
        if([string]::IsNullOrEmpty($IBM_LatestDriveFW)){
            $IBM_LatestDriveFW = "unknown"
        }
        $IBM_DriveFirmwareResult = $IBM_LatestDriveFW
    }
    
    end {
       return $IBM_DriveFirmwareResult
    }
}