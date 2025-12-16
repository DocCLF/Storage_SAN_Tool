Function SST_SaveFile_to_Directory {
    param(
        $TD_UserDataObject
    )
    $saveFileDialog = [System.Windows.Forms.SaveFileDialog]@{
        CheckPathExists  = $true
        OverwritePrompt  = $true
        InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
        Title            = 'Choose directory to save the output file'
        Filter           = "Credential files (.xml)|*.xml"
    }
    # Show save file dialog box
    if($saveFileDialog.ShowDialog() -eq 'Ok') {
        $TD_UserDataObject | Export-Clixml -Path $saveFileDialog.FileName 
    }
    $TD_lb_CerdExportPath.Content = "$($saveFileDialog.FileName)"
    return $saveFileDialog
}