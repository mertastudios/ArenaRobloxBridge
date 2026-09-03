# Arena Roblox Bridge

Verbindet **Roblox Studio** mit einem lokalen Programmfenster, damit eine
KI (z. B. Arena AI) Places direkt steuern kann: Instanzen lesen und bauen,
Skripte schreiben und prüfen, Play-Tests starten, GUI bedienen, Fehler lesen -
über einen Cloudflare-Tunnel und eine einfache HTTP-API.

- [Start in 30 Sekunden](#start-in-30-sekunden)
- [Voraussetzungen](#voraussetzungen)
- [Funktionen](#funktionen)
- [Auto-Update (GitHub)](#auto-update-github)
- [Für KI-Agenten: API-Übersicht](#für-ki-agenten-api-übersicht)
- [Mehrere Places](#mehrere-places)
- [Häufige Fragen / Fehler](#häufige-fragen--fehler)
- [Entwicklung](#entwicklung)

---

## Start in 30 Sekunden

1. **ZIP herunterladen:** `Code ▾ → Download ZIP` (oder
   [direkt](https://github.com/mertastudios/ArenaRobloxBridge/archive/refs/heads/main.zip)).
2. **ZIP entsperren (wichtig!):** Rechtsklick auf die heruntergeladene ZIP →
   **Eigenschaften** → unten den Haken bei **„Zulassen“** (engl. „Unblock“)
   setzen → OK. Erst **danach** entpacken. Sonst können Windows/SmartScreen
   Skriptdateien aus dem Internet stumm blockieren.
3. **Entpacken** in einen beliebigen Ordner (z. B. `C:\ArenaRobloxBridge`).
4. **Doppelklick auf `OPEN ME TO START.cmd`** - das ist die einzige Datei im
   Hauptordner und die einzige, die du je anklicken musst. Alles andere liegt
   im Unterordner `bridge`. Es öffnet sich nur das Programmfenster.
   *Klappt der Start nicht, bleibt das Fenster offen und nennt den Grund.*
5. Roblox Studio starten und ein Place öffnen. Das Plugin installiert sich
   automatisch, und das Place erscheint als Zeile im Programmfenster.
6. Den Zugangs-Prompt kopieren (Zeilen-Menü „…“ oder
   Einstellungen → „Key für alle Places“) und dem KI-Agenten geben.

> Wird das Programm ein zweites Mal gestartet, während es schon läuft,
> schließt sich die alte Instanz automatisch und die neue übernimmt - es gibt
> keinen Port-Fehler.

> **Fehlersuche:** Startet das Programm nicht und du willst sehen, was
> passiert, öffne eine Eingabeaufforderung im Programmordner und tippe:
> `"OPEN ME TO START.cmd" /debug` - dann läuft alles sichtbar im Vordergrund
> und das Fenster bleibt am Ende offen. Davon kannst du einen Screenshot
> machen.

## Ordner-Aufbau

Nach dem Entpacken sieht es genau so aus - bewusst minimal:

```
ArenaRobloxBridge\
├── OPEN ME TO START.cmd   <-- NUR das hier doppelklicken
├── README.md
└── bridge\                <-- der ganze Rest, nichts anfassen
    ├── version.json
    ├── CHANGELOG.md
    ├── app\
    │   ├── ArenaBridge.ps1     (das Programm)
    │   └── Start-Bridge.ps1    (Start-Wrapper mit Fehlermeldungen)
    └── docs\
        └── TOOLS.md
```

## Voraussetzungen

- Windows 10/11
- PowerShell 5.1 oder 7 (vorinstalliert; kein zusätzliches Setup)
- Roblox Studio (aktuell, für Play-Tests mit StudioTestService: mindestens die
  Version mit StudioTestService, Dez. 2025)
- Internet (für den Cloudflare-Tunnel)

## Funktionen

| Bereich | Beispiele |
|---|---|
| **Places** | Verbundene Places als Zeilen; pro Place Prompt kopieren, Token zurücksetzen, Lese-/Schreib-Modus; mehrere Places gleichzeitig |
| **Szene** | Baum lesen, suchen, Instanzen anlegen/klonen/löschen/umbenennen/verschieben, Properties lesen/setzen |
| **Skripte** | `get_script` (auch Editor-Quelle, Compile-Status), `set_script_source`, `patch_script` (punktgenaue Edits), `compile_check` ohne Schreiben, große Skripte > 200 KB über ScriptEditorService, `grep_scripts`, `list_scripts` |
| **Testen** | Echter Play-Test (Charakter + GUI + Client), Run-Modus, Pause/Resume, Kamera, Eingaben, Charakter bewegen, GUI klicken/Text setzen |
| **Output** | Studio-Output (Edit + Server + Client) lesen, nach Fehlern filtern, seit einem Zeitpunkt |
| **Werkzeuge** | `run_lua` mit persistenten Globals und Timeouts bis 300 s, Jobs für lange Läufe, Uploads für große Texte, Dokumentation `get_docs` / `GET /api/docs` |
| **Einstellungen** | Aufklappbare Kategorien: Updates, Sonstiges (Autostart, Neustart), Key für alle Places |

Details zu allen Werkzeugen: [bridge/docs/TOOLS.md](bridge/docs/TOOLS.md).

## Auto-Update (GitHub)

- Das Programm liest `version.json` aus diesem Repository (`main`) und prüft
  bei jedem Start (und auf Knopfdruck unter Einstellungen → Updates).
- Ist eine **neuere Version** verfügbar, lädt das Programm das komplette
  Repository im Hintergrund herunter, verifiziert es und zeigt eine
  **Benachrichtigung mit Version + Changelog**.
- Erst der **OK-Klick** aktiviert das Update: ein unsichtbarer Updater-Prozess
  tauscht alle Dateien aus und startet das Programm mit der neuen Version neu.
- Wird das Programm geschlossen, **bevor OK geklickt wurde**, erscheint die
  Benachrichtigung beim nächsten Start wieder - bis sie bestätigt ist.
- Danach arbeitet die KI nur noch in diesem Repository; das Programm
  aktualisiert sich selbst daraus.

## Für KI-Agenten: API-Übersicht

Jeder Zugang besteht aus **URL** (Tunnel) + **Token** (Key). Der Key erreicht
alle verbundenen Places. Endpunkte (alle mit `?token=…` oder `Authorization:
Bearer …`):

| Endpunkt | Zweck |
|---|---|
| `GET /api/places` | Übersicht aller verbundenen Places (placeId, Name, sessionId, Modus) |
| `GET /api/status` | Place-Zustand, Bridge-Version, alle Places, Zugriffsmodus |
| `GET /api/tool?tool=…` + Body | Ein Werkzeug ausführen (`{"tool": "...", "args": {...}}`) |
| `GET /api/tools/parallel` | Mehrere Werkzeuge parallel (`{"calls":[{tool,args},…]}`) |
| `GET /api/docs` | `?tool=`, `?category=`, `?full=1` - Schemas, Parameter, Beispiele |
| `GET /api/events` | Ereignisse (Place geöffnet/geschlossen, Testmodus …) |
| `POST /api/upload` | Große Texte in Stücken hochladen, dann `sourceRef` verwenden |
| `GET /api/blob?id=…` | Große Antworten in Stücken abholen |

**Regeln für Agenten (wichtig!):**

- **Große Skripte:** `Script.Source` hat ein Plugin-Limit (~200 000 Zeichen).
  `set_script_source`, `patch_script` und `insert_script` routen große Quellen
  automatisch über `ScriptEditorService:UpdateSourceAsync`. Über 200 KB ist der
  direkte Weg verboten; Fehlertext enthält „too large“. Absolute Obergrenze:
  8 000 000 Zeichen.
- **Schreiben ist verifiziert:** `applied`, `verified`, `compileOk` sind nur
  wahr, wenn die zurückgelesene Quelle der Zielquelle entspricht **und** sie
  kompiliert. Bei `DRAFT_OPEN` ist ein ungespeicherter Editor-Draft im Weg
  (`force=true` überschreibt ihn). `hash`/`bytes` beziehen sich auf die
  tatsächlich gespeicherte Quelle - nicht auf den Wunschtext.
- **Uploads sind 1-basiert:** erster Chunk `chunkIndex = 1`, letzter
  `chunkIndex = chunkCount`. `complete` ist erst dann `true`. `sourceRef` auf
  einen unfertigen Upload wird mit `UPLOAD_INCOMPLETE` abgelehnt.
- **`run_lua`:** Standard-Timeout 180 s, maximal 300 s. Die globale Umgebung
  ist über Aufrufe hinweg persistent (für Tests gewollt); Aufräumen über
  `run_lua { code = "…Globals löschen…" }` oder einen Undo-Waypoint. Ein
  Timeout ist **kein** Lua-Fehler - der Code läuft in Studio weiter (Ergebnis
  kommt später mit `job_status`/erneutem `get_script`-Lesen).
- **Play-Tests brauchen Fokus:** Studio muss sichtbar/fokussiert sein und darf
  keinen Dialog offen haben. `play_start` wartet 60 s und meldet Diagnose +
  Output, wenn Spieler/Charakter/Client fehlen. Run-Modus hat **keinen**
  Spieler, keine GUI und keinen Client (nur Server-Simulation).
- **GUI/Client:** GUI und PlayerScripts existieren erst im echten Play-Modus.
  `play_start` wartet auf den Client-Agent; GUI-/Client-Abfragen danach
  stellen.
- **Antworten enthalten `_bridge`:** placeId, placeName, sessionId,
  accessMode - damit die KI bei mehreren Places immer weiß, wo sie ist.

## Mehrere Places

- Ein Key erreicht **alle** Places, die gerade in Studio geöffnet und mit dem
 selben Programmfenster verbunden sind.
- `GET /api/places` = die Übersicht (Name, placeId, sessionId, Zugriffsmodus).
- Jeder Tool-Call akzeptiert `args.place` (placeId, placeName oder sessionId).
- Ohne `place` arbeitet ein Tool nur, wenn **genau ein** Place verbunden ist;
  sonst kommt `MULTIPLE_PLACES` mit der Auswahl.

## Häufige Fragen / Fehler

- **„Der lokale Port 17681 ist belegt“:** Eine andere Bridge-Instanz läuft
  bereits - sie wird beim Start normalerweise automatisch übernommen. Wenn die
  Meldung trotzdem erscheint, alte Instanz schließen und neu starten.
- **„Plugin installiert“-Toast erscheint nicht:** Studio neu starten oder den
  Plugin-Ordner prüfen (Studio → Plugins → Arena Roblox Bridge). Das Plugin
  verbindet sich automatisch, sobald ein Place geöffnet ist.
- **Umlaute erscheinen falsch:** Die Datei `bridge/app/ArenaBridge.ps1` muss
  „UTF-8 mit **genau einem** BOM“ sein. Das Programm repariert eine fehlende
  BOM selbst (Marker `äöüßÄÖÜ`), der Starter entfernt zusätzlich doppelte BOMs.
- **Beim Doppelklick passiert nichts (Fenster blitzt nur kurz auf):** Bis
  3.3.1 gab es dafür zwei Ursachen: erst ein dreifaches BOM in
  `ArenaBridge.ps1` (3.3.0), dann ein unerlaubter cmd.exe-Befehl im Starter
  (3.3.1). Beides ist ab 3.3.2 behoben. Sollte trotzdem etwas fehlschlagen,
  zeigt `OPEN ME TO START.cmd` den Grund an und schreibt ihn nach
  `%LOCALAPPDATA%\ArenaRobloxBridge\startup-error.log`. Für die Fehlersuche:
  `"OPEN ME TO START.cmd" /debug` startet alles sichtbar im Vordergrund.
- **„Diese Datei stammt von einem anderen Computer“:** Rechtsklick auf die
  ZIP → Eigenschaften → **„Zulassen“** („Unblock“) setzen, **bevor** du sie
  entpackst. Entpackte VBS-/PowerShell-Dateien aus dem Internet können sonst
  von Windows/SmartScreen blockiert werden.
- **Kein Play-Start:** Studio fokussieren, Dialoge schließen; `play_start`
  Antwort enthält `diagnostics` und `recentErrors`.

## Entwicklung

- Alles Wesentliche steckt in **einer** Datei: `bridge/app/ArenaBridge.ps1`
  (Programm + eingebettetes Studio-Plugin).
- Startkette: `OPEN ME TO START.cmd` → `bridge/app/Start-Bridge.ps1` (prüft
  Voraussetzungen, meldet Fehler im Klartext) → `bridge/app/ArenaBridge.ps1`.
  PowerShell wird vom Starter direkt und versteckt gestartet (kein wscript).
- `bridge/version.json` + `bridge/CHANGELOG.md` steuern das Auto-Update.
- Neue Versionen: Code ändern, `version` in `bridge/app/ArenaBridge.ps1` **und**
  `bridge/version.json` erhöhen, `bridge/CHANGELOG.md` ergänzen, committen und
  nach `main` pushen - das Programm aktualisiert sich danach selbst.
- `.gitattributes` erzwingt CRLF für `.cmd`/`.vbs`/`.ps1`.
- `bridge/docs/TOOLS.md`: Werkzeugreferenz (aus `GET /api/docs?full=1`).

---

_Lizenz: siehe Repository. Dieses Projekt ist nicht mit Roblox Corporation
verbunden._
