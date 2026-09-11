# Read the Google Maps API key from the clipboard and ship it to the VPS.
# The value is never printed - only its length and shape are shown.
# ASCII only: Windows PowerShell mis-decodes BOM-less UTF-8 .ps1 files and breaks string parsing.
$ErrorActionPreference = 'Stop'

$k = (Get-Clipboard -Raw)
if (-not $k) { throw 'Clipboard is empty' }
$k = $k.Trim()

if (-not $k.StartsWith('AIza')) { throw 'Clipboard does not look like a Google API key' }
if ($k -notmatch '^[A-Za-z0-9_\-]+$') { throw 'Key contains unexpected characters' }
if ($k.Length -lt 35 -or $k.Length -gt 45) { throw "Unexpected key length: $($k.Length)" }
Write-Output "OK: key looks valid, $($k.Length) chars"

# LF endings, no BOM - the server reads this with sed
$tmp = Join-Path $env:TEMP 'maps.key'
[IO.File]::WriteAllText($tmp, $k + "`n", (New-Object Text.UTF8Encoding $false))

$sshKey = Join-Path $env:USERPROFILE '.ssh\erp_vultr'
& 'C:\Program Files\Git\usr\bin\scp.exe' -i $sshKey -o BatchMode=yes $tmp 'root@141.164.46.88:/root/maps.key'
if ($LASTEXITCODE -ne 0) { throw 'scp failed' }
Write-Output 'Sent to server: /root/maps.key'

Remove-Item -LiteralPath $tmp -Force
Set-Clipboard -Value ' '
Write-Output 'Cleared temp file and clipboard'
