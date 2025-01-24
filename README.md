# How to install (offline, because the module is not yet available on PowerShell Gallery)

Download the [package here](https://github.com/DocCLF/Storage_SAN_Tool/releases/tag/v1.2.0) and unzip it.
If necessary, rename the folder to Storage_SAN_Tool and copy it to one of the module folders listed below.
 
```pwershell
PowerShell 5.1
Modules installed in the CurrentUser scope are stored in $HOME\Documents\WindowsPowerShell\Modules.
Modules installed in the AllUsers scope are stored in $env:ProgramFiles\WindowsPowerShell\Modules.
----------
PowerShell 7.4.x
Modules installed in the CurrentUser scope are stored in $HOME\Documents\PowerShell\Modules.
Modules installed in the AllUsers scope are stored in $env:ProgramFiles\PowerShell\7\Modules.
```
Installation is complete*, now you can validate if this module is available.
```powershell
get-module -ListAvailable -Name Storage_SAN_Tool
```
Depending on the settings of your system, an error message may appear stating that: The execution of scripts is disabled on this system.
You can check the setting with 
```powershell
Get-ExecutionPolicy
```
, the response will usually be “Restricted”.
To be able to use this module you only have to enter the following line:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```
followed by 
```powershell
Import-Module Storage_SAN_Kit
```
Or another measure can be that you have to confirm that you are allowed to perform the individual functions.

When everything is done, or everything is running normally, you only need to run the module with:
```powershell
Storage_SAN_Tool
```

Then it should look like this ...
<img width="1653" alt="image" src="https://github.com/user-attachments/assets/bf3c2855-ffdf-4191-b105-8ae57203f9ab">

If any problems or bugs are found, please do not hesitate to contact us.
