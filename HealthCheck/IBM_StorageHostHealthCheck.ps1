
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

        $TD_btn_SaveHostStatus.Visibility="Collapsed"
        #if($TD_Device_ConnectionTyp -eq "ssh"){
        #    $TD_CollectInfo = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP "lssystem |grep code_level && lshost && lshostcluster && lspartnership"
        #}else {
        #    $TD_CollectInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "lssystem |grep code_level && lshost && lshostcluster && lspartnership"
        #}
        <# next line one for testing #>
        #$TD_CollectInfo = Get-Content -Path "C:\Users\mailt\Documents\mimixexport.txt" #C:\Users\mailt\Documents\mimixexport.txt hyperswap
        #$TD_CollectInfo = Get-Content -Path "C:\Users\mailt\Desktop\FS5200_W.txt"
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        #Write-Host $PSPath
        #$TD_dg_HostStatusInfoText.Add_SelectionChanged({
        #    $TD_dg_HostStatusInfoText | ForEach-Object {
        #        Write-Hos
        #    }
        #    #$PSPath = Split-Path -Parent $PSCommandPath 
        #    Write-Host $PSPath -ForegroundColor Green
        #})
        #$TD_InfoCount = $TD_CollectInfo.count
        #0..$TD_InfoCount |ForEach-Object {
        #    if($TD_CollectInfo[$_] -match 'location '){
        #        $TD_TD_DeviceNameTemp = $TD_CollectInfo |Select-Object -Skip $_
        #    }
        #    if($TD_CollectInfo[$_] -match 'mapping_count'){
        #        $TD_HostClusterTemp = $TD_CollectInfo |Select-Object -Skip $_
        #    }
        #}
        
    }
    
    process {

        <# check if there are old files of that device and collect them into array #>
        try {
            $TD_HostLogHistoryFile = Get-ChildItem -Path $PSRootPath\ToolLog\ToolTEMP\ -Filter "*_$($TD_Device_DeviceName)_StorageHostStatusLog.csv"
            $TD_HostLogHistoryEntrys = Import-Csv -Path $TD_HostLogHistoryFile.FullName
            SST_ToolMessageCollector -TD_ToolMSGCollector "Import $($TD_HostLogHistoryFile.FullName)" -TD_ToolMSGType Message -TD_Shown no
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown no
            SST_ToolMessageCollector -TD_ToolMSGCollector "No File to import at $($TD_HostLogHistoryFile)" -TD_ToolMSGType Error -TD_Shown yes
        }
        
        #Write-Host $TD_HostLogHistoryFiles / $TD_HostLogHistoryFiles.Count

        <# create a array of newest data from the device #>
        #if($TD_HostLogHistoryFiles.Count -ge 1){
            #$TD_HostLogHistoryFile = Get-ChildItem -Path $TD_HostLogHistoryFiles |Sort-Object Fullname -Desc |Select-Object -First 1
            #Write-Host $TD_HostLogHistoryFile.FullName
            #$TD_HostLogHistoryEntrys = Import-Csv -Path $TD_HostLogHistoryFile.FullName 
            #Write-Host $TD_HostLogHistoryEntrys
            #Write-Host $TD_HostLogHistoryEntrys.count -ForegroundColor Yellow
            #if($TD_HostLogHistoryFiles.Count -ge 4){
            #    <# hold the last 3 and delete the rest #>
            #    Get-ChildItem $TD_HostLogHistoryFiles |Sort-Object Fullname -Desc|Select-Object -Skip 3 |Remove-Item
            #}
        #}
        <# HostID,HostName,PortCount,Type,Status,SiteName,HostClusterName,Protocol,StatusPolicy,StatusSite #>
        #$TD_HostChostClusterResaultTemp = @()
        #foreach ($TD_HostHostClusterInfo in $TD_CollectInfo){
        #    if($TD_HostHostClusterInfo |Select-String -Pattern "event_log_sequence"){break}
        #    $TD_HostChostClusterInfo = "" | Select-Object ACKHosts,HostName,Status,HostSiteName,HostClusterName,DeviceName
        #    $TD_HostChostClusterInfo.HostName = ($TD_HostHostClusterInfo|Select-String -Pattern '^\d+\s+([0-9a-zA-z-_]+)' -AllMatches).Matches.Groups[1].Value
        #    $TD_HostChostClusterInfo.Status = ($TD_HostHostClusterInfo|Select-String -Pattern '\s+(online|offline|degraded)\s+' -AllMatches).Matches.Groups[1].Value
        #    if($TD_HostChostClusterInfo.Status -eq "offline" -or $TD_HostChostClusterInfo.Status -eq "degraded"){
        #        [bool]$TD_HostChostClusterInfo.ACKHosts = $false
        #    }else {
        #        
        #        [bool]$TD_HostChostClusterInfo.ACKHosts = $true
        #    }
        #    $TD_HostChostClusterInfo.HostSiteName = ($TD_HostHostClusterInfo|Select-String -Pattern '\s+(online|offline|degraded)\s+\d+\s+(\w+)\s+\d+' -AllMatches).Matches.Groups[2].Value
        #    $TD_HostChostClusterInfo.HostClusterName = ($TD_HostHostClusterInfo|Select-String -Pattern '\s+(online|offline|degraded)\s+(\d+|)\s+([a-zA-Z0-9-_]+|)\s+(\d+|)\s+([a-zA-Z0-9-_]+)\s+scsi|fcnvme' -AllMatches).Matches.Groups[5].Value
        #    $TD_HostChostClusterInfo.DeviceName = $TD_DeviceName
        #    if((![string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostName))){
        #        <# HostClusterStatus implement maybe later #>
        #        #if(![string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostClusterName)){
        #        #    foreach ($TD_HostClusterStatus in $TD_HostClusterTemp){
        #        #        if($TD_HostClusterStatus |Select-String -Pattern "supports_unmap"){break}
        #        #        #if(![string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostClusterStatus)){break}
        #        #        $TD_HostChostClusterInfo.HostClusterStatus = ($TD_HostClusterStatus|Select-String -Pattern '\s+(online|offline|host_degraded|host_cluster_degraded)\s+' -AllMatches).Matches.Groups[1].Value
        #        #    }
        #        #}
        #        $TD_HostChostClusterResaultTemp += $TD_HostChostClusterInfo
        #    }
        #    if(([string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostClusterName))-and($TD_HostHostClusterInfo |Select-String -Pattern "mdisk_grp_name")){break}
        #}
        #Write-Host $TD_IBM_HostInfoCollection -ForegroundColor Blue
        #RZ1_ESXiDMZSRV1 RZ1_ESXiSRV1 RZ1_ESXiSRV2 RZ1_ESXiSRV3 RZ3_ESXiDMZSRV1 RZ3_ESXiSRV1 RZ4_ESXiDMZSRV1 RZ4_ESXiSRV1 RZ4_ESXiSRV2 RZ4_ESXiSRV3 CL-FILE-RZ1 CL-FILE-RZ4 RZ1-ESXiDMZSRV1_NVME vSQLCLN1_RZ1 vSQLCLN2_RZ4
        <# Match old vs current Data#>
        $TD_HostChostClusterResault = @()
        if($TD_HostLogHistoryFile.Count -ge 1){
            foreach ($TD_HostResaultSplit in $TD_IBM_HostInfoCollection) {
                <#ist der Host als online bekannt dann nächster durchlauf #>
                if($TD_HostResaultSplit.Status -eq "offline" -or $TD_HostResaultSplit.Status -eq "degraded"){
                    foreach ($TD_HostLogHistoryEntry in $TD_HostLogHistoryEntrys) {
                        if($TD_HostResaultSplit.HostName -eq $TD_HostLogHistoryEntry.HostName) {
                            #Write-Host $TD_HostResaultSplit.HostName -ForegroundColor Green
                            if ($TD_HostLogHistoryEntry.Status -eq "offline" -and $TD_HostLogHistoryEntry.ACKHosts -eq $false){
                                #Write-Host $TD_HostResaultSplit.HostName -ForegroundColor Yellow
                                $TD_HostChostClusterResault += $TD_HostResaultSplit
                            }
                            if ($TD_HostLogHistoryEntry.Status -eq "degraded" -and $TD_HostLogHistoryEntry.ACKHosts -eq $false){
                                #Write-Host $TD_HostResaultSplit.HostName -ForegroundColor DarkYellow
                                $TD_HostChostClusterResault += $TD_HostResaultSplit
                            }
                            if ($TD_HostLogHistoryEntry.Status -eq "online" ){
                                #Write-Host $TD_HostResaultSplit.HostName -ForegroundColor Magenta
                                $TD_HostChostClusterResault += $TD_HostResaultSplit
                            }
                            break
                        }else {
                            if ($TD_HostResaultSplit.Status -eq "offline" -and $TD_HostResaultSplit.ACKHosts -eq $false){
                                $TD_HostLogHistoryEntrys | ForEach-Object { if($_.HostName -eq $TD_HostResaultSplit.HostName){
                                    #Write-Host $TD_HostResaultSplit.HostName -ForegroundColor Yellow
                                    if($_.Status -ne $TD_HostResaultSplit.Status){
                                        $_.Status = $TD_HostResaultSplit.Status
                                        <# update the file if the status change to offline #>
                                        $TD_HostLogHistoryEntrys | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$(Get-Date -UFormat "%d%m%Y")_$($TD_DeviceName)_StorageHostStatusLog.csv -Delimiter ';'
                                    }

                                    if(!($_.ACKHosts -eq $false)){ break }
                                } }
                                $TD_HostChostClusterResault | ForEach-Object { if($_.HostName -eq $TD_HostResaultSplit.HostName){
                                    
                                    break
                                } }
                                #Write-Host $TD_HostResaultSplit.HostName -ForegroundColor Cyan
                                $TD_HostChostClusterResault += $TD_HostResaultSplit
                                #Write-Host $TD_HostChostClusterResault -ForegroundColor Red
                            }
                        }
                    }
                }else {
                    if($TD_HostResaultSplit.Status -eq "online"){
                        
                        $TD_HostLogHistoryEntrys | ForEach-Object {
                            if($_.HostName -eq  $TD_HostResaultSplit.HostName){
                                if($_.Status -eq "offline" -and $TD_HostResaultSplit.Status -eq "online"){
 
                                    <# delete the obj how is online from export log file#>
                                    $_.ACKHosts = $null
                                    $_.HostName = $null
                                    $_.Status = $null
                                    $_.HostSiteName = $null
                                    $_.HostClusterName = $null
                                    $_.DeviceName = $null
                                    <# needs a clean up of the empty obj #>
                                    $TD_HostLogHistoryEntrys | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$(Get-Date -UFormat "%d%m%Y")_$($TD_DeviceName)_StorageHostStatusLog.csv -Delimiter ';'
                                    
                                }
                            }
                        }
                    }
                }
            }
        }else{
            $TD_HostChostClusterResault = $TD_IBM_HostInfoCollection
            $TD_IBM_HostInfoCollection | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$(Get-Date -UFormat "%d%m%Y")_$($TD_DeviceName)_StorageHostStatusLog.csv -Delimiter ';'
        }
        <# Save the DG View as new logfile #> 
        $TD_btn_SaveHostStatus.add_click({
            $ErrorActionPreference="SilentlyContinue"
            [int]$i = 0
            $TD_dgHostResaults=@()
            $TD_IBM_HostInfoCollection=@()
            $PSPath = Split-Path -Parent $PSCommandPath
            <# switch case for all buttons #>
            switch ($TD_cb_Device_HealthCheck.Text) {
                {($_ -like "First")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_One.Content }
                {($_ -like "Second")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Two.Content }
                {($_ -like "Third")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Three.Content }
                {($_ -like "Fourth")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Four.Content }
                Default { <# Write a Message in the ToolLog #> }
            }
            
            $TD_HostLogHistoryFiles = Get-ChildItem -Path $PSPath\ToolLog\ -Filter "*_$($TD_DeviceName)_StorageHostStatusLog.csv"
            #Write-Host $TD_HostLogHistoryFiles -ForegroundColor Magenta
            $TD_HostLogHistoryFile = Get-ChildItem -Path $TD_HostLogHistoryFiles |Sort-Object Fullname -Desc |Select-Object -First 1
            #Write-Host $TD_HostLogHistoryFile.FullName -ForegroundColor Magenta
            $TD_dg_Count = $TD_dg_HostStatusInfoText.items.Count
            while ($i -le $TD_dg_Count) {
                $TD_dg_SaveResault = $TD_dg_HostStatusInfoText.items[$i]
                $TD_dgHostResaults += $TD_dg_SaveResault
                $i++
            }

            $TD_InputInfos = Import-Csv $TD_HostLogHistoryFile.FullName -Delimiter ';'

            $TD_InputInfos | ForEach-Object {
                #Write-Host $_
                $TD_IBM_HostInfoCollection += $_
            }
            $TD_dgHostResaults | ForEach-Object {
                #Write-Host $_.HostName $_.ACKHosts -ForegroundColor Cyan

                if($_.HostName -notin $TD_IBM_HostInfoCollection.HostName){
                    $TD_IBM_HostInfoCollection += $_
                }else{
                    if($_.ACKHosts -eq $TD_IBM_HostInfoCollection.ACKHosts){
                       # Write-Host $_.HostName -ForegroundColor Green
                        $TD_TestHost = $_
                        #Write-Host $TD_HostChostClusterResaultTemp.HostName -ForegroundColor Green
                        $TD_IBM_HostInfoCollection |ForEach-Object { if($_.HostName -eq $TD_TestHost.HostName ){
                            #Write-Host $_.HostName -ForegroundColor DarkGreen
                            #Write-Host $TD_TestHost -ForegroundColor DarkGreen
                            $_.ACKHosts = $TD_TestHost.ACKHosts
                        }}

                    }else{
                        #Write-Host $_.HostName -ForegroundColor Yellow
                        #$TD_HostChostClusterResaultTemp.ACKHosts = $_.ACKHosts
                        #Write-Host "is nicht so"
                    }
                }

                #Write-Host $TD_HostChostClusterResaultTemp.HostName 
                #Write-Host $TD_HostChostClusterResaultTemp.ACKHosts
            }

            #Write-Host $TD_HostChostClusterResaultTemp.count -ForegroundColor Red
            $TD_IBM_HostInfoCollection | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$(Get-Date -UFormat "%d%m%Y")_$($TD_DeviceName)_StorageHostStatusLog.csv -Delimiter ';'
        })

        #Write-Host $TD_HostChostClusterResault
        $TD_dg_HostStatusInfoText.ItemsSource=$EmptyVar
        
        if($TD_HostChostClusterResault.Count -gt 0){
            $TD_lb_HostStatusLight.Background = "red"
            if($TD_HostChostClusterResault.Count -ge 2){
                $TD_dg_HostStatusInfoText.ItemsSource=$TD_HostChostClusterResault
            }else{
                $TD_OneHost = $TD_HostChostClusterResault
                $TD_dg_HostStatusInfoText.ItemsSource=$TD_OneHost
            }
            $TD_btn_SaveHostStatus.Visibility="Visible"
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }else{
            $TD_lb_HostStatusLight.Background = "green"
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
            if($TD_HostLogHistoryFiles.Count -lt 1){
                $TD_IBM_HostInfoCollection | Export-Csv -Path $PSRootPath\ToolLog\ToolTEMP\$(Get-Date -UFormat "%d%m%Y")_$($TD_DeviceName)_StorageHostStatusLog.csv -Delimiter ';' 
            }
        }

    }
    
    end {
        <# the is no export because the export is triggerd by the funcs#>
    }
}