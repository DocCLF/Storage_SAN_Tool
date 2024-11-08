function IBM_DriveFirmwareCheck {
    #https://www.ibm.com/support/pages/node/6508601
    [CmdletBinding()]
    param (
        $IBM_DriveProdID,
        $IBM_DriveCurrentFW,
        [array]$IBM_DriveAffectedProdID,
        [array]$IBM_DriveFaultyFW,
        [array]$IBM_DriveFixFW
    )
    
    begin {
        <# nothing to do here #>
        $IBM_DriveAffectedProdID = "MZILT200HAHQ","MZILT400HAHQ","MZILT800HAHQ","MZILT800HAJQ","MZILT1T6HALS","MZILT1T9HAJQ","MZILT3T2HMLA","MZILT3T8HALS"
        $IBM_DriveFaultyFW = "MS63","MS64","MS68","MS69","MS66","MS66","MS33","MS34","MS35","MS36","MS38","MS39","MS3B"
        $IBM_DriveFixFW = "MS6C","MS3E"
    }
    
    process {
        switch ($x) {
            condition {  }
            Default {}
        }
    }
    
    end {
        <# nothing to do here #>
    }
}