# Foreword/personal comment

<ins>Before connecting to your devices</ins> with the tool for the first time, it has proven useful to do this beforehand from a PowerShell console via putty in order to save the host key properly.
Although it is possible to have the tool do this itself, in my opinion this is not efficient or clean enough, so it will only be included in a later version.
<ins>**SSH via key is currently not supported!**</ins>
I am aware that not everyone likes this or that the use of plink with user/password prompts seems too insecure, 
which is why I strongly recommend <ins>**ONLY using MONITORING USERS**</ins>, which are completely sufficient for this module!


# How to install (offline, because the module is not yet available on PowerShell Gallery)

Download the [package here](https://github.com/DocCLF/Storage_SAN_Tool/releases) and unzip it.
If necessary, rename the folder to Storage_SAN_Tool and copy it to one of the module folders listed below.
 
```pwershell
Check ModulPath with
$env:PSModulePath -split ';'
Examples
----------
PowerShell 5.1
Modules installed in the CurrentUser scope are stored in $HOME\Documents\WindowsPowerShell\Modules.
Modules installed in the AllUsers scope are stored in $env:Program Files\WindowsPowerShell\Modules.
----------
PowerShell 7.x
Modules installed in the CurrentUser scope are stored in $HOME\Documents\PowerShell\Modules.
Modules installed in the AllUsers scope are stored in $env:ProgramFiles\PowerShell\7\Modules.
```
PowerShell 5.1 Source: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-5.1

PowerShell 7.x Source: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-7.5

Installation is complete*, now you can validate if this module is available.
```powershell
get-module -ListAvailable -Name Storage_SAN_Tool
```
Example:

<img width="680" height="106" alt="image" src="https://github.com/user-attachments/assets/2fbb75f3-088f-4564-aedd-403fd207674b" />

Depending on your system settings, different messages may be displayed, so it may be necessary to take the following measures.

Starting with version 1.3.x, it is necessary to unlock the DB files!

Shown here in a PowerShell 5.1 session, but this can be adopted for PowerShell 7 with customized paths.
Please note that this is an administrative session!

<img width="1064" height="262" alt="image" src="https://github.com/user-attachments/assets/85baff56-aeed-4f79-8936-cdcdda37683c" />

This measure is usually only necessary once.

Another possibility is this:
Unlock the *dll files as shown in the image above, and then
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

I recommend creating a shortcut on the desktop and using it to start the module.
One option is to create a desktop shortcut to Powershell 5.1 exe and extend the path as follows.
```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -nologo -noprofile -executionpolicy bypass -command "Storage_SAN_Tool"
```
As shown here, this only works if you use the DefaultPath; everything else would have to be adjusted accordingly. The same applies to creating a shortcut with Powershell7 or with the help of a *.bat file.

If any problems or bugs are found, please do not hesitate to contact us.
