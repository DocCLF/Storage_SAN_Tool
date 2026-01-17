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

    public string RefreshIcon96  { get; set; }
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

public class DeviceToggle : INotifyPropertyChanged
{
    private bool _isChecked;
    private ObservableCollection<object> _baseRows;
    private ObservableCollection<object> _eventRows;
    private ObservableCollection<object> _auditLogRows;
    private ObservableCollection<object> _hostVolumeMapRows;
    private ObservableCollection<object> _hostRows;
    private ObservableCollection<object> _iPQuorumRows;

    public DeviceToggle()
    {
        _baseRows = new ObservableCollection<object>();
        _eventRows = new ObservableCollection<object>();
        _auditLogRows = new ObservableCollection<object>();
        _hostVolumeMapRows = new ObservableCollection<object>();
        _hostRows = new ObservableCollection<object>();
        _iPQuorumRows = new ObservableCollection<object>();
    }

    public string Id { get; set; }
    public string Label { get; set; }

    public ObservableCollection<object> BaseRows
    {
        get { return _baseRows; }
    }
    public ObservableCollection<object> IPQuorumRows
    {
        get { return _iPQuorumRows; }
    }
    public ObservableCollection<object> EventRows
    {
        get { return _eventRows; }
    }
    public ObservableCollection<object> AuditLogRows
    {
        get { return _auditLogRows; }
    }
    public ObservableCollection<object> HostVolumeMapRows
    {
        get { return _hostVolumeMapRows; }
    }
    public ObservableCollection<object> HostRows
    {
        get { return _hostRows; }
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
