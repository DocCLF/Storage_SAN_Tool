function Storage_San_Tool{

    #region GUILoad 
    <#StartPoint of Module#>
    try {
        SST_GUI_Control -ErrorAction Stop
    }
    catch {
        Write-Host "SST_GUI_Control Function was not loaded or is faulty, please contact the tool supporter!" -ForegroundColor Red
        Write-Error -Message $_.Exception.Message
        break
    }
    #endregion

}