function Initialize-SANHealthCheckSteps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $DeviceIdent,

        [Parameter(Mandatory)]
        $Device
    )

    # Remove existing GUI lines.
    if ($null -ne $DeviceIdent.SANHealthCheckRows) {
        $DeviceIdent.SANHealthCheckRows.Clear()
    }

    # Definitions of the HealthCheck steps.
    #
    # GetNewClosure() ensures that each ScriptBlock
    # retains the currently passed $Device.
    $HealthCheckSteps = @(
        [PSCustomObject]@{
            Id      = 'SwitchInfo'
            Name    = 'Collect switch information'
            Command = 'Get-BrocadeSwitchInfo'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'ChassisInfo'
            Name    = 'Collect chassis information'
            Command = 'Get-BrocadeChassisInfo'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'LogicalSwitches'
            Name    = 'Collect logical switches'
            Command = 'Get-BrocadeLogicalSwitches'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'ManagementInterface'
            Name    = 'Collect management interfaces'
            Command = 'Get-BrocadeManagementIPInterface'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'FCPorts'
            Name    = 'Collect FC ports'
            Command = 'Get-BrocadeFcPorts'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'FCStatistics'
            Name    = 'Collect FC statistics'
            Command = 'Get-BrocadeFCstatistics'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'SFP'
            Name    = 'Collect SFP information'
            Command = 'Get-BrocadeSfp'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'NameServer'
            Name    = 'Collect name server information'
            Command = 'Get-BrocadeNameServer'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'EffectiveZone'
            Name    = 'Collect effective zoning'
            Command = 'Get-BrocadeEffectiveZoneConfig'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'DefinedZone'
            Name    = 'Collect defined zoning'
            Command = 'Get-BrocadeDefinedZoneConfig'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'Aliases'
            Name    = 'Collect aliases'
            Command = 'Get-BrocadeAliases'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'License'
            Name    = 'Collect license information'
            Command = 'Get-BrocadeLicenseInfo'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'Temperature'
            Name    = 'Collect temperature sensors'
            Command = 'Get-BrocadeTemperatureInfo'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'Fans'
            Name    = 'Collect fan information'
            Command = 'Get-BrocadeFanInfo'
            RequiresPrivilege = $false
        }

        [PSCustomObject]@{
            Id      = 'PowerSupplies'
            Name    = 'Collect power supply information'
            Command = 'Get-BrocadePowerSupplyInfo'
            RequiresPrivilege = $false
        }
        
        [PSCustomObject]@{
            Id      = 'PasswordPolicy'
            Name    = 'Collect password policy'
            Command = 'Get-BrocadePasswdcfg'
            RequiresPrivilege = $true
        }

        [PSCustomObject]@{
            Id      = 'IPFilter'
            Name    = 'Collect IP filter configuration'
            Command = 'Get-BrocadeIPfilter'
            RequiresPrivilege = $true
        }

        [PSCustomObject]@{
            Id      = 'UserConfiguration'
            Name    = 'Collect user configuration'
            Command = 'Get-BrocadeUsercfg'
            RequiresPrivilege = $true
        }

        [PSCustomObject]@{
            Id      = 'Security'
            Name    = 'Collect security information'
            Command = 'Get-BrocadeSecurity'
            RequiresPrivilege = $true
        }

        [PSCustomObject]@{
            Id      = 'FCDiagnostics'
            Name    = 'Collect FC diagnostics'
            Command = 'Get-BrocadeFCdiagnostics'
            RequiresPrivilege = $true
        }

    )

    # Create visible GUI lines.
    foreach ($HealthCheckStep in $HealthCheckSteps) {
        $Step = New-Object SANHealthCheckStep

        $Step.Id        = $HealthCheckStep.Id
        $Step.Name      = $HealthCheckStep.Name
        $Step.Status    = 'Pending'
        $Step.Details   = 'Waiting for execution.'
        $Step.DataCount = 0

        $DeviceIdent.SANHealthCheckRows.Add($Step)
    }

    # Return the definitions, not the GUI collection
    # including the executable command script blocks.
    return $HealthCheckSteps
}
function Set-SANHealthCheckStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $DeviceIdent,

        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Pending',
            'Running',
            'Completed',
            'NoData',
            'Error'
        )]
        [string]$Status,

        [string]$Details = '',

        [int]$DataCount = 0
    )

    if ($null -eq $DeviceIdent.SANHealthCheckRows) {
        Write-Warning 'SANHealthCheckRows is not initialized.'
        return
    }

    $Step = $DeviceIdent.SANHealthCheckRows |
        Where-Object {
            $_.Id -eq $Id
        } |
        Select-Object -First 1

    if ($null -eq $Step) {
        Write-Warning "SAN HealthCheck step '$Id' was not found."
        return
    }

    $Step.Status    = $Status
    $Step.Details   = $Details
    $Step.DataCount = $DataCount

    return $Step
}
function New-SANHealthCheckBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,

        [Parameter(Mandatory)]
        [System.Windows.Controls.UserControl]
        $UCOBJ
    )

    # ------------------------------------------------------------
    # 1. Retrieve the target WrapPanel from the existing UserControl
    # ------------------------------------------------------------
    $HealthResultsPanel = $UCOBJ.FindName('WP_HealthResaults')

    if ($null -eq $HealthResultsPanel) {
        throw "The WrapPanel 'WP_HealthResaults' was not found."
    }

    # ------------------------------------------------------------
    # 2. Generate a unique name for the GUI block
    # ------------------------------------------------------------
    $DeviceBlockName = "SANHealthBlock_$($Device.ID)"

    # Check whether a block already exists for this device.
    # If so, the existing DeviceIdent is returned.
    $ExistingBlock = $UCOBJ.FindName($DeviceBlockName)

    if ($null -ne $ExistingBlock) {
        return $ExistingBlock.DataContext
    }

    # ------------------------------------------------------------
    # 3. Create a data object for this switch
    # ------------------------------------------------------------
    $DeviceIdent = [DeviceToggle]::new()

    $DeviceIdent.Id    = "DeviceBlock$($Device.ID)"
    $DeviceIdent.Label = [string]$Device.IPAddress

    $DeviceIdent.DeviceTitle = if (
        [string]::IsNullOrWhiteSpace([string]$Device.DeviceName)
    ) {
        [string]$Device.IPAddress
    }
    else {
        [string]$Device.DeviceName
    }

    $DeviceIdent.IsChecked = $true

    $DeviceIdent.SANHealthCheckTitle =
        "SAN Health Overview for - $($DeviceIdent.DeviceTitle)"

    # IMPORTANT:
    # Initialize-SANHealthCheckSteps is no longer called here.
    #
    # Initialization takes place after this function returns:
    #
    # $HealthCheckSteps = Initialize-SANHealthCheckSteps -DeviceIdent $DeviceIdent -Device $Device

    # ------------------------------------------------------------
    # 4. Create a GUI control for the entire switch
    # ------------------------------------------------------------
    $DeviceBorder = New-Object System.Windows.Controls.Border

    $DeviceBorder.Name            = $DeviceBlockName
    $DeviceBorder.Margin          = '10'
    $DeviceBorder.Padding         = '10'
    $DeviceBorder.MinWidth        = 480
    $DeviceBorder.BorderThickness = '1'
    $DeviceBorder.BorderBrush     =
        [System.Windows.Media.Brushes]::Gray

    # Das DeviceIdent wird als DataContext für den gesamten Block gesetzt.
    $DeviceBorder.DataContext = $DeviceIdent

    $MainPanel = New-Object System.Windows.Controls.StackPanel

    # ------------------------------------------------------------
    # 5. Create a heading
    # ------------------------------------------------------------
    $Title = New-Object System.Windows.Controls.TextBlock

    $Title.FontSize   = 16
    $Title.FontWeight = 'Bold'
    $Title.Margin     = '5'

    $TitleBinding = New-Object System.Windows.Data.Binding
    $TitleBinding.Path = 'SANHealthCheckTitle'

    [System.Windows.Data.BindingOperations]::SetBinding(
        $Title,
        [System.Windows.Controls.TextBlock]::TextProperty,
        $TitleBinding
    ) | Out-Null

    $MainPanel.Children.Add($Title) | Out-Null

    # ------------------------------------------------------------
    # 6. Create an ItemsControl for the HealthCheck rows
    # ------------------------------------------------------------
    $HealthItems = New-Object System.Windows.Controls.ItemsControl

    $RowsBinding = New-Object System.Windows.Data.Binding
    $RowsBinding.Path = 'SANHealthCheckRows'

    [System.Windows.Data.BindingOperations]::SetBinding(
        $HealthItems,
        [System.Windows.Controls.ItemsControl]::ItemsSourceProperty,
        $RowsBinding
    ) | Out-Null

    # ------------------------------------------------------------
    # 7. Display of a single HealthCheck row
    # ------------------------------------------------------------
    $TemplateXaml = @'
