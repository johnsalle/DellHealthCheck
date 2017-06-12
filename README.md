# DellHealthCheck
PowerShell module to check the hardware health of a Dell server - works for both iDRAC and OMSA over SNMP

# Installation
You need to install the SharpSNMPLib.dll file to C:\SharpSNMP\SharpSNMPLib.dll (currently hard coded, will change to param soon)
Download the tritonmate_8.0_bin.zip file here (v8.0) http://sharpsnmplib.codeplex.com/releases/view/79079
From that zip file, extract the SharpSNMPLib.dll file and place it in the directory above.

# Usage
(new-object Net.WebClient).DownloadString('https://goo.gl/uIVXKD') | iex ; Get-DellHealthStatus -IP <IP Address> -Comm <Community String>

This will show a single line reporting the overall status of the hardware. 'OK' means everything is fine, and 'Warning' or 'Critical' indicate an issue that needs to be looked at. 

To see more detailed information, add a -Verbose tag to the end of the command it will spit out detailed hardware information about all available modules. 


