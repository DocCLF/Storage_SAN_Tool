function IBM_PowerChecker {
    [CmdletBinding()]
    param (
        #[Parameter(Mandatory)]
        [String]$PowerServerMTM, 
        #[Parameter(Mandatory)]
        [String]$PowerServerFirmware,
        [String]$HMCFirmwareVersion = $null,
        [String]$HMCHostVersion = $null,
        [string]$TD_PSServerPath = (Split-Path -Path $PSScriptRoot -Parent),
        [string]$TD_PSRootPath = (Split-Path -Path $TD_PSServerPath -Parent),
        [string]$TD_Exportpath
    )
    
    begin {
        
    }
    
    process {
        <# Create a list for each PowerServer with its supported firmware #>
        try {
            $CheckOnlineCondition = $null
            $TD_IBMPowerServerInfo = 0
            $TD_IBMPowerServerCollection = Import-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedmtm_*"
            $TD_IBMPowerServerFWCollection = Import-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedfw_*"
            #$IBMPowerHW =$JsonPowerFWtemp.flrtReport.System.mtm.input
            #$IBMPowerSysFW =$JsonPowerFWtemp.flrtReport.System.fw
            foreach($PowerServer in $TD_IBMPowerServerCollection){
                Write-Host $TD_IBMPowerServerInfo
                foreach($PowerFirmware in $TD_IBMPowerServerFWCollection){
                    #Write-Host $($PowerServer.MTM) $($PowerFirmware.Version) -ForegroundColor Yellow
                    $CheckOnlineCondition = "https://esupport.ibm.com/customercare/flrt/report?format=json&plat=power&p0.mtm=$($PowerServer.Version)&p0.fw=$($PowerFirmware.Version)"
                    $JsonPowerFWtemp = Invoke-WebRequest $CheckOnlineCondition -UseBasicParsing | ConvertFrom-Json
                    if(!($JsonPowerFWtemp.flrtReport.System.fw.error)){
                        $IBMPowerHWBase = foreach ($some in $JsonPowerFWtemp ) {
                            Start-Sleep -Seconds 0.5
                            $IBMPowerHWBase = "" | Select-Object PwrName,PwrMTM,PwrReleaseDate,PwrAnnounce,PwrFwCurrentV,PwrFwCurrentRD,PwrFwCurrentEOS,PwrFwCurrenttDL,PwrFwLatestV,PwrFwLatestRD,PwrFwLatestEOS,PwrFwLatestDL,PwrFwUpdateV,PwrFwUpdateRD,PwrFwUpdateEOS,PwrFwUpdateDL,PwrFwUpdateNotes,PwrFwUpdateLatestV,PwrFwUpdateLatestRD,PwrFwUpdateLatestEOS,PwrFwUpdateLatestDL,PwrFwUpdateLatestNotes,PwrFwUpgradeV,PwrFwUpgradeRD,PwrFwUpgradeEOS,PwrFwUpgradeDL,PwrFwUpgradeNotes,PwrFwUpgradeLatestV,PwrFwUpgradeLatestRD,PwrFwUpgradeLatestEOS,PwrFwUpgradeLatestDL,PwrFwUpgradeLatestNotes
                            <#Hardware#>
                            $IBMPowerHWBase.PwrName = $some.flrtReport.System.mtm.input.version
                            $IBMPowerHWBase.PwrMTM = $some.flrtReport.System.mtm.input.name
                            $IBMPowerHWBase.PwrReleaseDate = $some.flrtReport.System.mtm.input.releaseDate
                            $IBMPowerHWBase.PwrAnnounce = $some.flrtReport.System.mtm.input.announce
                            <#Firmware Now/ Current#>
                            $IBMPowerHWBase.PwrFwCurrentV = $some.flrtReport.System.fw.input.version
                            $IBMPowerHWBase.PwrFwCurrentRD = $some.flrtReport.System.fw.input.releaseDate
                            $IBMPowerHWBase.PwrFwCurrentEOS = $some.flrtReport.System.fw.input.eosps
                            $IBMPowerHWBase.PwrFwCurrenttDL = $some.flrtReport.System.fw.input.download
                            <#Firmware Latest#> 
                            $IBMPowerHWBase.PwrFwLatestV = $some.flrtReport.System.fw.input.latest.version
                            $IBMPowerHWBase.PwrFwLatestRD = $some.flrtReport.System.fw.input.latest.releaseDate
                            $IBMPowerHWBase.PwrFwLatestEOS = $some.flrtReport.System.fw.input.latest.eosps
                            $IBMPowerHWBase.PwrFwLatestDL = $some.flrtReport.System.fw.input.latest.download
                            <#Firmware update#>
                            $IBMPowerHWBase.PwrFwUpdateV = $some.flrtReport.System.fw.update.version
                            $IBMPowerHWBase.PwrFwUpdateRD = $some.flrtReport.System.fw.update.releaseDate
                            $IBMPowerHWBase.PwrFwUpdateEOS = $some.flrtReport.System.fw.update.eosps
                            $IBMPowerHWBase.PwrFwUpdateDL = $some.flrtReport.System.fw.update.download
                            $IBMPowerHWBase.PwrFwUpdateNotes = $some.flrtReport.System.fw.update.notes |Select-Object -ExpandProperty note | Out-String
                            <#Firmware update Latest#>
                            $IBMPowerHWBase.PwrFwUpdateLatestV = $some.flrtReport.System.fw.update.latest.version
                            $IBMPowerHWBase.PwrFwUpdateLatestRD = $some.flrtReport.System.fw.update.latest.releaseDate
                            $IBMPowerHWBase.PwrFwUpdateLatestEOS = $some.flrtReport.System.fw.update.latest.eosps
                            $IBMPowerHWBase.PwrFwUpdateLatestDL = $some.flrtReport.System.fw.update.latest.download
                            $IBMPowerHWBase.PwrFwUpdateLatestNotes = $some.flrtReport.System.fw.update.latest.notes |Select-Object -ExpandProperty note | Out-String
                            <#Firmware upgrade#>
                            $IBMPowerHWBase.PwrFwUpgradeV = $some.flrtReport.System.fw.upgrade.version
                            $IBMPowerHWBase.PwrFwUpgradeRD = $some.flrtReport.System.fw.upgrade.releaseDate
                            $IBMPowerHWBase.PwrFwUpgradeEOS = $some.flrtReport.System.fw.upgrade.eosps
                            $IBMPowerHWBase.PwrFwUpgradeDL = $some.flrtReport.System.fw.upgrade.download
                            $IBMPowerHWBase.PwrFwUpgradeNotes = $some.flrtReport.System.fw.upgrade.notes |Select-Object -ExpandProperty note | Out-String
                            <#Firmware upgrade Latest#>
                            $IBMPowerHWBase.PwrFwUpgradeLatestV = $some.flrtReport.System.fw.upgrade.latest.version
                            $IBMPowerHWBase.PwrFwUpgradeLatestRD = $some.flrtReport.System.fw.upgrade.latest.releaseDate
                            $IBMPowerHWBase.PwrFwUpgradeLatestEOS = $some.flrtReport.System.fw.upgrade.latest.eosps
                            $IBMPowerHWBase.PwrFwUpgradeLatestDL = $some.flrtReport.System.fw.upgrade.latest.download
                            $IBMPowerHWBase.PwrFwUpgradeLatestNotes = $some.flrtReport.System.fw.upgrade.notes |Select-Object -ExpandProperty note | Out-String
                            $IBMPowerHWBase
                        }
                        $IBMPowerHWBase | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\$($PowerServer.Version)_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                    }
                }
                #if($TD_IBMPowerServerInfo -gt 50){break}
                $TD_IBMPowerServerInfo++
            }
        }
        catch {
            Write-Host -Message $_.Exception.Message
        }
        #$PowerServerMTM <#PowerServerMTM means PowerServer.Version | yes i had to fix this#>
        if((Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\$($PowerServerMTM)*.csv").FullName -and (Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\$($PowerServerMTM)*.csv").Count -eq 1){
            $PowerServerTemp = (Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\$($PowerServerMTM)*_20250305.csv").FullName | Import-Csv
        }else {           
            if((Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\$($PowerServerMTM)*.csv").Count -lt 1){Write-Host "No match could be found for your input $PowerServerMTM " -ForegroundColor Red;break}
            if((Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\$($PowerServerMTM)*.csv").Count -gt 1){Write-Host "Please narrow down your selection:$((Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\$($PowerServerMTM)*.csv").Name -replace('_\d+.csv'))" -ForegroundColor Yellow;break}

        }
        if(!([string]::IsNullOrEmpty($PowerServerFirmware))){
            $IBMPowerServerWithFW= $PowerServerTemp | ForEach-Object {
                if($_.PwrFwCurrentV -like "*$PowerServerFirmware*"){
                    $_
                }
            }
            if($IBMPowerServerWithFW.Count -lt 1){
                Write-Host "No match could be found for your input $PowerServerMTM with $PowerServerFirmware " -ForegroundColor Red;break
            }else {
                if($IBMPowerServerWithFW.Count -gt 1){Write-Host "Please narrow down your selection: $($IBMPowerServerWithFW.PwrFwCurrentV) " -ForegroundColor Yellow;break}
                $IBMPowerServerWithFW
            }
        }
        if(!([string]::IsNullOrEmpty($HMCFirmwareVersion))){
            $HMCFirmwareVersionTemp= ((Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedhmc_*.csv").FullName | Import-Csv) | ForEach-Object {
                if($_.Version -like "*$HMCFirmwareVersion*"){
                    $_
                }
            }
            if($HMCFirmwareVersionTemp.Count -lt 1){
                Write-Host "No match could be found for your input $HMCFirmwareVersion " -ForegroundColor Red;break
            }else {
                if($HMCFirmwareVersionTemp.Count -gt 1){Write-Host "Please narrow down your selection: $($HMCFirmwareVersionTemp.Version) " -ForegroundColor Yellow;break}
                if($IBMPowerServerWithFW.Count -lt 1 ) {
                    $IBMPowerServerWithFW,$HMCFirmwareVersionTemp
                }else {
                    $HMCFirmwareVersionTemp
                }
            }
        }
        if(!([string]::IsNullOrEmpty($HMCHostVersion))){
            $HMCHostVersionTemp= ((Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedhmchost_*.csv").FullName | Import-Csv) | ForEach-Object {
                if($_.Version -like "*$HMCHostVersion*"){
                    $_
                }
            }
            if($HMCHostVersionTemp.Count -lt 1){
                Write-Host "No match could be found for your input $HMCHostVersion " -ForegroundColor Red;break
            }else {
                if($HMCHostVersionTemp.Count -gt 1){Write-Host "Please narrow down your selection: $($HMCHostVersionTemp.Version) " -ForegroundColor Yellow;break}

                if($HMCHostVersionTemp.Count -lt 1 ) {
                    $IBMPowerServerWithFW,$HMCHostVersionTemp
                }else {
                    $HMCHostVersionTemp
                }
            }
        }

        Write-Host "If you want to check whether your compilation is supported, please have it checked online!" -ForegroundColor Yellow
        $UserInput = Read-Host "Would you like to have your selection checked online? yes or no"
        Write-Host "`n"
        if($UserInput -like "y*"){
            $urlTest = "https://esupport.ibm.com/customercare/flrt/report?format=json&plat=power&p0.mtm=$($IBMPowerServerWithFW.PwrName)&p0.fw=$($IBMPowerServerWithFW.PwrFwCurrentV)&p0.hmc=$($HMCFirmwareVersionTemp.Version)&p0.hmchost=$($HMCHostVersionTemp.Version)"
            $JsonHMCtemp= Invoke-WebRequest $urlTest -UseBasicParsing | ConvertFrom-Json 
            $JsonHMCtemp |ConvertTo-Json -Depth 100 | Add-Content "$TD_PSRootPath\ToolLog\ToolTEMP\$($IBMPowerServerWithFW.PwrName)_$($IBMPowerServerWithFW.PwrFwCurrentV)_$($HMCFirmwareVersionTemp.Version)_$($HMCHostVersionTemp.Version)_$(Get-Date -UFormat "%Y.%m.%d").json"
            $IBMPowerBaseResult =[ordered]@{}
            $IBMPowerHMCResult =[ordered]@{}
            #Get-Item "D:\GitRepo\9786-22H_ML1030_082_20250303.json" | Sort-Object CreationTime | ForEach-Object {
                $JsonHMCtemp | ForEach-Object {
                    $_ | ForEach-Object `
                    -Begin {Write-Host $_.flrtReport.System.mtm.input.name -ForegroundColor Green}`
                    -Process `
                    {
                        $IBMPowerHW =$_.flrtReport.System.mtm.input
                        $IBMPowerSysFW =$_.flrtReport.System.fw
                        #Write-Host $IBMPowerHW.Name $IBMPowerHW.Version $IBMPowerHW.releaseDate -ForegroundColor Magenta
                        #$IBMPowerHWBase #= "" | Select-Object PwrName,PwrMTM,PwrReleaseDate,PwrAnnounce,PwrFwLatestV,PwrFwLatestRD,PwrFwLatestEOS,PwrFwLatestDL,PwrFwUpdateV,PwrFwUpdateRD,PwrFwUpdateEOS,PwrFwUpdateDL,PwrFwUpdateLatestV,PwrFwUpdateLatestRD,PwrFwUpdateLatestEOS,PwrFwUpdateLatestDL,PwrFwUpgradeV,PwrFwUpgradeRD,PwrFwUpgradeEOS,PwrFwUpgradeDL,PwrFwUpgradeNotes,PwrFwUpgradeLatestV,PwrFwUpgradeLatestRD,PwrFwUpgradeLatestEOS,PwrFwUpgradeLatestDL,PwrFwUpgradeLatestNotes
                        <#Hardware#>
                        $IBMPowerBaseResult.'PowerSystem' = $IBMPowerHW.name
                        $IBMPowerBaseResult.'PowerSystem MTM' = $IBMPowerHW.version
                        $IBMPowerBaseResult.'PowerSystem ReleaseDate' = $IBMPowerHW.releaseDate
                        $IBMPowerBaseResult.'PowerSystem Announce' = $IBMPowerHW.announce
                        <#Firmware Latest#>
                        $IBMPowerBaseResult.'FirmWare Latest' = $IBMPowerSysFW.input.latest.version
                        $IBMPowerBaseResult.'FirmWare release' = $IBMPowerSysFW.input.latest.releaseDate
                        $IBMPowerBaseResult.'FirmWare eosps' = $IBMPowerSysFW.input.latest.eosps
                        $IBMPowerBaseResult.'FirmWare download' = $IBMPowerSysFW.input.latest.download
                        <#Firmware update#>
                        $IBMPowerBaseResult.'FW Update version' = $IBMPowerSysFW.update.version
                        $IBMPowerBaseResult.'FW Update release' = $IBMPowerSysFW.update.releaseDate
                        $IBMPowerBaseResult.'FW Update eosps' = $IBMPowerSysFW.update.eosps
                        $IBMPowerBaseResult.'FW Update download' = $IBMPowerSysFW.update.download
                        $IBMPowerBaseResult.'FW Update notes' = $IBMPowerSysFW.update.notes |Select-Object -ExpandProperty note | Out-String
                        <#Firmware update Latest#>
                        $IBMPowerBaseResult.'FW Update latest version' = $IBMPowerSysFW.update.latest.version
                        $IBMPowerBaseResult.'FW Update latest release' = $IBMPowerSysFW.update.latest.releaseDate
                        $IBMPowerBaseResult.'FW Update latest eosps' = $IBMPowerSysFW.update.latest.eosps
                        $IBMPowerBaseResult.'FW Update latest download' = $IBMPowerSysFW.update.latest.download
                        $IBMPowerBaseResult.'FW Update latest notes' = $IBMPowerSysFW.update.notes |Select-Object -ExpandProperty note | Out-String
                        <#Firmware upgrade#>
                        $IBMPowerBaseResult.'FW Upgrade version' = $IBMPowerSysFW.upgrade.version
                        $IBMPowerBaseResult.'FW Upgrade release' = $IBMPowerSysFW.upgrade.releaseDate
                        $IBMPowerBaseResult.'FW Upgrade eosps' = $IBMPowerSysFW.upgrade.eosps
                        $IBMPowerBaseResult.'FW Upgrade download' = $IBMPowerSysFW.upgrade.download
                        $IBMPowerBaseResult.'FW Upgrade notes' = $IBMPowerSysFW.upgrade.notes |Select-Object -ExpandProperty note | Out-String
                        <#Firmware upgrade Latest#>
                        $IBMPowerBaseResult.'FW Upgrade latest version' = $IBMPowerSysFW.upgrade.latest.version
                        $IBMPowerBaseResult.'FW Upgrade latest release' = $IBMPowerSysFW.upgrade.latest.releaseDate
                        $IBMPowerBaseResult.'FW Upgrade latest eosps' = $IBMPowerSysFW.upgrade.latest.eosps
                        $IBMPowerBaseResult.'FW Upgrade latest download' = $IBMPowerSysFW.upgrade.latest.download
                        $IBMPowerBaseResult.'FW Upgrade latest notes' = $IBMPowerSysFW.upgrade.latest.notes |Select-Object -ExpandProperty note | Out-String

                    },
                    { 
                        $IBMPowerSysHMCFW =$_.flrtReport.System.hmc
                        <#HMC with HMC geting a error#>
                        $IBMPowerHMCResult.'Combination Error' = $IBMPowerSysHMCFW.input.notes |Select-Object -ExpandProperty error | Out-String
                        <#HMC Firmware Latest#>
                        $IBMPowerHMCResult.'HMC FirmWare Latest' = $IBMPowerSysHMCFW.latest.version
                        $IBMPowerHMCResult.'HMC FirmWare release' = $IBMPowerSysHMCFW.latest.releaseDate
                        $IBMPowerHMCResult.'HMC FirmWare eosps' = $IBMPowerSysHMCFW.latest.eosps
                        $IBMPowerHMCResult.'HMC FirmWare download' = $IBMPowerSysHMCFW.latest.download
                        <#HMC Firmware update#>
                        $IBMPowerHMCResult.'HMC FW Update version' = $IBMPowerSysHMCFW.update.version
                        $IBMPowerHMCResult.'HMC FW Update release' = $IBMPowerSysHMCFW.update.releaseDate
                        $IBMPowerHMCResult.'HMC FW Update eosps' = $IBMPowerSysHMCFW.update.eosps
                        $IBMPowerHMCResult.'HMC FW Update download' = $IBMPowerSysHMCFW.update.download
                        <#HMC Firmware update Latest#>
                        $IBMPowerHMCResult.'HMC FW Update latest version' = $IBMPowerSysHMCFW.update.latest.version
                        $IBMPowerHMCResult.'HMC FW Update latest release' = $IBMPowerSysHMCFW.update.latest.releaseDate
                        $IBMPowerHMCResult.'HMC FW Update latest eosps' = $IBMPowerSysHMCFW.update.latest.eosps
                        $IBMPowerHMCResult.'HMC FW Update latest download' = $IBMPowerSysHMCFW.update.latest.download
                        <#HMC Firmware upgrade#>
                        $IBMPowerHMCResult.'HMC FW Upgrade version' = $IBMPowerSysHMCFW.upgrade.version
                        $IBMPowerHMCResult.'HMC FW Upgrade release' = $IBMPowerSysHMCFW.upgrade.releaseDate
                        $IBMPowerHMCResult.'HMC FW Upgrade eosps' = $IBMPowerSysHMCFW.upgrade.eosps
                        $IBMPowerHMCResult.'HMC FW Upgrade download' = $IBMPowerSysHMCFW.upgrade.download
                        $IBMPowerHMCResult.'HMC FW Upgrade notes' = $IBMPowerSysHMCFW.upgrade.notes |Select-Object -ExpandProperty note | Out-String
                        <#HMC Firmware upgrade Latest#>
                        $IBMPowerHMCResult.'HMC FW Upgrade latest version' = $IBMPowerSysHMCFW.upgrade.latest.version
                        $IBMPowerHMCResult.'HMC FW Upgrade latest release' = $IBMPowerSysHMCFW.upgrade.latest.releaseDate
                        $IBMPowerHMCResult.'HMC FW Upgrade latest eosps' = $IBMPowerSysHMCFW.upgrade.latest.eosps
                        $IBMPowerHMCResult.'HMC FW Upgrade latest download' = $IBMPowerSysHMCFW.upgrade.latest.download
                        $IBMPowerHMCResult.'HMC FW Upgrade latest notes' = $IBMPowerSysHMCFW.upgrade.latest.notes |Select-Object -ExpandProperty note | Out-String
                        #$IBMPowerSysFW =$_.flrtReport.System.fw
                        #Write-Host $IBMPowerSysFW.update.Version $IBMPowerSysFW.update.releaseDate $IBMPowerSysFW.update.eosps -ForegroundColor DarkMagenta
                    }`
                    -End {
                        foreach ($key in @($IBMPowerBaseResult.Keys)){if( -not $IBMPowerBaseResult[$key] ){$IBMPowerBaseResult.Remove($key) }}
                        foreach ($key in @($IBMPowerHMCResult.Keys)){if( -not $IBMPowerHMCResult[$key] ){$IBMPowerHMCResult.Remove($key) }}
                        Write-Host "Power System Output"
                        $IBMPowerBaseResult | Format-Table -Property Name, Value -AutoSize -HideTableHeaders
                        Write-Host "`n`nHMC Output"
                        $IBMPowerHMCResult | Format-Table -Property Name, Value -AutoSize -HideTableHeaders
                        
                        Write-Host "A json file was also created and saved!" -ForegroundColor Green
                    }
                }
            #}
        }
    }
    
    end {
        
    }
}