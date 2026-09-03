' ============================================================================
'  Arena Roblox Bridge  -  Start ohne Konsolenfenster
'  Doppelklick nach dem Entpacken (oder "OPEN ME TO START.cmd").
'  PowerShell laeuft versteckt (Fenster-Stil 0) und entkoppelt: Es erscheint
'  NUR das Programmfenster. Schliessen des Konsolenfensters kann das Programm
'  daher nie beenden - es gibt kein sichtbares Konsolenfenster.
' ============================================================================
Option Explicit

Dim fso, shell, base, ps1, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
base = fso.GetParentFolderName(WScript.ScriptFullName)

ps1 = fso.BuildPath(fso.BuildPath(base, "app"), "ArenaBridge.ps1")

If Not fso.FileExists(ps1) Then
    MsgBox "ArenaBridge.ps1 wurde nicht gefunden." & vbCrLf & _
           "Bitte entpacke das komplette Paket und starte 'Start Bridge.vbs'" & vbCrLf & _
           "aus dem Hauptordner.", vbExclamation, "Arena Roblox Bridge"
    WScript.Quit 1
End If

Set shell = CreateObject("WScript.Shell")
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & ps1 & """"
shell.Run cmd, 0, False