<DataTemplate
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">

    <Grid Margin="5">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="25"/>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="100"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <Ellipse
            Grid.Column="0"
            Width="14"
            Height="14"
            VerticalAlignment="Center">

            <Ellipse.Style>
                <Style TargetType="Ellipse">
                    <Setter Property="Fill" Value="Gray"/>

                    <Style.Triggers>
                        <DataTrigger
                            Binding="{Binding Status}"
                            Value="Pending">

                            <Setter
                                Property="Fill"
                                Value="Gray"/>
                        </DataTrigger>

                        <DataTrigger
                            Binding="{Binding Status}"
                            Value="Running">

                            <Setter
                                Property="Fill"
                                Value="DodgerBlue"/>
                        </DataTrigger>

                        <DataTrigger
                            Binding="{Binding Status}"
                            Value="Completed">

                            <Setter
                                Property="Fill"
                                Value="Green"/>
                        </DataTrigger>

                        <DataTrigger
                            Binding="{Binding Status}"
                            Value="NoData">

                            <Setter
                                Property="Fill"
                                Value="Orange"/>
                        </DataTrigger>

                        <DataTrigger
                            Binding="{Binding Status}"
                            Value="Error">

                            <Setter
                                Property="Fill"
                                Value="Red"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </Ellipse.Style>
        </Ellipse>

        <TextBlock
            Grid.Column="1"
            Text="{Binding Name}"
            VerticalAlignment="Center"
            Margin="5,0"/>

        <TextBlock
            Grid.Column="2"
            Text="{Binding Status}"
            VerticalAlignment="Center"
            Margin="5,0"
            FontWeight="SemiBold"/>

        <TextBlock
            Grid.Column="3"
            Text="{Binding Details}"
            VerticalAlignment="Center"
            Margin="5,0"
            TextWrapping="Wrap"/>
    </Grid>
