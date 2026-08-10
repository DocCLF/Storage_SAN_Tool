function SST_OpenFile_from_Directory {
    [CmdletBinding()]
    # Show an Open File Dialog and return the file selected by the user.
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select File"
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    $openFileDialog.Filter = "All files (*.csv)|*.*"
    $openFileDialog.MultiSelect = $false 
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null

    #Write-Host $openFileDialog.InitialDirectory
    return $openFileDialog
}