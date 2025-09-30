function SST_PRISMDBControl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("StorageDrive","StorageBase","StorageHostInfo","StorageEventLog","SANBase","FCPortStats")]
        $SST_InfoType,
        $CustomerNumber =$null,
        [bool]$SQLSVRCon = $false,
        [array]$SST_CollectedInformations,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -UFormat "%Y-%m-%d %R"
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        $PSRootPath = Split-Path -Path $PSRootPath -Parent

        try{
            $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
            $SST_LoadedToolSettings = Import-Clixml -Path "$PSRootPath\Resources\SavedToolSettings.clixml"
            $ConnectionStringPRISM = [System.Net.NetworkCredential]::new("", $SST_LoadedToolSettings.ConnectionStringPRISM).Password
            if($SST_LoadedToolSettings.CustomerNumber -like $TD_TB_CustomerNumberPRISM.Text){
                $SQLConnection.ConnectionString=$ConnectionStringPRISM
                while (!($SQLSVRCon)) {
                    if($SQLConnection.State -eq "open"){
                        $SQLSVRCon =$true
                        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_PRISMDBControl Func State $($SQLConnection.State)" -TD_ToolMSGType Message -TD_Shown yes
                    }else {
                        $SQLConnection.Open()
                        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_PRISMDBControl Func State $($SQLConnection.State)" -TD_ToolMSGType Message -TD_Shown no
                    }
                }
                $CustomerNumber = $SST_LoadedToolSettings.CustomerNumber
            }else {
                $CustomerNumber =$null
                $SST_LoadedToolSettings =$null
                $ConnectionStringPRISM =$null
                SST_ToolMessageCollector -TD_ToolMSGCollector "SST_PRISMDBControl Func there is a problem with the CustomerNumber" -TD_ToolMSGType Error -TD_Shown yes
            }
        }catch{
            Write-Host $_.exception.message
        }
    }
    
    process {
        try{
            $TD_SQLCommand = $SQLConnection.CreateCommand()
            Start-Sleep -Seconds 1
            #$TD_SQLCommand.CommandText="truncate table [PRISMDB].[dbo].[IBMStorageSoftware];" 
            #$Result=$TD_SQLCommand.ExecuteNonQuery()
            switch ($SST_InfoType) {
                "StorageBase" { 
                        $SST_CollectedInformations | ForEach-Object {
                            Start-Sleep -Seconds 0.5
                            $TD_SQLCommand.CommandText="INSERT INTO [dbo].[StorageBase] (STOName,STOClusterName,STOStatus,STOWWNN,STOProdMTM,STOSerialNumber,STOCodeLevel,STORecommendedPTF,STOIOgroupid,STOIOgroupName,STOConfigNode,STOSideID,STOSideName,STOMDiskTC,STOMDiskFC,STOMDiskUC,STOPhysicalTC,STOPhysicalFC,STOCustomerNumber,TimeStamp) VALUES ('$($_.Name)','$($_.ClusterName)','$($_.Status)','$($_.WWNN)','$($_.Prod_MTM)','$($_.Serial_Number)','$($_.Code_Level)','$($_.RecommendedPTF)','$($_.IO_group_id)','$($_.IO_group_Name)','$($_.ConfigNode)','$($_.SideID)','$($_.SideName)','$($_.'MDiskTotalCapacity')','$($_.'MDiskFreeCapacity')','$($_.'MDiskUsedCapacity')','$($_.'PhysicalTotalCapacity')','$($_.'PhysicalFreeCapacity')','$CustomerNumber','$TimeStamp');"
                            Write-Host $TD_SQLCommand.ExecuteNonQuery() 
                        }
                    }
                "StorageDrive" { 
                        $SST_CollectedInformations | ForEach-Object {
                            Start-Sleep -Seconds 0.5 
                            $TD_SQLCommand.CommandText="INSERT INTO [dbo].[StorageDrive] (DriveID,DriveSlot,DriveProductID,DriveStatus,DriveCurrentFW,DriveLatestFW,DriveCap,DrivePhyCap,DrivePhyUsedCap,DriveEffeUsedCap,STOSN,STOWWNN,STOCustomerNumber,TimeStamp) VALUES ('$($_.DriveID)','$($_.Slot)','$($_.ProductID)','$($_.DriveStatus)','$($_.FWlev)','$($_.LatestDriveFW)','$($_.DriveCap)','$($_.PhyDriveCap)','$($_.PhyUsedDriveCap)','$($_.EffeUsedDriveCap)','$($_.DeviceSN)','$($_.DeviceWWNN)','$CustomerNumber','$TimeStamp');"    
                            Write-Host $TD_SQLCommand.ExecuteNonQuery() 
                        }
                    }
                "SANBase" { 
                        $SST_CollectedInformations | ForEach-Object {
                            Start-Sleep -Seconds 0.5 
                            $TD_SQLCommand.CommandText="INSERT INTO [dbo].[SANBase] (SANName,SANStatus,SANCodeLevel,SANCodeLevelLV,SANBrocadeProdName,SANMTM,SANSerialNumber,SANCustomerNumber,TimeStamp) VALUES ('$($_.'Swicht Name')','$($_.'Switch State')','$($_.'Fabric OS')','$($_.'Fabric OSLV')','$($_.'Brocade Product Name')','$($_.'MTM')','$($_.'Serial Num')','$CustomerNumber','$TimeStamp');"    
                            Write-Host $TD_SQLCommand.ExecuteNonQuery() 
                        }
                    }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong during saving the $SST_InfoType data in the local db." -TD_ToolMSGType Error -TD_Shown yes}
            }
        }catch{
            Write-Host $_.exception.message
        }
    }
    
    end {
        $SQLConnection.Close()
    }
}