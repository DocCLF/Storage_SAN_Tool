# Change Log

All notable changes to this project will be documented in this file.

### Unreleased
- Storage Host WWPN overview
- Storage RC and FC 
- Stoarge Auditlog
- Storage Stats
- Storage Revision of the Storagehealthcheck
- Support for Virtual Fabrics
- Small SAN Healthcheck


# [v1.1.0] - 2024-09-26
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