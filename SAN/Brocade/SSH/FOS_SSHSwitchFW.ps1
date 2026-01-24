function FOS_SSHSwitchFW {
    [CmdletBinding()]
    param (
        $SwitchData,
        $i=0,
        $z=0
    )
    
    begin {
        $SwitchCurrFOS = (($SwitchData| Select-String -Pattern 'FOS\s+([v?][\d+]\.[\d+]\.[\d].*)$').Matches.Groups[1].Value)
        <# Testphase, will come later with 1.4.x #>
        #$FOSVersionen = @("922","922a","922b","922c")
        #foreach($FOSVersion in $FOSVersionen){
        #    $i++
        #    if(($FOSVersion -eq "922") -or ($i -le $z)){
        #        $z = $i
        #        $i = 0
        #    }
        #    #$fos = Invoke-WebRequest -Uri "https://docs.broadcom.com/doc/FOS-$FOSVersion-RN"
        #    #if($Error.Count -lt 1){
        #    #    Write-Host $fos.StatusCode -ForegroundColor Yellow
        #    #    Write-Host $FOSVersion
        #    #}else {
        #    #    $Error.Clear()
        #    #}
        #    #Start-Sleep -Seconds 1
        #}
    }
    
    process {
        switch ($SwitchCurrFOS) {
            {$_ -like "v10.0.*"}  { $FOS_Sw = "GA September 22, 2025" }
            {$_ -like "v9.2.*"}  { $FOS_Sw = "latest version 9.2.2b" }
            {$_ -like "v9.1.*"}  { $FOS_Sw = "EOS Dez 30, 2025, latest version 9.1.1d7" }
            {$_ -like "v9.0.*"}  { $FOS_Sw = "EOS Apr 30, 2025, latest version 9.0.x" }
            {$_ -like "v8.2.*"}  { $FOS_Sw = "EOS Jul 28, 2023, latest version 8.2.3e2" }
            {$_ -like "v8.1.*"}  { $FOS_Sw = "EOS Mar 15, 2022, latest version 8.1.x" }
            {$_ -like "v8.0.*"}  { $FOS_Sw = "EOS Jul 30, 2020, latest version 8.0.x" }
            {$_ -like "v7.4.*"}  { $FOS_Sw = "EOS Nov 14, 2019, latest version 7.4.2x" }
            Default {$FOS_Sw = "latest version 9.2.2x"}
        }
    }
    
    end {
        return $FOS_Sw
    }
}