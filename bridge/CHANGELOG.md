# Changelog

Alle wesentlichen Aenderungen an **Arena Roblox Bridge**. Das Programm
aktualisiert sich selbst aus diesem Repository (siehe `version.json` - die
dortige `notes`-Liste erscheint in der Update-Benachrichtigung).

## [3.3.2] - 2026-09-03

### Behoben - der Starter liess sich weiterhin nicht starten
- **Ungueltige cmd.exe-Syntax in `OPEN ME TO START.cmd`:** Die
  PowerShell-Pruefung stand als mehrzeiliger `if`-Klammerblock direkt hinter
  dem Verkettungsoperator `||` (`where ... || if not exist ... ( ... )`).
  cmd.exe bricht das Skript bei solchen Konstrukten schon beim Parsen ab -
  deshalb blitzte das Fenster nur kurz auf und schloss sich sofort. Der
  Starter wurde komplett neu gebaut: nur einfache Zeilen + `goto`-Labels,
  keine `||`/`&&`-Verkettungen, keine Klammerbloecke hinter Operatoren, kein
  `setlocal EnableDelayedExpansion`.
- **Fenster bleibt bei Fehlern offen:** In jedem Fehlerfall kommt jetzt eine
  Klartext-Meldung + `pause`. Das Fenster schliesst sich NUR, wenn der Start
  geklappt hat.
- **Diagnose-Modus:** `OPEN ME TO START.cmd /debug` (oder `-debug`/`debug`)
  fuehrt alles sichtbar im Vordergrund aus und pausiert am Ende - ideal fuer
  Screenshots bei Problemen.
- **Kaputte Meldung in `ArenaBridge.ps1`:** Eine Meldung enthielt ein
  Apostroph innerhalb eines Apostroph-Textes (`ist 'place' optional`). Der
  Text war dadurch zerbrochen und haette beim Thema "mehrere Places" einen
  Fehler geworfen. Jetzt `ist "place" optional`.

### Startkette vereinfacht (kein VBS mehr)
- Der Zwischenschritt ueber `wscript.exe`/`bridge/app/Start-Bridge.vbs` ist
  entfallen. `OPEN ME TO START.cmd` startet PowerShell jetzt direkt und
  versteckt: `OPEN ME TO START.cmd` -> `bridge/app/Start-Bridge.ps1` ->
  `bridge/app/ArenaBridge.ps1`.
- Grund: Vom Internet geladene VBS-Dateien (Mark of the Web) werden von
  Windows/SmartScreen leicht blockiert - ein stiller Start-Abbrecher. Ohne
  VBS entfaellt dieses Risiko.
- Autostart, Neustart und Auto-Update verwenden denselben direkten Weg
  (PowerShell versteckt, via `Get-LaunchCommand`).

### Dokumentation
- README erklaert jetzt das Entsperren einer GitHub-ZIP (Rechtsklick ->
  Eigenschaften -> "Zulassen") vor dem Entpacken sowie den neuen
  `/debug`-Modus.

## [3.3.1] - 2026-09-03

### Behoben - das Programm liess sich gar nicht starten
- **Dreifaches BOM in `ArenaBridge.ps1`:** Am Dateianfang standen drei
  UTF-8-Byte-Order-Marks hintereinander. PowerShell interpretiert das zweite
  und dritte BOM als Programmtext, bricht mit einem Parser-Fehler ab und
  beendet sich sofort. Weil der Start versteckt lief, sah der Nutzer davon
  nichts: `Start Bridge.vbs` tat scheinbar gar nichts und
  `OPEN ME TO START.cmd` blitzte nur kurz auf. Es gibt jetzt genau **ein** BOM.
- **Selbstheilung:** `Start-Bridge.ps1` prueft vor jedem Start den Dateianfang
  und entfernt ueberzaehlige BOMs automatisch.
- **Keine stillen Abstuerze mehr:** Jeder Startfehler erscheint als
  Meldungsfenster im Klartext und landet zusaetzlich in
  `%LOCALAPPDATA%\ArenaRobloxBridge\startup-error.log`.
- **`OPEN ME TO START.cmd` bleibt bei Fehlern offen** (`pause`) statt sich
  nach einer halben Sekunde zu schliessen. Es prueft ausserdem, ob die
  Programmdateien und PowerShell ueberhaupt vorhanden sind.
