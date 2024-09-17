function TD_ValueConverter {
    param (
        [Int16]$TD_InputNumber,
        [Int16]$TD_CompareNumber,
        [bool]$TD_OutputColor
    )
    if($TD_InputNumber -gt $TD_CompareNumber){
        $TD_OutputColor = $true

    }else {
        $TD_OutputColor = $false
    }

    $TD_OutputColor
}