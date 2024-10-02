
function IBM_StorageHealthCheck {
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
        [Int16]$TD_Line_ID,
        [Parameter(Mandatory)]
        [string]$TD_Device_ConnectionTyp,
        [Parameter(Mandatory)]
        [string]$TD_Device_UserName,
        [Parameter(Mandatory)]
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    
    begin {
        #<# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"

        $TD_btn_SaveHostStatus.Visibility="Collapsed"
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CollectInfo = ssh $TD_Device_UserName@$TD_Device_DeviceIP "lshost && lshostcluster && lsmdisk && lsvdisk && lsuser && lsfcmap && lsencryption && lsenclosurebattery && lsenclosurestats && lsenclosureslot && lsrcrelationship && lsrcconsistgrp && lspartnership && lssecurity && lseventlog | grep alert"
        }else {
            $TD_CollectInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "lshost && lshostcluster && lsmdisk && lsvdisk && lsuser && lsfcmap && lsencryption && lsenclosurebattery && lsenclosurestats && lsenclosureslot && lsrcrelationship && lsrcconsistgrp && lspartnership && lssecurity && lseventlog | grep alert"
        }
        <# next line one for testing #>
        #$TD_CollectInfo = Get-Content -Path "C:\Users\mailt\Documents\mimixexport.txt" #C:\Users\mailt\Documents\mimixexport.txt hyperswap
        #$TD_CollectInfo = Get-Content -Path "C:\Users\mailt\Desktop\FS5200_W.txt"
        $PSPath = Split-Path -Parent $PSCommandPath 
        #Write-Host $PSPath
        #$TD_dg_HostStatusInfoText.Add_SelectionChanged({
        #    $TD_dg_HostStatusInfoText | ForEach-Object {
        #        Write-Host $_.selecteditem[0]
        #    }
        #    #$PSPath = Split-Path -Parent $PSCommandPath 
        #    Write-Host $PSPath -ForegroundColor Green
        #})
        $TD_InfoCount = $TD_CollectInfo.count
        0..$TD_InfoCount |ForEach-Object {
            if($TD_CollectInfo[$_] -match 'location '){
                $TD_TD_DeviceNameTemp = $TD_CollectInfo |Select-Object -Skip $_
            }
            if($TD_CollectInfo[$_] -match 'mapping_count'){
                $TD_HostClusterTemp = $TD_CollectInfo |Select-Object -Skip $_
            }
            if($TD_CollectInfo[$_] -match 'ssh_protocol_suggested'){
                $TD_EventLogTemp = $TD_CollectInfo |Select-Object -Skip ($_ +1)
            }
            if($TD_CollectInfo[$_] -match 'site_name distributed'){
                $TD_MDiskInfoTemp = $TD_CollectInfo |Select-Object -Skip ($_ +1)
            }
            if($TD_CollectInfo[$_] -match 'vdisk_UID'){
                $TD_VDiskInfoTemp = $TD_CollectInfo |Select-Object -Skip ($_ +1)
            }
            if($TD_CollectInfo[$_] -match 'usergrp_id'){
                $TD_UserInfoTemp = $TD_CollectInfo |Select-Object -Skip ($_ +1)
            }
        }
        
        foreach ($TD_LineInfo in $TD_TD_DeviceNameTemp) {
                [string]$TD_DeviceName = ($TD_LineInfo |Select-String -Pattern '([a-zA-Z0-9-_]+)\s+local|remote' -AllMatches).Matches.Groups[1].Value
                #Write-Host $TD_DeviceName -ForegroundColor lightgreen
                #$TD_btn_HC_OpenGUI_One.Content = $TD_DeviceName LightGreen
                
                switch ($TD_cb_Device_HealthCheck.Text) {
                    {($_ -like "*First")} { $TD_btn_HC_OpenGUI_One.Content = $TD_DeviceName; $TD_btn_HC_OpenGUI_One.Background = "LightGreen" }
                    {($_ -like "*Second")} { $TD_btn_HC_OpenGUI_Two.Content = $TD_DeviceName; $TD_btn_HC_OpenGUI_Two.Background = "LightGreen" }
                    {($_ -like "*Third")} { $TD_btn_HC_OpenGUI_Three.Content = $TD_DeviceName; $TD_btn_HC_OpenGUI_Three.Background = "LightGreen" }
                    {($_ -like "*Fourth")} { $TD_btn_HC_OpenGUI_Four.Content = $TD_DeviceName; $TD_btn_HC_OpenGUI_Four.Background = "LightGreen" }
                    Default { <# Write a Message in the ToolLog #> Write-Host "nothing done"}
                }
                if(!([string]::IsNullOrEmpty($TD_DeviceName))){break}
        }
    }
    
    process {
        <# check if there are old files of that device and collect them into array #>
        $TD_EventLogHistoryFiles = Get-ChildItem -Path $PSPath\DeviceLog\ -Filter "*_$($TD_DeviceName)_EventLog.csv"
        <# hold the last 10 and delete the rest #>
        #Get-ChildItem $TD_EventLogHistoryFiles |Sort-Object Fullname -Desc|Select-Object -Skip 5 |Remove-Item
        <# create a array of newest data from the device #>
        $TD_EventCollection = @()
        foreach($EventLine in $TD_EventLogTemp){
            $TD_EventSplitInfo = "" | Select-Object ACKEvents,Seq_Number,LastTime,Status,Fixed,ErrorCode,Description
            $TD_EventSplitInfo.Seq_Number = ($EventLine |Select-String -Pattern '^(\d+)\s+' -AllMatches).Matches.Groups[1].Value
            $TD_EventSplitInfo.LastTime = ($EventLine|Select-String -Pattern '^\d+\s+(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_EventSplitInfo.Status = ($EventLine|Select-String -Pattern '\s+(alert)\s+' -AllMatches).Matches.Groups[1].Value
            if($TD_EventSplitInfo.Status -eq "alert"){
                <# all data that a collected with status alaert markt via default as false so that the user musst ack them to true to show "never" again #>
                [bool]$TD_EventSplitInfo.ACKEvents = $false
            }else {
                <# all rest data that a collected markt via default as true so that there a "never" show again #>
                [bool]$TD_EventSplitInfo.ACKEvents = $true
            }
            $TD_EventSplitInfo.Fixed = ($EventLine|Select-String -Pattern 'alert\s+(no|yes)' -AllMatches).Matches.Groups[1].Value
            if(!([String]::IsNullOrEmpty(($EventLine|Select-String -Pattern '\s+\d{6}\s+(\d+|)\s+' -AllMatches).Matches.Groups[1].Value))){
                $TD_EventSplitInfo.ErrorCode = ($EventLine|Select-String -Pattern '\s+\d{6}\s+(\d+|)\s+' -AllMatches).Matches.Groups[1].Value
            }else {
                $TD_EventSplitInfo.ErrorCode = "none"
            }
            $TD_EventSplitInfo.Description = ($EventLine|Select-String -Pattern '\s+\d{6}\s+(\d+|)\s+([a-zA-Z0-9\s_.,]+)$' -AllMatches).Matches.Groups[2].Value

            $TD_EventCollection += $TD_EventSplitInfo
        }

        #$TD_EventLogHistoryFile = Get-ChildItem -Path D:\GitRepo\ps_collection\DeviceLog\2024-08-12_RZ1_FS9500_HS_EventLog.csv |Sort-Object Fullname -Desc |Select-Object -First 1
        #$TD_EventLogHistoryEntrys = Import-Csv -Path $TD_EventLogHistoryFile.FullName -Delimiter ';'
        #$TD_EventLogHistoryEntrys = $TD_EventLogHistoryEntrys | Where-Object {($_.Status -eq "alert" -and $_.Fixed -eq "no")-or($_.ACK -eq $false)}

        <# Creates a file for and stores it in DeviceLog, if it is executed several times in one day, the respective new data is added. #>
        Out-File -FilePath $PSPath\DeviceLog\$(Get-Date -Format "yyyy-MM-dd")_$($TD_DeviceName)_EventLog.csv -InputObject $TD_EventCollection
        #$TD_EventCollection | Export-Csv -Path $PSPath\DeviceLog\$(Get-Date -Format "yyyy-MM-dd")_$($TD_DeviceName)_EventLog.csv -Delimiter ';' 

        $TD_dg_EventlogStatusInfoText.ItemsSource=$EmptyVar
        if($TD_EventCollection.Status -eq "alert"){
            $TD_lb_EventlogLight.Background="red"
            if(($TD_EventCollection | Where-Object {$_.Status -eq "alert"}).Count -ge 2){
                $TD_dg_EventlogStatusInfoText.ItemsSource=$TD_EventCollection | Where-Object {(($_.Status -eq "alert")-and(($_.Fixed -eq "no")-or($_.Fixed -eq "yes")))} |Select-Object -Last 10

            }else {
                $TD_OnlyOneEvent = $TD_EventCollection | Where-Object {(($_.Status -eq "alert")-and(($_.Fixed -eq "no")-or($_.Fixed -eq "yes")))}
                
                $TD_dg_EventlogStatusInfoText.ItemsSource=$TD_OnlyOneEvent
            }
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }elseif (($TD_EventCollection.Status -eq "monitoring")-or($TD_EventCollection.Status -eq "expired")) {
            $TD_lb_EventlogLight.Background="yellow"
            $TD_dg_EventlogStatusInfoText.ItemsSource=$TD_EventCollection | Where-Object {(($_.Status -ne "monitoring")-or($_.Status -eq "expired"))}
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }else {
            $TD_lb_EventlogLight.Background="green"
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }


        <# check if there are old files of that device and collect them into array #>
        $TD_HostLogHistoryFiles = Get-ChildItem -Path $PSPath\DeviceLog\ -Filter "*_$($TD_DeviceName)_HostLog.csv"
        #Write-Host $TD_HostLogHistoryFiles / $TD_HostLogHistoryFiles.Count

        <# create a array of newest data from the device #>
        if($TD_HostLogHistoryFiles.Count -ge 1){
            $TD_HostLogHistoryFile = Get-ChildItem -Path $TD_HostLogHistoryFiles |Sort-Object Fullname -Desc |Select-Object -First 1
            #Write-Host $TD_HostLogHistoryFile.FullName
            $TD_HostLogHistoryEntrys = Import-Csv -Path $TD_HostLogHistoryFile.FullName -Delimiter ';'
            #Write-Host $TD_HostLogHistoryEntrys
            #Write-Host $TD_HostLogHistoryEntrys.count -ForegroundColor Yellow
            if($TD_HostLogHistoryFiles.Count -ge 4){
                <# hold the last 3 and delete the rest #>
                Get-ChildItem $TD_HostLogHistoryFiles |Sort-Object Fullname -Desc|Select-Object -Skip 3 |Remove-Item
            }
        }
        $TD_HostChostClusterResaultTemp = @()
        foreach ($TD_HostHostClusterInfo in $TD_CollectInfo){
            if($TD_HostHostClusterInfo |Select-String -Pattern "mapping_count"){break}
            $TD_HostChostClusterInfo = "" | Select-Object ACKHosts,HostName,Status,HostSiteName,HostClusterName,DeviceName
            $TD_HostChostClusterInfo.HostName = ($TD_HostHostClusterInfo|Select-String -Pattern '^\d+\s+([0-9a-zA-z-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_HostChostClusterInfo.Status = ($TD_HostHostClusterInfo|Select-String -Pattern '\s+(online|offline|degraded)\s+' -AllMatches).Matches.Groups[1].Value
            if($TD_HostChostClusterInfo.Status -eq "offline" -or $TD_HostChostClusterInfo.Status -eq "degraded"){
                [bool]$TD_HostChostClusterInfo.ACKHosts = $false
            }else {
                <# Action when all if and elseif conditions are false #>
                [bool]$TD_HostChostClusterInfo.ACKHosts = $true
            }
            $TD_HostChostClusterInfo.HostSiteName = ($TD_HostHostClusterInfo|Select-String -Pattern '\s+(online|offline|degraded)\s+\d+\s+(\w+)\s+\d+' -AllMatches).Matches.Groups[2].Value
            $TD_HostChostClusterInfo.HostClusterName = ($TD_HostHostClusterInfo|Select-String -Pattern '\s+(online|offline|degraded)\s+(\d+|)\s+([a-zA-Z0-9-_]+|)\s+(\d+|)\s+([a-zA-Z0-9-_]+)\s+scsi|fcnvme' -AllMatches).Matches.Groups[5].Value
            $TD_HostChostClusterInfo.DeviceName = $TD_DeviceName

            if((![string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostName))){
                <# HostClusterStatus implement maybe later #>
                #if(![string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostClusterName)){
                #    foreach ($TD_HostClusterStatus in $TD_HostClusterTemp){
                #        if($TD_HostClusterStatus |Select-String -Pattern "supports_unmap"){break}
                #        #if(![string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostClusterStatus)){break}
                #        $TD_HostChostClusterInfo.HostClusterStatus = ($TD_HostClusterStatus|Select-String -Pattern '\s+(online|offline|host_degraded|host_cluster_degraded)\s+' -AllMatches).Matches.Groups[1].Value
                #    }
                #}
                $TD_HostChostClusterResaultTemp += $TD_HostChostClusterInfo
            }
            if(([string]::IsNullOrEmpty($TD_HostChostClusterInfo.HostClusterName))-and($TD_HostHostClusterInfo |Select-String -Pattern "mdisk_grp_name")){break}
        }

        <# Match old vs current Data#>
        $TD_HostChostClusterResault = @()
        if($TD_HostLogHistoryFiles.Count -ge 1){
            foreach ($TD_HostResaultSplit in $TD_HostChostClusterResaultTemp) {
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
                                        $TD_HostLogHistoryEntrys | Export-Csv -Path $PSPath\DeviceLog\$(Get-Date -Format "yyyy-MM-dd")_$($TD_DeviceName)_HostLog.csv -Delimiter ';'
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
                                    $TD_HostLogHistoryEntrys | Export-Csv -Path $PSPath\DeviceLog\$(Get-Date -Format "yyyy-MM-dd")_$($TD_DeviceName)_HostLog.csv -Delimiter ';'
                                    
                                }
                            }
                        }
                    }
                }
            }
        }else{
            $TD_HostChostClusterResault = $TD_HostChostClusterResaultTemp
            $TD_HostChostClusterResaultTemp | Export-Csv -Path $PSPath\DeviceLog\$(Get-Date -Format "yyyy-MM-dd")_$($TD_DeviceName)_HostLog.csv -Delimiter ';'
        }
        <# Save the DG View as new logfile #> 
        $TD_btn_SaveHostStatus.add_click({
            $ErrorActionPreference="SilentlyContinue"
            [int]$i = 0
            $TD_dgHostResaults=@()
            $TD_HostChostClusterResaultTemp=@()
            $PSPath = Split-Path -Parent $PSCommandPath
            <# switch case for all buttons #>
            switch ($TD_cb_Device_HealthCheck.Text) {
                {($_ -like "First")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_One.Content }
                {($_ -like "Second")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Two.Content }
                {($_ -like "Third")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Three.Content }
                {($_ -like "Fourth")} { $TD_DeviceName = $TD_btn_HC_OpenGUI_Four.Content }
                Default { <# Write a Message in the ToolLog #> }
            }
            
            $TD_HostLogHistoryFiles = Get-ChildItem -Path $PSPath\DeviceLog\ -Filter "*_$($TD_DeviceName)_HostLog.csv"
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
                $TD_HostChostClusterResaultTemp += $_
            }
            $TD_dgHostResaults | ForEach-Object {
                #Write-Host $_.HostName $_.ACKHosts -ForegroundColor Cyan

                if($_.HostName -notin $TD_HostChostClusterResaultTemp.HostName){
                    $TD_HostChostClusterResaultTemp += $_
                }else{
                    if($_.ACKHosts -eq $TD_HostChostClusterResaultTemp.ACKHosts){
                       # Write-Host $_.HostName -ForegroundColor Green
                        $TD_TestHost = $_
                        #Write-Host $TD_HostChostClusterResaultTemp.HostName -ForegroundColor Green
                        $TD_HostChostClusterResaultTemp |ForEach-Object { if($_.HostName -eq $TD_TestHost.HostName ){
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
            $TD_HostChostClusterResaultTemp | Export-Csv -Path $PSPath\DeviceLog\$(Get-Date -Format "yyyy-MM-dd")_$($TD_DeviceName)_HostLog.csv -Delimiter ';'
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
                $TD_HostChostClusterResaultTemp | Export-Csv -Path $PSPath\DeviceLog\$(Get-Date -Format "yyyy-MM-dd")_$($TD_DeviceName)_HostLog.csv -Delimiter ';' 
            }
        }
        

        $TD_MDiskResault = @()
        foreach ($TD_MDisk in $TD_MDiskInfoTemp){
            if($TD_MDisk |Select-String -Pattern "vdisk_UID"){break}
            $TD_MDiskInfo = "" | Select-Object Pool,Status,Capacity
            $TD_MDiskInfo.Status = ($TD_MDisk|Select-String -Pattern '\d+\s+([a-zA-Z0-9-_]+)\s+(online|offline|excluded|degraded|degraded_paths|degraded_ports)' -AllMatches).Matches.Groups[2].Value
            $TD_MDiskInfo.Pool = ($TD_MDisk|Select-String -Pattern '\s+\d+\s+([a-zA-Z0-9-_]+)\s+(\d+.\d+[A-Z]+)' -AllMatches).Matches.Groups[1].Value
            $TD_MDiskInfo.Capacity = ($TD_MDisk|Select-String -Pattern '\s+\d+\s+([a-zA-Z0-9-_]+)\s+(\d+.\d+[A-Z]+)' -AllMatches).Matches.Groups[2].Value
            $TD_MDiskResault += $TD_MDiskInfo
        }
        $TD_dg_MdiskStatusInfoText.ItemsSource=$EmptyVar
        if(($TD_MDiskResault.Status -eq "offline")-or($TD_MDiskResault.Status -eq "excluded")){
            $TD_lb_MdiskStatusLight.Background ="red"
            $TD_dg_MdiskStatusInfoText.ItemsSource=$TD_MDiskResault
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }elseif ($TD_MDiskResault.Status -like "degraded*") {
            $TD_lb_MdiskStatusLight.Background ="yellow"
            $TD_dg_MdiskStatusInfoText.ItemsSource=$TD_MDiskResault
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }elseif (($TD_MDiskResault.Status -eq "online").count -eq ($TD_MDiskResault.count)){
            $TD_lb_MdiskStatusLight.Background ="green"
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }
        

        $TD_VdiskResaultTemp = @()
        foreach($TD_VDisk in $TD_VDiskInfoTemp){
            if($TD_VDisk |Select-String -Pattern "usergrp_id"){break}
            $TD_VDiskinfo = "" | Select-Object Volume_Name,IO_Group,Status,Pool,Volume_UID,VolFunc
            $TD_VDiskinfo.Volume_Name = ($TD_VDisk|Select-String -Pattern '^\d+\s+([a-zA-Z0-9-_]+)\s+\d+\s+([a-zA-Z0-9-_]+)\s+' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.IO_Group = ($TD_VDisk|Select-String -Pattern '^\d+\s+([a-zA-Z0-9-_]+)\s+\d+\s+([a-zA-Z0-9-_]+)\s+' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Status = ($TD_VDisk|Select-String -Pattern '\s+(online|offline|deleting|degraded)\s+' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.Pool = ($TD_VDisk|Select-String -Pattern '\s+(online|offline|deleting|degraded)\s+\d+\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[2].Value
            $TD_VDiskinfo.Volume_UID = ($TD_VDisk|Select-String -Pattern '\s+([0-9A-F]+)\s+\d+\s+\d+\s+' -AllMatches).Matches.Groups[1].Value
            $TD_VDiskinfo.VolFunc = ($TD_VDisk|Select-String -Pattern '\s+(master_change|master|aux_change|aux)\s+' -AllMatches).Matches.Groups[1].Value
            If([String]::IsNullOrEmpty($TD_VDiskinfo.VolFunc)){
                $TD_VDiskinfo.VolFunc="none"
            }
            $TD_VdiskResaultTemp += $TD_VDiskinfo
        }
        <# performance opti #>
        #$TD_VdiskResault=@()
        #$TD_VdiskResaultTemp | ForEach-Object {
        #    if(($_.VolFunc -eq 'master')-or($_.VolFunc -eq 'none')){
        #        #Write-Host $_
        #        $TD_VdiskResault += $_
        #    }
        #}
        [array]$TD_VdiskResault += foreach($_ in $TD_VdiskResaultTemp){
            if(($_.VolFunc -eq 'master')-or($_.VolFunc -eq 'none')){
                #Write-Host $_
                $_
            }
        }
        $TD_dg_VDiskStatusInfoText.ItemsSource=$EmptyVar
        if((($TD_VdiskResault| Where-Object {$_.Status -eq "offline"}).count) -gt 0){
            $TD_lb_VDiskStatusLight.Background ="red"
            if((($TD_VdiskResault| Where-Object {($_.Status -eq "offline")-or($_.Status -eq "deleting")-or($_.Status -eq "degraded")}).count) -ge 2){
            $TD_dg_VDiskStatusInfoText.ItemsSource= $TD_VdiskResault | Where-Object {(($_.Status -eq "offline")-or($_.Status -eq "deleting")-or($_.Status -eq "degraded"))}
            }else {
                $TD_OneVdisk = $TD_VdiskResault | Where-Object {($_.Status -eq "offline")-or($_.Status -eq "deleting")}
                $TD_dg_VDiskStatusInfoText.ItemsSource= ,$TD_OneVdisk
            }
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }elseif ((($TD_VdiskResault| Where-Object {$_.Status -eq "degraded"}).count) -gt 0) {
            $TD_lb_VDiskStatusLight.Background ="yellow"
            if((($TD_VdiskResault| Where-Object {$_.Status -eq "degraded"}).count) -ge 2){
                $TD_dg_VDiskStatusInfoText.ItemsSource= $TD_VdiskResault | Where-Object {($_.Status -eq "degraded")}
            }else{
                $TD_OneVdisk = $TD_VdiskResault | Where-Object {($_.Status -eq "degraded")}
                $TD_dg_VDiskStatusInfoText.ItemsSource= ,$TD_OneVdisk
            }
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }elseif ($TD_VdiskResault.Status -eq "online") {
            $TD_lb_VDiskStatusLight.Background ="green"
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }
        
        #$TD_QuorumResult = IBM_IPQuorum -TD_Line_ID $TD_Line_ID -TD_Device_ConnectionTyp $TD_Device_ConnectionTyp -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW -TD_Export yes -TD_Exportpath $TD_Exportpath
        if(!([String]::IsNullOrEmpty($TD_QuorumResult))){
            $TD_lb_QuorumStatusLight.Background ="green"
            $TD_dg_QuorumStatusInfo.ItemsSource = $TD_QuorumResult
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }else{
            $TD_lb_QuorumStatusLight.Background ="red"
            $TD_tb_QuorumErrorMsg.Visibility = "Visible"
            $TD_tb_QuorumErrorMsg.Text = "Your current quorum configuration differs from the default and does not`n seem to have the minimum number of 3 quorum devices, please check this!"
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }

        $TD_UserResault=@()
        foreach($TD_User in $TD_UserInfoTemp){
            if($TD_User |Select-String -Pattern "quorum_index"){break}
            $TD_Userinfo = "" | Select-Object User_Name,Password,SSH_Key,Remote,UserGrp,Locked,PW_Change_required
            $TD_Userinfo.User_Name = ($TD_User|Select-String -Pattern '^\d+\s+([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_Userinfo.Password = ($TD_User|Select-String -Pattern '\s+(yes|no)\s+(yes|no)\s+(yes|no)\s+' -AllMatches).Matches.Groups[1].Value
            $TD_Userinfo.SSH_Key = ($TD_User|Select-String -Pattern '\s+(yes|no)\s+(yes|no)\s+(yes|no)\s+' -AllMatches).Matches.Groups[2].Value
            $TD_Userinfo.Remote = ($TD_User|Select-String -Pattern '\s+(yes|no)\s+(yes|no)\s+(yes|no)\s+' -AllMatches).Matches.Groups[3].Value
            $TD_Userinfo.UserGrp = ($TD_User|Select-String -Pattern '\s+(yes|no)\s+(yes|no)\s+(yes|no)\s+\d+\s+([a-zA-Z0-9-_]+)\s+' -AllMatches).Matches.Groups[4].Value
            $TD_Userinfo.Locked = ($TD_User|Select-String -Pattern '\s+(no|auto|manual)\s+(yes|no)\s+$' -AllMatches).Matches.Groups[1].Value
            $TD_Userinfo.PW_Change_required = ($TD_User|Select-String -Pattern '\s+(no|auto|manual)\s+(yes|no)\s+$' -AllMatches).Matches.Groups[2].Value

            $TD_UserResault += $TD_Userinfo
        }
        $TD_dg_UserStatusInfoText.ItemsSource=$EmptyVar
        if(($TD_UserResault.PW_Change_required -eq "yes")){
            $TD_lb_UserStatusLight.Background ="red"
            $TD_dg_UserStatusInfoText.ItemsSource=$TD_UserResault
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }elseif (($TD_UserResault.PW_Change_required -like "yes")-or($TD_UserResault.SSH_Key -eq "no")) {
            $TD_lb_UserStatusLight.Background ="yellow"
            $TD_dg_UserStatusInfoText.ItemsSource=$TD_UserResault
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }elseif ($TD_UserResault.PW_Change_required -eq "no"){
            $TD_lb_UserStatusLight.Background ="green"
            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
        }

        $TD_StorageSecurityResult = IBM_StorageSecurity -TD_Line_ID $TD_Line_ID -TD_Device_ConnectionTyp $TD_Device_ConnectionTyp -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW -TD_Export yes -TD_Exportpath $TD_Exportpath
        if(!([String]::IsNullOrEmpty($TD_StorageSecurityResult))){
            $TD_lb_SecurityStatusLight.Background ="green"
            $TD_dg_SecurityStatusInfoText.ItemsSource = $TD_StorageSecurityResult
            $TD_tb_SecurityInfoMsg.Text ="*For further information visit the IBM Docs page of your system,`ne.g. for FS5X00 :https://www.ibm.com/docs/en/flashsystem-5x00/8.6.x?topic=csc-lssecurity-2"
            $TD_tb_SecurityInfoMsg.Visibility = "Visible"
            $TD_UserControl3_2.Dispatcher.Invoke([System.Action]{},"Render")
        }else{
            $TD_lb_SecurityStatusLight.Background ="red"
            $TD_tb_SecurityStatusErrorMsg.Visibility = "Visible"
            $TD_tb_SecurityStatusErrorMsg.Text = "There is a problem, please check your storage system settings!"
            $TD_UserControl3_2.Dispatcher.Invoke([System.Action]{},"Render")
        }
        
    }
    
    end {
    
    }
}