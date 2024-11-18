function IBM_BackUpConfig {
    <#
    .SYNOPSIS


    .DESCRIPTION
        Used as a placeholder for the moment, but can also be used as a standalone function!
        Version 1.0.0 | 20240730
    .EXAMPLE


    .LINK

    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Exportpath

    )
    
    begin{
        $ErrorActionPreference="Stop"
        Write-Debug -Message "IBM_BackUpConfig Begin block |$(Get-Date)"
        <# int for the progressbar #>
        $ProgressBar = New-ProgressBar
        
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete ((25/50) * 100)
        if($TD_Device_ConnectionTyp -eq "ssh"){
            <# try-catch is placed for later use #>
            #try {
                ssh $TD_Device_UserName@$TD_Device_DeviceIP "svcconfig backup"
                Start-Sleep -Seconds 1
                pscp -unsafe -pw $TD_Device_PW $TD_Device_UserName@$($TD_Device_DeviceIP):/dumps/svc.config.backup.* $TD_Exportpath
            #}
            #catch {
            #    <#Do this if a terminating exception happens#>
            #    Write-Host "Somethign went wrong" -ForegroundColor DarkMagenta
            #    Write-Host $_.Exception.Message
            #}
        }else {
            <# try-catch is placed for later use #>
            #try {
                plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "svcconfig backup"
                Start-Sleep -Seconds 1
                pscp -unsafe -pw $TD_Device_PW $TD_Device_UserName@$($TD_Device_DeviceIP):/dumps/svc.config.backup.* $TD_Exportpath
            #}
            #catch {
            #    <#Do this if a terminating exception happens#>
            #    Write-Host "Somethign went wrong" -ForegroundColor DarkMagenta
            #    Write-Host $_.Exception.Message
            #}
        }
        
    }

    process{
        Write-Debug -Message "IBM_BackUpConfig Process block |$(Get-Date)"
        
        <# try-catch is placed for later use #>
        #try {
            $TD_ExportFiles = Get-ChildItem -Path $TD_Exportpath -Filter "svc.config.backup.* "
            <# maybe add a filter #>
        #}
        #catch {
        #    <#Do this if a terminating exception happens#>
        #    Write-Host "Somethign went wrong" -ForegroundColor DarkMagenta
        #    Write-Host $_.FullyQualifiedErrorId
        #}
    }

    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        Write-Debug -Message "IBM_BackUpConfig End block |$(Get-Date) `n"
        return $TD_ExportFiles
        Clear-Variable TD* -Scope Global
    }
}