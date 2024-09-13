# How to install (offline)

Download the package here and place it in an area of your choice and unzip it.

Now copy the downloaded module to 
```pwershell
PowerShell 5.1
C:\Program Files\WindowsPowerShell\Modules
----------
PowerShell 7.4.x
C:\Users\(yourname)\Documents\PowerShell\Modules
```
Installation is complete*, now you can validate if this module is available.

*Sometimes you may still need to use this command to make the module usable.
```powershell
Import-Module Storage_SAN_Kit
```

Example:
```powershell
Get-Module -ListAvailable Storage_SAN_Kit
```
<img width="721" alt="image" src="https://github.com/user-attachments/assets/202f70bb-0f07-449f-9acd-6135f606ac9f">


And finally we can get list of available commands for installed module.
<img width="675" alt="image" src="https://github.com/user-attachments/assets/87f3642d-01d2-4da8-b423-372a9b6f7b98">

You can start the GUi by calling the following.
```powershell
Storage_SAN_Kit
```

Then it should look like this ...

<img width="684" alt="image" src="https://github.com/user-attachments/assets/e3531f18-7315-4f8a-82f2-dc3c3483bce9">


... or the home page should be shown (possibly also in the background)
<img width="1653" alt="image" src="https://github.com/user-attachments/assets/bf3c2855-ffdf-4191-b105-8ae57203f9ab">
