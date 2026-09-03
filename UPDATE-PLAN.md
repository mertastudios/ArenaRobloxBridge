# ArenaRobloxBridge – Umbauplan (Stand: 2026-09-03)

> **Status: Wartet auf die Programm-Dateien.**
> Die im Chat hochgeladenen Dateien sind **nie angekommen** (Workspace + GitHub-Repo geprüft – nur diese README-Struktur vorhanden).
> Verdacht des Nutzers: **Arena-Agent-Bug** – wenn GitHub gleichzeitig verbunden ist UND Dateien hochgeladen werden, kommen die Dateien nie an. Wurde gemeldet, bitte an Arena weitergeben.
>
> **Übergabe an die nächste Session:** Der Nutzer lädt die Programm-Dateien selbst direkt ins GitHub-Repo (Branch `main`). Diese Datei liegt auf dem Branch `arena/01a067c9-arenarobloxbridge` (PR gestellt). Nach dem Upload der Programm-Dateien: PR mergen (oder Branch angeben), dann `UPDATE-PLAN.md` 1:1 am **bestehenden Code** umsetzen – nichts wird neu gebaut.

---

## A. Deine 7 Änderungswünsche

### A1. PowerShell-Fenster verschwinden lassen
- **Problem:** Beim Start öffnet sich ein leeres PowerShell-Konsolefenster + das eigentliche Programm. Das Programmfenster ist vom Konsolenfenster abhängig (Konsole zu → Programm zu).
- **Lösung:**
  - Starter (`Start Bridge.vbs` o. ä.) ruft `powershell.exe` mit `-WindowStyle Hidden` und Fenster-Style 0 auf → **kein sichtbares Konsolenfenster mehr**, nur noch das eigentliche Programmfenster.
  - Der Prozess wird **entkoppelt** gestartet (eigener Prozess, kein Parent-Kind-Verhältnis zur Konsole) → Schließen irgendeines Fensters außer dem Programmfenster beendet das Programm nicht.
  - Fallback prüfen: wenn das bestehende Programm per `.bat`/Verknüpfung startet, wird nur der Startbefehl angepasst, der Rest bleibt unverändert.

### A2. Echter Play-Test mit Charakter, GUI und Client ✅ recherchiert
Roblox hat dafür im **Dezember 2025 den `StudioTestService`** veröffentlicht (Plugin-Security, genau für diesen Zweck):
- `StudioTestService:ExecutePlayModeAsync(args)` → **echter Play Solo** (Server + Client mit Charakter, GUI, PlayerScripts)
- `StudioTestService:ExecuteRunModeAsync(args)` → Run-Modus (nur Server)
- `StudioTestService:ExecuteMultiplayerTestAsync(numPlayers, args)` → bis zu **8 simulierte Clients**
- `StudioTestService:AddPlayers(n)` → Spieler während des Tests hinzufügen
- `StudioTestService:EndTest(result)` → Test beenden, Ergebnis zurück an Plugin
- `StudioTestService:LeaveTest()` / `CanLeaveTest()` → Client-seitig verlassen
- `StudioTestService:GetTestArgs()` → Argumente im Test-Skript lesen
- `StudioTestService.EditModeActive` → Status, ob Edit-Session aktiv ist
- **Umsetzung im Plugin:** Play-Test-Tool bekommt 60 s Timeout, Fokus-Hinweis, Auflistung blockierender Dialoge, Übergabe der Output-Logs. Client-Einblicke über einen vor Teststart injizierten Client-Prob (RunContext=Client): sammelt Client-Output (LogService-History), meldet PlayerGui/Character-Zustand, kann per `HttpService` direkt die lokale Bridge pollen (Studio erlaubt localhost) → Live-Client-Kommandos während des Play-Tests.
- Quelle: devforum.roblox.com/t/introducing-studiotestservice/4116257 + create.roblox.com/docs/reference/engine/classes/StudioTestService

### A3. Einstellungen: aufklappbare Kategorien (max. eine gleichzeitig offen)
- **Kategorie „Updates“:** Anzeige „Kein Update verfügbar – das Programm ist auf dem neuesten Stand und aktualisiert sich automatisch.“ (+ Versionsnummer, „Jetzt prüfen“-Button)
- **Kategorie „Sonstiges“:** Neustart-Button (Programm schließt und öffnet automatisch wieder) + **Autostart mit Windows** (bekannte Einstellung, wandert in diese Kategorie)
- **Kategorie „Key für alle Places“:**
  - Prompt kopieren (der Arena-AI-Zugriffsprompt)
  - Key zurücksetzen
  - Lese-/Schreib-Modus einstellen
  - **Multi-Place-Übersicht für Arena AI:** neuer Endpunkt `GET /places` → listet alle verbundenen Places mit Name, PlaceId, Zugriff (Key/Modus), Play/Edit-Status, damit die AI bei Zugriff auf mehrere Places immer Überblick hat und gezielt `place` als Parameter angeben kann
