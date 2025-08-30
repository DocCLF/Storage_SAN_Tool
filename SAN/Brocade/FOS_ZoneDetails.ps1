using namespace System.Net

function FOS_ZoneDetails  {
    <#
    .SYNOPSIS
        Displays zone information.
    .DESCRIPTION
        Use this command to display zone configuration information. 
        This command includes sorting and search options to customize the output. 
        If a pattern is specified, the command displays only matching zone configuration names in the defined configuration. 
        When used without operands, the command displays all zone configuration information for the Defined and the Effective configuration.        
    .EXAMPLE
        not required
    .LINK
        BrocadeÂ® Fabric OSÂ® Command Reference Manual, 9.2.x
        https://techdocs.broadcom.com/us/en/fibre-channel-networking/fabric-os/fabric-os-commands/9-2-x/Fabric-OS-Commands.html
    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    begin{
        Write-Debug -Message "Begin GET_ZoneDetails |$(Get-Date)"
        
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $FOS_MainInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'zoneshow'
        }else {
            $FOS_MainInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'zoneshow'
        }

        $FOS_ZoneCount = $FOS_MainInformation.count
        0..$FOS_ZoneCount |ForEach-Object {
            # Pull only the effective ZoneCFG back into ZoneList
            if($FOS_MainInformation[$_] -match '^Effective'){
                $FOS_EffectiveZoneList = $FOS_MainInformation |Select-Object -Skip $_
                $FOS_DefinedZoneList = $FOS_MainInformation |Select-Object -SkipLast ($FOS_ZoneCount - $_) 
                #break
            }
        } 

        <# The following is not pretty, but it's quick and dirty. #>
        $FOS_DefinedAliasList = $null
        0..$FOS_DefinedZoneList.Count |ForEach-Object{
            if($FOS_DefinedZoneList[$_] -match 'alias:'){
                if($null -eq $FOS_DefinedAliasList){
                $FOS_DefinedAliasList = $FOS_DefinedZoneList |Select-Object -Skip $_
                }
            }
        }
        
        $FOS_ConfigName = (($FOS_EffectiveZoneList | Select-String -Pattern '\s+cfg:\s+(.*)' |ForEach-Object {$_.Matches.Groups[1].Value}))
        $FOS_ConfigName = $FOS_ConfigName.Trim()
        # Remove the first 2 Rows because we don't needed any more
        $FOS_EffectiveZoneList = $FOS_EffectiveZoneList |Select-Object -Skip 2
        
        SST_ToolMessageCollector -TD_ToolMSGCollector "`nZoneName: $FOS_ConfigName,`nDefinedZoneCount: $($FOS_DefinedZoneList.Count) " -TD_Shown yes
        
    }
    process{

        # is not necessary, but even a system needs a break from time to time
        Start-Sleep -Seconds 0.5;

        # Creat a List of Aliases with WWPN based on switch-case decision
        if(($FOS_EffectiveZoneList.count) -ge 4){
            #Create PowerShell Objects out of the Aliases
            [array]$FOS_ZoneCollection = foreach ($FOS_Zone in $FOS_EffectiveZoneList) {
                $FOS_TempCollection = "" | Select-Object Zone,WWPN,Alias
                # Get the ZoneName
                if(Select-String -InputObject $FOS_Zone -Pattern '^ zone:\s+(.*)'){
                    $FOS_ZoneName = Select-String -InputObject $FOS_Zone -Pattern '^ zone:\s+(.*)' |ForEach-Object {$_.Matches.Groups[1].Value}
                    $FOS_TempCollection.Zone = $FOS_ZoneName
                    #Write-Host $FOS_ZoneName -ForegroundColor Yellow
                }else{
                    $EffectiveAliasWWPN = $FOS_Zone.Trim()
                    #Write-Host $FOS_Zone -ForegroundColor Green
                    foreach($Dzone in $FOS_DefinedAliasList){
                        if($Dzone -match '^ alias:\s(.*)'){
                            $DefinedAliasName = $Dzone -replace '^ alias:\s',''
                            $AliasName = $DefinedAliasName.Trim()
                        }else{
                            $DzoneWWPN = $Dzone -replace ';',','
                            $DefinedAliasWWPN = $DzoneWWPN.Trim()
                        }

                        if($DefinedAliasWWPN -like "$EffectiveAliasWWPN*"){
                            #Write-Host $AliasName $DefinedAliasWWPN -ForegroundColor Cyan
                            $FOS_TempCollection.WWPN = $DefinedAliasWWPN
                            $FOS_TempCollection.Alias = $AliasName
                            $AliasName = $null
                            break
                        }
                    }
                }
                if(-Not (([string]::IsNullOrEmpty($FOS_TempCollection.Zone)) -and ([string]::IsNullOrEmpty($FOS_TempCollection.WWPN)) -and ([string]::IsNullOrEmpty($FOS_TempCollection.Alias)))){
                    $FOS_TempCollection
                }
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$FOS_EffectiveZoneList.Count) * 100)

            }
            $FOS_ZoneCollection = $FOS_ZoneCollection |Select-Object -SkipLast 1
        }else {
             <# Action when all if and elseif conditions are false #>
            SST_ToolMessageCollector -TD_ToolMSGCollector "Something wrong, notthing was not found." -TD_ToolMSGType Error -TD_Shown yes
            SST_ToolMessageCollector -TD_ToolMSGCollector "Some Infos: notthing was found, ZoneEntry count: $($FOS_EffectiveZoneList.count)`n, $FOS_EffectiveZoneList" -TD_Shown no
        }

    }
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        <# returns the hashtable for further processing, not mandatory but the safe way #>
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $FOS_ZoneCollection | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($FOS_ConfigName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($FOS_ConfigName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $FOS_ZoneCollection | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($FOS_ConfigName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($FOS_ConfigName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_ZoneCollection
        }
        SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Device_DeviceName `n$FOS_ZoneCollection" -TD_Shown no
        SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Device_DeviceName `n$FOS_ConfigName" -TD_Shown no

        <# FOS_usedPorts commented out can be used later via filter option if necessary #>
        return $FOS_ZoneCollection, $FOS_ConfigName
        
        <# Cleanup all TD* Vars #>
        Clear-Variable FOS* -Scope Global
    }
}