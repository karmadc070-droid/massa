@echo off
rem One-shot: build, then print the log and the produced files.
call "%~dp0build2.bat"
echo ===LOG===
type "%~dp0build.log"
echo ===FILES===
dir /b "%~dp0*.aab" "%~dp0*.apk" 2>nul
