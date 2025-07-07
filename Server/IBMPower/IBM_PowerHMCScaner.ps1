function IBM_PowerHMCScanner {
    <# Wenn eine neuen Verion des HMCScanner erscheint dann den Ordner HMCScannerTool löschen und die *.zip in den HMCScannerTEMP ablegen der Rest passiert von allein #>
    [CmdletBinding()]
    param (
        $PT_TempDirHMCScaner = $null,
        [Parameter(Mandatory=$false)]
        [string]$HMCIP = "",
        [Parameter(Mandatory=$false)]
        [string]$HMCUser = "",
        [Parameter(Mandatory=$false)]
        [string]$HMCPass = ""
    )
    
    begin {
        if([string]::IsNullOrWhiteSpace($HMCIP)){Continue}
        try {
            $PT_TempDirHMCScaner = Get-Item -Path $PSScriptRoot\HMCScanerTEMP -ErrorAction Break
            if($null -eq $PT_TempDirHMCScaner.Name){
                New-Item -Path $PSScriptRoot -ItemType Directory -Name HMCScanerTEMP -Confirm:$false -Force
                Write-Debug -Message "Create Directory HMCScanerTEMP"
            }
            if(!(Get-Item -Path $PSScriptRoot\HMCScanerTEMP\HMCScannerTool)){
                New-Item -Path $PSScriptRoot\HMCScanerTEMP\ -ItemType Directory -Name HMCScannerTool -Confirm:$false -Force
                Write-Debug -Message "Create Directory HMCScannerTool"
            }
            if(Get-ChildItem -Path $PSScriptRoot\HMCScanerTEMP\hmc*.zip){
                $TP_HMCScanerTool = Get-ChildItem -Path $PSScriptRoot\HMCScanerTEMP\hmc*.zip -ErrorAction Break
                Write-Debug -Message "The $($TP_HMCScanerTool.Name) was found and we move on"
                Expand-Archive -Path $PSScriptRoot\HMCScanerTEMP\$($TP_HMCScanerTool.Name) -DestinationPath $PSScriptRoot\HMCScanerTEMP\HMCScannerTool\ -Confirm:$false -Force
                Remove-Item -Path $PSScriptRoot\HMCScanerTEMP\$($TP_HMCScanerTool.Name) -Confirm:$false -Force
            }
            Get-ChildItem -Path $PSScriptRoot\HMCScanerTEMP\HMCScannerTool\hmcS*.bat -ErrorAction Break
            Write-Debug -Message "found the HMCScanner.bat, we move on"
            Remove-Item -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMC*.csv -Recurse -Confirm:$false -Force -ErrorAction Continue
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host -Message $_.Exception.Message
        }
        Write-Debug -Message "Start using $($TP_HMCScanerTool.Name)"
        try {   
            $PT_GetCMDID = Start-Process -FilePath $PSScriptRoot\HMCScanerTEMP\HMCScannerTool\hmcScanner.bat -ArgumentList "$HMCIP $HMCUser -p $HMCPass -dir $PSScriptRoot\HMCScanerTEMP" -Confirm:$false -PassThru -ErrorAction Break
            Wait-Process -Id $PT_GetCMDID.Id
            Write-Debug -Message "Collected all Date from HMC and push them into a folder named $HMCIP"
            if(Get-ChildItem -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP){
                Write-Host "All files can be found here: $PSScriptRoot\HMCScanerTEMP\$HMCIP "
            }else {
                Write-Host "There is something wrong -.-"
            }
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host -Message $_.Exception.Message
        }
    }
    
    process {
        try {
            Write-Debug -Message "Start with Process Block"
            Write-Host "Start with Process Block"
            <#get all files #>
            $PT_AllTXTFiles = Get-ChildItem -Path "$PSScriptRoot\HMCScanerTEMP\$($HMCIP)\*.txt" -ErrorAction Break
            <# Get the contents of the required files for the next step #>
            foreach($PT_AllTXTFile in $PT_AllTXTFiles){
                if(($PT_AllTXTFile.Name -like "lshmc-*")-or$PT_AllTXTFile.Name -like "system_data*"){
                    switch ($PT_AllTXTFile.Name) {
                        'lshmc-b.txt' { $PT_LSHMCB =Get-Content -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP\lshmc-b.txt; break }
                        'lshmc-n.txt' { $PT_LSHMCN =Get-Content -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP\lshmc-n.txt; break }
                        'lshmc-v.txt' { $PT_LSHMCV =Get-Content -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP\lshmc-v.txt; break }
                        'lshmc-vv.txt' { $PT_LSHMCVV =Get-Content -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP\lshmc-vv.txt; break }
                        'system_data.txt' { $PT_Sys_Datas = Get-Content -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP\system_data.txt; break }
                        Default {Write-Host $PT_AllTXTFile.Name}
                    }
                }
            }
            Write-Debug -Message "Collect all HMC Information"
            <# HMC Information #>
            $PT_HMCData = "" | Select-Object HMCName,HMCHWModell,HMCHWSN,HMCHWBios,HMCSWVersion,HMCSWBuildLevel,HMCSWBaseVersion,HMCSWFixes
            $PT_HMCData.HMCName = ($PT_LSHMCN|Select-String -Pattern 'hostname=([\w\d\-]+)' -AllMatches).Matches.Groups[1].Value
            $PT_HMCData.HMCHWModell = ($PT_LSHMCV|Select-String -Pattern 'TM\s([\w\d\-]+)' -AllMatches).Matches.Groups[1].Value
            $PT_HMCData.HMCHWSN = ($PT_LSHMCV|Select-String -Pattern 'SE\s([\w\d\-]+)' -AllMatches).Matches.Groups[1].Value
            $PT_HMCData.HMCHWBios = ($PT_LSHMCB|Select-String -Pattern 'bios=([\w\d\-]+)' -AllMatches).Matches.Groups[1].Value
            $PT_HMCData.HMCSWVersion = ($PT_LSHMCV|Select-String -Pattern '\*RM\s([\w\d\-\.]+)' -AllMatches).Matches.Groups[1].Value
            $PT_HMCData.HMCSWBuildLevel = ($PT_LSHMCVV|Select-String -Pattern 'HMC Build level ([\w\d]+)' -AllMatches).Matches.Groups[1].Value
            $PT_HMCData.HMCSWBaseVersion = ($PT_LSHMCVV|Select-String -Pattern 'base_version=([\w\d\-\.]+)' -AllMatches).Matches.Groups[1].Value
            $PT_HMCData.HMCSWFixes = $null
            Write-Host "sadad $PT_HMCData"
            <# create the SystemSummary#>
            Write-Debug -Message "Collect all SystemSummarys"
            foreach($PT_Sys_Data in $PT_Sys_Datas) {
                $PT_Data = "" | Select-Object ManagedSystem,SystemStatus,SystemMTM,SystemSN,MGRIPAddr,PrimSPIPAddr,ECNumber,IPLLevel,IPLActivatedLevel,CoDEvent
                $PT_Data.ManagedSystem = ($PT_Sys_Data|Select-String -Pattern 'name=([\w\d\-_]+)' -AllMatches).Matches.Groups[1].Value
                $PT_Data.SystemStatus = ($PT_Sys_Data|Select-String -Pattern '\,state=(Operating|Power Off|)' -AllMatches).Matches.Groups[1].Value
                $PT_Data.SystemMTM = ($PT_Sys_Data|Select-String -Pattern 'type_model=([\w\d\-]{7,9})' -AllMatches).Matches.Groups[1].Value
                $PT_Data.SystemSN = ($PT_Sys_Data|Select-String -Pattern 'serial_num=([\w\d\-]{6,9})' -AllMatches).Matches.Groups[1].Value
                <# Since we are here, we are also collecting all the data for the LPAR. #>
                Write-Debug -Message "Collect LPARSummary for $($PT_AllTXTFile.Name)"
                    foreach($PT_AllTXTFile in $PT_AllTXTFiles){
                        if($PT_AllTXTFile.Name -like "$($PT_Data.ManagedSystem)*lpar_config.txt"){
                            [array]$PT_LPARFiles += "$($PT_Data.ManagedSystem)_lpar_config.txt"
                            continue
                        }
                    }
                $PT_Data.MGRIPAddr = $HMCIP <# wase ist das wo kommt die her und kann die auch abweichen gilt für beide Blöcke #>
                $PT_Data.PrimSPIPAddr = ($PT_Sys_Data|Select-String -Pattern 'ipaddr=([\d]{1,3}\.[\d]{1,3}\.[\d]{1,3}\.[\d]{1,3})' -AllMatches).Matches.Groups[1].Value
                $PT_SysPower = Get-Content -Path "$PSScriptRoot\HMCScanerTEMP\$HMCIP\$($PT_Data.ManagedSystem)_lslic_syspower.txt"
                $PT_Data.ECNumber = ($PT_SysPower|Select-String -Pattern 'ecnumber\=([\w\d]{6,8})\,' -AllMatches).Matches.Groups[1].Value <# Firmware level #>
                $PT_Data.IPLLevel = ($PT_SysPower|Select-String -Pattern 'platform_ipl_level\=([\d]{2,4}|[\w]+)\,' -AllMatches).Matches.Groups[1].Value
                $PT_Data.IPLActivatedLevel = ($PT_SysPower|Select-String -Pattern 'curr_level_primary\=([\d]{2,4}|[\w]+)\,' -AllMatches).Matches.Groups[1].Value
                $PT_CoDEvents = Get-Content -Path "$PSScriptRoot\HMCScanerTEMP\$HMCIP\$($PT_Data.ManagedSystem)_lscod_hist.txt"
                if((($PT_CoDEvents|Select-String -Pattern '(HSCL0362[\w\d\s]+|[A-Z][\w\d\s]+)' -AllMatches)) -like "*HSCL0362*"){
                    $PT_Data.CoDEvent = ($PT_CoDEvents|Select-String -Pattern 'entry\=(HSCL0362[\w\d\s\,\:\/]+)' -AllMatches).Matches.Groups[1].Value
                }else {
                    <# Action when all if and elseif conditions are false #>
                    $PT_Data.CoDEvent = $null
                }
                $PT_Data | Export-Csv -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCScannerSysSummary.csv -NoTypeInformation -Append
            } 
            
            $PT_SysPower = $null
            foreach($PT_LPARFile in $PT_LPARFiles){

                $PT_LPARFileDatas = Get-Content -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP\$PT_LPARFile
                $PT_ManagedSystem = $PT_LPARFile -replace ('_lpar_config.txt')

                foreach($PT_LPARFileData in $PT_LPARFileDatas){
                    $PT_LPAR = "" | Select-Object LPARName,LPARID,LPARStatus,LPAREnvironment,LPAROSVersion,RMCIP,ManagedSystemName,ManagedSystemSN
                    $PT_LPAR.LPARName = ($PT_LPARFileData|Select-String -Pattern 'name=([\w\d\-_]+)' -AllMatches).Matches.Groups[1].Value
                    $PT_LPAR.LPARID = ($PT_LPARFileData|Select-String -Pattern 'lpar_id=([\d]+)' -AllMatches).Matches.Groups[1].Value
                    $PT_LPAR.LPARStatus = ($PT_LPARFileData|Select-String -Pattern '\,state=(Running|Not Activated|Not Available|)' -AllMatches).Matches.Groups[1].Value
                    $PT_LPAR.LPAREnvironment = ($PT_LPARFileData|Select-String -Pattern 'lpar_env=(aixlinux|vioserver|os400)' -AllMatches).Matches.Groups[1].Value
                    $PT_LPAR.LPAROSVersion = ($PT_LPARFileData|Select-String -Pattern 'os_version=(.*),logic' -AllMatches).Matches.Groups[1].Value
                    if((($PT_LPARFileData|Select-String -Pattern 'rmc_state=(active|none|)' -AllMatches).Matches.Groups[1].Value) -eq "active"){
                        $PT_LPAR.RMCIP = ($PT_LPARFileData|Select-String -Pattern 'rmc_ipaddr=([\d]{1,3}\.[\d]{1,3}\.[\d]{1,3}\.[\d]{1,3})' -AllMatches).Matches.Groups[1].Value
                    }else{
                        $PT_LPAR.RMCIP = $null <# was ist das und warum is es wichtig #>
                    }
                    $PT_SysPower = Get-Content -Path "$PSScriptRoot\HMCScanerTEMP\$HMCIP\$($PT_ManagedSystem)_lslic_syspower.txt"
                    $PT_LPAR.ManagedSystemName = ($PT_SysPower|Select-String -Pattern 'mtms\=([\w\d\-]+)\*' -AllMatches).Matches.Groups[1].Value
                    $PT_LPAR.ManagedSystemSN = ($PT_SysPower|Select-String -Pattern 'mtms\=[\w\d\-]+\*([\w\d]+)\,' -AllMatches).Matches.Groups[1].Value
                    $PT_LPAR | Export-Csv -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCScannerLPARSummary.csv -NoTypeInformation -Append
                }
            }
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host -Message $_.Exception.Message
        }
    }
    
    end {
        Write-Debug -Message "Start the end block and export all data to $PSScriptRoot\HMCScanerTEMP\"
        Write-Host "ende"
        <# export all Data #>
        try {
            $PT_HMCData | Export-Csv -Path $PSScriptRoot\HMCScanerTEMP\CustomerHMCData.csv -NoTypeInformation -ErrorAction Continue
        }
        catch {
            <#Do this if a terminating exception happens#>
            Write-Host -Message $_.Exception.Message
        }

        <# CleanUp for the next run #>
        Write-Debug -Message "Delete $HMCIP Folder"
        Remove-Item -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP -Confirm:$false -Force
        Remove-Item -Path $PSScriptRoot\HMCScanerTEMP\$HMCIP*_scan.* -Confirm:$false -Force
        Remove-Item -Path $PSScriptRoot\hmcScanner-*.log -Confirm:$false -Force
    }
}