function IBM_StorageSWCheck {
    <#
    .SYNOPSIS
        The function checks the firmware version of the IBM Storage Virtualize Family of Products.
    .DESCRIPTION
        The function checks the firmware version of IBM Storage Virtualize Family of Products 
        The output is then displayed in a subdivision that shows the respective Minimum, Recommended and Latest PTF with the corresponding date.
        At the first start of the function it would be useful to have an internet connection so that the latest data is available, 
        for the pure subsequent operation this is then not absolutely necessary.
    .PARAMETER IBM_CurrentSpectrVirtuFW
        Specifies the firmware level of the System.
    .PARAMETER IBM_ProdMTM
        (optional) Specifies the product machine type, like 2077, 2078 or 4680 for a FS5x00 etc.
    .NOTES
        Autor: Doc find me by https://github.com/DocCLF
        MIT license
        
        v1.2.0 Initial release
    .LINK
        https://github.com/DocCLF/Storage_SAN_Kit/blob/v1.2.0/IBM_StorageSWCheck.ps1
    .EXAMPLE
        Without firmware and Debug
        IBM_StorageSWCheck IBM_CurrentSpectrVirtuFW 8.7.0
        -or with disk firmware and Debug-
        IBM_StorageSWCheck IBM_CurrentSpectrVirtuFW 8.5.0.6 IBM_ProdMTM 4666 -Debug 
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $IBM_CurrentSpectrVirtuFW,
        $IBM_ProdMTM
    )
    
    begin {
        
        $PSRootPath = ((([IO.DirectoryInfo] $PSScriptRoot).Parent).Parent).FullName

        try {
            SST_FileCleanUp -TD_UserInputPath $PSRootPath\Resources\ -TD_KeepFilesForDays 24
            $IBM_LocDateInfo=((((Get-Item -Path $PSRootPath\Resources\IBM_StorageSWCheck_*).FullName).TrimStart("$PSScriptRoot\Resources\IBM_StorageSWCheck_").TrimEnd('.txt')).Trim())  
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector "No File found, show MSG: $($_.Exception.Message)." -TD_ToolMSGType Error -TD_Shown no
            Write-Debug -Message $_.Exception.Message
            $IBM_LocDateInfo ="01 October 2024"
        }

        try {
            $IBM_WebSpecVirtSWInofs = Invoke-WebRequest https://www.ibm.com/support/pages/ibm-storage-virtualize-family-products-upgrade-planning
            $IBM_WebSpecVirtSWInofs.Content | Out-File -FilePath $PSRootPath\ToolLog\ToolTEMP\IBMSVSWTemp.txt
            $IBM_LocSpecVirtSWInofsTemp = Get-Content -Path $PSRootPath\ToolLog\ToolTEMP\IBMSVSWTemp.txt
            $IBM_WebDateInfo = ($IBM_LocSpecVirtSWInofsTemp|Select-String -Pattern '([1-9]+\s[A-Za-z]+\s[0-9]+)' -AllMatches).Matches.Groups[1].Value
            Remove-Item -Path $PSRootPath\ToolLog\ToolTEMP\IBMSVSWTemp.txt -Force
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is a problem with the online check of the software status $($_.Exception.Message)." -TD_ToolMSGType Error -TD_Shown no
            Write-Debug -Message $_.Exception.Message
            $IBM_WebSpecVirtSWInofs ="nothing in here"
        }
        
        Write-Debug -Message "$($IBM_LocDateInfo) - $($IBM_WebDateInfo)"
        if("$($IBM_LocDateInfo)" -ne "$($IBM_WebDateInfo)"){
            
            0..$IBM_LocSpecVirtSWInofsTemp.count |ForEach-Object {
                if($IBM_LocSpecVirtSWInofsTemp[$_] -match "(Long Term Support \(LTS\) releases:)"){
                    $IBM_LocSpecVirtSWInofs = $IBM_LocSpecVirtSWInofsTemp |Select-Object -Skip $_
                }
            }

            $IBM_LocSpecVirtSWInofs = $IBM_LocSpecVirtSWInofs |Select-Object -SkipLast ($IBM_LocSpecVirtSWInofs.Count - 80)
            $IBM_LocSpecVirtSWInofs | Out-File -FilePath $PSRootPath\Resources\IBM_StorageSWCheck_$IBM_WebDateInfo.txt
            Remove-Item -Path $PSRootPath\Resources\IBM_StorageSWCheck_$IBM_LocDateInfo.txt -Force
            $IBM_LocDateInfo = $null
            $IBM_LocDateInfo = $IBM_WebDateInfo
        }else {
            <# Action when all if and elseif conditions are false #>
            $IBM_LocSpecVirtSWInofs = Get-Content -Path $PSRootPath\Resources\IBM_StorageSWCheck_$IBM_WebDateInfo.txt
        }
    }
    
    process {
        Write-Debug -Message " $IBM_CurrentSpectrVirtuFW ------- $IBM_ProdMTM "
        SST_ToolMessageCollector -TD_ToolMSGCollector " $IBM_CurrentSpectrVirtuFW ------- $IBM_ProdMTM " -TD_ToolMSGType Debug -TD_Shown no
        $IBM_SpecVirtSWInfo = switch ($IBM_CurrentSpectrVirtuFW) {
            <# FlashSystem 5x00 Software Levels #>
            {$_ -like "8.7.0*"} { 

                $IBM_LocSpecVirtSW = "" | Select-Object IBM_ReleaseDate,MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.IBM_ReleaseDate = $IBM_LocDateInfo
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

                $IBM_LocSpecVirtSW = "" | Select-Object IBM_ReleaseDate,MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.IBM_ReleaseDate = $IBM_LocDateInfo
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

                $IBM_LocSpecVirtSW = "" | Select-Object IBM_ReleaseDate,MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.IBM_ReleaseDate = $IBM_LocDateInfo
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

                $IBM_LocSpecVirtSW = "" | Select-Object IBM_ReleaseDate,MinimumPTF,MinimumPTFDate,RecommendedPTF,RecommendedPTFDate,LatestPTF,LatestPTFDate
                $IBM_LocSpecVirtSW.IBM_ReleaseDate = $IBM_LocDateInfo
                $IBM_LocSpecVirtSW.MinimumPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[9].Value
                $IBM_LocSpecVirtSW.MinimumPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[9].Value
                $IBM_LocSpecVirtSW.RecommendedPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[10].Value
                $IBM_LocSpecVirtSW.RecommendedPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[10].Value
                $IBM_LocSpecVirtSW.LatestPTF = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '(\d+.\d+.\d+.\d+)' -AllMatches).Matches[11].Value
                $IBM_LocSpecVirtSW.LatestPTFDate = ($IBM_LocSpecVirtSWInofs|Select-String -Pattern '([A-Za-z]+\s+\d+)' -AllMatches).Matches[11].Value
                $IBM_LocSpecVirtSW

            }
            Default {
                $IBM_LocSpecVirtSW = "" | Select-Object MinimumPTF
                $IBM_LocSpecVirtSW.MinimumPTF = $null
                SST_ToolMessageCollector -TD_ToolMSGCollector "Feedback Switch-Case of Storage FWCheck $IBM_CurrentSpectrVirtuFW" -TD_ToolMSGType Debug -TD_Shown no
                Write-Debug -Message $IBM_CurrentSpectrVirtuFW
            }
        }
        SST_ToolMessageCollector -TD_ToolMSGCollector "Result Storage FWCheck $IBM_SpecVirtSWInfo" -TD_ToolMSGType Debug -TD_Shown no
        IBM_StorageFWCollector -FWRes $IBM_SpecVirtSWInfo -IBM_SpecVirtSWInfo $IBM_CurrentSpectrVirtuFW
    }
    
    end {
       return $IBM_SpecVirtSWInfo
    }
}