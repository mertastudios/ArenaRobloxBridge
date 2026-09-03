# Werkzeug-Referenz (Tools) — Arena Roblox Bridge

Die vollständige, maschinenlesbare Doku liefert das Programm selbst:
`get_docs` als Tool, `GET /api/docs?tool=…`, `GET /api/docs?category=…` und
`GET /api/docs?full=1`. Dieses Dokument fasst die wichtigsten Verträge
zusammen, die ein Agent kennen muss.

## Antwort-Format

Jede Tool-Antwort hat die Form:

```json
{
  "ok": true,
  "result": { ... },
  "warnings": [ ... ],
  "_bridge": { "placeId": 123, "placeName": "...", "sessionId": "...", "accessMode": "readwrite" }
}
```

Fehler: `{ "ok": false, "code": "FEHLERCODE", "error": "...", ... }`.
Wichtige Codes: `TOO_LARGE`, `DRAFT_OPEN`, `WRITE_UNVERIFIED`,
`WRITE_FAILED`, `COMPILE_ERROR` (mit `line`), `COMPILER_UNAVAILABLE`,
`UPLOAD_INCOMPLETE`, `UNKNOWN_UPLOAD`, `READONLY_TOKEN`, `MULTIPLE_PLACES`,
`PLACE_NOT_FOUND`, `BAD_ARGS`, `NOT_FOUND`, `NO_ACCESS`.

Jede Antwort enthält `_bridge` mit placeId/placeName/sessionId/accessMode.

## Referenzen (ref / path)

- `path`: Roblox-Pfad ab `game`, z. B. `game.ServerScriptService.Foo.Server`.
- `ref`: entweder `{ path = "…" }`, `{ id = "#42" }` (Instanz-Id des Places;
  ids sind pro Place stabil), `{ name = "…" }` (erste Fundstelle) oder
  Selektor `{ query = "…" }` / `{ tag = "…" }` / `{ className = "…",
  rootRef = "…" }`.
- Mit mehreren Places: zusätzlich `args.place` = placeId / placeName /
  sessionId (siehe `GET /api/places`). Ohne `place` nur bei genau EINEM
  verbundenen Place.

## Kategorien

### info / Struktur
- `get_place_info` (alias `bridge_info`): Name, placeId, pluginVersion,
  state (edit/run/play), capabilities.
- `get_tree { ref, depth, includeProperties }`, `get_children`,
  `get_instance { ref, includeSource }`, `get_properties { ref }`,
  `search { query }`, `resolve_ref`, `get_selection`, `select_instance`.

### Skripte (wichtigste Verträge)
- `get_script { ref | path, editor?, checkCompile? }` →
  `{ source, bytes, hash, disabled, lines, editorOpen, draftDirty, editorSource?,
  compiled?, compileError?, compileLine? }`. Mit `editor=true` wird die
  ScriptEditorService-Editor-Quelle zurückgegeben (entspricht dem, was Studio
  wirklich anzeigt - inkl. ungespeicherter Drafts).
- `set_script_source { ref | path, source, expectHash?, force? }` → schreibt
  und **verifiziert**. Erfolg bedeutet: zurückgelesene Quelle == `source` UND
  Compile ok. Antwort: `{ applied, verified, compileOk, method, id, path,
  bytes, lines, previousBytes, hash }`. `method` = `direct` oder
  `ScriptEditorService`. `hash` = Hash der **tatsächlichen** Quelle.
- `patch_script { ref | path, edits, expectHash?, dryRun?, force? }` mit
  Edits `{ op = "replace" | "insertBefore" | "insertAfter" | "delete",
  find?, replace?, index?, line?, ... }` → wie oben plus `operations`,
  `oldLines`, `newLines`, `lineDelta`, `preview`.
- `insert_script { parentRef | parentPath, name?, className?, source?,
  properties? }`, `bulk_insert_scripts`.
- `compile_check { source }` — **schreibt nichts**, prüft nur Syntax
  (in-memory; große Quellen über den Editor-Weg). Antwort `{ compiles,
  checked = "syntax only - the code was NOT executed", bytes }` oder
  `COMPILE_ERROR` mit `line`.
- `grep_scripts { query | pattern, regex?, ignoreCase?, roots?, limit?,
  contextLines?, depth? }`, `list_scripts { roots?, limit?, depth? }`.

**200-KB-Limit:** `Script.Source` (direkte Zuweisung) ist auf ~200 000 Zeichen
begrenzt. Die Bridge routet darüber liegende Quellen automatisch über
`ScriptEditorService:UpdateSourceAsync` (Obergrenze 8 Mio. Zeichen). Eine
Zuweisung über dem Limit schlägt mit klarem `TOO_LARGE` fehl - niemals
opak. Da der Editor-Weg nur für Instanzen im Datenmodell funktioniert, sollten
neu erstellte Skripte zuerst geparentet und geöffnet werden.

**Drafts:** Ist im Skript-Editor ein ungespeicherter Draft geöffnet, der von
der gespeicherten Quelle abweicht, meldet der Write `DRAFT_OPEN` statt still
die veraltete Quelle zu bestätigen. `force=true` überschreibt den Draft.

