# Change Log

All notable changes to this project will be documented in this file.

### Unreleased
- Performance improved
- Storage Host WWPN overview
- Storage RC and FC 
- Stoarge Auditlog
- Support for Virtual Fabrics
- Small SAN Healthcheck

# [v1.2.0] - 2024-tbd
### Added
- FOS Sensor BasicInfo
- FOS SFP BasicDetails
- FOS an info that admin rights are required for Statsclear
- IBM Storage Security check
- SSH-Agent and Key Support at Settings Panel
- IBM FCPort Info
- IBM Storage Base information (this function must be confirmed for a svc-cluster by the check in the first line of the settings panel, the default setting is FlashSystems)
- IBM Storage replication policies information on the system (Important this is only possible with IBM Spectrum Virtualize software 8.6.x)
- IBM Storage Volume replication information for a volume group (Important this is only possible with IBM Spectrum Virtualize software 8.5.x)
- IBM MDiskInfo as an stand-alone function to remain flexible for further developments
- IBM UserInfo as an stand-alone function to remain flexible for further developments
- IBM VolumeInfo as an stand-alone function to remain flexible for further developments
- Tooltips for the tables and columns where it makes sense.
- give some tables a color
- Reginon for better readability

### Fixed
- Regex error that was sometimes triggered when no host cluster is configured. 
- DriveInfo the message that the SVC has no drives was not displayed
- SVC IP CheckBox setting was not exported
- FOS SFP BasicDetails Status View

### Changed
- GUI from Storage Healthcheck compl. redesigned 
- IBM GUI from IBM Spectrum Virtualize Panel, due to the new possibilities, a breakdown by software version has now been made.
- FOS PortBufferShow from Listview to Datagrid
- FOS Add a Information that shows a Info for StatsClear Func
- The control function of the storage health checks has been completely revised to be more flexible for later developments.
- Tooltips adjusted for most buttons.
- DriveInfo shows a Information if the SVC Checkbox is checked
- View of Host Volume Map Info
- The Filter placement of Host Volume Map Info
- Some other annoying GUI Bugs

### Removed
- try catch form DriveInfo Func
- some unnecessary array creations
- some unnecessary Write-Host creations
- Code clean up

### Known Bugs
- Try-Catch does not give any feedback regarding the successful or unsuccessful execution of the ssh-agent commands


# [v1.1.1] - 2024-09-27
### Added
- ProgressBar at LicenseShow
- ProgrBar at BackUpFunc
- Contact Data and Link to Repo at Github

### Fixed
- Bug at HostVolumeMap Filter
- Typo bug at PortErrShow 
- Bug how eventlog is displayed

### Changed
- the CleanUp for the Files in TempFolder
- Orientation to Horizontal at HostVolumeMap Panels
- Can UserSortColumns to false at Zoneshow, Switchshow
- Eventlog now shows up to 100 entries, previously there were 25
- some tables adjusted in column width

### Removed
- Button for svc config clear


## [v1.1.0] - 2024-09-26
### Added
- Filter function for Zoneshow
- Filter for SwitchShow
- A Overview of FOS Support Matrix at Basic Switch Info
- Quorum check at Storage Health

### Changed
- Filter for Host Volume View, now based on Lists
- Export Path to own documents. There will be a Folder "StorageSANKit" created, where the csv files will be exported.
- the most Lists from listbox to datagrid
- the distance between the views for a better overview at FCPortStats

### Fixes
- the filter Var from the Backupfunction
- many small annoying bugs but probably not all of them yet

### Known Bug 
- filter by ZoneShows does not show wwpn or aliases when filtering by zone


## [v1.0.10] - 2024-09-17
### Added
- A small logo and the module version number at the bottom of the main window.
- Extension of the host volume display to all 4 storage systems/clusters, previously there were only 2

### Changed
- The display of most lists in the storage area has been redesigned.
- The display of the Zoneshow has been modified
- Significant performance improvement in the progress bar

### Fixes
- performance improvement for most of the functions 
- The name of the effective zone configuration is now displayed correctly
- SAN License is now readonly
- Progressbar at Switch Info is now displayed correctly
- Bug where the FOS version was not displayed under switch info

## [v1.0] - 2024-09-12
- initial release


The format is based on [Keep a Changelog](http://keepachangelog.com/),
and this project adheres to [Semantic Versioning](http://semver.org/).