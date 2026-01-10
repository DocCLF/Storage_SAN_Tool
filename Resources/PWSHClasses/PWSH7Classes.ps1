
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

    // <<< DAS ist die View-Umschaltung >>>
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