### Upload (große Texte)
`POST /api/upload` mit `{ token, text, uploadId?, chunkIndex?, chunkCount? }`
- **`chunkIndex` ist 1-basiert.** 0/negativ → expliziter Fehler.
- Erst `chunkIndex == chunkCount` setzt `complete = true`.
- `sourceRef = uploadId` an `set_script_source`/`insert_script`/`run_lua`/
  `compile_check`/`patch_script` ist nur nach `complete` erlaubt
  (sonst `UPLOAD_INCOMPLETE`).
- Beispiel 3 Chunks: `chunkIndex` 1, 2, 3 (gleiche `uploadId`), danach
  `set_script_source { path = …, sourceRef = "myScript" }`.

### Instanzen & Szene
`create_instance { className, name?, parentPath?, properties? }`,
`bulk_create`, `clone_instance`, `delete_instance`, `bulk_delete`,
`rename_instance`, `move_instance`, `set_property`, `set_properties`,
`bulk_set_properties`, `set_attribute`, Gruppen/Tags, Solid-Modeling
(`union`, `subtract`, `negate`, `intersect`, `separate`), Ausrichtung
(`place_on`, `align`, `stack`, `grid_arrange`, `distribute`,
`snap_to_ground`, `look_at`, `rotate_around`, `move_relative`, `resize_part`,
`fit_between`, `point_at`), `raycast`, `parts_in_box`, `parts_in_sphere`,
`nearest_parts`, `what_is_in_the_way`, Messen (`measure`, `measure_height`,
`ground_height`, `raycast_many`, `verify_measurable`).

### Play / Client
- `play_start { mode = "play" | "run" }` — **echter Play-Modus** wartet auf
  Spieler + Charakter + Client-Agent (bis 60 s) und liefert
  `playerReady`, `character`, `clientAgent`. Fehler enthalten `diagnostics`
  (was könnte blockieren) und `recentErrors`. Play braucht **Studio-Fokus**
  und keine offenen Dialoge.
- `play_stop`, `play_pause`, `play_resume`, `send_input`, `gui_click`,
  `gui_set_text`, `move_character`, `set_camera` usw. (Client-Werkzeuge
  funktionieren nur im echten Play-Modus mit Charakter/GUI).
- Run-Modus = Server-Simulation ohne Spieler/GUI/Client (Antwort sagt das
  explizit).
- `wait { seconds }` — im Place warten, Output wird mitgelesen.

### Output / Fehler
- `get_output { limit?, sinceSeq?, onlyErrors?, filter?, regex? }` →
  `{ lines, returned, matched, cursorSeq, nextSince, errorCount,
  warningCount }`. Für „nur neue Zeilen“: beim nächsten Aufruf
  `sinceSeq = nextSince` setzen.
- `get_errors`, `clear_output`.

### Ausführen
- `run_lua { code, timeoutSeconds? (bis 300), sandbox? , undo? }` —
  führt Code im Studio-Plugin aus. **Globals sind persistent** (für Tests
  gewollt); isolieren durch eigene Namen/`_ENV`, aufräumen per Code oder
  Undo-Waypoint. Antwort unterscheidet: Erfolg / `LUA_ERROR` (mit
  Stack-Trace) / `TIMEOUT` (Code läuft in Studio weiter!) / Verbindungsfehler.
- `batch`, `parallel` (auch als HTTP `POST /api/tools/parallel`),
  Jobs: `start_job`, `job_status`, `job_result`, `list_jobs`, `cancel_job`;
  jeder Call akzeptiert `args.asJob = true`.
- `get_docs { tool? | category? | full? }`.

## HTTP-Endpunkte (Zusammenfassung)

Siehe README. Alle Antworten enthalten `_bridge`. `GET /api/places` ist die
Multi-Place-Übersicht; `place`-Auswahl über `args.place`/`?place=`/Body.

## Grenzen, die man kennen muss

| Grenze | Wert |
|---|---|
| `Script.Source` direkt | 200 000 Zeichen (darüber: UpdateSourceAsync, automatisch) |
| Absolute Skript-Obergrenze | 8 000 000 Zeichen |
| Upload-Chunks | 1-basiert, `complete` erst beim letzten Chunk |
| run_lua-Timeout | Standard 180 s, max. 300 s |
| Play-Start-Wartezeit | 60 s (danach Diagnose) |
| Antwort-Größe | große Antworten werden als `blob`/Chunks geliefert |
| Selektor-Treffer | max. 500 pro Expansion |

## Verhaltensregeln für Agenten

1. **Kein „still ok“:** `ok:true` mit `applied`/`verified` ist eine harte
   Zusage (Quelle == Ziel UND Compile ok). Bei jedem `WRITE_UNVERIFIED` ist
   der alte Stand bereits wiederhergestellt - erneut mit `get_script
   (editor=true)` prüfen.
2. **Fehlertexte sind Handlungsanweisungen:** `howToFix`/`fix` in der Antwort
   befolgen, nicht raten.
3. **Play braucht Fokus und Zeit** - nicht sofort abbrechen; `diagnostics`
   und `recentErrors` auswerten.
4. **Globals aus run_lua sind persistent** - dokumentieren, nicht
   verlassen; bei Unsicherheit Umgebung zurücksetzen.
5. Bei **mehreren Places** immer `place` angeben oder erst `GET /api/places`
   konsultieren.
