function IBM_IPPortInfo {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        [int]$TD_i=0
    )
    
    begin {
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        <# int for the progressbar #>
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connection to the system via ssh and filtering and provision of data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CollectIPPortInfos = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP 'lsip -nohdr -delim :'
        }else {
            $TD_CollectIPPortInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsip -nohdr -delim :'
        }
    }
    
    process {
        $TD_IPPortInfoResault = foreach($TD_CollectIPPortInfo in $TD_CollectIPPortInfos){
            $TD_IPPortInfo = "" | Select-Object ID,NodeID,NodeName,PortID,PortSetName,IPAddresse,Prefix,VLAN,GateWay
            $TD_IPPortInfo.ID = ($TD_CollectIPPortInfo|Select-String -Pattern '^(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_IPPortInfo.NodeID = ($TD_CollectIPPortInfo|Select-String -Pattern '^\d+\s+(\d+|)' -AllMatches).Matches.Groups[1].Value
            $TD_IPPortInfo.NodeName = ($TD_CollectIPPortInfo|Select-String -Pattern '^\d+\s+(\d+|)\s+([a-zA-Z0-9-_]+|)\s+(\d+)\s+(\d+)' -AllMatches).Matches.Groups[2].Value
            $TD_IPPortInfo.PortID = ($TD_CollectIPPortInfo|Select-String -Pattern '^\d+\s+(\d+|)\s+([a-zA-Z0-9-_]+|)\s+(\d+)\s+(\d+)' -AllMatches).Matches.Groups[3].Value
            $TD_IPPortInfo.PortSetName = ($TD_CollectIPPortInfo|Select-String -Pattern '\d+\s+\d+\s+([a-zA-Z0-9-_]+)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' -AllMatches).Matches.Groups[1].Value
            $TD_IPPortInfo.IPAddresse = ($TD_CollectIPPortInfo|Select-String -Pattern '\d+\s+\d+\s+([a-zA-Z0-9-_]+)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' -AllMatches).Matches.Groups[2].Value
            $TD_IPPortInfoIPV6Addresse = ($TD_CollectIPPortInfo|Select-String -Pattern '\s+((([a-fA-F0-9:]{0,4}):([a-fA-F0-9]{0,4}))+)\s+' -AllMatches).Matches.Groups[1].Value
            if(([string]::IsNullOrWhiteSpace($TD_IPPortInfo.IPAddresse))-and (!([string]::IsNullOrWhiteSpace($TD_IPPortInfoIPV6Addresse)))){$TD_IPPortInfo.IPAddresse = $TD_IPPortInfoIPV6Addresse}
            $TD_IPPortInfo.Prefix = ($TD_CollectIPPortInfo|Select-String -Pattern '\s+(\d+|)\s+(\d+|)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|)\s+(\d+|)\s+([a-zA-Z0-9-_]+|)$' -AllMatches).Matches.Groups[1].Value
            $TD_IPPortInfo.VLAN = ($TD_CollectIPPortInfo|Select-String -Pattern '\s+(\d+|)\s+(\d+|)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|)\s+(\d+|)\s+([a-zA-Z0-9-_]+|)$' -AllMatches).Matches.Groups[2].Value
            $TD_IPPortInfo.GateWay = ($TD_CollectIPPortInfo|Select-String -Pattern '\s+(\d+|)\s+(\d+|)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|)\s+(\d+|)\s+([a-zA-Z0-9-_]+|)$' -AllMatches).Matches.Groups[3].Value

            $TD_IPPortInfo
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_FCPortInfo.NodeName)" -PercentComplete (($ProgCounter/$TD_CollectIPPortInfos.Count) * 100)
            Start-Sleep -Seconds 0.2
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_IPPortInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_IPPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_IPPortInfoResault | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_IPPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
        }else {
            <# output on the promt #>
            return $TD_IPPortInfoResault
        }
        return $TD_IPPortInfoResault
    }
}