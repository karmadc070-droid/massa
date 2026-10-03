@echo off
rem 2 - build and sign. Run step1-update.bat first; this one must NOT call update
rem because update would overwrite the targetSdk 36 patch.
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
call bubblewrap build --skipPwaValidation
echo ===FILES===
dir /b *.aab *.apk 2>nul
endlocal
