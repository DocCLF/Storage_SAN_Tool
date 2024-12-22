function SST_ExportCredential {
    param (
        $TD_CollectedCredDatas
    )
    <# collect the access data for subsequent processing #>

    $TD_CredCollection=foreach($TD_CollectedCredData in $TD_CollectedCredDatas){
        $TD_ToExportCredInfo = ""| Select-Object ID,DeviceTyp,ConnectionTyp,IPAddress,DeviceName,UserName,Password,SVCorVF
        $TD_ToExportCredInfo.ID = $TD_CollectedCredData.ID
        $TD_ToExportCredInfo.DeviceTyp = $TD_CollectedCredData.DeviceTyp;
        $TD_ToExportCredInfo.ConnectionTyp = $TD_CollectedCredData.ConnectionTyp;
        $TD_ToExportCredInfo.IPAddress = $TD_CollectedCredData.IPAddress;
        $TD_ToExportCredInfo.DeviceName = $TD_CollectedCredData.DeviceName;
        $TD_ToExportCredInfo.UserName = $TD_CollectedCredData.UserName;
        $TD_ToExportCredInfo.Password =    $TD_CollectedCredData.Password
        $TD_ToExportCredInfo.SVCorVF = $TD_CollectedCredData.SVCorVF;
        $TD_ToExportCredInfo
    }
    
    return $TD_CredCollection
}