@echo off
setlocal
set "SCRIPT=%~dp0app\ArenaBridge.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "%SCRIPT%"
endlocal
