function IBM_DriveFirmwareCheck {
    #https://www.ibm.com/support/pages/node/6508601
    [CmdletBinding()]
    param (
        $IBM_DriveProdID = "101406E2",
        $IBM_DriveCurrentFW  = "4_1_8",
        <# The following arrays may be used later as "real params" #>
        [array]$IBM_FCMDriveFaultyFW,
        [array]$IBM_FCMDriveFixFW,
        [array]$IBM_NVMeDriveFaultyFW,
        [array]$IBM_NVMeDriveFixFW,
        [array]$IBM_SASDriveFaultyFW,
        [array]$IBM_SASDriveFixFW
    )
    
    begin {
        <# nothing to do here #>

        $IBM_FCMDriveFaultyFW = "2_1_2","2_1_3","2_1_4","2_1_5","2_1_6","2_1_10","2_1_11","3_0_1","3_1_2","3_1_4","3_1_7","3_1_8","3_1_11","4_1_4","4_1_8"
        $IBM_FCMDriveFixFW = (("3_1_15",("101406B0","101406B1","101406B2","101406B3")),("2_1_12",("10140653","10140654","10140655","10140656")),("4_1_9",("101406E2","101406E3","101406E4","101406E5")))

        $IBM_NVMeDriveFaultyFW = "C6S5"
        $IBM_NVMeDriveFixFW = (("C6S6",("10140689","1014068A","1014068B","1014068C","1014068D")))

        $IBM_SASDriveFaultyFW = "MS63","MS64","MS68","MS69","MS66","MS66","MS33","MS34","MS35","MS36","MS38","MS39","MS3B"
        $IBM_SASDriveFixFW =(("MS6C",("MZILT200HAHQ","MZILT400HAHQ","MZILT800HAHQ")),("MS3E",("MZILT800HAJQ","MZILT1T6HALS","MZILT1T9HAJQ","MZILT3T2HMLA","MZILT3T8HALS")))
    }
    
    process {
        $IBM_DriveFirmwareResult = switch ($IBM_DriveCurrentFW) {
                                    {$_ -in $IBM_SASDriveFaultyFW} { 
                                        Write-Host "yes" -ForegroundColor Magenta
                                        $IBM_SASDriveFixFW | ForEach-Object {
                                           $IBM_LatestDriveFW = $_[0]
                                                    Write-Host $_[1]
                                                    switch ($_[1]) {
                                                        {$IBM_DriveProdID -in $_} {  
                                                            Write-Host $_ $IBM_LatestDriveFW -ForegroundColor Green
                                                            $IBM_LatestDriveFW
                                                            break }
                                                        Default {}
                                                    }
                                                
                                            }
                                    }
                                    {$_ -in $IBM_NVMeDriveFaultyFW} { 
                                        Write-Host "yes" -ForegroundColor Magenta
                                        $IBM_NVMeDriveFixFW | ForEach-Object {
                                           $IBM_LatestDriveFW = $_[0]
                                                    Write-Host $_[1]
                                                    switch ($_[1]) {
                                                        {$IBM_DriveProdID -in $_} {  
                                                            Write-Host $_ $IBM_LatestDriveFW -ForegroundColor Green; 
                                                            $IBM_LatestDriveFW
                                                            break }
                                                        Default {}
                                                    }
                                                
                                            }
                                    }
                                    {$_ -in $IBM_FCMDriveFaultyFW} { 
                                        Write-Host "yes" -ForegroundColor Magenta
                                        $IBM_FCMDriveFixFW | ForEach-Object {
                                           $IBM_LatestDriveFW = $_[0]
                                                    Write-Host $_[1]
                                                    switch ($_[1]) {
                                                        {$IBM_DriveProdID -in $_} {  
                                                            Write-Host $_ $IBM_LatestDriveFW -ForegroundColor Green; 
                                                            $IBM_LatestDriveFW
                                                            break }
                                                        Default {}
                                                    }
                                                
                                            }
                                    }
                                    Default {
                                        Write-Host "all fine" -ForegroundColor Green
                                        $IBM_AllotherDrives = Get-Content -Path D:\GitRepo\Storage_SAN_Kit\Resources\IBM_FW_DRIVES241024.txt }
                                }
    }
    
    end {
        <# nothing to do here #>
        return $IBM_DriveFirmwareResult
    }
}
