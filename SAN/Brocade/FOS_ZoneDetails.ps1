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
        Brocade® Fabric OS® Command Reference Manual, 9.2.x
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
        <# next line is only for tests #>
        #$FOS_MainInformation = Get-Content -Path "C:\Users\mailt\Documents\Schl_Fab1.txt"

        $FOS_ZoneCount = $FOS_MainInformation.count
        0..$FOS_ZoneCount |ForEach-Object {
            # Pull only the effective ZoneCFG back into ZoneList
            if($FOS_MainInformation[$_] -match '^Effective'){
                $FOS_ZoneList = $FOS_MainInformation |Select-Object -Skip $_
                #break
            }
        }
        $FOS_ZoneName = (($FOS_ZoneList | Select-String -Pattern '\s+cfg:\s+(.*)' |ForEach-Object {$_.Matches.Groups[1].Value}))
        $FOS_ZoneName = $FOS_ZoneName.Trim()
        SST_ToolMessageCollector -TD_ToolMSGCollector "`nZoneliste`n $FOS_ZoneList,`nZoneName`n $FOS_ZoneName,`nZoneCount`n $FOS_ZoneCollection " -TD_Shown yes
        
    }
    process{
        Write-Debug -Message "Start of Process from GET_ZoneDetails |$(Get-Date)"
        # Creat a list of Aliase with WWPN based on the decision by AliasName, with a "wildcard" there is only a list similar Aliasen or without a Aliasname there will be all Aliases of the cfg in the List.

        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_Operand Default`n, Search: zoneshow`n, Zoneliste`n $FOS_ZoneCount, `nZoneEntrys`n $FOS_MainInformation, `nZoneCount`n $FOS_ZoneList " -TD_Shown yes

        # is not necessary, but even a system needs a break from time to time
        Start-Sleep -Seconds 0.5;

        # Creat a List of Aliases with WWPN based on switch-case decision
        if(($FOS_ZoneList.count) -ge 4){
            #Create PowerShell Objects out of the Aliases
            $FOS_ZoneCollection = foreach ($FOS_Zone in $FOS_ZoneList) {
                $FOS_TempCollection = "" | Select-Object Zone,WWPN,Alias
                # Get the ZoneName
                if(Select-String -InputObject $FOS_Zone -Pattern '^ zone:\s+(.*)'){
                    $FOS_AliName = Select-String -InputObject $FOS_Zone -Pattern '^ zone:\s+(.*)' |ForEach-Object {$_.Matches.Groups[1].Value}
                    $FOS_TempCollection.Zone = $FOS_AliName.Trim()
                    SST_ToolMessageCollector -TD_ToolMSGCollector "$FOS_TempCollection" -TD_Shown yes
                }elseif(Select-String -InputObject $FOS_Zone -Pattern '(:[\da-f]{2}:[\da-f]{2}:[\da-f]{2})$') {
                    $FOS_AliWWN = $FOS_Zone
                    $FOS_TempCollection.WWPN = $FOS_AliWWN.Trim()
                    <# Boolean to control the do until loop #>
                    $FOS_DoUntilLoop = $true
                    foreach($FOS_BasicZoneListTemp in $FOS_MainInformation){
                        <# Start of the do until loop #>
                        do {
                            if($FOS_BasicZoneListTemp -match '^ alias:\s(.*)'){
                                SST_ToolMessageCollector -TD_ToolMSGCollector "$FOS_BasicZoneListTemp" -TD_Shown yes
                                $FOS_TeampAliasName = $FOS_BasicZoneListTemp
                                $FOS_TempAliasName = $FOS_TeampAliasName -replace '^ alias:\s',''.Trim()
                                break
                            }

                            if($FOS_BasicZoneListTemp -match ($FOS_AliWWN.Trim())){
                                SST_ToolMessageCollector -TD_ToolMSGCollector "$FOS_BasicZoneListTemp" -TD_Shown yes
                                $FOS_DoUntilLoop = $false
                                $FOS_TempCollection.Alias = $FOS_TempAliasName
                                break
                            }
                            break
                            
                        } until (

                            $FOS_DoUntilLoop -eq $true
                        )
                        <# Boolean to control the do until loop with break out option #>
                        If($FOS_DoUntilLoop -eq $false){break}
                    }
                    SST_ToolMessageCollector -TD_ToolMSGCollector "$FOS_AliName`n, $FOS_Zone" -TD_Shown yes
                }else{
                    <# Action when all if and elseif conditions are false #>
                    Write-Host "`n"
                }
                if(-Not (([string]::IsNullOrEmpty($FOS_TempCollection.Zone)) -and ([string]::IsNullOrEmpty($FOS_TempCollection.WWPN)) -and ([string]::IsNullOrEmpty($FOS_TempCollection.Alias)))){
                    $FOS_TempCollection
                }

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$FOS_ZoneList.Count) * 100)

            }

        }else {
             <# Action when all if and elseif conditions are false #>
            SST_ToolMessageCollector -TD_ToolMSGCollector "Something wrong, notthing was not found." -TD_ToolMSGType Error
            SST_ToolMessageCollector -TD_ToolMSGCollector "Some Infos: notthing was found, ZoneEntry count: $($FOS_ZoneList.count)`n, $FOS_ZoneList" -TD_Shown yes
        }

    }
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        <# returns the hashtable for further processing, not mandatory but the safe way #>
        Write-Debug -Message "End Func FOS_ZoneDetails |$(Get-Date)`n "
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $FOS_ZoneCollection | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($FOS_ZoneName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($FOS_ZoneName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $FOS_ZoneCollection | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($FOS_ZoneName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($FOS_ZoneName)_ZoneShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_ZoneCollection
        }
        SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Device_DeviceName `n$FOS_ZoneCollection" -TD_Shown yes
        SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Device_DeviceName `n$FOS_ZoneName" -TD_Shown yes

        <# FOS_usedPorts commented out can be used later via filter option if necessary #>
        return $FOS_ZoneCollection, $FOS_ZoneName
        
        <# Cleanup all TD* Vars #>
        Clear-Variable FOS* -Scope Global
    }
}