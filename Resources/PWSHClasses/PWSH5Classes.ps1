# Nur einmal pro Session laden
if (-not ("RootViewModel" -as [type])) {

$cs = @"
using System;
using System.Collections.ObjectModel;
using System.ComponentModel;

public class RootViewModel : INotifyPropertyChanged
{
    private MainViewModel _main;

    public RootViewModel()
    {
        _main = new MainViewModel();
    }

    public MainViewModel Main
    {
        get { return _main; }
    }

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
                OnPropertyChanged("CustomerYN");
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;

    protected void OnPropertyChanged(string name)
    {
        var handler = PropertyChanged;
        if (handler != null)
            handler(this, new PropertyChangedEventArgs(name));
    }
}

public class MainViewModel : INotifyPropertyChanged
{
    private ObservableCollection<DeviceToggle> _deviceToggles;
    private bool _selectAll;
    private string _selectedView;

    public MainViewModel()
    {
        _deviceToggles = new ObservableCollection<DeviceToggle>();
        _selectedView = "Base";
    }

    public ObservableCollection<DeviceToggle> DeviceToggles
    {
        get { return _deviceToggles; }
    }

    public bool SelectAll
    {
        get { return _selectAll; }
        set
        {
            if (_selectAll != value)
            {
                _selectAll = value;
                OnPropertyChanged("SelectAll");

                foreach (var d in _deviceToggles)
                    d.IsChecked = _selectAll;
            }
        }
    }

    // View-Umschaltung
    public string SelectedView
    {
        get { return _selectedView; }
        set
        {
            if (_selectedView != value)
            {
                _selectedView = value;
                OnPropertyChanged("SelectedView");
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;

    protected void OnPropertyChanged(string name)
    {
        var handler = PropertyChanged;
        if (handler != null)
            handler(this, new PropertyChangedEventArgs(name));
    }
}

public class SANHealthCheckStep : INotifyPropertyChanged
{
    private string _status;
    private string _details;
    private int _dataCount;

    public string Id { get; set; }
    public string Name { get; set; }

    public SANHealthCheckStep()
    {
        _status = "Pending";
        _details = "";
        _dataCount = 0;
    }

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

    public event PropertyChangedEventHandler PropertyChanged;

    protected void OnPropertyChanged(string name)
    {
        var handler = PropertyChanged;
        if (handler != null)
            handler(this, new PropertyChangedEventArgs(name));
    }
}

public class DeviceToggle : INotifyPropertyChanged
{
    private bool _isChecked;

    private ObservableCollection<object> _baseRows;
    private ObservableCollection<object> _eventRows;
    private ObservableCollection<object> _auditLogRows;
    private ObservableCollection<object> _hostVolumeMapRows;
    private ObservableCollection<object> _hostRows;
    private ObservableCollection<object> _iPQuorumRows;
    private ObservableCollection<object> _mDiskRows;
    private ObservableCollection<object> _volumeRows;
    private ObservableCollection<object> _driveRows;
    private ObservableCollection<object> _fCPortRows;
    private ObservableCollection<object> _fCPortStatsRows;
    private ObservableCollection<object> _partitionRows;
    private ObservableCollection<object> _securityRows;
    private ObservableCollection<object> _userInfoRows;

    private ObservableCollection<object> _sANSwitchBaseRows;
    private ObservableCollection<object> _sANSwitchShowRows;
    private ObservableCollection<object> _sANPortbufferShowRows;
    private ObservableCollection<object> _sANPortErrorShowRows;
    private ObservableCollection<object> _sANSFPDetailsRows;
    private ObservableCollection<object> _sANZoneDetailsRows;
    private ObservableCollection<object> _secureCheckRows;
    private ObservableCollection<object> _sANHealthCheckRows;
    private ObservableCollection<object> _userCFGCheckRows;
    private ObservableCollection<object> _pWCFGCheckRows;

    private ObservableCollection<object> _hmcRows;
    private ObservableCollection<object> _managedSystemRows;
    private ObservableCollection<object> _lparRows;

    // === DG Tape ===
    private ObservableCollection<object> _libraryBaseRows;
    private ObservableCollection<object> _libraryEventsRows;
    private ObservableCollection<object> _libraryReportsRows;
    private ObservableCollection<object> _libraryMediaRows;
    private ObservableCollection<object> _libraryDriveRows;
    private ObservableCollection<object> _libraryInventorySlotsRows;
    private ObservableCollection<object> _libraryInventoryDrivesRows;

    // === NEU: DumpInfo ===
    private ObservableCollection<object> _dumpInfoRows;
    private string _dumpInfoTitle;
    private string _dumpInfoText;
    private ObservableCollection<object> _backUpInfoRows;
    private string _backUpInfoTitle;
    private string _backUpInfoText;
    private ObservableCollection<object> _licenseInfoRows;
    private string _DeviceTitle;
    private string _licenseInfoText;
    private ObservableCollection<object> _sensorShowRows;
    private string _sensorShowTitle;
    private string _sensorShowText;
    private string _sanHealthCheckTitle;

    public DeviceToggle()
    {
        _baseRows = new ObservableCollection<object>();
        _eventRows = new ObservableCollection<object>();
        _auditLogRows = new ObservableCollection<object>();
        _hostVolumeMapRows = new ObservableCollection<object>();
        _hostRows = new ObservableCollection<object>();
        _iPQuorumRows = new ObservableCollection<object>();
        _mDiskRows = new ObservableCollection<object>();
        _volumeRows = new ObservableCollection<object>();
        _driveRows = new ObservableCollection<object>();
        _fCPortRows = new ObservableCollection<object>();
        _fCPortStatsRows = new ObservableCollection<object>();
        _partitionRows = new ObservableCollection<object>();
        _securityRows = new ObservableCollection<object>();
        _userInfoRows = new ObservableCollection<object>();

        _sANSwitchBaseRows = new ObservableCollection<object>();
        _sANSwitchShowRows = new ObservableCollection<object>();
        _sANPortbufferShowRows = new ObservableCollection<object>();
        _sANPortErrorShowRows = new ObservableCollection<object>();
        _sANSFPDetailsRows = new ObservableCollection<object>();
        _sANZoneDetailsRows = new ObservableCollection<object>();
        _secureCheckRows = new ObservableCollection<object>();
        _sANHealthCheckRows = new ObservableCollection<object>();
        _userCFGCheckRows = new ObservableCollection<object>();
        _pWCFGCheckRows = new ObservableCollection<object>();

        _hmcRows = new ObservableCollection<object>();
        _managedSystemRows = new ObservableCollection<object>();
        _lparRows = new ObservableCollection<object>();

        // DG Tape
        _libraryBaseRows = new ObservableCollection<object>();
        _libraryEventsRows = new ObservableCollection<object>();
        _libraryReportsRows = new ObservableCollection<object>();
        _libraryMediaRows = new ObservableCollection<object>();
        _libraryDriveRows = new ObservableCollection<object>();
        _libraryInventorySlotsRows = new ObservableCollection<object>();
        _libraryInventoryDrivesRows = new ObservableCollection<object>();

        // NEU
        _dumpInfoRows = new ObservableCollection<object>();
        _dumpInfoTitle = "";
        _dumpInfoText = "";
        _backUpInfoRows = new ObservableCollection<object>();
        _backUpInfoTitle = "";
        _backUpInfoText = "";
        _licenseInfoRows = new ObservableCollection<object>();
        _DeviceTitle = "";
        _licenseInfoText = "";
        _sensorShowRows = new ObservableCollection<object>();
        _sensorShowTitle = "";
        _sensorShowText = "";
        _sanHealthCheckTitle = "";
    }

    public string Id { get; set; }
    public string Label { get; set; }

    public ObservableCollection<object> BaseRows { get { return _baseRows; } }
    public ObservableCollection<object> IPQuorumRows { get { return _iPQuorumRows; } }
    public ObservableCollection<object> EventRows { get { return _eventRows; } }
    public ObservableCollection<object> AuditLogRows { get { return _auditLogRows; } }
    public ObservableCollection<object> HostVolumeMapRows { get { return _hostVolumeMapRows; } }
    public ObservableCollection<object> HostRows { get { return _hostRows; } }
    public ObservableCollection<object> MDiskRows { get { return _mDiskRows; } }
    public ObservableCollection<object> VolumeRows { get { return _volumeRows; } }
    public ObservableCollection<object> DriveRows { get { return _driveRows; } }
    public ObservableCollection<object> FCPortRows { get { return _fCPortRows; } }
    public ObservableCollection<object> FCPortStatsRows { get { return _fCPortStatsRows; } }
    public ObservableCollection<object> PartitionRows { get { return _partitionRows; } }
    public ObservableCollection<object> SecurityRows { get { return _securityRows; } }
    public ObservableCollection<object> UserInfoRows { get { return _userInfoRows; } }

    public ObservableCollection<object> SANSwitchBaseRows { get { return _sANSwitchBaseRows; } }
    public ObservableCollection<object> SANSwitchShowRows { get { return _sANSwitchShowRows; } }
    public ObservableCollection<object> SANPortbufferShowRows { get { return _sANPortbufferShowRows; } }
    public ObservableCollection<object> SANPortErrorShowRows { get { return _sANPortErrorShowRows; } }
    public ObservableCollection<object> SANSFPDetailsRows { get { return _sANSFPDetailsRows; } }
    public ObservableCollection<object> SANZoneDetailsRows { get { return _sANZoneDetailsRows; } }
    public ObservableCollection<object> SecureCheckRows { get { return _secureCheckRows; } }
    public ObservableCollection<object> SANHealthCheckRows { get { return _sANHealthCheckRows; } }
    public ObservableCollection<object> UserCFGCheckRows { get { return _userCFGCheckRows; } }
    public ObservableCollection<object> PWCFGCheckRows { get { return _pWCFGCheckRows; } }

    public ObservableCollection<object> HmcRows { get { return _hmcRows; } }
    public ObservableCollection<object> ManagedSystemRows { get { return _managedSystemRows; } }
    public ObservableCollection<object> LparRows { get { return _lparRows; } }

    public ObservableCollection<object> LibraryBaseRows { get { return _libraryBaseRows; } }
    public ObservableCollection<object> LibraryEventsRows { get { return _libraryEventsRows; } }
    public ObservableCollection<object> LibraryReportsRows { get { return _libraryReportsRows; } }
    public ObservableCollection<object> LibraryMediaRows { get { return _libraryMediaRows; } }
    public ObservableCollection<object> LibraryDriveRows { get { return _libraryDriveRows; } }
    public ObservableCollection<object> LibraryInventorySlotsRows { get { return _libraryInventorySlotsRows; } }
    public ObservableCollection<object> LibraryInventoryDrivesRows { get { return _libraryInventoryDrivesRows; } }

    public ObservableCollection<object> DumpInfoRows { get { return _dumpInfoRows; } }
    public ObservableCollection<object> BackUpInfoRows { get { return _backUpInfoRows; } }
    public ObservableCollection<object> LicenseInfoRows { get { return _licenseInfoRows; } }
    public ObservableCollection<object> SensorShowRows { get { return _sensorShowRows; } }

    // === NEU: dynamische Headline ===
    public string SensorShowTitle
    {
        get { return _sensorShowTitle; }
        set
        {
            if (_sensorShowTitle != value)
            {
                _sensorShowTitle = value;
                OnPropertyChanged("SensorShowTitle");
            }
        }
    }
    public string DumpInfoTitle
    {
        get { return _dumpInfoTitle; }
        set
        {
            if (_dumpInfoTitle != value)
            {
                _dumpInfoTitle = value;
                OnPropertyChanged("DumpInfoTitle");
            }
        }
    }
    public string BackUpInfoTitle
    {
        get { return _backUpInfoTitle; }
        set
        {
            if (_backUpInfoTitle != value)
            {
                _backUpInfoTitle = value;
                OnPropertyChanged("BackUpInfoTitle");
            }
        }
    }
    public string DeviceTitle
    {
        get { return _DeviceTitle; }
        set
        {
            if (_DeviceTitle != value)
            {
                _DeviceTitle = value;
                OnPropertyChanged("DeviceTitle");
            }
        }
    }

    public string SANHealthCheckTitle
    {
        get { return _sanHealthCheckTitle; }
        set
        {
            if (_sanHealthCheckTitle != value)
            {
                _sanHealthCheckTitle = value;
                OnPropertyChanged("SANHealthCheckTitle");
            }
        }
    }

    // === NEU: Text für TextBlock ===
    public string SensorShowText
    {
        get { return _sensorShowText; }
        set
        {
            if (_sensorShowText != value)
            {
                _sensorShowText = value;
                OnPropertyChanged("SensorShowText");
            }
        }
    }

    public string DumpInfoText
    {
        get { return _dumpInfoText; }
        set
        {
            if (_dumpInfoText != value)
            {
                _dumpInfoText = value;
                OnPropertyChanged("DumpInfoText");
            }
        }
    }

    public string LicenseInfoText
    {
        get { return _licenseInfoText; }
        set
        {
            if (_licenseInfoText != value)
            {
                _licenseInfoText = value;
                OnPropertyChanged("LicenseInfoText");
            }
        }
    }

    public string BackUpInfoText
    {
        get { return _backUpInfoText; }
        set
        {
            if (_backUpInfoText != value)
            {
                _backUpInfoText = value;
                OnPropertyChanged("BackUpInfoText");
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
                OnPropertyChanged("IsChecked");
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;

    protected void OnPropertyChanged(string name)
    {
        var handler = PropertyChanged;
        if (handler != null)
            handler(this, new PropertyChangedEventArgs(name));
    }
}
"@

    try {
        Add-Type -TypeDefinition $cs -Language CSharp -ErrorAction Stop
    }
    catch {
        Write-Host "Add-Type FEHLER:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        throw
    }
}
