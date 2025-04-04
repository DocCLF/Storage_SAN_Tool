#$PowerHMCHostSelced = {(Import-Csv (Get-ChildItem -Path "D:\GitRepo\supportedhmchost_20250305.csv").FullName | ForEach-Object {
#    New-Object -Type System.Management.Automation.CompletionResult -ArgumentList $_.Version, 
#    $_.Version,
#    "ParameterValue",
#    "This is the description for $($_.Version)"
#})}
#Register-ArgumentCompleter -CommandName IBM_PowerCollector -ParameterName PowerHMCHostSel -ScriptBlock $PowerHMCHostSelced
function IBM_PowerCollector {
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
    <# Collegt and Filter the IBM Data#>
    begin {
        $ErrorActionPreference="SilentlyContinue"
        <# Collect all required data as csv for better processing #>
        if((Get-ChildItem -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supported*"| Where-Object {$_.LastWriteTime -LT $(Get-Date).AddDays(-7)}).Count -ge 1) {
            Remove-Item -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supported*" -Confirm:$false -Force
        }
    }
    
    process {
        if((Get-Item "$TD_PSRootPath\ToolLog\ToolTEMP\supported*").Count -lt 1){
            <# PowerServer Firmware #>
            try {
                Invoke-WebRequest -Uri "http://esupport.ibm.com/customercare/flrt/liteTable?prodKey=fw&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_fw.csv -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_fw.csv").FullName | ForEach-Object {
                    if($_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if($_.'Release Date' -eq "NA" -or $_.'Release Date' -eq ""){$_.'Release Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if(!($_.'EoSPS Date' -eq "NA")){[Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)}
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateEOL -lt 2020 -or $TempDateRL -lt 2017)){
                            $IBMPowerFW = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date
                            $IBMPowerFW.Version = $_.version
                            $IBMPowerFW.Recommended_Update = $_.'Recommended Update'
                            $IBMPowerFW.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMPowerFW.Release_Date = $_.'Release Date'
                            $IBMPowerFW.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerFW | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedfw_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# PowerServer HW #>
            try {
                $CheckPowerSystem = @("9843-AE2","9119-FHA","9119-FHB","7778-23X","7998-60X","7998-61X","1457-7FL","7988-xxx","7954-24X","8005-22N","8005-12N","8248-L4T","8268-E1D","8261-E4S","8408-E8D","8844-xxx","8842-xxx","9109-RMD","8412-EAD") 
                Invoke-WebRequest -Uri "http://esupport.ibm.com/customercare/flrt/liteTable?prodKey=mtm&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_mtm.csv -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_mtm.csv").FullName | ForEach-Object {
                    if(!($_.Version -in $CheckPowerSystem -or $_.Version -like '9179-MH*' -or $_.Version -like '911*-5*' -or $_.Version -like '9125-F2*' -or $_.Version -like '913*-5*' -or $_.Version -like '777*'-or $_.Version -like '789*'-or $_.Version -like '820*'-or $_.Version -like '823*'-or $_.Version -like '940*'-or $_.Version -like '9117*' -or $_.Version -like '8246*' -or $_.Version -like '8406-7*Y')){ 
                            $IBMPowerHW = "" | Select-Object MTM,ReleaseDate,EoSPS_Date
                            $IBMPowerHW.MTM = $_.Version
                            $IBMPowerHW.ReleaseDate = $_.'Release Date'
                            $IBMPowerHW.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerHW | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedmtm_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                    }
                }
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# HMC Software #>
            try {
                Invoke-WebRequest -Uri "http://esupport.ibm.com/customercare/flrt/liteTable?prodKey=hmc&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_hmc.csv  -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_hmc.csv").FullName | ForEach-Object {
                    if($_.'EoSPS Date' -eq "NA" -or $_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    [Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateEOL -lt 2020 -or $TempDateRL -lt 2017)){
                            $IBMHMCFW = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date
                            $IBMHMCFW.Version = $_.version
                            $IBMHMCFW.Recommended_Update = $_.'Recommended Update'
                            $IBMHMCFW.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMHMCFW.Release_Date = $_.'Release Date'
                            $IBMHMCFW.EoSPS_Date = $_.'EoSPS Date'
                            $IBMHMCFW | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedhmc_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# HMC Hardware #>
            try {
                Invoke-WebRequest -Uri "http://esupport.ibm.com/customercare/flrt/liteTable?prodKey=hmchost&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedhmchost_$(Get-Date -UFormat "%Y%m%d").csv  -ErrorAction Stop
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# AIX #>
            try {
                Invoke-WebRequest -Uri "https://esupport.ibm.com/customercare/flrt/liteTable?prodKey=aix&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_aix.csv  -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_aix.csv").FullName | ForEach-Object {
                    if($_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if($_.'Release Date' -eq "NA" -or $_.'Release Date' -eq ""){$_.'Release Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if(!($_.'EoSPS Date' -eq "NA")){[Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)}
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateEOL -lt 2020 -or $TempDateRL -lt 2017)){
                            $IBMPowerOSAIX = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date,Next_Pack_Date
                            $IBMPowerOSAIX.Version = $_.version
                            $IBMPowerOSAIX.Recommended_Update = $_.'Recommended Update'
                            $IBMPowerOSAIX.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMPowerOSAIX.Release_Date = $_.'Release Date'
                            $IBMPowerOSAIX.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerOSAIX.Next_Pack_Date = $_.'Next Pack Date'
                            $IBMPowerOSAIX | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedosaix_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# IBMi #>
            try {
                Invoke-WebRequest -Uri "https://esupport.ibm.com/customercare/flrt/liteTable?prodKey=ibmi&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_ibmi.csv  -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_ibmi.csv").FullName | ForEach-Object {
                    <#'EoSPS Date' seems not to work here i dont know why#>
                    #if($_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if($_.'Release Date' -eq "NA" -or $_.'Release Date' -eq ""){$_.'Release Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    #if(!($_.'EoSPS Date' -eq "NA")){[Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)}
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateRL -lt 2016)){
                            $IBMPowerOSIBMi = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date
                            $IBMPowerOSIBMi.Version = $_.version
                            $IBMPowerOSIBMi.Recommended_Update = $_.'Recommended Update'
                            $IBMPowerOSIBMi.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMPowerOSIBMi.Release_Date = $_.'Release Date'
                            $IBMPowerOSIBMi.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerOSIBMi | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedosibmi_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# VIOS #>
            try {
                Invoke-WebRequest -Uri "https://esupport.ibm.com/customercare/flrt/liteTable?prodKey=vios&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_vios.csv  -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_vios.csv").FullName | ForEach-Object {
                    if($_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if($_.'Release Date' -eq "NA" -or $_.'Release Date' -eq ""){$_.'Release Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if(!($_.'EoSPS Date' -eq "NA")){[Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)}
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateEOL -lt 2020 -or $TempDateRL -lt 2017)){
                            $IBMPowerOSAIX = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date,Next_Pack_Date
                            $IBMPowerOSAIX.Version = $_.version
                            $IBMPowerOSAIX.Recommended_Update = $_.'Recommended Update'
                            $IBMPowerOSAIX.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMPowerOSAIX.Release_Date = $_.'Release Date'
                            $IBMPowerOSAIX.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerOSAIX.Next_Pack_Date = $_.'Next Pack Date'
                            $IBMPowerOSAIX | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedosvios_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# RHEL #>
            try {
                Invoke-WebRequest -Uri "http://esupport.ibm.com/customercare/flrt/liteTable?prodKey=rhel&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_rhel.csv  -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_rhel.csv").FullName | ForEach-Object {
                    #if($_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if($_.'Release Date' -eq "NA" -or $_.'Release Date' -eq ""){$_.'Release Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    #if(!($_.'EoSPS Date' -eq "NA")){[Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)}
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateRL -lt 2020)){
                            $IBMPowerOSAIX = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date
                            $IBMPowerOSAIX.Version = $_.version
                            $IBMPowerOSAIX.Recommended_Update = $_.'Recommended Update'
                            $IBMPowerOSAIX.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMPowerOSAIX.Release_Date = $_.'Release Date'
                            $IBMPowerOSAIX.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerOSAIX | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedosrhel_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# SLES #>
            try {
                Invoke-WebRequest -Uri "http://esupport.ibm.com/customercare/flrt/liteTable?prodKey=sles&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_sles.csv  -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_sles.csv").FullName | ForEach-Object {
                    if($_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if($_.'Release Date' -eq "NA" -or $_.'Release Date' -eq ""){$_.'Release Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if(!($_.'EoSPS Date' -eq "NA")){[Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)}
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateEOL -lt 2020 -or $TempDateRL -lt 2019)){
                            $IBMPowerOSAIX = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date
                            $IBMPowerOSAIX.Version = $_.version
                            $IBMPowerOSAIX.Recommended_Update = $_.'Recommended Update'
                            $IBMPowerOSAIX.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMPowerOSAIX.Release_Date = $_.'Release Date'
                            $IBMPowerOSAIX.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerOSAIX | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedossles_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            <# UBUNTU #>
            try {
                Invoke-WebRequest -Uri "http://esupport.ibm.com/customercare/flrt/liteTable?prodKey=ubuntu&format=csvdl" -OutFile $TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_ubuntu.csv  -ErrorAction Stop
                Import-Csv (Get-ChildItem "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP_ubuntu.csv").FullName | ForEach-Object {
                    if($_.'EoSPS Date' -eq ""){$_.'EoSPS Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if($_.'Release Date' -eq "NA" -or $_.'Release Date' -eq ""){$_.'Release Date' = "$(Get-Date -UFormat "%Y.%m.%d")"}
                    if(!($_.'EoSPS Date' -eq "NA")){[Int16]$TempDateEOL=$($_.'EoSPS Date').Remove(4,6)}
                    [Int16]$TempDateRL=$($_.'Release Date').Remove(4,6)
                    if(!($TempDateEOL -lt 2020 -or $TempDateRL -lt 2017)){
                            $IBMPowerOSAIX = "" | Select-Object Version,Recommended_Update,Recommended_Upgrade,Release_Date,EoSPS_Date
                            $IBMPowerOSAIX.Version = $_.version
                            $IBMPowerOSAIX.Recommended_Update = $_.'Recommended Update'
                            $IBMPowerOSAIX.Recommended_Upgrade = $_.'Recommended Upgrade'
                            $IBMPowerOSAIX.Release_Date = $_.'Release Date'
                            $IBMPowerOSAIX.EoSPS_Date = $_.'EoSPS Date'
                            $IBMPowerOSAIX | Export-Csv -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedosubuntu_$(Get-Date -UFormat "%Y%m%d").csv" -NoTypeInformation -Append
                        }  
                    } 
            }
            catch {
                Write-Host -Message $_.Exception.Message
            }
            Remove-Item -Path "$TD_PSRootPath\ToolLog\ToolTEMP\supportedTEMP*" -Force
        }
    }
}