- **Syntaxfehler im Auto-Updater:** Im generierten `apply_update.ps1` stand
  `param(...)` hinter einer Anweisung - in PowerShell nicht erlaubt. Updates
  brachen dadurch ab. `param()` steht jetzt an erster Stelle.

### Aufgeraeumter Ordner
- Im **Hauptordner** liegt nur noch `OPEN ME TO START.cmd` (plus `README.md`).
  Der Nutzer sieht sofort, was zu tun ist.
- Alles andere steckt im Unterordner **`bridge`**: `app/`, `docs/`,
  `version.json`, `CHANGELOG.md`.
- `Start Bridge.vbs` ist entfallen; der lautlose Start liegt jetzt als
  `bridge/app/Start-Bridge.vbs` beim Programm und wird vom Starter aufgerufen.
- Auto-Update, Autostart und Neustart kennen den neuen Aufbau und entfernen
  alte Startdateien frueherer Versionen.
- `.gitattributes` erzwingt CRLF-Zeilenenden fuer `.cmd`, `.bat`, `.vbs`
  und `.ps1`, damit die Startdateien unter Windows zuverlaessig laufen.

## [3.3.0] - 2026-09-03

### Fenster & Start
- **Kein Konsolenfenster mehr:** Der Start laeuft ueber `Start Bridge.vbs`
  (Doppelklick) bzw. `OPEN ME TO START.cmd` - PowerShell wird versteckt und
  entkoppelt gestartet. Es existiert nur noch das Programmfenster; ein
  Konsolenfenster kann das Programm nicht mehr beenden.
- **Doppelstart ohne Port-Fehler:** Startet das Programm, waehrend es bereits
  laeuft, schliesst sich die alte Instanz (`/internal/shutdown` mit Handoff),
  die neue uebernimmt Port und Tunnel. Notfalls wird eine haengende alte
  Instanz gezielt beendet (nur wenn es wirklich die Bridge ist).

### Einstellungen (aufklappbare Kategorien, max. eine offen)
- Kategorie **Updates:** Statusanzeige („Kein Update verfügbar - Programm ist
  aktuell und aktualisiert sich automatisch“), installierte Version, Button
  „Jetzt nach Updates suchen“.
- Kategorie **Sonstiges:** Autostart mit Windows (bekannte Checkbox) + Neustart.
- Kategorie **Key für alle Places:** Prompt kopieren (alle Places),
  Key zuruecksetzen (alle Places), Lese-/Schreib-Modus fuer alle Places.
- **Multi-Place-Uebersicht fuer die KI:** `GET /api/places` listet alle
  verbundenen Places (placeId, Name, sessionId, Zugriffsmodus). Jeder
  Tool-Call kann `args.place` (placeId / placeName / sessionId) tragen; bei
  mehreren Places ohne `place` kommt `MULTIPLE_PLACES` mit der Uebersicht.

### Auto-Update (GitHub)
- Das Programm prueft selbst ueber die GitHub-API (`version.json` auf `main`),
  laedt das Repository-ZIP im Hintergrund in einen Staging-Ordner
  (%LOCALAPPDATA%\ArenaRobloxBridge\update_staging), verifiziert die Version
  und tauscht beim Aktivieren alle Dateien (Updater-Prozess, Neustart).
- **Persistente Update-Benachrichtigung:** Modal mit neuer Version + Changelog
  und OK-Button. Erst OK aktiviert das Update (Updater + Neustart). Wird das
  Programm vorher geschlossen, erscheint die Benachrichtigung bei jedem Start
  erneut, bis OK geklickt wurde.

### Play-Test (echt)
- Start ueber **StudioTestService** (`ExecutePlayModeAsync` /
  `ExecuteRunModeAsync`), wenn die Studio-Version es anbietet; Fallback F5/F8
  per VirtualInputManager.
- Wartezeit beim Start 60 s (statt 15 s); bei Fehlschlag Diagnose
  (`blockedByReport`: Modus, Selection, TestService, Spielerzahl) + Hinweis
  auf Fokus/Dialoge + letzte Output-Fehler in der Antwort.
- Echter Play-Modus wartet auf Spieler, Charakter und Client-Agent und meldet
  `play_start` erst dann erfolgreich (mit Character-Infos). Run-Modus meldet
  ausdruecklich, dass es dort keinen Spieler/GUI gibt.
- Stop ebenfalls 60 s + StudioTestService:EndTest, wenn die Sitzung so lief.

