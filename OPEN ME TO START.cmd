@echo off
setlocal EnableExtensions
rem ============================================================================
rem  Arena Roblox Bridge  -  Doppelklick zum Starten
rem
rem  Das ist die EINZIGE Datei, die du starten musst.
rem  Alles andere liegt im Unterordner "bridge".
rem
rem  Wichtig: Dieses Fenster schliesst sich NUR, wenn der Start geklappt hat.
rem  Geht etwas schief, bleibt es offen und zeigt den Grund im Klartext an.
rem ============================================================================
title Arena Roblox Bridge - Start

set "ROOT=%~dp0"
set "APPDIR=%ROOT%bridge\app"
set "LAUNCHER=%APPDIR%\Start-Bridge.ps1"
set "SILENT=%APPDIR%\Start-Bridge.vbs"

echo.
echo   Arena Roblox Bridge wird gestartet...
echo.

rem --- 1. Liegt das Programm da, wo es hingehoert? ----------------------------
if not exist "%LAUNCHER%" (
    echo   [FEHLER] Die Programmdateien wurden nicht gefunden.
    echo.
    echo   Erwartet wurde:
    echo     %LAUNCHER%
    echo.
    echo   Bitte entpacke das komplette ZIP-Paket in einen Ordner
    echo   ^(Rechtsklick auf die ZIP-Datei ^> "Alle extrahieren..."^)
    echo   und starte diese Datei erneut aus dem entpackten Ordner.
    echo.
    goto :fail
)

rem --- 2. Ist PowerShell vorhanden? ------------------------------------------
set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PSEXE%" set "PSEXE=powershell.exe"
where "%PSEXE%" >nul 2>&1 || if not exist "%PSEXE%" (
    echo   [FEHLER] Windows PowerShell wurde auf diesem PC nicht gefunden.
    echo   Arena Roblox Bridge benoetigt Windows 10 oder neuer.
    echo.
    goto :fail
)

rem --- 3. Bevorzugt: voellig lautloser Start ueber den Windows Script Host ----
rem     Dadurch bleibt kein Konsolenfenster offen - nur das Programmfenster.
if exist "%SystemRoot%\System32\wscript.exe" if exist "%SILENT%" (
    start "" "%SystemRoot%\System32\wscript.exe" "%SILENT%"
    if not errorlevel 1 goto :done
)

rem --- 4. Fallback: PowerShell direkt, versteckt und abgekoppelt --------------
start "" "%PSEXE%" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%LAUNCHER%"
if errorlevel 1 (
    echo   [FEHLER] Der Start ueber PowerShell ist fehlgeschlagen.
    echo.
    echo   Bitte pruefe die Datei:
    echo     %%LOCALAPPDATA%%\ArenaRobloxBridge\startup-error.log
    echo.
    goto :fail
)

:done
echo   Fertig - das Programmfenster oeffnet sich gleich.
echo   ^(Beim allerersten Start kann das einige Sekunden dauern.^)
timeout /t 3 >nul
exit /b 0

:fail
echo   ------------------------------------------------------------------
echo   Der Start wurde abgebrochen. Dieses Fenster bleibt offen,
echo   damit du die Meldung oben in Ruhe lesen kannst.
echo   ------------------------------------------------------------------
echo.
pause
exit /b 1
