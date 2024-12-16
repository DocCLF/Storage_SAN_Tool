function SST_ExportCredential {
    param (
        $TD_CollectedCredDatas
    )
    <# collect the access data for subsequent processing #>

    $TD_CredCollection=foreach($TD_CollectedCredData in $TD_CollectedCredDatas){
        $TD_ToExportCredInfo = ""| Select-Object ID,DeviceTyp,ConnectionTyp,IPAdresse,UserName,SVCorVF
        $TD_ToExportCredInfo.ID = $TD_CollectedCredData.ID
        $TD_ToExportCredInfo.DeviceTyp = $TD_CollectedCredData.DeviceTyp;
        $TD_ToExportCredInfo.ConnectionTyp = $TD_CollectedCredData.ConnectionTyp;
        $TD_ToExportCredInfo.IPAddress = $TD_CollectedCredData.IPAddress;
        $TD_ToExportCredInfo.UserName = $TD_CollectedCredData.UserName;
        $TD_ToExportCredInfo.SVCorVF = $TD_CollectedCredData.SVCorVF;
        $TD_ToExportCredInfo
    }
    
    #$TD_CredObject=New-Object -TypeName psobject -Property $TD_CredCollection
    
    return $TD_CredCollection
}