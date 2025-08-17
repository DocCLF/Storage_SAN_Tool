function FOS_SwitchFW {
    [CmdletBinding()]
    param (
        $SwitchData
    )
    
    begin {
        $SwitchCurrFOS = (($SwitchData| Select-String -Pattern 'FOS\s+([v?][\d]\.[\d+]\.[\d].*)$').Matches.Groups[1].Value)
    }
    
    process {
        switch ($SwitchCurrFOS) {
            {$_ -like "v10.0.*"}  { $FOS_Sw = "Not available" }
            {$_ -like "v9.3.*"}  { $FOS_Sw = "Not available" }
            {$_ -like "v9.2.*"}  { $FOS_Sw = "latest version 9.2.2x" }
            {$_ -like "v9.1.*"}  { $FOS_Sw = "EOS Dez 30, 2025, latest version 9.1.1dx" }
            {$_ -like "v9.0.*"}  { $FOS_Sw = "EOS Apr 30, 2025, latest version 9.0.x" }
            {$_ -like "v8.2.*"}  { $FOS_Sw = "EOS Jul 28, 2023, latest version 8.2.3ex" }
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