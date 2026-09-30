# 안드로이드 TWA(massa.apk)가 어느 주소를 여는지 확인한다. 배포 대상을 틀리지 않기 위해서다.
$apk = 'C:\Users\user\Claude\Projects\massa\android-package\massa.apk'
$bytes = [IO.File]::ReadAllBytes($apk)
$text = [Text.Encoding]::ASCII.GetString($bytes)
$hosts = @('massa-seven.vercel.app', 'app.massaviet.com', 'massa.moahagwon.com', 'massaviet.com')
foreach ($h in $hosts) {
  $n = ([regex]::Matches($text, [regex]::Escape($h))).Count
  '{0,-26} {1}' -f $h, $n
}
