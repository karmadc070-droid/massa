@echo off
rem 1 - regenerate the Android project from twa-manifest.json. Nothing else.
rem The targetSdk patch is NOT done here: PowerShell's Get-Content/Set-Content wrote the file
rem back as ANSI and mangled the Korean app name, which broke the Groovy string in build.gradle.
rem Patch with patch-target-sdk.py instead (UTF-8 safe), then run step2-build.bat.
setlocal
cd /d "%~dp0"
set "JAVA_HOME=C:\Users\user\jbr"
set "ANDROID_HOME=C:\Users\user\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%PATH%"
call bubblewrap update --skipVersionUpgrade
endlocal
