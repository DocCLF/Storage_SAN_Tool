function SST_RESTTokenValidation {
    [CmdletBinding()]
    param (
        [string]$RESTFileName,
        [string]$TD_Device_ConnectionTyp,
        [bool]$NoToken
    )
    
    begin {
        
    }
    
    process {
        try {
            $CredImportXML = Import-Clixml -Path "$PSScriptRoot\ToolLog\ToolTEMP\$RESTFileName.xml"
            $TimeBegin = $null
            Get-ChildItem -Path "$PSScriptRoot\ToolLog\ToolTEMP\$RESTFileName.xml" -Recurse | Where-Object { $TimeBegin = $_.CreationTime}
            $ExpireTime = $TimeBegin.AddMinutes($CredImportXML.Expires)
            $Remaining  = $ExpireTime - (Get-Date)
        }
        catch {
            $NoToken = $false
        }

        if (($Remaining.TotalSeconds -le 10) -or (!($NoToken))) {
            Remove-Item -Path "$PSScriptRoot\ToolLog\ToolTEMP\$RESTFileName.xml" -Confirm:$false -Force
            $TD_Device_ConnectionTyp = $null
        }else {
            $TD_Device_ConnectionTyp = "REST"
        }
    }
    
    end {
        return $TD_Device_ConnectionTyp
    }
}