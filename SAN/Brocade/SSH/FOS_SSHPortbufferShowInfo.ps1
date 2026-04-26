
function FOS_SSHPortbufferShowInfo {
    <#
    .SYNOPSIS
    Displays the buffer usage information for a port group or for all port groups in the switch.

    .DESCRIPTION
    Use this command to display the current long distance buffer information for the ports in a port group. 
    The port group can be specified by giving any port number in that group. If no port is specified, 
    then the long distance buffer information for all of the port groups of the switch is displayed.    

    .EXAMPLE
    Get_PortbufferShowInfo -FOS_MainInformation $PortBufferShowOutPut

    $PortBufferShowOutPut means the content of the cli outcome from "portbuffershow"
            
    .LINK
    Brocade® Fabric OS® Command Reference Manual, 9.2.x
    https://techdocs.broadcom.com/us/en/fibre-channel-networking/fabric-os/fabric-os-commands/9-2-x/Fabric-OS-Commands/portBufferShow.html
    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        [string]$TD_RefreshView
    )

    begin{
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        Write-Debug -Message "Start Func Get_PortbufferShowInfo |$(Get-Date)` "

        <# int for the progressbar #>
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar

        if($TD_Device_ConnectionTyp -eq "ssh"){
            Write-Debug -Message "ssh |$(Get-Date)"
            $FOS_MainInformation = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP "portbuffershow"
        }else {
            Write-Debug -Message "plink |$(Get-Date)"
            $FOS_MainInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "portbuffershow"
        }
        
        $SANSwitchIdent = FOS_SSHSwitchIdent -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
        
        <# Create an array #>
        $FOS_InfoCount = $FOS_MainInformation.count
        0..$FOS_InfoCount |ForEach-Object {
            # Pull only the effective ZoneCFG back into ZoneList
            if($FOS_MainInformation[$_] -match 'Buffers$'){
                $FOS_pbs_temp = $FOS_MainInformation |Select-Object -Skip $_
                $FOS_Temp_var = $FOS_pbs_temp |Select-Object -Skip 2
            
            }
        }
        $SwitchShowRowID = "$($SANSwitchIdent.SwitchWWNN)|$($TD_Line_ID)"
    }

    process{
        $FOS_pbs= foreach ($FOS_thisLine in $FOS_Temp_var) {
            # Skip empty or invalid lines
            if ([string]::IsNullOrWhiteSpace($FOS_thisLine)) { continue }
            # Process only lines that begin with a port number
            if ($FOS_thisLine -notmatch '^\s+\d+') { continue }

            $FOS_PortBuff = "" | Select-Object Port,Type,Mode,Max_Resv,Tx,Rx,Usage,Buffers,Distance,Buffer,SwitchWWNN,SerialNumber,RowID
            $FOS_PortBuff.RowID = $SwitchShowRowID
            $m = $FOS_thisLine | Select-String -Pattern '^\s+(\d+)'
            if ($m) {$FOS_PortBuff.Port = $m.Matches[0].Groups[1].Value}else {continue}
            $m = $FOS_thisLine | Select-String -Pattern '\b([EFGLU])\b'
            if ($m) {$FOS_PortBuff.Type = $m.Matches[0].Groups[1].Value}
            $m = $FOS_thisLine | Select-String -Pattern '\b(LE|LD|L0|LS)\b'
            if ($m) {$FOS_PortBuff.LX_Mode = $m.Matches[0].Groups[1].Value}
            $m = $FOS_thisLine | Select-String -Pattern '(\d+)\s+(\d+\(|-\s\()'
            if ($m) {$FOS_PortBuff.Max_Resv = $m.Matches[0].Groups[1].Value}
            $matchesTxRx = ($FOS_thisLine | Select-String -Pattern '(\d+\(\d+\)|\d\(\s\d+\)|-\s\(\s\d+\)|-\s\(\s+\d+\)|-\s\(\d+\)|-\s\(\s+-\s+\))' -AllMatches).Matches
            if ($matchesTxRx.Count -gt 0) {$FOS_PortBuff.Tx = $matchesTxRx[0].Groups[1].Value}
            if ($matchesTxRx.Count -gt 1) {$FOS_PortBuff.Rx = $matchesTxRx[1].Groups[1].Value}
            $m = $FOS_thisLine | Select-String -Pattern '\)\s+(\d+)\s+'
            if ($m) {$FOS_PortBuff.Usage = $m.Matches[0].Groups[1].Value}
            $m = $FOS_thisLine | Select-String -Pattern '\)\s+(\d+)\s+(\d+|-)'
            if ($m) {$FOS_PortBuff.Buffers = $m.Matches[0].Groups[2].Value}
            $m = $FOS_thisLine | Select-String -Pattern '\d\s+(\d+|-)\s+(\d+km|\<\d+km|-)'
            if ($m) {$FOS_PortBuff.Distance = $m.Matches[0].Groups[2].Value}
            $m = $FOS_thisLine | Select-String -Pattern '\s+(\d+)$'
            if ($m) {$FOS_PortBuff.Buffer = $m.Matches[0].Groups[1].Value}

            $FOS_PortBuff.SwitchWWNN = $SANSwitchIdent.SwitchWWNN
            $FOS_PortBuff.SerialNumber = $SANSwitchIdent.SerialNumber

            # Print only if at least one port is available
            if ($FOS_PortBuff.Port) {$FOS_PortBuff}

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$FOS_Temp_var.Count) * 100)
        }
    }

    end {

        Close-ProgressBar -ProgressBar $ProgressBar

        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $FOS_pbs | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                #SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $FOS_pbs | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                #SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_pbs
        }

        return $FOS_pbs
        
    }
}