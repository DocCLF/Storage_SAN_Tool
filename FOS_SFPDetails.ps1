function FOS_SFPDetails {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    
    begin {
        Write-Debug -Message "Start Func FOS_SensorShow |$(Get-Date)` "
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $FOS_SFPInformations = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP 'sfpshow -health'
        }else {
            $FOS_SFPInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'sfpshow -health'
        }
    }
    
    process {
        $TD_SFPDetailsResault = foreach ($TD_SFP in $FOS_SFPInformations){
            $TD_SFPInfo = "" | Select-Object Port,SFPUsed,SFPTyp,Vendor,SerialNo,SpeedRange,HealthStatus
            
            $TD_SFPInfo.SFPUsed = ($TD_SFP|Select-String -Pattern '^Port\s+\d+:\s+(Media\snot\sinstalled)' -AllMatches).Matches.Groups[1].Value
            if($TD_SFPInfo.SFPUsed -eq "Media not installed"){
                Write-Debug $TD_SFPInfo.SFPUsed
                continue
            }

            $TD_SFPInfo.Port = ($TD_SFP|Select-String -Pattern '^Port\s+(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_SFPInfo.SFPTyp = ($TD_SFP|Select-String -Pattern '\s+id\s+(\([a-z]+\))\s+' -AllMatches).Matches.Groups[1].Value
            $TD_SFPInfo.Vendor = ($TD_SFP|Select-String -Pattern '\s+Vendor:\s+([a-zA-Z]+)\s+' -AllMatches).Matches.Groups[1].Value
            $TD_SFPInfo.SerialNo = ($TD_SFP|Select-String -Pattern '\s+Serial\s+No:\s+([a-zA-Z0-9]+)\s+' -AllMatches).Matches.Groups[1].Value
            $TD_SFPInfo.SpeedRange = ($TD_SFP|Select-String -Pattern '\s+Speed:\s+(\d+,\d+,\d+[a-zA-Z_]+)\s+' -AllMatches).Matches.Groups[1].Value
            $TD_SFPInfo.HealthStatus = ($TD_SFP|Select-String -Pattern '\s+Health:\s+(Green|Yellow|Unknown|Paused|No\s+License)' -AllMatches).Matches.Groups[1].Value
            $TD_SFPInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$FOS_SFPInformations.Count) * 100)
            Start-Sleep -Seconds 0.5
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                $TD_SFPDetailsResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_SFPDetails_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_SFPDetailsResault | Export-Csv -Path $PSScriptRoot\Export\$($TD_Line_ID)_SFPDetails_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
        }else {
            <# output on the promt #>
            return $TD_SFPDetailsResault
        }

        return $TD_SFPDetailsResault
    }
}