@echo off
rem Regenerate from twa-manifest.json, force targetSdk 36, build, then print the files.
rem Why the patch step: Play rejects targetSdk 35 ("API 36 이상을 타겟팅해야 합니다"),
rem and bubblewrap writes 35 into app/build.gradle every time `update` runs.
rem So the order matters — update first, patch second, build last. Patch before update is lost.
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "JAVA_HOME=C:\Users\user\jbr"
set "ANDROID_HOME=C:\Users\user\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"
for /f "tokens=2 delims=:" %%A in ('findstr /c:"Key store password:" ..\android-package\signing-key-info.txt') do set "KSPW=%%A"
set "KSPW=%KSPW: =%"
set "BUBBLEWRAP_KEYSTORE_PASSWORD=%KSPW%"
set "BUBBLEWRAP_KEY_PASSWORD=%KSPW%"
del /q app-release-bundle.aab app-release-signed.apk 2>nul

call bubblewrap update --skipVersionUpgrade

echo === targetSdk 35 -^> 36 ===
powershell -NoProfile -Command "$p='app/build.gradle'; $s=Get-Content $p -Raw; $s=$s -replace 'targetSdkVersion 35','targetSdkVersion 36'; Set-Content $p $s -NoNewline"
findstr /c:"targetSdkVersion" app\build.gradle

call bubblewrap build --skipPwaValidation
echo ===FILES===
dir /b *.aab *.apk 2>nul
endlocal