</DataTemplate>
'@

    $StringReader = [System.IO.StringReader]::new($TemplateXaml)
    $XmlReader    = [System.Xml.XmlReader]::Create($StringReader)

    try {
        $HealthItems.ItemTemplate =
            [System.Windows.Markup.XamlReader]::Load($XmlReader)
    }
    finally {
        $XmlReader.Dispose()
        $StringReader.Dispose()
    }

    $MainPanel.Children.Add($HealthItems) | Out-Null

    $DeviceBorder.Child = $MainPanel

    # ------------------------------------------------------------
    # 8. Register the control and add it to the WrapPanel
    # ------------------------------------------------------------
    $UCOBJ.RegisterName(
        $DeviceBorder.Name,
        $DeviceBorder
    )

    $HealthResultsPanel.Children.Add(
        $DeviceBorder
    ) | Out-Null

    # Display the empty block and heading immediately.
    # The HealthCheck lines are added immediately afterward by
    # Initialize-SANHealthCheckSteps.
    $UCOBJ.Dispatcher.Invoke(
        [System.Action] {},
        [System.Windows.Threading.DispatcherPriority]::Render
    )

    return $DeviceIdent
}
function Invoke-SANHealthStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $DeviceIdent,

        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$CommandName,

        [Parameter(Mandatory)]
        $Device,

        [Parameter(Mandatory)]
        $UCOBJ,

        [PSCredential]$Credential
    )

    $Step = $DeviceIdent.SANHealthCheckRows |
        Where-Object { $_.Id -eq $Id } |
        Select-Object -First 1

    if ($null -eq $Step) {
        Write-Warning "SAN HealthCheck step '$Id' was not found."
        return
    }

    $StepName = [string]$Step.Name

    Set-SANHealthCheckStep -DeviceIdent $DeviceIdent -Id $Id -Status Running -Details "$StepName is running." -DataCount 0 | Out-Null

    try {
        $UCOBJ.Dispatcher.Invoke(
            [System.Action] {},
            [System.Windows.Threading.DispatcherPriority]::Render
        )
    }
    catch {
    }

    try {
        $Command = Get-Command -Name $CommandName -CommandType Function -ErrorAction Stop

        $InvokeParameters = @{
            Device = $Device
        }

        # Pass the credential only if it is available and is actually supported by the
        # target function.
        if ($null -ne $Credential -and $Command.Parameters.ContainsKey('Credential')) {
            $InvokeParameters.Credential = $Credential
        }

        $StepResult = & $Command @InvokeParameters

        $HasSuccessProperty =
            $null -ne $StepResult -and
            $null -ne $StepResult.PSObject.Properties['Success']

        if ($HasSuccessProperty -and -not [bool]$StepResult.Success) {
            $ErrorDetails = if ($StepResult.PSObject.Properties['Error'] -and -not [string]::IsNullOrWhiteSpace([string]$StepResult.Error)) {
                [string]$StepResult.Error
            }
            elseif ($StepResult.PSObject.Properties['StatusCode']) {
                "REST request failed with status code $($StepResult.StatusCode)."
            }
            else {
                'The REST request failed.'
            }

            Set-SANHealthCheckStep -DeviceIdent $DeviceIdent -Id $Id -Status Error -Details $ErrorDetails -DataCount 0 | Out-Null

            return $StepResult
        }

        $ValidItems = @(
            @($StepResult) |
                Where-Object { $null -ne $_ }
        )

        if ($ValidItems.Count -eq 0) {
            Set-SANHealthCheckStep -DeviceIdent $DeviceIdent -Id $Id -Status NoData -Details "No data returned for $StepName." -DataCount 0 | Out-Null

            return $StepResult
        }

        Set-SANHealthCheckStep -DeviceIdent $DeviceIdent -Id $Id -Status Completed -Details "$StepName completed." -DataCount $ValidItems.Count | Out-Null

        return $StepResult
    }
    catch {
        $ErrorDetails = $_.Exception.Message

        Set-SANHealthCheckStep -DeviceIdent $DeviceIdent -Id $Id -Status Error -Details $ErrorDetails -DataCount 0 | Out-Null

        SST_ToolMessageCollector -TD_ToolMSGCollector "SAN HealthCheck step '$Id' failed: $ErrorDetails" -TD_ToolMSGType Error -TD_Shown no

        return $null
    }
    finally {
        try {
            $UCOBJ.Dispatcher.Invoke(
                [System.Action] {},
                [System.Windows.Threading.DispatcherPriority]::Render
            )
        }
        catch {
        }
    }
}
function Test-BrocadePrivilegeError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Result
    )

    if ($null -eq $Result) {
        return $false
    }

    if (-not $Result.PSObject.Properties['Success'] -or [bool]$Result.Success) {
        return $false
    }

    if ($Result.PSObject.Properties['StatusCode'] -and $Result.StatusCode -in @(400, 401, 403)) {
        return $true
    }

    $ErrorText = [string]$Result.Error

    return (
        $ErrorText -match '\((400|401|403)\)' -or
        $ErrorText -match 'status code.*\b(400|401|403)\b' -or
        $ErrorText -match 'unauthorized|forbidden|permission|not permitted'
    )
}