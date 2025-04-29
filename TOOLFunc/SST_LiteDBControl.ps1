function SST_LiteDBControl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("Drive","StorageBase")]
        $SST_InfoType,
        $SST_NewDBObject =$null,
        [array]$SST_CollectedInformations
    )
    
    begin {
        
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        try {
            $SST_LocalDB = [LiteDB.LiteDatabase]::new("Filename= $PSRootPath\Resources\DBFolder\SSTLocalDB.db")
            $SST_IBMDriveTable = $SST_LocalDB.GetCollection("IBMDriveTable")
            $SST_IBMSTOHWTable = $SST_LocalDB.GetCollection("IBMSTOHWTable")
            SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB is ready and loaded" -TD_ToolMSGType Message -TD_Shown no
        }
        catch {
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "$($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
        }
        #$SST_CreationTime = Get-Date -UFormat "%Y%m%d %T"
    }
    
    process {
        # Objekt zum Einfügen
        switch ($SST_InfoType) {
            "Drive" { 
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_NewDBObject = [LiteDB.BsonDocument]::new()
                    $SST_NewDBObject["DriveID"] = $SST_CollectedInformation.DriveID
                    $SST_NewDBObject["Slot"] = $SST_CollectedInformation.Slot
                    $SST_NewDBObject["ProductID"] = $SST_CollectedInformation.ProductID
                    $SST_NewDBObject["DriveStatus"] = $SST_CollectedInformation.DriveStatus
                    $SST_NewDBObject["FWlev"] = $SST_CollectedInformation.FWlev
                    $SST_NewDBObject["DriveCap"] = $SST_CollectedInformation.DriveCap
                    $SST_NewDBObject["PhyDriveCap"] = $SST_CollectedInformation.PhyDriveCap
                    $SST_NewDBObject["PhyUsedDriveCap"] = $SST_CollectedInformation.PhyUsedDriveCap
                    $SST_NewDBObject["EffeUsedDriveCap"] = $SST_CollectedInformation.EffeUsedDriveCap
                    $SST_NewDBObject["DeviceSN"] = $SST_CollectedInformation.DeviceSN
                    $SST_NewDBObject["DeviceWWNN"] = $SST_CollectedInformation.DeviceWWNN
                    # In DB speichern 
                    $SST_IBMDriveTable.Insert($SST_NewDBObject)
                }
             }
            "StorageBase" { 
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_NewDBObject = [LiteDB.BsonDocument]::new()
                    $SST_NewDBObject["ID"] = $SST_CollectedInformation.ID
                    $SST_NewDBObject["Name"] = $SST_CollectedInformation.Name
                    $SST_NewDBObject["WWNN"] = $SST_CollectedInformation.WWNN
                    $SST_NewDBObject["Status"] = $SST_CollectedInformation.Status
                    $SST_NewDBObject["IO_group_id"] = $SST_CollectedInformation.IO_group_id
                    $SST_NewDBObject["IO_group_Name"] = $SST_CollectedInformation.IO_group_Name
                    $SST_NewDBObject["Serial_Number"] = $SST_CollectedInformation.Serial_Number
                    $SST_NewDBObject["Code_Level"] = $SST_CollectedInformation.Code_Level
                    $SST_NewDBObject["Config_Node"] = $SST_CollectedInformation.Config_Node
                    $SST_NewDBObject["SideID"] = $SST_CollectedInformation.SideID
                    $SST_NewDBObject["SideName"] = $SST_CollectedInformation.SideName
                    $SST_NewDBObject["Prod_MTM"] = $SST_CollectedInformation.Prod_MTM
                    # In DB speichern 
                    $SST_IBMSTOHWTable.Insert($SST_NewDBObject)
                }
             }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong during saving the $SST_InfoType data in the local db." -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {
        #Verbindung schließen
        $SST_CollectedInformations =$null
        $SST_LocalDB.Dispose()
    }
}