' ============================================================================
'  Arena Roblox Bridge  -  lautloser Start (Hilfsdatei)
'
'  Diese Datei bitte NICHT direkt anklicken.
'  Zum Starten gibt es im Hauptordner "OPEN ME TO START.cmd".
'
'  Sie startet PowerShell versteckt. Klappt etwas nicht, erscheint jetzt
'  IMMER ein Meldungsfenster mit dem Grund (frueher passierte einfach nichts).
' ============================================================================
Option Explicit

Dim fso, shell, appDir, launcher, psExe, cmd, rc
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

appDir = fso.GetParentFolderName(WScript.ScriptFullName)
launcher = fso.BuildPath(appDir, "Start-Bridge.ps1")

If Not fso.FileExists(launcher) Then
    MsgBox "Die Programmdatei 'Start-Bridge.ps1' wurde nicht gefunden." & vbCrLf & vbCrLf & _
           "Erwartet in:" & vbCrLf & launcher & vbCrLf & vbCrLf & _
           "Bitte entpacke das komplette Paket und starte danach" & vbCrLf & _
           "'OPEN ME TO START.cmd' im Hauptordner.", _
           vbCritical, "Arena Roblox Bridge"
    WScript.Quit 1
End If

psExe = fso.BuildPath(shell.ExpandEnvironmentStrings("%SystemRoot%"), _
                      "System32\WindowsPowerShell\v1.0\powershell.exe")
If Not fso.FileExists(psExe) Then psExe = "powershell.exe"

cmd = """" & psExe & """ -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & launcher & """"

On Error Resume Next
rc = shell.Run(cmd, 0, False)
If Err.Number <> 0 Then
    MsgBox "Arena Roblox Bridge konnte nicht gestartet werden." & vbCrLf & vbCrLf & _
           "Windows meldet: " & Err.Description & vbCrLf & vbCrLf & _
           "Bitte starte stattdessen 'OPEN ME TO START.cmd' im Hauptordner -" & vbCrLf & _
           "dort wird der Fehler ausfuehrlich angezeigt.", _
           vbCritical, "Arena Roblox Bridge"
    WScript.Quit 1
End If
On Error GoTo 0
