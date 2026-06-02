---
name: harvest-journal
description: Depositar el journal de la sesión de Claude Code en el convexo-activity-log de Engram, cerrando la "ceguera de Engram" (el sistema solo veía el chat, no el trabajo en CC). Use al final de una sesión productiva — normalmente lo invoca close-session automáticamente, o el usuario con "harvesteá la sesión" / "mandá esto al activity-log". Es el bridge lado-CC (R4) de proyecto-sistema-atencion.
allowed-tools: Bash, Read
---

# harvest-journal

El bridge lado-Claude-Code del sistema de atención: toma el journal recién escrito
y deposita un entry equivalente en `convexo-activity-log` (Engram). Sin esto, el
trabajo en CC es invisible para el reconciliador (la "ceguera de Engram", C1).

**Responsabilidad única.** `close-session` escribe el journal; `harvest-journal`
lo deposita. No re-narra, no decide cierre — solo traslada la señal a Engram.

## Filosofía: BAA (separación de responsabilidades)

- **Vos (Claude)** autoría el entry — tenés el contexto de la sesión, escribís un
  `por_que_importa` pensado (no extracción mecánica). Esto es el juicio agéntico.
- **El script `append-activity-log.py`** hace el read-merge-write seguro a Engram.
  Esto es la parte determinística. **NUNCA hagas el write a mano** — el script
  lee el estado vivo, dedupea y tiene asserts que evitan pisar lo que otras
  sesiones escribieron en paralelo (lección load-bearing).

## Cuándo se dispara

- Automático: como último paso de `close-session`, si se escribió un journal.
- Manual: "harvesteá la sesión", "mandá el cierre al activity-log".
- Salteable: si la sesión no tuvo journal (trivial), no hay nada que harvestear.

## Flujo

### 1. Identificar el journal a depositar
El que `close-session` acaba de escribir: `<repo>/.journal/YYYY-MM-DD-<tema>.md`
(el más reciente). Si te pasan un path explícito, usá ese. Leelo completo.

### 2. Resolver el `punto` de atención
Mapear el repo actual → punto, usando `references/repo-punto.md` (derivado del
`registro-atencion.yaml`). Si el repo no está mapeado, usá el nombre del repo y
avisá que falta en el registro.

### 3. Autorar el entry (schema del activity-log)
Construir UN objeto JSON con TODOS estos campos:
- `date` — fecha del journal (YYYY-MM-DD).
- `fuente` — **`"claude-code"`** (siempre, es lo que distingue del chat).
- `tema` — título humano del journal + sufijo del punto, ej `"...(Genexa)"`.
- `que_paso` — 2-4 oraciones: el arco + las decisiones cargadas. Sintetizá las
  secciones "Lo que pasó" + "Decisiones" del journal. No copies literal.
- `por_que_importa` — **lo más valioso**: 1-3 oraciones de significancia real.
  Salir de "Patrones observados" / el insight de fondo. Es la señal que lee el
  reconciliador; escribilo con calidad, no resumas mecánicamente.
- `punto` — el del paso 2.
- `tipo` — una de: `tiron` (trabajo de proyecto que avanzó) / `esta-bien`
  (rutina sana sin hallazgo) / `necesaria` (meta/relacional) / `emergente`
  (nació algo nuevo: un método, tool, fix estructural).
- `tags` — lista; incluir siempre `"claude-code"` + el repo + 2-4 temáticos.

### 4. Depositar con el script (la parte segura)
```bash
echo '<entry-json-en-una-linea>' | \
  python3 <skill-dir>/append-activity-log.py
```
- Probá primero con `--dry-run` si querés ver el plan sin escribir.
- El script toma `ENGRAM_URL`/`ENGRAM_API_KEY` del env, o los lee de
  `~/.claude/settings.json` (mcpServers.engram.env) automáticamente.
- Es idempotente: re-correr sobre el mismo journal no duplica (dedup por date+fuente+tema).

### 5. Reportar
Una línea: qué entry se depositó y el conteo nuevo del activity-log (el script lo imprime).

## Backfill (varios journals de una)
Para depositar journals históricos, pasar un **array** de entries al script:
```bash
echo '[<entry1>,<entry2>,...]' | python3 <skill-dir>/append-activity-log.py
```
Mismos asserts y dedup. Útil al adoptar el bridge en un repo con journals viejos.

## Qué NO hacer
- NO escribir a Engram con `engram_write` / curl PUT a mano (te saltás los asserts).
- NO depositar sin journal (la fuente de verdad del entry es el journal).
- NO inventar `por_que_importa` — si el journal no dice por qué importó, es señal
  de que el journal quedó pobre; mejorá el journal primero.
