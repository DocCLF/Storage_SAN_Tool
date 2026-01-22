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

public class DeviceToggle : INotifyPropertyChanged
{
    private bool _isChecked;

    public string Id { get; set; }
    public string Label { get; set; }

    // Pro Ansicht eine Collection (für dein XAML)
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

    public ObservableCollection<object> DumpInfoRows { get; } = new ObservableCollection<object>();
    public ObservableCollection<object> BackUpInfoRows { get; } = new ObservableCollection<object>();

    // === NEU: Headline + Text für Lösung 1 ===
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