function IBM_StorageSWCheck {
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
        $IBM_DriveCurrentFW,
        [Parameter(Mandatory)]
        $IBM_ProdMTM,
        $IBM_WebDateInfo
    )
    
    begin {
        
        $IBM_WebSpecVirtSWInofs = Invoke-WebRequest https://www.ibm.com/support/pages/ibm-storage-virtualize-family-products-upgrade-planning
        $IBM_WebSpecVirtSWInofs.Content | Out-File -FilePath D:\GitRepo\Storage_SAN_Kit\Resources\test.txt
        $IBM_LocSpecVirtSWInofsTemp = Get-Content -Path D:\GitRepo\Storage_SAN_Kit\Resources\test.txt
        $IBM_WebDateInfo = ($IBM_LocSpecVirtSWInofsTemp|Select-String -Pattern '([1-9]+\s[A-Za-z]+\s[0-9]+)' -AllMatches).Matches.Groups[1].Value
        0..$IBM_LocSpecVirtSWInofsTemp.count |ForEach-Object {
            if($IBM_LocSpecVirtSWInofsTemp[$_] -match "(Long Term Support \(LTS\) releases:)"){
                $IBM_LocSpecVirtSWInofs = $IBM_LocSpecVirtSWInofsTemp |Select-Object -Skip $_
            }
        }
        #Remove-Item -Path D:\GitRepo\Storage_SAN_Kit\Resources\test.txt -Force
        $IBM_LocSpecVirtSWInofs = $IBM_LocSpecVirtSWInofs |Select-Object -SkipLast ($IBM_LocSpecVirtSWInofs.Count - 80)
        $IBM_LocSpecVirtSWInofs | Out-File -FilePath D:\GitRepo\Storage_SAN_Kit\Resources\IBM_StorageSWCheck_$IBM_WebDateInfo.txt
    }
    
    process {
        Write-Debug -Message " $IBM_DriveCurrentFW ------------------------ $IBM_ProdMTM "
        $IBM_SpecVirtSWInfo = switch ($IBM_DriveCurrentFW) {
            <# FlashSystem 5x00 Software Levels #>
            {$_ -like "8.7.0*"} { 

                $IBM_LocSpecVirtSW = "" | Select-Object MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.MinimumPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[0].Value
                $IBM_LocSpecVirtSW.MinimumPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[0].Value
                $IBM_LocSpecVirtSW.RecommendedPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[1].Value
                $IBM_LocSpecVirtSW.RecommendedPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[1].Value
                $IBM_LocSpecVirtSW.LatestPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[2].Value
                $IBM_LocSpecVirtSW.LatestPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[2].Value
                $IBM_LocSpecVirtSW
            }
            <# FlashSystem 7x00 Software Levels #>
            {$_ -like "8.6.0*"} { 

                $IBM_LocSpecVirtSW = "" | Select-Object MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.MinimumPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[3].Value
                $IBM_LocSpecVirtSW.MinimumPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[3].Value
                $IBM_LocSpecVirtSW.RecommendedPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[4].Value
                $IBM_LocSpecVirtSW.RecommendedPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[4].Value
                $IBM_LocSpecVirtSW.LatestPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[5].Value
                $IBM_LocSpecVirtSW.LatestPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[5].Value
                $IBM_LocSpecVirtSW
                
            }
            <#  FlashSystem 9x00 Software Levels #>
            {$_ -like "8.5.0*"} { 

                $IBM_LocSpecVirtSW = "" | Select-Object MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.MinimumPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[6].Value
                $IBM_LocSpecVirtSW.MinimumPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[6].Value
                $IBM_LocSpecVirtSW.RecommendedPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[7].Value
                $IBM_LocSpecVirtSW.RecommendedPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[7].Value
                $IBM_LocSpecVirtSW.LatestPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[8].Value
                $IBM_LocSpecVirtSW.LatestPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[8].Value
                $IBM_LocSpecVirtSW

            }
            <#  FlashSystem 9x00 Software Levels #>
            {$_ -like "8.4.0*"} { 

                $IBM_LocSpecVirtSW = "" | Select-Object MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.MinimumPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[9].Value
                $IBM_LocSpecVirtSW.MinimumPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[9].Value
                $IBM_LocSpecVirtSW.RecommendedPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[10].Value
                $IBM_LocSpecVirtSW.RecommendedPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[10].Value
                $IBM_LocSpecVirtSW.LatestPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[11].Value
                $IBM_LocSpecVirtSW.LatestPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[11].Value
                $IBM_LocSpecVirtSW

            }
            Default {Write-Debug -Message $IBM_DriveCurrentFW}
        }
        
        Write-Debug -Message $IBM_SpecVirtSWInfo
    }
    
    end {
       return $IBM_SpecVirtSWInfo
    }
}