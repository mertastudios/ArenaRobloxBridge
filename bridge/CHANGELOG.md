# Changelog

Alle wesentlichen Aenderungen an **Arena Roblox Bridge**. Das Programm
aktualisiert sich selbst aus diesem Repository (siehe `bridge/version.json` -
die dortige `notes`-Liste erscheint in der Update-Benachrichtigung).

## [3.3.5] - 2026-09-03

### Behoben - Auto-Update fand nie ein Update
- **Symptom:** Die integrierte Update-Suche meldete dauerhaft "Keine Verbindung
  zu GitHub" bzw. zeigte nie eine Update-Benachrichtigung; Updates mussten
  manuell als ZIP von GitHub heruntergeladen werden.
- **Ursache 1 (falsche URL):** `$script:UpdateInfoUrl` zeigte auf
  `.../main/version.json` - die Datei liegt im Repository aber unter
  `bridge/version.json`. GitHub antwortete auf die falsche Adresse mit 404,
  also wurde nie ein Update gefunden.
- **Ursache 2 (falsche Staging-Verifikation):** Nach dem Download des Repo-ZIPs
  wurde `version.json` im Stamm des entpackten Archivs geprueft - im ZIP liegt
  sie unter `bridge\`. Die Verifikung schlug deshalb immer fehl; selbst ein
  erfolgreich heruntergeladenes Update waere nie als gueltig erkannt und
  angewendet worden.
- **Fix:** Update-URL auf `main/bridge/version.json` korrigiert; die
  Verifikation (und der Marker in `Get-StagedVersionDir`) prueft jetzt
  `bridge\version.json` mit Rueckfall auf den Stamm.
- **Kompatibilitaet:** Im Repository-Stamm liegt jetzt eine Kopierversion
  `version.json`. Grund: Bereits installierte 3.3.3-Versionen fragen mit ihrer
  alten (falschen) URL genau diese Stamm-Datei ab - mit der Kopie finden auch
  sie das Update und stagen es erfolgreich (deren Verifikation prueft den
  Stamm, den das ZIP durch die Kopie jetzt ebenfalls enthaelt). Lokal wird die
  Stamm-Kopie nie gelesen (es gilt immer `bridge\version.json`).

### Behoben - Fehler-Toast "... Methode ... NULL" beim Start
- **Symptom:** Kurz nach dem Start erschien der Toast "Fehler abgefangen: Es
  ist nicht moeglich, eine Methode fuer einen Ausdruck aufzurufen, der den
  NULL hat."
- **Ursache:** Der Auto-Update-Start-Timer rief in seinem `Add_Tick`-Handler
  `$delay.Stop()` auf. Lokale Variablen sind in PowerShell-Event-Handlern
  nicht sichtbar (keine Closure) - `$delay` war im Handler NULL, die Zeile
  warf die gemeldete Ausnahme und `Start-AutoUpdateFlow` lief folglich nie.
  Der Code kennt diese Falle (Kommentar bei den Toast-Timern) - vier Stellen
  hatten sie trotzdem missachtet.
- **Fix (4 Stellen):** Auto-Update-Start-Timer, "Jetzt nach Updates suchen"-
  Button und Autostart-Checkbox arbeiten jetzt mit dem Sender (`param($s, $e)`
  bzw. `$s.Tag`), die Update-Benachrichtigung merkt sich das OK auf dem
  Dialog-Fenster selbst (`$dialog.Tag`) statt in einer lokalen Variable. Damit
  laesst sich der Update-Dialog auch erstmals wirklich per OK schliessen und
  das Update anwenden.

## [3.3.4] - 2026-09-03

### Behoben - PowerShell-Fenster blieb trotz 3.3.3 offen
- **Symptom:** Bei einem betroffenen Rechner blieb neben dem Programmfenster
  weiterhin ein leeres PowerShell-Fenster offen (Titelleiste = Dateipfad
  `C:\Windows\System32\...\powershell.exe`); schloss man es, beendete sich auch
  das Programm. Der 3.3.3-Fix (Fenster nur *verstecken*) griff dort nicht.
- **Ursache:** 3.3.3 versteckte das Fenster nur per `ShowWindow(SW_HIDE)` auf
  der eigenen Fensterkennung (`GetConsoleWindow`). Unter Windows 11 mit
  **Windows Terminal als Standardkonsole** gehoert das sichtbare Fenster aber
  `WindowsTerminal.exe`; `ShowWindow` auf der ConPTY-Kennung versteckt es
  nicht. Auch konnte das nur *versteckte* Fenster durch sein Schliessen das
  Programm weiterhin beenden, weil der Prozess weiter an der Konsole hing.
- **Fix:** Neue Funktion `Remove-Console` in `ArenaBridge.ps1` **und**
  `Start-Bridge.ps1`: Das Fenster wird kurz versteckt (SW_HIDE, damit nichts
  aufblitzt) und der Prozess loest sich dann per `FreeConsole()` (kernel32)
  **komplett** von der Konsole. conhost.exe schliesst das Fenster sofort
  (bzw. Windows Terminal schliesst den Tab), und das Schliessen eines
  eventuell verbleibenden Fensters kann das Programm nicht mehr beenden.
  Aufgerufen beim Start und erneut beim Laden der Oberflaeche (`Add_Loaded`).
- **Diagnose-Modus unveraendert:** Nur mit `OPEN ME TO START.cmd` `/debug`
  (`ARENABRIDGE_DEBUG=1`) bleibt die Konsole verbunden und sichtbar.

## [3.3.3] - 2026-09-03

### Behoben - offenes PowerShell-Fenster neben dem Programm
- **Symptom:** Neben dem Programm blieb ein leeres PowerShell-Fenster offen;
  in der Titelleiste stand der Dateipfad `C:\Windows\System32\...\powershell.exe`
  (kein freundlicher Titel). Schloss man dieses Fenster, schloss sich auch das
  Programm - es war also das Konsolenfenster des Programms selbst, das nicht
  versteckt wurde.
- **Ursache:** Das Verstecken hing an der Bedingung, dass an der Konsole GENAU
  EIN Prozess haengt (`GetConsoleProcessList == 1`). Bei Doppelklick ueber die
  `.cmd`, beim Autostart oder nach Neustart/Update haengen jedoch oft mehrere
  Prozesse an derselben Konsole (oder PowerShell beachtet `-WindowStyle Hidden`
  nicht zuverlaessig). Dann griff das Verstecken nie - das Fenster blieb offen.
- **Fix:** `ArenaBridge.ps1` versteckt sein eigenes Konsolenfenster jetzt
  IMMER (Win32 `GetConsoleWindow` + `ShowWindow` SW_HIDE), sobald es existiert -
  unabhaengig davon, wie viele Prozesse daran haengen und wie das Programm
  gestartet wurde. Zusaetzlich wird das Fenster nach dem Laden der Oberflaeche
  noch einmal endgueltig ausgeblendet (doppelte Absicherung gegen das
  Start-Rennen beim Laden).
- **Diagnose-Modus bleibt sichtbar:** `OPEN ME TO START.cmd` setzt beim
  Aufruf mit `/debug` (bzw. `-debug`/`debug`) die Umgebungsvariable
  `ARENABRIDGE_DEBUG=1`. Nur dann bleibt die Konsole sichtbar, damit man bei
  Problemen einen Screenshot vom ganzen Ablauf machen kann. Normaler Start
  setzt diese Variable nicht - das Fenster wird also versteckt.

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
