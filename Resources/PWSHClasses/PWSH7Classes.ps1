Add-Type -TypeDefinition @"
using System.Collections.ObjectModel;
using System.ComponentModel;

public class RootViewModel : INotifyPropertyChanged
{
    public MainViewModel Main { get; } = new MainViewModel();

    public string RefreshIcon96 { get; set; }
    public string IBMFS73Icon { get; set; }
    public string SAN64B7Icon { get; set; }
    public string IBMPower11Icon { get; set; }
    public string HMCIcon { get; set; }
    public string PowerIcon { get; set; }
    public string ClockIcon96 { get; set; }
    public string SAN720 { get; set; }
    public string STOIcon { get; set; }
    public string BrocadeIcon { get; set; }
    public string IBMArchive { get; set; }
    

    private bool _customerYN;
    public bool CustomerYN
    {
        get { return _customerYN; }
        set
        {
            if (_customerYN != value)
            {
                _customerYN = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CustomerYN)));
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}

public class MainViewModel : INotifyPropertyChanged
{
    public ObservableCollection<DeviceToggle> DeviceToggles { get; } = new ObservableCollection<DeviceToggle>();

    private bool _selectAll;
    public bool SelectAll
    {
        get { return _selectAll; }
        set
        {
            if (_selectAll != value)
            {
                _selectAll = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SelectAll)));
                foreach (var d in DeviceToggles) d.IsChecked = _selectAll;
            }
        }
    }

    private string _selectedView = "Base";
    public string SelectedView
    {
        get { return _selectedView; }
        set
        {
            if (_selectedView != value)
            {
                _selectedView = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SelectedView)));
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}
// === SANHealthCheck ===
// Id         = Unique technical designation
// Name       = Visible task
// Status     = Pending, Running, Completed, NoData, Error
// Details    = Additional information or error message
// DataCount  = Number of collected data records
public class SANHealthCheckStep : INotifyPropertyChanged
{
    private string _status;
    private string _details;
    private int _dataCount;

    public string Id { get; set; }
    public string Name { get; set; }

    public string Status
    {
        get { return _status; }
        set
        {
            if (_status != value)
            {
                _status = value;
                OnPropertyChanged("Status");
            }
        }
    }

    public string Details
    {
        get { return _details; }
        set
        {
            if (_details != value)
            {
                _details = value;
                OnPropertyChanged("Details");
            }
        }
    }

    public int DataCount
    {
        get { return _dataCount; }
        set
        {
            if (_dataCount != value)
            {
                _dataCount = value;
                OnPropertyChanged("DataCount");
            }
        }
    }

    public SANHealthCheckStep()
    {
        _status = "Pending";
        _details = "";
        _dataCount = 0;
    }

    public event PropertyChangedEventHandler PropertyChanged;

    protected void OnPropertyChanged(string name)
    {
        var handler = PropertyChanged;

        if (handler != null)
        {
            handler(this, new PropertyChangedEventArgs(name));
        }
    }
}
public class DeviceToggle : INotifyPropertyChanged
{
    private bool _isChecked;

    public string Id { get; set; }
    public string Label { get; set; }

    // Pro Ansicht eine Collection (für dein XAML)
    // === DG STO ===
    public ObservableCollection<object> BaseRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> EventRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> AuditLogRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> HostVolumeMapRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> HostRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> IPQuorumRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> MDiskRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> VolumeRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> DriveRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> FCPortRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> FCPortStatsRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> PartitionRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SecurityRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> UserInfoRows { get; } = new ObservableCollection<object>();

    // === DG SAN ===
    public ObservableCollection<object> SANSwitchBaseRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SANSwitchShowRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SANPortbufferShowRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SANPortErrorShowRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SANSFPDetailsRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SANZoneDetailsRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SecureCheckRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SANHealthCheckRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> UserCFGCheckRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> PWCFGCheckRows { get; } = new ObservableCollection<object>();

    // === BTN PWR ===
    public ObservableCollection<object> HmcRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> ManagedSystemRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LparRows { get; } = new ObservableCollection<object>();

    // === Textfield STO & SAN ===
    public ObservableCollection<object> DumpInfoRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> BackUpInfoRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LicenseInfoRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> SensorShowRows { get; } = new ObservableCollection<object>();

    // === DG Tape ===
    public ObservableCollection<object> LibraryBaseRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LibraryEventsRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LibraryReportsRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LibraryMediaRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LibraryDriveRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LibraryInventorySlotsRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> LibraryInventoryDrivesRows { get; } = new ObservableCollection<object>();


    // === NEU: Headline + Text für Lösung 1 ===
    private string _sensorShowTitle;
    public string SensorShowTitle
    {
        get { return _sensorShowTitle; }
        set
        {
            if (_sensorShowTitle != value)
            {
                _sensorShowTitle = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SensorShowTitle)));
            }
        }
    }

    private string _sensorShowText;
    public string SensorShowText
    {
        get { return _sensorShowText; }
        set
        {
            if (_sensorShowText != value)
            {
                _sensorShowText = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SensorShowText)));
            }
        }
    }
    private string _dumpInfoTitle;
    public string DumpInfoTitle
    {
        get { return _dumpInfoTitle; }
        set
        {
            if (_dumpInfoTitle != value)
            {
                _dumpInfoTitle = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(DumpInfoTitle)));
            }
        }
    }

    private string _dumpInfoText;
    public string DumpInfoText
    {
        get { return _dumpInfoText; }
        set
        {
            if (_dumpInfoText != value)
            {
                _dumpInfoText = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(DumpInfoText)));
            }
        }
    }
   private string _backUpInfoTitle;
    public string BackUpInfoTitle
    {
        get { return _backUpInfoTitle; }
        set
        {
            if (_backUpInfoTitle != value)
            {
                _backUpInfoTitle = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(BackUpInfoTitle)));
            }
        }
    }

    private string _backUpInfoText;
    public string BackUpInfoText
    {
        get { return _backUpInfoText; }
        set
        {
            if (_backUpInfoText != value)
            {
                _backUpInfoText = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(BackUpInfoText)));
            }
        }
    }

   private string _DeviceTitle;
    public string DeviceTitle
    {
        get { return _DeviceTitle; }
        set
        {
            if (_DeviceTitle != value)
            {
                _DeviceTitle = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(DeviceTitle)));
            }
        }
    }

    private string _licenseInfoText;
    public string LicenseInfoText
    {
        get { return _licenseInfoText; }
        set
        {
            if (_licenseInfoText != value)
            {
                _licenseInfoText = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(LicenseInfoText)));
            }
        }
    }
    
    private string _sanHealthCheckTitle;

    public string SANHealthCheckTitle
    {
        get { return _sanHealthCheckTitle; }
        set
        {
            if (_sanHealthCheckTitle != value)
            {
                _sanHealthCheckTitle = value;
                PropertyChanged?.Invoke(
                    this,
                    new PropertyChangedEventArgs(nameof(SANHealthCheckTitle))
                );
            }
        }
    }
    
    public bool IsChecked
    {
        get { return _isChecked; }
        set
        {
            if (_isChecked != value)
            {
                _isChecked = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsChecked)));
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}
"@ -Language CSharp