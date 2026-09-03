@echo off
cd /d "%~dp0"
title Arena Roblox Bridge - Start
rem ============================================================================
rem  Arena Roblox Bridge  -  Doppelklick zum Starten
rem
rem  Das ist die EINZIGE Datei, die du starten musst.
rem  Alles andere liegt im Unterordner "bridge".
rem
rem  Bei einem Fehler bleibt dieses Fenster offen und zeigt den Grund an.
rem  Es schliesst sich NUR, wenn der Start geklappt hat.
rem
rem  Fehlersuche: in einer Eingabeaufforderung so starten:
rem      "OPEN ME TO START.cmd" /debug
rem  Dann laeuft alles sichtbar im Vordergrund und das Fenster bleibt offen.
rem ============================================================================

set "APPDIR=%~dp0bridge\app"
set "LAUNCHER=%APPDIR%\Start-Bridge.ps1"
set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

echo.
echo   Arena Roblox Bridge wird gestartet...
echo.

rem --- Diagnose-Modus? ---------------------------------------------------------
if /i "%~1"=="/debug" goto :debug
if /i "%~1"=="-debug" goto :debug
if /i "%~1"=="debug" goto :debug

rem --- 1. Liegen die Programmdateien da, wo sie hingehoeren? ------------------
if not exist "%LAUNCHER%" goto :fehler_dateien

rem --- 2. Ist Windows PowerShell vorhanden? ------------------------------------
if not exist "%PSEXE%" goto :fehler_powershell

rem --- 3. Start: PowerShell direkt, versteckt und entkoppelt -------------------
rem     Es erscheint nur das Programmfenster, kein Konsolenfenster.
rem     ARENABRIDGE_DEBUG wird hier bewusst NICHT gesetzt: Das Programm
rem     versteckt sein eigenes Konsolenfenster dann immer selbst.
set ARENABRIDGE_DEBUG=
start "" "%PSEXE%" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%LAUNCHER%"

echo.
echo   Fertig - das Programmfenster oeffnet sich gleich.
echo   Beim allerersten Start kann das einige Sekunden dauern.
echo.
timeout /t 3 /nobreak >nul
exit /b 0

rem ============================================================================
rem  Diagnose-Modus: alles sichtbar im Vordergrund, am Ende bleibt das Fenster
rem ============================================================================
:debug
set ARENABRIDGE_DEBUG=1
echo.
echo   [DIAGNOSE-MODUS] Alles laeuft jetzt sichtbar im Vordergrund.
echo   Dieses Fenster bleibt am Ende offen. Bei Problemen bitte einen
echo   Screenshot vom GESAMTEN Fenster machen und mitsenden.
echo.
if not exist "%LAUNCHER%" goto :fehler_dateien
if not exist "%PSEXE%" goto :fehler_powershell
echo   Starte PowerShell im Vordergrund:
echo   "%PSEXE%" -NoProfile -ExecutionPolicy Bypass -STA -File "%LAUNCHER%"
echo.
"%PSEXE%" -NoProfile -ExecutionPolicy Bypass -STA -File "%LAUNCHER%"
echo.
echo   ----------------------------------------------------------------
echo   Das Programm wurde beendet. Pruefe oben die Meldungen.
echo   ----------------------------------------------------------------
pause
exit /b 0

rem ============================================================================
rem  Fehlerfaelle: Meldung + Pause, das Fenster bleibt offen
rem ============================================================================
:fehler_dateien
echo.
echo   [FEHLER] Die Programmdateien wurden nicht gefunden.
echo.
echo   Erwartet wurde:
echo     %LAUNCHER%
echo.
echo   Bitte entpacke das KOMPLETTE ZIP-Paket in einen Ordner
echo   ^(Rechtsklick auf die ZIP-Datei, dann "Alle extrahieren..."^)
echo   und starte diese Datei erneut aus dem entpackten Ordner.
echo.
echo   Tipp: Entpacke in einen normalen Ordner wie C:\ArenaRobloxBridge
echo   und nicht direkt in Downloads oder auf den Desktop.
goto :ende_fehler

:fehler_powershell
echo.
echo   [FEHLER] Windows PowerShell wurde auf diesem PC nicht gefunden.
echo   Arena Roblox Bridge benoetigt Windows 10 oder neuer.
echo.
goto :ende_fehler

:ende_fehler
echo   ----------------------------------------------------------------
echo   Der Start wurde abgebrochen. Dieses Fenster bleibt offen,
echo   damit du die Meldung oben in Ruhe lesen kannst.
echo   ----------------------------------------------------------------
echo.
pause
exit /b 1
