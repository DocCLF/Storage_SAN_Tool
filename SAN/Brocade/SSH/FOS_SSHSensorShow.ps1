function FOS_SSHSensorShow {

    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
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
        $FOS_SensorShow =[ordered]@{}
        #[int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $FOS_SensorInformations = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP 'sensorshow'
        }else {
            $FOS_SensorInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'sensorshow'
        }

        $SANSwitchIdent = FOS_SSHSwitchIdent -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
        
    }
    
    process {
        <# int for the progressbar #>
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete ((10/50) * 100)
        Start-Sleep -Seconds 0.5;
        $FOS_SensorShow.Add('RowID',"$($TD_Device_UserName.count)|$TD_Line_ID")
        $FOS_SensorShow.Add('DeviceName',$TD_Device_DeviceName)
        $FOS_SensorShow.Add('SensorShowInfo',$FOS_SensorInformations)
        $FOS_SensorShow.Add('SwitchWWNN',$($SANSwitchIdent.SwitchWWNN))
        $FOS_SensorShow.Add('SerialNumber',$($SANSwitchIdent.SerialNumber))
    }
    
    end {
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
            return $FOS_SensorShow
        }
        Close-ProgressBar -ProgressBar $ProgressBar
        return $FOS_SensorShow
    }
}