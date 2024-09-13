Function New-ProgressBar {

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    $syncHash = [hashtable]::Synchronized(@{})
    $newRunspace =[runspacefactory]::CreateRunspace()
    $syncHash.Runspace = $newRunspace
    $newRunspace.ApartmentState = "STA"
    $newRunspace.ThreadOptions = "ReuseThread"
    $newRunspace.Open()
    $newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    $PowerShellCommand = [PowerShell]::Create().AddScript({
        [xml]$xaml = @"
        <Window
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Name="Window" Title="Progress..." WindowStartupLocation = "CenterScreen"
            Width = "400" Height = "120" ShowInTaskbar = "True" >
            <StackPanel Margin="20" >
               <ProgressBar Name="ProgressBar" Width="300" Height="20" Margin="0,5,0,5"/> 
               <TextBlock FontSize="12" Text="{Binding ElementName=ProgressBar, Path=Value, StringFormat={}{0:0}%}" HorizontalAlignment="Center" VerticalAlignment="Center" />
            </StackPanel>
        </Window>
"@

        $reader=(New-Object System.Xml.XmlNodeReader $xaml)
        $syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
        #===========================================================================
        # Store Form Objects In PowerShell
        #===========================================================================
        $xaml.SelectNodes("//*[@Name]") | %{ $SyncHash."$($_.Name)" = $SyncHash.Window.FindName($_.Name)}


        $syncHash.Window.ShowDialog() | Out-Null
        $syncHash.Error = $Error

    })
    $PowerShellCommand.Runspace = $newRunspace
    $data = $PowerShellCommand.BeginInvoke()


    Register-ObjectEvent -InputObject $SyncHash.Runspace `
            -EventName 'AvailabilityChanged' `
            -Action {

                    if($Sender.RunspaceAvailability -eq "Available")
                    {
                        $Sender.Closeasync()
                        $Sender.Dispose()
                    }

                }

    return [System.Collections.Hashtable]$SyncHash

}


function Write-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]$ProgressBar,
        [Parameter(Mandatory=$true)]
        [String]$Activity,
        [String]$Status,
        [int]$Id,
        [int]$PercentComplete,
        [int]$SecondsRemaining,
        [String]$CurrentOperation,
        [int]$ParentId,
        [Switch]$Completed,
        [int]$SourceID
    )

   # This updates the control based on the parameters passed to the function
   $ProgressBar.Window.Dispatcher.Invoke([action]{

      $ProgressBar.Window.Title = $Activity

   }, "Normal")

   if($PercentComplete)
   {

       $ProgressBar.Window.Dispatcher.Invoke([action]{

          $ProgressBar.ProgressBar.Value = $PercentComplete

       }, "Normal")

   }

}


function Close-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]$ProgressBar
    )

    $ProgressBar.Window.Dispatcher.Invoke([action]{

      $ProgressBar.Window.Close()

    }, "Normal")

}