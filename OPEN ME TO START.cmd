@echo off
rem ============================================================================
rem  Arena Roblox Bridge  -  Start ohne Konsolenfenster
rem  Dieser Starter ruft "Start Bridge.vbs" auf (wscript.exe) und beendet sich
rem  sofort. Es erscheint NUR das Programmfenster - kein Konsolenfenster bleibt
rem  offen und kein Konsolenfenster kontrolliert die Lebensdauer des Programms.
rem ============================================================================
start "" wscript.exe "%~dp0Start Bridge.vbs"