### Skript-Writes (P0)
- **>200-KB-Limit:** `writeSource` routet grosse Quellen (ueber 200000 Zeichen)
  automatisch ueber `ScriptEditorService:UpdateSourceAsync`; absolute
  Obergrenze 8 Mio. Zeichen. Fehler sagen klar „too large“ und dass der
  Editor-Weg (UpdateSourceAsync) automatisch genutzt wird.
- **Verifizierte Writes:** `set_script_source`, `patch_script`,
  `insert_script` schreiben ueber `writeSource`: Erfolg nur, wenn die
  zurueckgelesene Quelle == Zielquelle UND die Quelle kompiliert
  (`applied`, `verified`, `compileOk`, `method`, Hash der tatsaechlichen
  Quelle). Bei Abweichung Rueckrollen auf den vorherigen Stand.
- **Drafts:** Offene Editor-Drafts mit abweichendem Text fuehren zu
  `DRAFT_OPEN` (nicht zu stillen Luegen); `force=true` ueberschreibt.
- **compile_check ohne Schreiben:** reine In-Memory-Pruefung
  (`compileSource`, Fallback `compileViaModuleSet`), auch fuer grosse Quellen.
- **Uploads:** `chunkIndex` ist strikt 1-basiert (0 wird explizit abgelehnt),
  `complete` wird erst bei `chunkIndex == chunkCount` wahr, `sourceRef` auf
  unfertige Uploads -> `UPLOAD_INCOMPLETE`.

### Fehlerklarheit, Timeouts, Werkzeuge
- run_lua-Timeouts bis 300 s; Timeout-Antworten unterscheiden Timeout von
  Lua-Fehlern (Stack-Trace) und Plugin-Crashs.
- `get_output` mit `sinceSeq`/`nextSince` (nur neue Zeilen), `filter`,
  `onlyErrors` - Studio-Output als Werkzeug statt „bitte Output melden“.
- `grep_scripts` / `list_scripts` ueber alle Services (Server + Starter-*).
- `get_script` meldet jetzt `bytes`, `hash`, `disabled`, `editorOpen`,
  `draftDirty`, optional `compiled`/`compileError`/`compileLine`; mit
  `editor=true` kommt die ScriptEditorService-Editor-Quelle.
- Jede Antwort enthaelt `_bridge` (placeId, placeName, sessionId, Modus).

### Sonstiges
- Place-Zeilen-Menue („…“) ist jetzt ein Toggle: Klick bei offenem Menue
  schliesst es (350-ms-Sperre gegen die Schluss-Animation); die drei Optionen
  sind unveraendert.
- `Start Bridge.vbs` + `OPEN ME TO START.cmd` ersetzen den bisherigen
  Konsolenstart; Autostart nutzt denselben Weg (wscript).

## [3.2] - Bugfix-Release
1. **Part-Erstellung repariert:** `create_instance`/`bulk_create`/`clone`/
   `fill_region` crashten mit „CanCollide is not a valid member of
   RaycastParams“; alle betroffenen Zuweisungen entfernt.
2. **run_lua/compile_check/Jobs mit `source` repariert:** neuere Studio-
   Versionen haben `load()` aus dem Plugin-Kontext entfernt; robuste
   Fallback-Kette load -> loadstring -> Require-Trick (temporaeres
   ModuleScript mit `local _ENV`), Fehler melden Stack-Traces.
3. **Selektor-Referenzen** (`{ query=… }`, `{ tag=… }`, `{ className=…,
   rootRef=… }`) funktionieren jetzt ueberall, wo refs akzeptiert werden.
4. **bulk_create:** template + count, Grid-Parameter, nameTemplate `{n}`,
   Obergrenze 400 Instanzen pro Call.

## [3.1] - Doku & Jobs
1. Vollautomatische Tool-Dokumentation (bei Bedarf, `get_docs`,
   `/api/docs?tool=…`), Beispielen und Fehlerfaellen.
2. Jobs: `start_job`, `job_status`, `job_result`, `list_jobs`, `cancel_job`;
   jeder Call kann mit `args.asJob=true` in den Hintergrund.

## [3.0] und frueher - Basis
- Erste Version: Bridge zwischen Roblox Studio (Plugin) und lokalem
  PowerShell-Server mit Tunnel; Platz-Zeilen im Fenster, Prompts, Token,
  Lese-/Schreib-Modus, Teil-Erzeugung/-Bearbeitung, GUI-Bedienung, Kamera,
  Charakter, Output-Lesen, Uploads fuer grosse Texte.
