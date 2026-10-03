# 새로 만든 TWA 가 정말 app.massaviet.com 을 여는지 확인한다.
# 빌드가 성공했다는 말만 믿지 않는다. 주소 문자열이 실제로 들어 있는지 센다.
# AAB 는 리소스가 압축돼 있어 원본 바이트 검색이 안 된다. 풀어서 resources.pb 를 본다.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$targets = @('massa-seven.vercel.app', 'app.massaviet.com')

function Scan([string]$label, [string]$path, [string[]]$entries) {
  if (-not (Test-Path $path)) { "{0}: 없음" -f $label; return }
  '--- {0} ---' -f $label
  $zip = [IO.Compression.ZipFile]::OpenRead($path)
  try {
    foreach ($name in $entries) {
      $e = $zip.Entries | Where-Object { $_.FullName -eq $name }
      if (-not $e) { '    {0}: 항목 없음' -f $name; continue }
      $sr = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::ASCII)
      $text = $sr.ReadToEnd(); $sr.Close()
      foreach ($t in $targets) {
        '    {0,-22} {1,-26} {2}' -f $name, $t, ([regex]::Matches($text, [regex]::Escape($t))).Count
      }
    }
  } finally { $zip.Dispose() }
}

Scan '옛 APK (지금 스토어에 있는 것)' 'C:\Users\user\Claude\Projects\massa\android-package\massa.apk' @('resources.arsc')
Scan '새 APK' 'C:\Users\user\Claude\Projects\massa\twa\app-release-signed.apk' @('resources.arsc')
Scan '새 AAB (Play 에 올릴 것)' 'C:\Users\user\Claude\Projects\massa\twa\app-release-bundle.aab' @('base/resources.pb')
