# ============================================================================
#  Arena Roblox Bridge - Start-Wrapper
#
#  Dieser kleine Wrapper startet das eigentliche Programm (ArenaBridge.ps1)
#  und faengt JEDEN Startfehler ab. Frueher ist das Programm bei einem Fehler
#  einfach still verschwunden ("es passiert gar nichts"), weil PowerShell
#  versteckt lief und die Fehlermeldung niemand gesehen hat.
#
#  Ab jetzt gilt:
#    - Startet das Programm nicht, erscheint ein Fenster mit Klartext-Grund.
#    - Zusaetzlich landet alles in:
#      %LOCALAPPDATA%\ArenaRobloxBridge\startup-error.log
# ============================================================================
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$logDir = Join-Path $env:LOCALAPPDATA 'ArenaRobloxBridge'
$logFile = Join-Path $logDir 'startup-error.log'

function Write-StartupLog {
    param([string]$Text)
    try {
        if (-not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -LiteralPath $logFile -Value ('{0:u}  {1}' -f (Get-Date), $Text) -Encoding UTF8
    } catch {}
}

function Show-StartupError {
    param([string]$Message)
    Write-StartupLog $Message
    $full = @"
Arena Roblox Bridge konnte nicht gestartet werden.

$Message

Details stehen in:
$logFile
"@
    # 1. Versuch: normales Windows-Meldungsfenster.
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show(
            $full, 'Arena Roblox Bridge',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    } catch {}
    # 2. Versuch: Meldungsfenster ueber den Windows Script Host.
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shell.Popup($full, 0, 'Arena Roblox Bridge', 16) | Out-Null
        return
    } catch {}
    # 3. Versuch: wenigstens auf die Konsole schreiben.
    try { Write-Host $full -ForegroundColor Red } catch {}
}

try {
    # ---------------------------------------------------------------------
    # 1. Voraussetzungen pruefen (verstaendliche Meldung statt stillem Ende)
    # ---------------------------------------------------------------------
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Show-StartupError ("Es wird Windows PowerShell 5.1 benoetigt, gefunden wurde Version " +
            "$($PSVersionTable.PSVersion). Bitte Windows aktualisieren oder das Programm " +
            "ueber die Datei 'OPEN ME TO START.cmd' starten.")
        exit 1
    }

    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
        Show-StartupError ("PowerShell laeuft nicht im STA-Modus. Die Oberflaeche kann so nicht " +
            "geoeffnet werden. Bitte das Programm ueber 'OPEN ME TO START.cmd' im Hauptordner starten.")
        exit 1
    }

    $appDir = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($appDir)) {
        $appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $mainScript = Join-Path $appDir 'ArenaBridge.ps1'

    if (-not (Test-Path -LiteralPath $mainScript)) {
        Show-StartupError ("Die Programmdatei wurde nicht gefunden:`r`n$mainScript`r`n`r`n" +
            "Bitte das komplette Paket entpacken (nicht einzelne Dateien aus dem ZIP starten).")
        exit 1
    }

    # ---------------------------------------------------------------------
    # 2. Byte Order Mark (BOM) reparieren
    #    Ein doppeltes/dreifaches BOM am Dateianfang laesst PowerShell die
    #    Datei gar nicht erst laden - genau deshalb "passierte nichts".
    # ---------------------------------------------------------------------
    try {
        $bytes = [System.IO.File]::ReadAllBytes($mainScript)
        $bom = [byte[]](0xEF, 0xBB, 0xBF)
        $offset = 0
        while (($bytes.Length - $offset) -ge 3 -and
               $bytes[$offset] -eq $bom[0] -and $bytes[$offset + 1] -eq $bom[1] -and $bytes[$offset + 2] -eq $bom[2]) {
            $offset += 3
        }
        if ($offset -gt 3) {
            $keep = New-Object byte[] ($bytes.Length - $offset + 3)
            [System.Array]::Copy($bom, 0, $keep, 0, 3)
            [System.Array]::Copy($bytes, $offset, $keep, 3, $bytes.Length - $offset)
            [System.IO.File]::WriteAllBytes($mainScript, $keep)
            Write-StartupLog "Mehrfaches BOM in ArenaBridge.ps1 entfernt (Start repariert)."
        }
    } catch {
        Write-StartupLog "BOM-Pruefung uebersprungen: $($_.Exception.Message)"
    }

    # ---------------------------------------------------------------------
    # 3. Programm starten
    # ---------------------------------------------------------------------
    Write-StartupLog "Starte $mainScript"
    $env:ARENABRIDGE_PATH = $mainScript
    & $mainScript
} catch {
    $detail = $_ | Out-String
    Show-StartupError $detail.Trim()
    exit 1
}
