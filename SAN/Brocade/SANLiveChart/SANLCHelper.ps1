function ConvertFrom-SANSQLiteDateTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    # Remove possible leading/trailing whitespace from SQLite TEXT values.
    $Value = $Value.Trim()

    $SupportedFormats = @(
        'yyyy-MM-dd HH:mm:ss'
        'yyyy-MM-dd HH:mm'
    )

    foreach ($Format in $SupportedFormats) {

        $ParsedDateTime =
            [datetime]::MinValue

        $Success =
            [datetime]::TryParseExact(
                $Value,
                [string]$Format,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::None,
                [ref]$ParsedDateTime
            )

        if ($Success) {
            return $ParsedDateTime
        }
    }

    throw (
        "SQLite DateTime value '$Value' could not be parsed. " +
        "Supported formats: $($SupportedFormats -join ', ')."
    )
}

function ConvertTo-DBNull {
    param($Value)

    if ($null -eq $Value) {
        return [DBNull]::Value
    }

    return $Value
}