function FOS_SFPDetails {
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
    
    begin {
        Write-Debug -Message "Start Func FOS_SensorShow |$(Get-Date)` "
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $FOS_SFPInformations = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'sfpshow -health'
        }else {
            $FOS_SFPInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'sfpshow -health'
        }
    }
    
    process {
        $TD_SFPDetailsResault = foreach ($TD_SFP in $FOS_SFPInformations){
            $TD_SFPInfo = "" | Select-Object Port,SFPUsed,SFPTyp,Vendor,SerialNo,SpeedRange,HealthStatus
            
            $TD_SFPInfo.SFPUsed = ($TD_SFP|Select-String -Pattern '^Port\s+\d+:\s+(Media\snot\sinstalled)' -AllMatches).Matches.Groups[1].Value
            if($TD_SFPInfo.SFPUsed -eq "Media not installed"){
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_SFPInfo.SFPUsed" -TD_Shown no
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
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$FOS_SFPInformations.Count) * 100)
            Start-Sleep -Seconds 0.5
        }
    }
    
    end {
        if($TD_Line_ID -eq 1){$TD_LB_SFPShowOne.Visibility = "Visible";     $TD_LB_SFPShowOne.Content = "$TD_Device_DeviceName"  ;$TD_CB_SAN_DG1.IsChecked="true";$TD_CB_SAN_DG1.Visibility="visible";$TD_LB_SAN_DG1.Visibility="visible"; $TD_LB_SAN_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_LB_SFPShowTwo.Visibility = "Visible";     $TD_LB_SFPShowTwo.Content = "$TD_Device_DeviceName"  ;$TD_CB_SAN_DG2.IsChecked="true";$TD_CB_SAN_DG2.Visibility="visible";$TD_LB_SAN_DG2.Visibility="visible"; $TD_LB_SAN_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_LB_SFPShowThree.Visibility = "Visible";   $TD_LB_SFPShowThree.Content = "$TD_Device_DeviceName";$TD_CB_SAN_DG3.IsChecked="true";$TD_CB_SAN_DG3.Visibility="visible";$TD_LB_SAN_DG3.Visibility="visible"; $TD_LB_SAN_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_LB_SFPShowFour.Visibility = "Visible";    $TD_LB_SFPShowFour.Content = "$TD_Device_DeviceName" ;$TD_CB_SAN_DG4.IsChecked="true";$TD_CB_SAN_DG4.Visibility="visible";$TD_LB_SAN_DG4.Visibility="visible"; $TD_LB_SAN_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_LB_SFPShowFive.Visibility = "Visible";    $TD_LB_SFPShowFive.Content = "$TD_Device_DeviceName" ;$TD_CB_SAN_DG5.IsChecked="true";$TD_CB_SAN_DG5.Visibility="visible";$TD_LB_SAN_DG5.Visibility="visible"; $TD_LB_SAN_DG5.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 6){$TD_LB_SFPShowSix.Visibility = "Visible";     $TD_LB_SFPShowSix.Content = "$TD_Device_DeviceName"  ;$TD_CB_SAN_DG6.IsChecked="true";$TD_CB_SAN_DG6.Visibility="visible";$TD_LB_SAN_DG6.Visibility="visible"; $TD_LB_SAN_DG6.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 7){$TD_LB_SFPShowSeven.Visibility = "Visible";   $TD_LB_SFPShowSeven.Content = "$TD_Device_DeviceName";$TD_CB_SAN_DG7.IsChecked="true";$TD_CB_SAN_DG7.Visibility="visible";$TD_LB_SAN_DG7.Visibility="visible"; $TD_LB_SAN_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_LB_SFPShowEight.Visibility = "Visible";   $TD_LB_SFPShowEight.Content = "$TD_Device_DeviceName";$TD_CB_SAN_DG8.IsChecked="true";$TD_CB_SAN_DG8.Visibility="visible";$TD_LB_SAN_DG8.Visibility="visible"; $TD_LB_SAN_DG8.Content=$TD_Device_DeviceName}

        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_SFPDetailsResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_SFPDetails_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_SFPDetails_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_SFPDetailsResault | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_SFPDetails_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_SFPDetails_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_SFPDetailsResault
        }

        return $TD_SFPDetailsResault
    }
}