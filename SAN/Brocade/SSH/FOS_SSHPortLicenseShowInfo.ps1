function FOS_SSHPortLicenseShowInfo {
    <#
    .SYNOPSIS
    Get SAN-Switch License Infos 

    .DESCRIPTION

    .EXAMPLE
    FOS_Port_LicenseShow -UserName admin -SwitchIP 10.10.10.25

    .LINK
    Brocade® Fabric OS® Command Reference Manual, 9.1.x
    https://techdocs.broadcom.com/us/en/fibre-channel-networking/fabric-os/fabric-os-commands/9-1-x/Fabric-OS-Commands.html
    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        [string]$TD_RefreshView,
        [string]$TD_FOSVersion = "FOS 9.1"
    )
    
    begin{
        $ErrorActionPreference="SilentlyContinue"
        Write-Debug -Message "FOS_PortLicenseShow Begin block |$(Get-Date)"
        $FOS_LicenseInfos =[ordered]@{}
        <# int for the progressbar #>
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar


           if($TD_FOSVersion -like "FOS 9*"){
              $FOS_PortLicenseInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "license --show && license --show -port"
           }else {
              $FOS_PortLicenseInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "licenseShow"
           }
        

        <# need to impl. #>
        $SANSwitchIdent = FOS_SSHSwitchIdent -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW

    }

    process{
        Write-Debug -Message "FOS_PortLicenseShow Process block |$(Get-Date)"
        $i = $FOS_PortLicenseInfo.Count

        0..$i |ForEach-Object {
            $TD_Resaults = $FOS_PortLicenseInfo | Select-Object #-Skip ($_ +1)
            $i = $_
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$FOS_PortLicenseInfo.Count) * 100)
        }  
        $FOS_LicenseInfos.Add('RowID',"$($TD_Device_UserName.count)|$TD_Line_ID")
        $FOS_LicenseInfos.Add('DeviceName',$TD_Device_DeviceName)
        $FOS_LicenseInfos.Add('LicenseInfo',$TD_Resaults)
        $FOS_LicenseInfos.Add('SwitchWWNN',$($SANSwitchIdent.SwitchWWNN))
        $FOS_LicenseInfos.Add('SerialNumber',$($SANSwitchIdent.SerialNumber))
    }
    end {
        
        Close-ProgressBar -ProgressBar $ProgressBar
       
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                Out-File -FilePath $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortLicenseShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $TD_Resaults
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortLicenseShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                Out-File -FilePath $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortLicenseShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $TD_Resaults
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortLicenseShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_LicenseInfos
        }

        return $FOS_LicenseInfos 

        <# Cleanup all TD* Vars #>
        Clear-Variable FOS* -Scope Global
    }
}