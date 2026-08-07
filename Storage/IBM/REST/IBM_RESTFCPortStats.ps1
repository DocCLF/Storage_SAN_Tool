function IBM_RESTFCPortStats {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        #[string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        $body = @{} <# This is the only part you are allowed to change. #>
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        $BaseUrl = "https://$TD_Device_DeviceIP"+":7443"
        if(Test-Path -Path "$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db"){
            $RESTInfo = SST_RESTDBControl -SST_InfoType "UseStorageToken" -SST_BaseUrl $BaseUrl
            if(([string]::IsNullOrEmpty($RESTInfo)) -and ($TD_Device_ConnectionTyp -eq "REST")){
                SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            }
        }
        if([string]::IsNullOrWhiteSpace($TD_Device_ConnectionTyp)){
            $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW 
        }
        Clear-Variable -Name TD_Device_PW -Force
        if($TD_Device_ConnectionTyp -eq "REST"){
            #$TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsportstats -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
    }

    process{
        [int]$imax = $STONodeInfo.Count
        [array]$TD_PortStats_Overview = for ($i = 0; $i -lt $imax; $i++) {
            <# Max requests/sec to command endpoints = 10 -.- #>
            if ($i % 8 -eq 0) { Start-Sleep -Milliseconds 1500 }
            $NodeID = $STONodeInfo.id[$i]
            $body = @{node = "$($NodeID)"}
            $IBMSTOName = $STONodeInfo.name[$i]
            $IBMSTOWWNN = $STONodeInfo.WWNN[$i]
            $IBMSTOSN = if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}

            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsportstats -Body $body -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            
            [int]$iNodemax = $TD_DeviceInformation.Count 
            for ($ndr = 0; $ndr -lt $iNodemax; $ndr++) {
                if($($TD_DeviceInformation.type[$ndr]) -ne "FC"){continue}
                $TD_PortStatsSplitInfos = "" | Select-Object RowID,NodeID,SerialNumber,NodeName,WWNN,CardType,CardID,PortID,WWPN,LinkFailure,LoseSync,LoseSig,PSErrCount,InvTransErr,CRCErr,ZeroBtB,SFPTemp,TXPwr,TXPwrlow,RXPwr,RXPwrlow
                #Write-Host  $IBMSTOName $NodeID -ForegroundColor Yellow                   
                $TD_PortStatsSplitInfos.CardType    = $TD_DeviceInformation.type[$ndr]
                $TD_PortStatsSplitInfos.CardID      = $TD_DeviceInformation.type_id[$ndr]
                $TD_PortStatsSplitInfos.PortID      = $TD_DeviceInformation.'port id'[$ndr]
                $TD_PortStatsSplitInfos.WWPN        = $TD_DeviceInformation.fc_wwpn[$ndr] -replace '0x',''
                $TD_PortStatsSplitInfos.LinkFailure = $TD_DeviceInformation.lf[$ndr]
                $TD_PortStatsSplitInfos.LoseSync    = $TD_DeviceInformation.lsy[$ndr]
                $TD_PortStatsSplitInfos.LoseSig     = $TD_DeviceInformation.lsi[$ndr]
                $TD_PortStatsSplitInfos.PSErrCount  = $TD_DeviceInformation.pspe[$ndr]
                $TD_PortStatsSplitInfos.InvTransErr = $TD_DeviceInformation.itw[$ndr]
                $TD_PortStatsSplitInfos.CRCErr      = $TD_DeviceInformation.icrc[$ndr]
                $TD_PortStatsSplitInfos.ZeroBtB     = $TD_DeviceInformation.bbcz[$ndr]
                $TD_PortStatsSplitInfos.SFPTemp     = $TD_DeviceInformation.tmp[$ndr]
                $TD_PortStatsSplitInfos.TXPwr       = $TD_DeviceInformation.txpwr[$ndr]
                $TD_PortStatsSplitInfos.TXPwrLow    = $TD_DeviceInformation.txpwrlt[$ndr]
                $TD_PortStatsSplitInfos.RXPwr       = $TD_DeviceInformation.rxpwr[$ndr]
                $TD_PortStatsSplitInfos.RXPwrLow    = $TD_DeviceInformation.rxpwrlt[$ndr]

                $TD_PortStatsSplitInfos.NodeID          = $NodeID
                $TD_PortStatsSplitInfos.NodeName        = $IBMSTOName
                $TD_PortStatsSplitInfos.WWNN            = $IBMSTOWWNN
                $TD_PortStatsSplitInfos.SerialNumber    = $IBMSTOSN
                $TD_PortStatsSplitInfos.RowID           = "$IBMSTOSN|$IBMSTOWWNN|$($TD_PortStatsSplitInfos.WWPN)"
                $TD_PortStatsSplitInfos

                <# Progressbar  #>
                $ProgCounter++
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($IBMSTOSN)" -PercentComplete (($ProgCounter/$imax) * 100)
            }
        }
    }

    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        SST_CustomerSTODBInsertTable -SST_InfoType "FCPortStats" -SST_CollectedInformations $TD_PortStats_Overview
        <# export y or n #>
        if($TD_export -eq "yes"){

            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_PortStats_Overview | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_PortStats_Overview | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_FCPortStatsOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_PortStats_Overview
        }
        return $TD_PortStats_Overview
    }
}
