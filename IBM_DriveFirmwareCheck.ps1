function IBM_DriveFirmwareCheck {
    #https://www.ibm.com/support/pages/node/6508601
    [CmdletBinding()]
    param (
        $IBM_DriveProdID,
        $IBM_DriveCurrentFW,
        $IBM_ProdMTM
    )
    
    begin {
        <# nothing to do here #>
    }
    
    process {
        switch ($IBM_ProdMTM) {
            <# FlashSystem 5x00 Software Levels #>
            {$_ -like "2077*" -or $_ -like "2078*" -or $_ -like "2072*" -or $_ -like "4680*" -or $_ -like "4662*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SSA/0cm9c/0/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSScriptRoot\Resources\IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSScriptRoot\Resources\IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path D:\GitRepo\Storage_SAN_Kit\Resources\IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_241024_release_note.txt
                    Write-Debug -Message $IBM_AllotherDrives.Count
                }else{
                    Remove-Item -Path $PSScriptRoot\Resources\* -Filter 'IBM_FlashSystem5x00_and_StorwizeV5000_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SSA/0cm9c/0/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSScriptRoot\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    $IBM_AllotherDrives = $IBM_UpdateFWDriveFile.Content
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                }
                
            }
            <# FlashSystem 7x00 Software Levels #>
            {$_ -like "2076*" -or $_ -like "4664*" -or $_ -like "4657*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SDA/0cm74/1/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSScriptRoot\Resources\IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSScriptRoot\Resources\IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path $PSScriptRoot\Resources\* -Filter IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*
                    Write-Debug -Message $IBM_AllotherDrives
                }else{
                    Remove-Item -Path $PSScriptRoot\Resources\* -Filter 'IBM_FlashSystem7x00_and_StorwizeV7000_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SDA/0cm74/1/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSScriptRoot\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    $IBM_AllotherDrives = $IBM_UpdateFWDriveFile.Content
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                    
                }
            }
            <#  FlashSystem 9x00 Software Levels #>
            {$_ -like "4666*" -or $_ -like "4983*" -or $_ -like "9846*" -or $_ -like "9848*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SSA/0cm75/1/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSScriptRoot\Resources\IBM_FlashSystem9x00_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSScriptRoot\Resources\IBM_FlashSystem9x00_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path $PSScriptRoot\Resources\* -Filter IBM_FlashSystem9x00_DRIVES_*
                    Write-Debug -Message $IBM_AllotherDrives
                }else{
                    Remove-Item -Path $PSScriptRoot\Resources\* -Filter 'IBM_FlashSystem9x00_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SSA//0cm75/1/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSScriptRoot\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    $IBM_AllotherDrives = $IBM_UpdateFWDriveFile.Content
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                    
                }
            }
            <#  FlashSystem 9x00 Software Levels #>
            {$_ -like "2145*" -or $_ -like "2147*"} { 
                $IBM_WebFWInofs = Invoke-WebRequest https://download4.boulder.ibm.com/sar/CMA/SSA/0cm78/1/
                $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value 
                if((Get-Item -Path $PSScriptRoot\Resources\IBM_SVC_DRIVES_*).Name -eq "IBM_$($IBM_WebRNName)"){
                    Write-Debug -Message "$(Get-Item -Path $PSScriptRoot\Resources\IBM_SVC_DRIVES_*) was used"
                    $IBM_AllotherDrives = Get-Content -Path $PSScriptRoot\Resources\* -Filter IBM_SVC_DRIVES_*
                    Write-Debug -Message $IBM_AllotherDrives
                }else{
                    Remove-Item -Path $PSScriptRoot\Resources\* -Filter 'IBM_SVC_DRIVES_*' -Force
                    $IBM_WebRNName = ($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*_release_note.txt)' -AllMatches).Matches.Groups[1].Value
                    $IBM_UpdateFWDriveFile = Invoke-WebRequest "https://download4.boulder.ibm.com/sar/CMA/SSA//0cm78/1/IBM_$($IBM_WebRNName)"
                    $IBM_UpdateFWDriveFile.Content | Out-File -FilePath $PSScriptRoot\Resources\IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt
                    $IBM_AllotherDrives = $IBM_UpdateFWDriveFile.Content
                    Write-Debug -Message "IBM_$(($IBM_WebFWInofs.Content| Select-String -Pattern 'IBM_(.*)_release_note' -AllMatches).Matches.Groups[1].Value)_release_note.txt was build"
                    
                }
            }
            Default {Write-Debug -Message $IBM_DriveFirmwareResult}
        }
        
        $IBM_LatestDriveFW = $null
        $IBM_LatestDriveFW = $IBM_AllotherDrives |ForEach-Object {
            if(($IBM_DriveProdID) -eq (($_ | Select-String -Pattern '^(([a-zA-Z0-9]+){5,})\s+.*\s+Firmware\sLevel:\s+([a-zA-Z0-9_]+)' -AllMatches).Matches.Groups[1].Value)){
                
                $IBM_DriveFWFile = ($_|Select-String -Pattern '^(([a-zA-Z0-9]+){5,})\s+.*\s+Firmware\sLevel:\s+([a-zA-Z0-9_]+)' -AllMatches).Matches.Groups[3].Value
                
                $IBM_DriveFWFile
                break
            }
            
        }
        if([string]::IsNullOrEmpty($IBM_LatestDriveFW)){
            $IBM_LatestDriveFW = "unknown"
        }
        $IBM_DriveFirmwareResult = $IBM_LatestDriveFW
    }
    
    end {
        <# nothing to do here #>
       return $IBM_DriveFirmwareResult
    }
}