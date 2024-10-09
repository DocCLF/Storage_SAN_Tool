function IBM_MDiskInfo {
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
        $ErrorActionPreference="SilentlyContinue"
        $TD_lb_MDiskErrorInfo.Visibility="Collapsed"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            try {
                $TD_MDiskInformation = ssh $TD_Device_UserName@$TD_Device_DeviceIP 'lsmdisk -delim :'
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Host "Something went wrong, pls check if it is a SVC Connection" -ForegroundColor DarkMagenta
                Write-Host $_.Exception.Message
                $TD_lb_MDiskErrorInfo.Visibility="Visible"
                $TD_lb_MDiskErrorInfo.Content = "At Panel $TD_Line_ID is following Problem,`n $($_.Exception.Message)"
            }
        }else {
            try {
                $TD_MDiskInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsmdisk -delim :'
            }
            catch {
                <#Do this if a terminating exception happens#>
                Write-Host "Something went wrong, pls check if it is a SVC Connection" -ForegroundColor DarkMagenta
                Write-Host $_.Exception.Message
                $TD_lb_MDiskErrorInfo.Visibility="Visible"
                $TD_lb_MDiskErrorInfo.Content = "At Panel $TD_Line_ID is following Problem,`n $($_.Exception.Message)"
            }
        }
        $TD_MDiskInformation = $TD_MDiskInformation |Select-Object -Skip 1
    }
    
    process {
        $TD_MDiskInfoResault = foreach ($TD_MDisk in $TD_MDiskInformation){
            $TD_MDiskInfo = "" | Select-Object Name,Pool,Status,Capacity,unmap
            $TD_MDiskInfo.Name = ($TD_MDisk|Select-String -Pattern '\d+:([a-zA-Z0-9-_]+):(online|offline|excluded|degraded|degraded_paths|degraded_ports):' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.Status = ($TD_MDisk|Select-String -Pattern '\d+:([a-zA-Z0-9-_]+):(online|offline|excluded|degraded|degraded_paths|degraded_ports):' -AllMatches).Matches.Groups[2].Value
            $TD_MDiskInfo.Pool = ($TD_MDisk|Select-String -Pattern ':\d+:([a-zA-Z0-9-_]+):(\d+.\d+[A-Z]+):' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.Capacity = ($TD_MDisk|Select-String -Pattern ':\d+:([a-zA-Z0-9-_]+):(\d+.\d+[A-Z]+):' -AllMatches).Matches.Groups[2].Value
            $TD_MDiskInfo.unmap = ($TD_MDisk|Select-String -Pattern ':(yes|no)$' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_MDiskInformation.Count) * 100)
            Start-Sleep -Seconds 0.5
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            <# exported as .\<nbr>_User_Result_<date>.csv #>
            if([string]$TD_Exportpath -ne "$PSCommandPath\Export\"){
                $TD_MDiskInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                Write-Host "The Export can be found at $TD_Exportpath " -ForegroundColor Green
            }else {
                $TD_MDiskInfoResault | Export-Csv -Path $PSCommandPath\Export\$($TD_Line_ID)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                Write-Host "The Export can be found at $PSCommandPath\Export\ " -ForegroundColor Green
            }
        }else {
            <# output on the promt #>
            return $TD_MDiskInfoResault
        }
        return $TD_MDiskInfoResault
    }
}