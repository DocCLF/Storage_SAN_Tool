function SST_CreateCheckBox {
    [CmdletBinding()]
    param (
        $SST_UCOBJ
    )
    
    begin {

    }
    
    process {
        try {
            $SST_DummyCB = New-Object Windows.Controls.CheckBox
            $SST_DummyCB.Style = $SST_UCOBJ.TryFindResource("MainCheckBoxStyle")
            $SST_DummyCB.Name = "test1" <# der Name sollte entweder aus der ID +UN oder ähnlichen bestehen oder IP-Addr nutzen #>
            $SST_DummyCB.Content = $SST_UCOBJ.name  <# der Name sollte entweder aus dem DeviceNamen oder ähnlichen bestehen oder IP-Addr nutzen #>
        }
        catch {
            #SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes       
        }
    }
    
    end {
        #SST_ToolMessageCollector -TD_ToolMSGCollector "End to create Button for $DeviceTyp Healthcheck" -TD_ToolMSGType Message -TD_Shown no
        return $SST_DummyCB
    }
}