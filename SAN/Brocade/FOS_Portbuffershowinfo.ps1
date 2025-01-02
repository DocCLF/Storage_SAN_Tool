
function FOS_PortbufferShowInfo {
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
        <# next line one for testing #>
        #$FOS_MainInformation=Get-Content -Path "C:\Users\mailt\Documents\pbs_s.txt"
        #Out-File -FilePath $Env:TEMP\$($TD_Line_ID)_PortBufferShow_Temp.txt -InputObject $FOS_MainInformation

        <# Create an array #>
        
        $FOS_InfoCount = $FOS_MainInformation.count
        0..$FOS_InfoCount |ForEach-Object {
            # Pull only the effective ZoneCFG back into ZoneList
            if($FOS_MainInformation[$_] -match 'Buffers$'){
                $FOS_pbs_temp = $FOS_MainInformation |Select-Object -Skip $_
                $FOS_Temp_var = $FOS_pbs_temp |Select-Object -Skip 2
            
            }
        }
    }

    process{
        $FOS_pbs= foreach ($FOS_thisLine in $FOS_Temp_var) {
            <# Only collect data up to the next section, marked by Defined #>
            if($FOS_thisLine -match '^Defined'){break}

            #create a var and pipe some objects in and fill them with some data
            $FOS_PortBuff = "" | Select-Object Port,Type,Mode,Max_Resv,Tx,Rx,Usage,Buffers,Distance,Buffer
            # Index number of the port.
            $FOS_PortBuff.Port = ($FOS_thisLine |Select-String -Pattern '^\s+(\d+)' -AllMatches).Matches.Groups.Value[1]
            # E (E_Port), F (F_Port), G (G_Port), L (L_Port), or U (U_Port).
            $FOS_PortBuff.Type = ($FOS_thisLine |Select-String -Pattern '([EFGLU])' -AllMatches).Matches.Groups.Value[1]
            # Long distance mode. L0 -> Link is not in long distance mode. LE -> Link is up to 10 km. LD -> Distance is determined dynamically. LS -> Distance is determined statically by user input.
            $FOS_PortBuff.LX_Mode = ($FOS_thisLine |Select-String -Pattern '(LE|LD|L0|LS)' -AllMatches).Matches.Groups.Value[1]
            # The maximum or reserved number of buffers that are allocated to the port based on the estimated distance.
            $FOS_PortBuff.Max_Resv = ($FOS_thisLine |Select-String -Pattern '(\d+)\s+(\d+\(|-\s\()' -AllMatches).Matches.Groups.Value[1]
            # The average buffer usage and average frame size for Tx and Rx.
            $FOS_PortBuff.Tx = ($FOS_thisLine |Select-String -Pattern '(\d+\(\d+\)|\d\(\s\d+\)|-\s\(\s\d+\)|-\s\(\s+\d+\)|-\s\(\d+\)|-\s\(\s+-\s+\))' -AllMatches).Matches.Groups.Value[1]
            $FOS_PortBuff.Rx = ($FOS_thisLine |Select-String -Pattern '(\d+\(\d+\)|\d\(\s\d+\)|-\s\(\s\d+\)|-\s\(\s+\d+\)|-\s\(\d+\)|-\s\(\s+-\s+\))' -AllMatches).Matches.Value[1]
            # The actual number of buffers allocated to the port.
            $FOS_PortBuff.Usage = ($FOS_thisLine |Select-String -Pattern '\)\s+(\d+)\s+' -AllMatches).Matches.Groups.Value[1]
            # The number of buffers needed to utilize the port at full bandwidth (depending on the port configuration).
            $FOS_PortBuff.Buffers = ($FOS_thisLine |Select-String -Pattern '\)\s+(\d+)\s+(\d+|-)' -AllMatches).Matches.Groups.Value[2]
            <# For L0 (not in long distance mode), the command displays the fixed distance based on port speed, for instance: 10 km (1G), 5 km (2G), 2 km (4G), 1 km (8G), or upto 150 meters for all other port speed. 
            For static long distance mode (LE), the fixed distance of 10 km displays. For LD mode, the distance in kilometers displays as measured by timing the return trip of a MARK primitive that is sent and then echoed back to the switch. 
            LD mode supports distances up to 500 km. Distance measurement on a link longer than 500 km might not be accurate. If the connecting port does not support LD mode, is shows "N/A". #>
            $FOS_PortBuff.Distance = ($FOS_thisLine |Select-String -Pattern '\d\s+(\d+|-)\s+(\d+km|\<\d+km|-)' -AllMatches).Matches.Groups.Value[2]
            # The remaining (unallocated) buffers available for allocation in this group.
            $FOS_PortBuff.Buffer = ($FOS_thisLine |Select-String -Pattern '\s+(\d+)$' -AllMatches).Matches.Groups.Value[1]
            
            <# add the values to the array #>
            $FOS_PortBuff

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$FOS_Temp_var.Count) * 100)
        }
    }

    end {

        if($TD_Line_ID -eq 1){$TD_LB_PortBufferShowOne.Visibility = "Visible";     $TD_LB_PortBufferShowOne.Content = "$TD_Device_DeviceName" }
        if($TD_Line_ID -eq 2){$TD_LB_PortBufferShowTwo.Visibility = "Visible";     $TD_LB_PortBufferShowTwo.Content = "$TD_Device_DeviceName" }
        if($TD_Line_ID -eq 3){$TD_LB_PortBufferShowThree.Visibility = "Visible";   $TD_LB_PortBufferShowThree.Content = "$TD_Device_DeviceName" }
        if($TD_Line_ID -eq 4){$TD_LB_PortBufferShowFour.Visibility = "Visible";    $TD_LB_PortBufferShowFour.Content = "$TD_Device_DeviceName" }
        if($TD_Line_ID -eq 5){$TD_LB_PortBufferShowFive.Visibility = "Visible";    $TD_LB_PortBufferShowFive.Content = "$TD_Device_DeviceName" }
        if($TD_Line_ID -eq 6){$TD_LB_PortBufferShowSix.Visibility = "Visible";     $TD_LB_PortBufferShowSix.Content = "$TD_Device_DeviceName" }
        if($TD_Line_ID -eq 7){$TD_LB_PortBufferShowSeven.Visibility = "Visible";   $TD_LB_PortBufferShowSeven.Content = "$TD_Device_DeviceName" }
        if($TD_Line_ID -eq 8){$TD_LB_PortBufferShowEight.Visibility = "Visible";   $TD_LB_PortBufferShowEight.Content = "$TD_Device_DeviceName" }

        Close-ProgressBar -ProgressBar $ProgressBar

        <# export y or n #>
        if($TD_Export -eq "yes"){
            <# exported to .\Host_Volume_Map_Result.csv #>
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $FOS_pbs | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $FOS_pbs | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_PortBufferShow_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $FOS_pbs
        }

        return $FOS_pbs
        
    }
}