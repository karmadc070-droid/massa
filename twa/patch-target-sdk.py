# bubblewrap 이 targetSdk 35 로 쓰는데 Play 는 36 이상을 요구한다. update 뒤에 이걸 돌린다.
# PowerShell 로 하면 안 된다 — Get-Content/Set-Content 가 ANSI 로 되써서 한글 앱 이름이 깨지고
# build.gradle 의 Groovy 문자열이 통째로 망가진다. 인코딩을 명시해서 읽고 쓴다.
import io, re, sys, pathlib

p = pathlib.Path(__file__).parent / 'app' / 'build.gradle'
s = p.read_text(encoding='utf-8')
new = s.replace('targetSdkVersion 35', 'targetSdkVersion 36')
if new == s:
    print('바꿀 게 없다 — 이미 36 이거나 패턴이 달라졌다')
else:
    p.write_text(new, encoding='utf-8', newline='\n')
    print('targetSdkVersion 35 -> 36')

out = p.read_text(encoding='utf-8')
for line in out.splitlines():
    if 'SdkVersion' in line or 'versionCode' in line or 'name:' in line:
        print(' ', line.strip())
