@echo off
rem bubblewrap does not quote the JDK path, so a path containing spaces breaks apksigner.
rem Make a space-free junction and point bubblewrap at that instead.
mklink /J "C:\Users\user\jbr" "C:\Program Files\Android\Android Studio\jbr"
dir /b "C:\Users\user\jbr\bin\java.exe"
