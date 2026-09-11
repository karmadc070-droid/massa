# Extract the two R2 credential values from r2.txt (stripping any "Label:" prefix)
# and send them to the VPS. Values are never printed - only lengths are shown.
# ASCII only: Windows PowerShell mis-decodes BOM-less UTF-8 .ps1 files and breaks string parsing.
$ErrorActionPreference = 'Stop'

$src = Join-Path $env:USERPROFILE 'OneDrive\바탕 화면\r2.txt'
if (-not (Test-Path -LiteralPath $src)) {
  $found = Get-ChildItem $env:USERPROFILE -Filter 'r2.txt' -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) { $src = $found.FullName } else { throw 'r2.txt not found' }
}

$vals = @(Get-Content -LiteralPath $src |
  Where-Object { $_.Trim() -ne '' } |
  ForEach-Object {
    $t = $_.Trim()
    if ($t.Contains(':')) { $t.Substring($t.LastIndexOf(':') + 1).Trim() } else { $t }
  })

if ($vals.Count -ne 2) { throw "Expected 2 values, got $($vals.Count)" }
foreach ($v in $vals) { if ($v -notmatch '^[0-9a-fA-F]+$') { throw 'Value contains non-hex characters' } }
if ($vals[0].Length -ne 32) { throw "Access Key ID must be 32 chars, got $($vals[0].Length)" }
if ($vals[1].Length -ne 64) { throw "Secret must be 64 chars, got $($vals[1].Length)" }
Write-Output "OK: Access Key ID $($vals[0].Length) chars, Secret $($vals[1].Length) chars"

# LF endings, no BOM - the server reads this with sed
$tmp = Join-Path $env:TEMP 'r2.key'
[IO.File]::WriteAllText($tmp, ($vals -join "`n") + "`n", (New-Object Text.UTF8Encoding $false))

$key  = Join-Path $env:USERPROFILE '.ssh\erp_vultr'
$dest = 'root@141.164.46.88:/root/r2.key'
& 'C:\Program Files\Git\usr\bin\scp.exe' -i $key -o BatchMode=yes $tmp $dest
if ($LASTEXITCODE -ne 0) { throw 'scp failed' }
Write-Output 'Sent to server: /root/r2.key'

Remove-Item -LiteralPath $tmp -Force
Remove-Item -LiteralPath $src -Force
Write-Output 'Deleted local copies (desktop r2.txt and temp file)'
