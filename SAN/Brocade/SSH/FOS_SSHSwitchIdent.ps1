function FOS_SSHSwitchIdent {
    <#
    .SYNOPSIS
        Creates a hashtable with Basic information about the switch.
    .DESCRIPTION
        Use this Function to display basic information about the switch. 
        This function uses various FOS commands to provide the required information.
        FOS Commands are firmwareshow, ipaddrshow, lscfg --show -n, switchshow 
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        GET_BasicSwitchInfos -FOS_MainInformation $yourvarobject 
    #>
    
    [CmdletBinding()]
    param (
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW
    )
    
    begin {

        Write-Debug -Message "Start Func GET_BasicSwitchInfos |$(Get-Date)` "
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        <# Connect to Device and get all needed Data #>
        $FOS_MainInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'firmwareshow && ipaddrshow && chassisshow && switchshow'

        <# Hashtable for BasicSwitch Info #>
        $FOS_SwGeneralInfos =[ordered]@{}
        
        <# collect the information with the help of regex pattern and remove the blanks with the help of replace and trim #>
        $FOS_LoSw_CFG = ($FOS_MainInformation | Select-String -Pattern 'switchName:\s+(.*)$','switchDomain:\s+(\d+)$','switchWwn:\s+(.*)$','\D\((\w+)\)$','^Serial\sNum\:\s+(.*)' |ForEach-Object {$_.Matches.Groups[1].Value})
    }
    
    process {
        Write-Debug -Message "Process Func GET_BasicSwitchInfos |$(Get-Date)` "
        <# add the values to the hashtable #>
        $FOS_SwGeneralInfos.Add('SwitchWWNN',$FOS_LoSw_CFG[3])
        $FOS_SwGeneralInfos.Add('Brocade Product Name',$FOS_SwHw)
        $FOS_SwGeneralInfos.Add('MTM',$FOS_HWMTM)
        $FOS_SwGeneralInfos.Add('SerialNumber',$FOS_LoSw_CFG[0])
    }
    
    end {
        return $FOS_SwGeneralInfos
        
    }
}