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

        try {
            $IBM_LocDateInfo=((((Get-Item -Path $PSRootPath\Resources\IBMFlashSystem_$($IBM_DriveProdID)_DRIVES_*).FullName).TrimStart("$PSScriptRoot\Resources\IBMFlashSystem_$($IBM_DriveProdID)_DRIVES_").TrimEnd('.txt')).Trim())  
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Debug -Message "Something went wrong"
            Write-Debug -Message $_.Exception.Message
            $IBM_LocDateInfo ="01 October 2024"
        }

        try {
            $IBM_WebStoDRIVESWInofs = Invoke-WebRequest https://www.ibm.com/support/pages/supported-drive-types-and-firmware-levels-ibm-storage-virtualize-family-products
            $IBM_WebStoDRIVESWInofs.Content | Out-File -FilePath $PSRootPath\ToolLog\ToolTEMP\IBMFSDriveSWTemp.txt
            $IBM_WebStoDRIVESWInofsTemp = Get-Content -Path $PSRootPath\ToolLog\ToolTEMP\IBMFSDriveSWTemp.txt
            $IBM_WebDateInfo = ($IBM_WebStoDRIVESWInofsTemp|Select-String -Pattern '([1-9]+\s[A-Za-z]+\s[0-9]+)' -AllMatches).Matches.Groups[1].Value
            Remove-Item -Path $PSRootPath\ToolLog\ToolTEMP\IBMFSDriveSWTemp.txt -Force
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Debug -Message "Something went wrong"
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is a problem with the online check of the software status." -TD_ToolMSGType Error
            SST_ToolMessageCollector -TD_ToolMSGCollector "$($_.Exception.Message)" -TD_ToolMSGType Error
            Write-Debug -Message $_.Exception.Message
            $IBM_WebStoDRIVESWInofs ="nothing in here"
        }

        Write-Debug -Message "$($IBM_LocDateInfo) - $($IBM_WebDateInfo)"
        if("$($IBM_LocDateInfo)" -ne "$($IBM_WebDateInfo)"){
            
            0..$IBM_WebStoDRIVESWInofsTemp.count |ForEach-Object {
                if($IBM_WebStoDRIVESWInofsTemp[$_] -match $IBM_DriveProdID){
                    $IBM_LocStoDRIVESWInofs = $IBM_WebStoDRIVESWInofsTemp |Select-Object -Skip $_
                }
            }
            $IBM_LocStoDRIVESWInofs = $IBM_LocStoDRIVESWInofs |Select-Object -SkipLast ($IBM_LocStoDRIVESWInofs.Count - 20)
            $IBM_LocStoDRIVESWInofs | Out-File -FilePath $PSRootPath\Resources\IBMFlashSystem_$($IBM_DriveProdID)_DRIVES_$IBM_WebDateInfo.txt
            
        }else {
            <# Action when all if and elseif conditions are false #>
            $IBM_LocStoDRIVESWInofs = Get-Content -Path $PSRootPath\Resources\IBMFlashSystem_$($IBM_DriveProdID)_DRIVES_$IBM_WebDateInfo.txt
        }

        $IBM_LocSpecVirtSW = $null
        $IBM_LocSpecVirtSW = "" | Select-Object MinimumPTF,RecommendedPTF,LatestPTF
        foreach($IBM_LocStoDRIVESWInof in $IBM_LocStoDRIVESWInofs) {

            if(($IBM_LocStoDRIVESWInof|Select-String -Pattern '(\d+_\d+_\d+)' -AllMatches).Matches[0].Value){
                $IBM_LocFSDriveFW = ($IBM_LocStoDRIVESWInof|Select-String -Pattern '(\d+_\d+_\d+)' -AllMatches).Matches[0].Value

                if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.MinimumPTF)){$IBM_LocSpecVirtSW.MinimumPTF = $IBM_LocFSDriveFW;continue}
                if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.RecommendedPTF)){$IBM_LocSpecVirtSW.RecommendedPTF = $IBM_LocFSDriveFW;continue}
                if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.LatestPTF)){$IBM_LocSpecVirtSW.LatestPTF = $IBM_LocFSDriveFW;continue}
                if(!([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.LatestPTF))){
                    $IBM_LocSpecVirtSW
                    break
                }
            }
            if(($IBM_LocStoDRIVESWInof|Select-String -Pattern '>([0-9A-Z]{3,5})<' -AllMatches).Matches.Groups[1].Value){
                $IBM_LocFSDriveFW = ($IBM_LocStoDRIVESWInof|Select-String -Pattern '>([0-9A-Z]{3,5})<' -AllMatches).Matches.Groups[1].Value

                if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.MinimumPTF)){$IBM_LocSpecVirtSW.MinimumPTF = $IBM_LocFSDriveFW;continue}
                if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.RecommendedPTF)){$IBM_LocSpecVirtSW.RecommendedPTF = $IBM_LocFSDriveFW;continue}
                #if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.LatestPTF)){$IBM_LocSpecVirtSW.LatestPTF = $IBM_LocFSDriveFW;continue}
                if(!([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.RecommendedPTF))){
                    $IBM_LocSpecVirtSW
                    break
                }
            }
            if((($IBM_LocStoDRIVESWInof|Select-String -Pattern '>([0-9A-Z]{5,10})<' -AllMatches).Matches.Groups[1].Value)-ne($IBM_DriveProdID)){
                $IBM_LocFSDriveFW = ($IBM_LocStoDRIVESWInof|Select-String -Pattern '>([0-9A-Z]{5,10})<' -AllMatches).Matches.Groups[1].Value

                if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.MinimumPTF)){$IBM_LocSpecVirtSW.MinimumPTF = $IBM_LocFSDriveFW;continue}
                if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.RecommendedPTF)){$IBM_LocSpecVirtSW.RecommendedPTF = $IBM_LocFSDriveFW;continue}
                #if([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.LatestPTF)){$IBM_LocSpecVirtSW.LatestPTF = $IBM_LocFSDriveFW;continue}
                if(!([string]::IsNullOrWhiteSpace($IBM_LocSpecVirtSW.RecommendedPTF))){
                    $IBM_LocSpecVirtSW
                    break
                }
            }
        }

        Write-Debug -Message $IBM_LocSpecVirtSW
        if([string]::IsNullOrEmpty($IBM_LocSpecVirtSW)){
            $IBM_LocSpecVirtSW = "unknown"
        }
        $IBM_DriveFirmwareResult = $IBM_LocSpecVirtSW.RecommendedPTF
    }
    
    end {
       return $IBM_DriveFirmwareResult
    }
}