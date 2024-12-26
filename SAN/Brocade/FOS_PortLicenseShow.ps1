function FOS_PortLicenseShowInfo {
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
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        [string]$TD_RefreshView,
        [string]$TD_FOSVersion
    )
    
    begin{
        $ErrorActionPreference="SilentlyContinue"
        Write-Debug -Message "FOS_PortLicenseShow Begin block |$(Get-Date)"

        <# int for the progressbar #>
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar

        if($TD_Device_ConnectionTyp -eq "ssh"){
           Write-Debug -Message "ssh |$(Get-Date)"
           if($TD_FOSVersion -like "FOS 9*"){
                <# Improved Command for more details #>
              $FOS_PortLicenseInfo = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP "license --show && license --show -port"
           }else {
              $FOS_PortLicenseInfo = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP "licenseShow"
           }
        }else {
            Write-Debug -Message "plink |$(Get-Date)"
           if($TD_FOSVersion -like "FOS 9*"){
              $FOS_PortLicenseInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "license --show && license --show -port"
           }else {
              $FOS_PortLicenseInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "licenseShow"
           }
        }
        <# next line one for testing #>
        #$FOS_PortLicenseInfo = Get-Content -Path "C:\Users\mailt\Documents\0.txt"
        #Out-File -FilePath $Env:TEMP\$($TD_Line_ID)_PortLicenseShow_Temp.txt -InputObject $FOS_MainInformation

    }

    process{
        Write-Debug -Message "FOS_PortLicenseShow Process block |$(Get-Date)"
        $i = $FOS_PortLicenseInfo.Count

        0..$i |ForEach-Object {
            $TD_Resaults = $FOS_PortLicenseInfo | Select-Object #-Skip ($_ +1)
            $i = $_
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$FOS_PortLicenseInfo.Count) * 100)
        }  
    }
    end {
        <# returns the hashtable for further processing, not mandatory but the safe way #>
        Close-ProgressBar -ProgressBar $ProgressBar
        Write-Debug -Message "FOS_PortLicenseShow End block |$(Get-Date) `n"
        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\Export\"){
                Out-File -FilePath $TD_Exportpath\$($TD_Line_ID)_PortLicenseShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $TD_Resaults
            }else {
                Out-File -FilePath $PSScriptRoot\Export\$($TD_Line_ID)_PortLicenseShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -InputObject $TD_Resaults
            }
        }else {
            <# output on the promt #>
            return $TD_Resaults
        }

        return $TD_Resaults 

        <# Cleanup all TD* Vars #>
        Clear-Variable FOS* -Scope Global
    }
}