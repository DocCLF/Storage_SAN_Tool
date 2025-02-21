
function IBM_StorageHostHealthCheck {
    <#
    .SYNOPSIS
        A short one-line action-based description, e.g. 'Tests if a function is valid'
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $TD_IBM_HostInfoCollection,
        [string]$TD_Device_DeviceName
    )
    
    begin {
        #<# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        $TD_IBM_HostCheckResultNewStatus = @()
        $TD_btn_SaveHostStatus.Visibility="Collapsed"
        $TD_btn_SaveHostStatus.Background = "#FFDDDDDD"
        if($TD_IBM_HostInfoCollection.Count -lt 1){ 
            SST_ToolMessageCollector -TD_ToolMSGCollector "There are no Entrys in TD_IBM_HostInfoCollection, Skip HostCheck" -TD_ToolMSGType Error -TD_Shown "yes"
            break }
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent

        $TD_IBM_HostCollection = foreach($TD_IBM_HostInfo in $TD_IBM_HostInfoCollection){
            $TD_HostInfo = "" | Select-Object ACKHosts,HostID,HostName,Status,OldStatus,SiteName,HostClusterName
            if($TD_IBM_HostInfo.Status -eq "offline" -or $TD_IBM_HostInfo.Status -eq "degraded"){
                [bool]$TD_HostInfo.ACKHosts = $false
            }
            $TD_HostInfo.HostID = $TD_IBM_HostInfo.HostID
            $TD_HostInfo.HostName = $TD_IBM_HostInfo.HostName
            $TD_HostInfo.Status = $TD_IBM_HostInfo.Status
            $TD_HostInfo.SiteName = $TD_IBM_HostInfo.SiteName
            $TD_HostInfo.HostClusterName = $TD_IBM_HostInfo.HostClusterName
            $TD_HostInfo
        }
    }
    
    process {
        <# check if there are old files of that device and collect them into array #>
        <# $TD_HostLogHistoryEntrys should be:
        "ACK";"HostID";"HostName";"Status";"OldStatus";"SiteName";"HostClusterName"#>
        try {
            $TD_HostLogHistoryFile = Get-ChildItem -Path $PSRootPath\ToolLog\ToolTEMP\ -Filter "*_$($TD_Device_DeviceName)_StorageHostStatusLog.csv"
            $TD_HostLogHistoryEntrys = Import-Csv -Path $TD_HostLogHistoryFile.FullName
            SST_ToolMessageCollector -TD_ToolMSGCollector "Import $($TD_HostLogHistoryFile.FullName)" -TD_ToolMSGType Message -TD_Shown "no"
        }
        catch {
            <#Do this if a terminating exception happens#>
            $TD_HostLogHistoryEntrys = $null
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown no
            SST_ToolMessageCollector -TD_ToolMSGCollector "No File to import at $($TD_HostLogHistoryFile)" -TD_ToolMSGType Error -TD_Shown "yes"
        }

        <# Match old vs current Data#>
        foreach($TD_IBM_HostInfo in $TD_IBM_HostCollection) {
            switch ($TD_IBM_HostInfo.Status) {
                "online" 
                { 
                    $TD_IBM_HostCheckResult += $TD_IBM_HostInfo
                }
                "offline" 
                {  
                    if($TD_HostLogHistoryEntrys.Count -ge 1){
                        $TD_HostLogHistoryEntrys | ForEach-Object {
                            if($_.HostName -eq $TD_IBM_HostInfo.HostName){
                                if($_.OldStatus -eq "offline" -and $_.ACKHosts -eq $true){
                                    $TD_IBM_HostCheckResult += $TD_IBM_HostInfo
                                }else {
                                    $TD_IBM_HostCheckResultNewStatus += $TD_IBM_HostInfo
                                }
                            }else{
                                if($TD_IBM_HostInfo.Status -eq "offline"){
                                    if(($TD_HostLogHistoryEntrys.HostName -notcontains $TD_IBM_HostInfo.HostName) -and ($TD_IBM_HostCheckResultNewStatus.HostName -notcontains $TD_IBM_HostInfo.HostName)){
                                        $TD_IBM_HostCheckResultNewStatus += $TD_IBM_HostInfo
                                    }
                                }
                            }
                        }
                    } else {
                        $TD_IBM_HostCheckResultNewStatus += $TD_IBM_HostInfo
                    }
                }
                "degraded" 
                {  
                    if($TD_HostLogHistoryEntrys.Count -ge 1){
                        $TD_HostLogHistoryEntrys | ForEach-Object {
                            if($_.HostName -eq $TD_IBM_HostInfo.HostName){
                                if($_.OldStatus -eq "degraded" -and $_.ACKHosts -eq $true){
                                    $TD_IBM_HostCheckResult += $TD_IBM_HostInfo
                                }else {
                                    $TD_IBM_HostCheckResultNewStatus += $TD_IBM_HostInfo
                                }
                            }else{
                                if($TD_IBM_HostInfo.Status -eq "degraded"){
                                    if(($TD_HostLogHistoryEntrys.HostName -notcontains $TD_IBM_HostInfo.HostName) -and ($TD_IBM_HostCheckResultNewStatus.HostName -notcontains $TD_IBM_HostInfo.HostName)){
                                        $TD_IBM_HostCheckResultNewStatus += $TD_IBM_HostInfo
                                    }
                                }
                            }
                        }
                    } else {
                        $TD_IBM_HostCheckResultNewStatus += $TD_IBM_HostInfo
                    }
                }
                Default {Write-Host "something went wrong `n$TD_IBM_HostInfo"}
            }
        }

        $TD_dg_HostStatusInfoText.ItemsSource=$EmptyVar
        if($TD_IBM_HostCheckResultNewStatus.Count -gt 0){
            $TD_lb_HostStatusLight.Background = "red"
            if($TD_IBM_HostCheckResultNewStatus.Count -ge 2){
                $TD_dg_HostStatusInfoText.ItemsSource=$TD_IBM_HostCheckResultNewStatus
            }else{
                $TD_OneHost = $TD_IBM_HostCheckResultNewStatus
                $TD_dg_HostStatusInfoText.ItemsSource=$TD_OneHost
            }
            $TD_btn_SaveHostStatus.Visibility="Visible"
        }

        $TD_btn_SaveHostStatus.add_click({
            $TD_IBM_HostCheckSaveStatus = @()
            <# switch case for all buttons #>
            switch ($TD_cb_Device_HealthCheck.Text) {
                {($_ -like "*First")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_One.Content }
                {($_ -like "*Second")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Two.Content }
                {($_ -like "*Third")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Three.Content }
                {($_ -like "*Fourth")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Four.Content }
                Default { <# Write a Message in the ToolLog #> }
            }
            $TD_IBM_HostCheckSaveStatus = $TD_dg_HostStatusInfoText.ItemsSource
            $TD_IBM_SaveHostStatus = foreach($TD_IBM_HostStatus in $TD_IBM_HostCheckSaveStatus){
                $TD_HostInfo = "" | Select-Object ACKHosts,HostID,HostName,OldStatus,SiteName,HostClusterName
                $TD_HostInfo.ACKHosts = $TD_IBM_HostStatus.ACKHosts
                $TD_HostInfo.HostID = $TD_IBM_HostStatus.HostID
                $TD_HostInfo.HostName = $TD_IBM_HostStatus.HostName
                $TD_HostInfo.OldStatus = $TD_IBM_HostStatus.Status
                $TD_HostInfo.SiteName = $TD_IBM_HostStatus.SiteName
                $TD_HostInfo.HostClusterName = $TD_IBM_HostStatus.HostClusterName
                $TD_HostInfo
            }
            $TD_IBM_SaveHostStatus | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$(Get-Date -UFormat "%d%m%Y")_$($TD_DeviceName)_StorageHostStatusLog.csv
            $TD_btn_SaveHostStatus.Background = "LightGreen"
        })
    }
    
    end {
        <# the is no export because the export is triggerd by the funcs#>
    }
}