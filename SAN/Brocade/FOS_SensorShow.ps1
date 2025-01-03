function FOS_SensorShow {

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
        [string]$TD_Exportpath,
        [string]$TD_FOSVersion
    )
    
    begin {
        Write-Debug -Message "Start Func FOS_SensorShow |$(Get-Date)` "
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        #[int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $FOS_SensorInformations = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'sensorshow'
        }else {
            $FOS_SensorInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'sensorshow'
        }
    }
    
    process {
        <# int for the progressbar #>
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete ((10/50) * 100)
        Start-Sleep -Seconds 0.5;
    }
    
    end {

        if($TD_Line_ID -eq 1){$TD_LB_SensorInfoOne.Visibility = "Visible";     $TD_LB_SensorInfoOne.Content = "$TD_Device_DeviceName"  ;$TD_CB_SAN_DG1.Visibility="visible";$TD_LB_SAN_DG1.Visibility="visible"; $TD_LB_SAN_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_LB_SensorInfoTwo.Visibility = "Visible";     $TD_LB_SensorInfoTwo.Content = "$TD_Device_DeviceName"  ;$TD_CB_SAN_DG2.Visibility="visible";$TD_LB_SAN_DG2.Visibility="visible"; $TD_LB_SAN_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_LB_SensorInfoThree.Visibility = "Visible";   $TD_LB_SensorInfoThree.Content = "$TD_Device_DeviceName";$TD_CB_SAN_DG3.Visibility="visible";$TD_LB_SAN_DG3.Visibility="visible"; $TD_LB_SAN_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_LB_SensorInfoFour.Visibility = "Visible";    $TD_LB_SensorInfoFour.Content = "$TD_Device_DeviceName" ;$TD_CB_SAN_DG4.Visibility="visible";$TD_LB_SAN_DG4.Visibility="visible"; $TD_LB_SAN_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_LB_SensorInfoFive.Visibility = "Visible";    $TD_LB_SensorInfoFive.Content = "$TD_Device_DeviceName" ;$TD_CB_SAN_DG5.Visibility="visible";$TD_LB_SAN_DG5.Visibility="visible"; $TD_LB_SAN_DG5.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 6){$TD_LB_SensorInfoSix.Visibility = "Visible";     $TD_LB_SensorInfoSix.Content = "$TD_Device_DeviceName"  ;$TD_CB_SAN_DG6.Visibility="visible";$TD_LB_SAN_DG6.Visibility="visible"; $TD_LB_SAN_DG6.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 7){$TD_LB_SensorInfoSeven.Visibility = "Visible";   $TD_LB_SensorInfoSeven.Content = "$TD_Device_DeviceName";$TD_CB_SAN_DG7.Visibility="visible";$TD_LB_SAN_DG7.Visibility="visible"; $TD_LB_SAN_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_LB_SensorInfoEight.Visibility = "Visible";   $TD_LB_SensorInfoEight.Content = "$TD_Device_DeviceName";$TD_CB_SAN_DG8.Visibility="visible";$TD_LB_SAN_DG8.Visibility="visible"; $TD_LB_SAN_DG8.Content=$TD_Device_DeviceName}

        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                Out-File -FilePath $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Switch_SensorShow_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $FOS_SensorInformations
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Switch_SensorShow_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                Out-File -FilePath $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Switch_SensorShow_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $FOS_SensorInformations
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Switch_SensorShow_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_SensorInformations
        }
        Close-ProgressBar -ProgressBar $ProgressBar
        return $FOS_SensorInformations
    }
}