Add-Type -AssemblyName System
Add-Type -AssemblyName System.Core
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework

$cs = @"
using System;
using System.Collections.ObjectModel;
using System.ComponentModel;

public class RootViewModel : INotifyPropertyChanged
{
    public RootViewModel()
    {
        Main = new MainViewModel();
    }

    public MainViewModel Main { get; private set; }

    public string RefrehIcon96 { get; set; }
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
                var handler = PropertyChanged;
                if (handler != null) handler(this, new PropertyChangedEventArgs("CustomerYN"));
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}

public class BaseStorageRow
{
    public string ID { get; set; }
    public string Name { get; set; }
    public string ClusterName { get; set; }
    public string WWNN { get; set; }
    public string Status { get; set; }
    public string IO_group_id { get; set; }
    public string IO_group_Name { get; set; }
    public string Prod_MTM { get; set; }
    public string Serial_Number { get; set; }
    public string Code_Level { get; set; }
    public string RecommendedPTF { get; set; }
    public string Config_Node { get; set; }
    public string SideID { get; set; }
    public string SideName { get; set; }
    public string MDiskTotalCapacity { get; set; }
    public string MDiskFreeCapacity { get; set; }
    public string MDiskUsedCapacity { get; set; }
    public string PhysicalTotalCapacity { get; set; }
    public string PhysicalFreeCapacity { get; set; }
    public string HostUnmap { get; set; }
    public string BackendUnmap { get; set; }
    public string Topology { get; set; }
    public string Layer { get; set; }
    public string QuorumMode { get; set; }
}

public class DeviceToggle : INotifyPropertyChanged
{
    public DeviceToggle()
    {
        DGRow = new ObservableCollection<BaseStorageRow>();
    }

    private bool _isChecked;
    public string Id { get; set; }
    public string Label { get; set; }

    public ObservableCollection<BaseStorageRow> DGRow { get; private set; }

    public bool IsChecked
    {
        get { return _isChecked; }
        set
        {
            if (_isChecked != value)
            {
                _isChecked = value;
                var handler = PropertyChanged;
                if (handler != null) handler(this, new PropertyChangedEventArgs("IsChecked"));
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}

public class MainViewModel : INotifyPropertyChanged
{
    public MainViewModel()
    {
        DeviceToggles = new ObservableCollection<DeviceToggle>();
    }

    public ObservableCollection<DeviceToggle> DeviceToggles { get; private set; }

    private bool _selectAll;
    public bool SelectAll
    {
        get { return _selectAll; }
        set
        {
            if (_selectAll != value)
            {
                _selectAll = value;

                var handler = PropertyChanged;
                if (handler != null) handler(this, new PropertyChangedEventArgs("SelectAll"));

                foreach (var d in DeviceToggles) d.IsChecked = _selectAll;
            }
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
}
"@

try {
    Add-Type -TypeDefinition $cs -Language CSharp -ErrorAction Stop
}
catch {
    Write-Host "Add-Type (classes.ps1) FEHLER:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    throw
}