- **Accordion-Logik:** genau eine Kategorie darf offen sein; Klick auf andere Kategorie schließt die vorherige (Animation deaktiviert oder sauber getoggelt)

### A4. GitHub: Projekt ins Repo, Download-and-Run, Auto-Update
- Gesamtes überarbeitetes Projekt wird ins Repo `mertastudios/ArenaRobloxBridge` gepusht (Branch `main` + Session-Branch).
- **Repo-Zip → entpacken → Doppelklick = lauffähig** (Starter aus A1).
- **Auto-Update über die GitHub-API:**
  - `version.json` im Repo (aktuelle Version); Programm prüft bei Start + zyklisch (`api.github.com/repos/mertastudios/ArenaRobloxBridge`)
  - Bei neuer Version: lädt alle geänderten Dateien im Hintergrund herunter (in Staging-Ordner), tauscht sie beim Neustart/start des Programms aus (Updater-Prozess, der das Programm kurz beendet, Dateien tauscht und neu startet)
  - **Persistente Update-Notification:** Popup mit neuer Version + Changelog (was wurde geändert) + **OK-Button**. OK wird in den lokalen Einstellungen gespeichert. Wird nicht auf OK geklickt (Fenster geschlossen, Programm beendet), erscheint die Notification **beim nächsten Start wieder** – erst OK-Klick quittiert endgültig („Nutzer hat das Update bemerkt“).
  - Danach arbeite ich (Arena AI) **nur noch im Repo** – das Programm aktualisiert sich selbst von dort.

### A5. Kein Port-Fehler bei bereits geöffnetem Programm
- Neue Instanz erkennt laufende Instanz (IPC über festen Localhost-Port/Mutex) → schickt „Shutdown & Übergabe“ an die alte Instanz → **altes Fenster schließt sich, neue Instanz übernimmt Port/Tunnel** sauber → kein Portfehler.

### A6. Place-Liste „…“-Menü: Toggle statt Neu-Öffnen
- Klick auf „…“ bei geöffnetem Optionsmenü **schließt** das Menü; nur bei geschlossenem Menü öffnet es sich (keine erneute Öffnen-Animation). Die 3 Optionen selbst bleiben unverändert.

---

## B. Alle Schwachstellen-Fixes (Arena-AI-Testbericht)

### P0 – kritisch
| # | Problem | Fix |
|---|---------|-----|
| P0.1 | `set_script_source`/`patch_script`/`compile_check` sterben bei >200 k Zeichen (Plugin-Limit `Script.Source`) | Große Writes **immer** über `ScriptEditorService:UpdateSourceAsync`, nie `Script.Source`; Tools routen die Größe intern und dokumentieren das Limit in der Antwort |
| P0.2 | `patch_script` meldet „Success“, obwohl Draft/Editor noch alt ist und Compile scheitert | Nach **jedem** Write: Editor-Source zurücklesen + `loadstring`-Compile-Check + Hash der **tatsächlichen** Source. Success nur wenn: Editor-Source == Zielsource UND Compile ok. Antwort enthält `applied`, `verified`, `compileError`, `hash`, `bytes` |
| P0.3 | Upload `chunkIndex` 1-basiert, 0-basiert wird geschluckt → Upload schließt nie → „Compile error: nil“ | Strikte Validierung: `chunkIndex` muss ≥ 1 sein, 0 wird **explizit abgelehnt**; `complete:false` explizit; kein `sourceRef` auf unfertige Uploads |
| P0.4 | Undurchsichtige Fehler | Klare Fehlertexte mit Code: `TOO_LARGE (>200000 Zeichen, UpdateSourceAsync wird automatisch genutzt/empfohlen)`, `DRAFT_OPEN`, `COMPILE_ERROR (Zeile N)`, `TIMEOUT (180 s) vs LUA_ERROR vs PLUGIN_OFFLINE` |

