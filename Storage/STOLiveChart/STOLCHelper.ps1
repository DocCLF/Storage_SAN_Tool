function ConvertFrom-ByteValue {
    <#
    .SYNOPSIS
        Converts a byte value into a selected capacity unit.

    .PARAMETER Value
        Numeric byte value.

    .PARAMETER Unit
        Target unit.

    .OUTPUTS
        System.Double
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Int64]$Value,

        [Parameter(Mandatory)]
        [ValidateSet(
            'KB',
            'MB',
            'GB',
            'TB',
            'PB'
        )]
        [string]$Unit
    )

    $Divisor = switch ($Unit) {
        'KB' { [double]1KB }
        'MB' { [double]1MB }
        'GB' { [double]1GB }
        'TB' { [double]1TB }
        'PB' { [double]1PB }
    }

    return (
        [double]$Value /
        $Divisor
    )
}