Add-Type -TypeDefinition @"
using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;

public class RootViewModel : INotifyPropertyChanged
{
    public MainViewModel Main { get; } = new MainViewModel();
    
    public string RefrehIcon96 { get; set; }
    public string IBMFS73Icon { get; set; }
    public string SAN64B7Icon { get; set; }
    public string IBMPower11Icon { get; set; }

    private bool _customerYN;
    public bool CustomerYN
    {
        get { return _customerYN; }
        set {
            if (_customerYN != value) {
                _customerYN = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs("CustomerYN"));
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}

public class BaseStorageRow
{
    public string ID { get; set; }
    public string Name { get; set; }
    public string WWNN { get; set; }
    public string Status { get; set; }
    public string IO_group_id { get; set; }
    public string IO_group_Name { get; set; }
    public string Serial_Number { get; set; }
    public string Code_Level { get; set; }
    public string RecommendedPTF { get; set; }
    public string Config_Node { get; set; }
    public string SideID { get; set; }
    public string SideName { get; set; }
}
public class BaseStorageRowMin
{
    public string ID { get; set; }
    public string Name { get; set; }
    public string WWNN { get; set; }
    public string Status { get; set; }
    public string IO_group_id { get; set; }
    public string IO_group_Name { get; set; }
    public string SideID { get; set; }
    public string SideName { get; set; }
}
public class DeviceToggle : INotifyPropertyChanged
{
    private bool _isChecked;
    public string Id { get; set; }
    public string Label { get; set; }

    // jede Checkbox bekommt "ihre" Daten fürs Grid
    public ObservableCollection<BaseStorageRow> Rows { get; } = new ObservableCollection<BaseStorageRow>();
    public ObservableCollection<BaseStorageRowMin> RowsMin { get; } = new ObservableCollection<BaseStorageRowMin>();

    public bool IsChecked
    {
        get { return _isChecked; }
        set {
            if (_isChecked != value) {
                _isChecked = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsChecked)));
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
        set {
            if (_selectAll != value) {
                _selectAll = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(SelectAll)));
                foreach (var d in DeviceToggles) d.IsChecked = _selectAll;
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}
"@ -Language CSharp
