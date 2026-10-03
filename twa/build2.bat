@echo off
rem Same as build.bat but writes everything to build.log so a long gradle run can be polled.
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "JAVA_HOME=C:\Users\user\jbr"
set "ANDROID_HOME=C:\Users\user\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"
for /f "tokens=2 delims=:" %%A in ('findstr /c:"Key store password:" ..\android-package\signing-key-info.txt') do set "KSPW=%%A"
set "KSPW=%KSPW: =%"
set "BUBBLEWRAP_KEYSTORE_PASSWORD=%KSPW%"
set "BUBBLEWRAP_KEY_PASSWORD=%KSPW%"
call bubblewrap build --skipPwaValidation > build.log 2>&1
echo EXITCODE=%errorlevel% >> build.log
endlocal