### P1 – wichtig
| # | Problem | Fix |
|---|---------|-----|
| P1.1 | `compile_check` schreibt Source | Compile-Check **ohne Schreiben** (in-memory `loadstring`), auch für große Scripts |
| P1.2 | `run_lua` Timeout 60 s zu kurz; keine Unterscheidung Timeout/Lua-Error/Crash; persistente Globals | Timeout konfigurierbar **180–300 s**, Streaming/Heartbeat für lange Läufe, optionale Sandbox (`setfenv`/eigene Umgebung), optionales Auto-Undo (Waypoint), Fehlercode klassifiziert |
| P1.3 | Play-Start 15 s zu knapp, kein „was blockiert?“ | 60 s Timeout, Fokus-Hinweis, Liste offener Dialoge/Modals/Selection/ActiveScript/TestService-State, Output-Log in der Antwort |
| P1.4 | Kein Client-Kontext | `client_run_lua` (Play-Session) + Client-Output-Capture + PlayerGui/Character-Inspektion über injizierten Client-Prob (siehe A2) |
| P1.5 | Kein Tool-Katalog | `GET /tools` mit JSON-Schema aller Argumente, Limits (200 k, Chunk-Größe), Beispielen |

### P2 – Ausbau
| # | Problem | Fix |
|---|---------|-----|
| P2.1 | Tunnel ohne feste Domain → Session tot | Tunnel-Watchdog (autom. Reconnect, Statusanzeige, neue URL im Programm + aktualisierter Prompt), lokal direkte Verbindung bevorzugt |
| P2.2 | Place-Scope: nur der offene Place | Multi-Place: mehrere Studio-Instanugen verbinden sich; Tools akzeptieren `place`-Parameter; `GET /places`-Übersicht (siehe A3); „kopiere Script X → Place Y“-Tool |
| P2.3 | Fehlende Helper | `grep_scripts`, `list_scripts`, Diff-Patch mit Kontext (größenfest), `get_output` (Studio-Output seit Timestamp) |

### Agent-DX (Anforderungsliste des Callers)
1. ✅ Write-Tool routet Größe intern (P0.1)
2. ✅ `get_script({path|id, editor=true})` → `source, bytes, hash, disabled, compiled, openInEditor`
3. ✅ Kein stilles OK: jede Mutation antwortet mit `applied, verified, compileError`
4. ✅ Logs als Tool: `get_output` seit Timestamp
5. ✅ Helper mit harten Checks: Chunk-Doku, `ok && complete` Pflicht, Token nur aus Env/Einstellungen (nicht hardcoded)
6. ✅ Doku im Repo: Tool-Liste, 200k-Limit, 1-based Chunks, Play braucht ggf. Fokus, `run_lua` persistiert Globals

---

## C. Recherche-Ergebnisse (für die Umsetzung)

- **StudioTestService** (Dez 2025, Plugin-Security):
  - `ExecutePlayModeAsync(args)` / `ExecuteRunModeAsync(args)` / `ExecuteMultiplayerTestAsync(numPlayers≤8, args)` (yield bis `EndTest`)
  - `GetTestArgs()` im Test-Skript, `EndTest(result)` vom Server, `LeaveTest()`/`CanLeaveTest()` vom Client, `AddPlayers(n)` vom Server
  - `EditModeActive` (Property) = true wenn keine Test-Session läuft
  - Limitationen: nur aus Plugins; eine Multiplayer-Session pro Studio; max 8 Clients; bekannter Bug bei `GetTestArgs` im Client-LocalScript
  - Doku: create.roblox.com/docs/reference/engine/classes/StudioTestService
- **ScriptEditorService:UpdateSourceAsync(script, source)** für große Quellen (>200 k) statt `Script.Source`.
- **Studio MCP** existiert offiziell (start_stop_play) – bleibt irrelevant, da eigene Bridge mehr kann (multi-client, args).
- **VirtualInput** für Maus/Tastatur-Simulation im Play-Test existiert; Stand „funktioniert teils nicht zur Laufzeit“ – optionaler späterer Ausbau, kein Blocker.

## D. Repo-Zielstruktur (nach Umbau, final mit echten Dateien)

```
/                          ← GitHub „Code → Download ZIP“ → entpacken → Doppelklick = läuft
├── Start Bridge.vbs       ← Starter ohne Konsolenfenster (A1)
├── (bestehende Programmdateien, überarbeitet)
├── version.json           ← Auto-Update-Marker (A4)
├── CHANGELOG.md           ← Changelog für die Update-Notification (A4)
├── docs/TOOLS.md          ← Tool-Katalog + Limits + Beispiele (Agent-DX 6)
└── .gitignore             ← lokale Daten (Einstellungen/Keys) ausschließen
```
