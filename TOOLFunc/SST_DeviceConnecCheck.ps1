function SST_DeviceConnecCheck {
    [CmdletBinding()]
    param (
        $TD_Selected_Items,
        $TD_Selected_DeviceType,
        $TD_Selected_DeviceConnectionType,
        $TD_Selected_DeviceIPAddr,
        $TD_Selected_DeviceUserName,
        $TD_Selected_DevicePassword,
        $TD_Selected_DeviceSSHFile,
        $TD_Selected_SVCorVF,
        $TD_TapeCred = $null,
        $CockpitView
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        
        switch ($TD_Selected_Items) {
            "yes" { 
                $TD_Selected_DeviceType
                $TD_Selected_DeviceConnectionType
                $TD_Selected_DeviceIPAddr
                $TD_Selected_DeviceUserName
                $TD_Selected_DevicePassword
                $TD_UserInputCred = $TD_Selected_SVCorVF
                $TD_Creds = [PSCustomObject]@{
                    DeviceTyp = $TD_Selected_DeviceType
                    UserName = $TD_Selected_DeviceUserName
                    IPAddress = $TD_Selected_DeviceIPAddr
                    Password = $TD_Selected_DevicePassword
                }
             }
            "no" { 
                $TD_Selected_DeviceIPAddr = $TD_TB_DeviceIPAddr.Text
                $TD_Selected_DeviceUserName = $TD_TB_DeviceUserName.Text
                $TD_Selected_DevicePassword = [string]$TD_TB_DevicePassword.Password
                $TD_Selected_DeviceType = $TD_CB_DeviceType.Text
                if($TD_CB_SVCorVF.IsChecked -and ($TD_Selected_DeviceType -like "*Storage")){$TD_UserInputCred = "SVC"};
                if(!($TD_CB_SVCorVF.IsChecked)){$TD_UserInputCred = "Nothing"};
                $TD_Creds = [PSCustomObject]@{
                    DeviceTyp = $TD_Selected_DeviceType
                    UserName = $TD_TB_DeviceUserName.Text
                    IPAddress = $TD_TB_DeviceIPAddr.Text
                    Password = [string]$TD_TB_DevicePassword.Password
                }
             }
            Default {
                SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at SST_DeviceConnecCheck Func please check the promt or close the gui and write $error in the promt." -TD_ToolMSGType Warning
                }
        }

    }
    
    process {

        switch ($TD_Selected_DeviceType) {
            {$_ -like "*Storage"} { 
                #-TD_Line_ID $Device.ID -TD_Device_UserName $Device.UserName -TD_Device_DeviceIP $Device.IPAddress -TD_Device_PW $pw -TD_Exportpath $ExportPath

                try {
                    $TD_BasicInfoTemp = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc IBM_RESTBaseStorageInfos -SSHFunc IBM_SSHBaseStorageInfos
                }
                catch {
                    Write-Host $_.Exception.Message 
                }finally{
                    $TD_Creds =$null
                }

                <# not the best check but try-catch do not work, i have to check why #>
                $TD_BasicDeviceInfos = $TD_BasicInfoTemp.FuncResult.StorageInfo
                $TD_BasicDeviceConnection = $TD_BasicInfoTemp.FuncResult.ConnectionTyp
                if($TD_BasicDeviceInfos.count -gt 0){
                    $TD_BInfo = "" | Select-Object ConnectionTyp,DeviceName,ProductDes,Prod_MTM,Code_Level
                    
                    $TD_BInfo.ConnectionTyp = $TD_BasicDeviceConnection

                    if($TD_BasicDeviceInfos.ClusterName[0] -ne ""){
                        $TD_BInfo.DeviceName = $TD_BasicDeviceInfos.ClusterName[0]
                    }else {
                        $TD_BInfo.DeviceName = $TD_BasicDeviceInfos.SerialNumber[0]
                    }

                    switch ($TD_BasicDeviceInfos.ProdMTM[0]) {
                        {$_ -like "2078-324"} { $TD_BInfo.ProductDes = "V5030 Gen2" }
                        {$_ -like "2072-3N*" -or $_ -like "2078-2N*"} { $TD_BInfo.ProductDes = "FlashSystem 5000" }
                        {$_ -like "4680-3*"}  { $TD_BInfo.ProductDes = "FlashSystem 5045" }
                        {$_ -like "2077-4H4" -or $_ -like "2078-4H4" }  { $TD_BInfo.ProductDes = "FlashSystem 5100" }
                        {$_ -like "4662-6H2" -or $_ -like "4662-UH6" }  { $TD_BInfo.ProductDes = "FlashSystem 5200" }
                        {$_ -like "4662-7H2"}  { $TD_BInfo.ProductDes = "FlashSystem 5300" }
                        {$_ -like "2076-824" -or $_ -like "4664-824" -or $_ -like "*-U7C" }  { $TD_BInfo.ProductDes = "FlashSystem 7200" }
                        {$_ -like "4657-924" -or $_ -like "4657-U7D"}  { $TD_BInfo.ProductDes = "FlashSystem 7300" }
                        {$_ -like "4666-AH8" -or $_ -like "4666-UH8" -or $_ -like "4983-AH8" }  { $TD_BInfo.ProductDes = "FlashSystem 9500" }
                        {$_ -like "4666-AG8" -or $_ -like "4666-UG8" -or $_ -like "984*G8" }  { $TD_BInfo.ProductDes = "FlashSystem 9200" }
                        {$_ -like "2145-DH8"}  { $TD_BInfo.ProductDes = "SVC DH8" }
                        {$_ -like "2145-SV1"}  { $TD_BInfo.ProductDes = "SVC SV1" }
                        {$_ -like "2145-SV2"}  { $TD_BInfo.ProductDes = "SVC SV2" }
                        {$_ -like "2145-SA2"}  { $TD_BInfo.ProductDes = "SVC SA2" }
                        {$_ -like "2145-SV3"}  { $TD_BInfo.ProductDes = "SVC SV3" }
            
                        Default {
                            $TD_BInfo.ProductDes = $TD_BasicDeviceInfos.ProdMTM[0]
                            SST_ToolMessageCollector -TD_ToolMSGCollector "Unknown Storage MTM, please check this MTM Number via google $($TD_BasicDeviceInfos.Prod_MTM[0])" -TD_ToolMSGType Warning
                        }
                    }
                    
                    $TD_BInfo.Prod_MTM = $TD_BasicDeviceInfos.ProdMTM[0]
                    $TD_BInfo.Code_Level = $TD_BasicDeviceInfos.CodeLevel[0] -replace '\s+\(.*\)',''
                    $TD_BasicDeviceInfo += $TD_BInfo
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Added Storage Device to the List" -TD_ToolMSGType Message
                }else {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong, no data could be received from Storage device." -TD_ToolMSGType Error
                    break
                }
            }
            {$_ -like "*SAN"} { 

                try {
                    $TD_BasicDeviceInfosTemp = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc Get-BrocadeBaseInfo -SSHFunc FOS_SSHBasicSwitchInfos
                    $TD_BasicDeviceInfos  = $TD_BasicDeviceInfosTemp['FuncResult']
                }
                catch {
                     Write-Host $_.Exception.Message
                }

                switch ($($TD_BasicDeviceInfos.'BrocadeProductName')) {
                    {$_ -like "Brocade G720"}  { $FOS_HWMTM = "8960-P/R64" }
                    {$_ -like "Brocade G730"}  { $FOS_HWMTM = "8960-P/R96" }
                    {$_ -like "Brocade G610"}  { $FOS_HWMTM = "8969-F24" }
                    {$_ -like "Brocade G620"}  { $FOS_HWMTM = "8960-F/N65 V2" }
                    {$_ -like "Brocade G630"}  { $FOS_HWMTM = "8960-F/N97" }
                    {$_ -like "Brocade 6510"}  { $FOS_HWMTM = "2498-F48" }
                    {$_ -like "Brocade 6505"}  { $FOS_HWMTM = "2498-F24" }
                    Default {$FOS_HWMTM = "Unknown Type"}
                }
                
                if($null -ne $TD_BasicDeviceInfos){
                    $TD_BInfo = "" | Select-Object ConnectionTyp,DeviceName,ProductDes,Prod_MTM,Code_Level,VFenabled
                    $TD_BInfo.ConnectionTyp = if(!($null -eq $TD_BasicDeviceInfos.VFID)){"REST"}else{"plink"}
                    $TD_BInfo.DeviceName = $TD_BasicDeviceInfos.'SwitchName'
                    $TD_BInfo.ProductDes = $TD_BasicDeviceInfos.'BrocadeProductName'
                    $TD_BInfo.Prod_MTM = $TD_BasicDeviceInfos.'MTM'
                    $TD_BInfo.Code_Level = $TD_BasicDeviceInfos.'FabricOS'
                    $TD_BInfo.VFenabled = $TD_BasicDeviceInfos.'VFenabled'
                    $TD_BasicDeviceInfo += $TD_BInfo
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Added SAN Device to the List" -TD_ToolMSGType Message
                }else {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong, no data could be received from SAN device." -TD_ToolMSGType Error
                    break
                }
            }
            {$_ -like "*PowerHMC"} {
                $TD_BasicDeviceInfos = $null
                $FunctionResult = New-DeviceBlock -Device $TD_Creds -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCConsole
                $TD_BasicDeviceInfos = $FunctionResult.FuncResult
                if($null -ne $TD_BasicDeviceInfos){
                    $TD_BInfo = "" | Select-Object ConnectionTyp,DeviceName,ProductDes,Prod_MTM,Code_Level
                    $TD_BInfo.ConnectionTyp = if(!($null -eq $TD_BasicDeviceInfos.HMCMTM)){"REST"}else{"unkonwn"}
                    $TD_BInfo.DeviceName = $TD_BasicDeviceInfos.HMCName
                    $TD_BInfo.ProductDes = "PowerHMC"
                    $TD_BInfo.Prod_MTM = $TD_BasicDeviceInfos.HMCMTM
                    $TD_BInfo.Code_Level = $TD_BasicDeviceInfos.BaseVersion
                    $TD_BasicDeviceInfo += $TD_BInfo
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Added HMC Device to the List" -TD_ToolMSGType Message
                }else {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong, no data could be received from HMC device." -TD_ToolMSGType Error
                    break
                }
            }
            {$_ -like "*Tape"} {
                if($null -eq $TD_TapeCred){
                    $TD_Creds =@{
                        IPAddress = $TD_Selected_DeviceIPAddr
                        UserName = $TD_Selected_DeviceUserName
                        Password = $TD_Selected_DevicePassword
                    }
                }else {
                    $TD_Creds = $TD_TapeCred
                }
                $TD_BasicTapeInfos = Invoke_IBMTapeLibraryApi -Device $TD_Creds -Endpoint 'library/baseinfo'
                $TD_BasicDeviceInfos = $TD_BasicTapeInfos.BaseInfo
                if($TD_BasicDeviceInfos.Count -gt 0){
                    $CombiSNMTM = $null
                    $CombiSNMTM = $TD_BasicDeviceInfos.SerialNumber
                    $SN = $CombiSNMTM.Substring($CombiSNMTM.Length -7)
                    #$SN = $CombiSNMTM.Substring($CombiSNMTM.Length -7) # not needed at moment
                    $TD_BInfo = "" | Select-Object ConnectionTyp,DeviceName,ProductDes,Prod_MTM,Code_Level,TapeWWNN
                    $TD_BInfo.ConnectionTyp = if(!($null -eq $TD_BasicTapeInfos.Prod_MTM)){"REST"}else{"unkonwn"}
                    $TD_BInfo.DeviceName = if([string]::IsNullOrWhiteSpace($($TD_BasicDeviceInfos.name))){$SN}else{$($TD_BasicDeviceInfos.name)}
                    $TD_BInfo.ProductDes = "Tape Library"
                    $TD_BInfo.Prod_MTM = $($CombiSNMTM.TrimEnd($SN)).Insert(4,"-")
                    $TD_BInfo.Code_Level = $TD_BasicDeviceInfos.BaseFWRevision
                    $TD_BInfo.TapeWWNN = $TD_BasicDeviceInfos.WWNodeName
                    $TD_BasicDeviceInfo += $TD_BInfo
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Added Tape Device to the List" -TD_ToolMSGType Message
                }else {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong, no data could be received from Tape device." -TD_ToolMSGType Error
                    break
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at SST_DeviceConnecCheck Func or no Device Type was found, please check the promt." -TD_ToolMSGType Warning}
        }
        
        if($TD_Selected_Items -eq "yes"){
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource
            <# ForEach is needed if you import ced, because you musst add the pw this was not exported  #>
            [array]$TD_Credentials = foreach ($TD_ExistingCred in $TD_Credentials) {
                if($TD_ExistingCred.IPAddress -eq $TD_Selected_DeviceIPAddr){
                    $TD_UserInputCred = "" | Select-Object ID,DeviceTyp,ConnectionTyp,IPAddress,DeviceName,UserName,Password,TapeWWNN,SVCorVF,MTMCode,ProductDescr,CurrentFirmware,Exportpath
                    $TD_UserInputCred.ID               =   $TD_ExistingCred.ID;
                    $TD_UserInputCred.DeviceTyp        =   $TD_ExistingCred.DeviceTyp;
                    $TD_UserInputCred.ConnectionTyp    =   $TD_BasicDeviceInfo.ConnectionTyp;
                    $TD_UserInputCred.IPAddress        =   $TD_ExistingCred.IPAddress;
                    $TD_UserInputCred.DeviceName       =   $TD_BasicDeviceInfo.DeviceName;
                    $TD_UserInputCred.TapeWWNN         =   $TD_BasicDeviceInfo.TapeWWNN
                    $TD_UserInputCred.UserName         =   $TD_ExistingCred.UserName;
                    <# The PwLine needs a better Option #>
                    $TD_UserInputCred.Password         =   $TD_Selected_DevicePassword;
                    $TD_UserInputCred.SVCorVF          =   if($TD_BasicDeviceInfo.VFenabled -like "True"){"vFabric"}else{$TD_ExistingCred.SVCorVF;}
                    $TD_UserInputCred.MTMCode          =   $TD_BasicDeviceInfo.Prod_MTM;
                    $TD_UserInputCred.ProductDescr     =   $TD_BasicDeviceInfo.ProductDes;
                    $TD_UserInputCred.CurrentFirmware  =   $TD_BasicDeviceInfo.Code_Level;
                    
                    $TD_ExistingCredUpdate = $TD_UserInputCred
                }else{
                    $TD_ExistingCredUpdate = $TD_ExistingCred |Where-Object {$_}
                }
                $TD_ExistingCredUpdate
            }
            $TD_DG_KnownDeviceList.ItemsSource = $TD_Credentials
        }
    }
    
    end {
        if(($TD_Selected_Items -eq "no")-or ($CockpitView -eq "JobMode")){
            return $TD_BasicDeviceInfo
        }
    }
}