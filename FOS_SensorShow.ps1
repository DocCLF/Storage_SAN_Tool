function FOS_SensorShow {

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
            $FOS_SensorInformations = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP 'sensorshow'
        }else {
            $FOS_SensorInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'sensorshow'
        }
    }
    
    process {
        <# int for the progressbar #>
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete ((10/50) * 100)
        Start-Sleep -Seconds 0.5;
    }
    
    end {
        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                Out-File -FilePath $TD_Exportpath\$($TD_Line_ID)_Switch_SensorShow_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $FOS_SensorInformations
            }else {
                Out-File -FilePath $PSScriptRoot\Export\$($TD_Line_ID)_Switch_SensorShow_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $FOS_SensorInformations
            }
        }else {
            <# output on the promt #>
            return $FOS_SensorInformations
        }
        Close-ProgressBar -ProgressBar $ProgressBar
        return $FOS_SensorInformations
    }
}