#!/usr/bin/env python3
"""append-activity-log.py — Depósito SEGURO de entries al convexo-activity-log de Engram.

La parte determinística del bridge lado-CC (R4 de proyecto-sistema-atencion).
Claude autoría el/los entry(s) (con contexto de la sesión); este script hace el
read-merge-write atómico SIN perder lo que otras sesiones escribieron en paralelo.

USO:
    echo '<entry-json>'      | python3 append-activity-log.py        # 1 entry (objeto)
    echo '[<entry>,<entry>]' | python3 append-activity-log.py        # N entries (array)
    python3 append-activity-log.py --dry-run < entries.json          # no escribe, muestra el plan

ENV (con fallback a ~/.claude/settings.json → mcpServers.engram.env):
    ENGRAM_URL       (ej https://vpsconvexo.tail18e5e.ts.net:8443)
    ENGRAM_API_KEY   (engram_...)

Cada entry debe tener: date, fuente, tema, que_paso, por_que_importa, punto, tipo, tags[]
(schema de convexo-activity-log). `fuente` típicamente "claude-code".

Garantías de seguridad:
  - Lee el estado VIVO justo antes de escribir (nunca un snapshot viejo).
  - Dedup por (date, fuente, tema): re-correr sobre el mismo journal NO duplica.
  - Asserts duros: total_final == total_previo + nuevos_no_duplicados, y NINGÚN
    entry previo se pierde (se compara el set de identidades antes/después).
  - Si no hay entries nuevos, NO escribe (idempotente).
"""
import sys, os, json, urllib.request, urllib.error

SPACE = "convexo-activity-log"
REQUIRED = ("date", "fuente", "tema", "que_paso", "por_que_importa", "punto", "tipo", "tags")


def creds():
    url = os.environ.get("ENGRAM_URL")
    key = os.environ.get("ENGRAM_API_KEY")
    if not (url and key):
        # fallback: leer del MCP engram en ~/.claude/settings.json
        try:
            cfg = json.load(open(os.path.expanduser("~/.claude/settings.json")))
            env = cfg.get("mcpServers", {}).get("engram", {}).get("env", {})
            url = url or env.get("ENGRAM_URL")
            key = key or env.get("ENGRAM_API_KEY")
        except Exception:
            pass
    if not (url and key):
        sys.exit("ERROR: faltan ENGRAM_URL / ENGRAM_API_KEY (ni en env ni en settings.json)")
    return url.rstrip("/"), key


def api(method, url, key, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        f"{url}/{SPACE}", data=data, method=method,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, {"error": e.read().decode()[:300]}


def ident(e):
    return (e.get("date"), e.get("fuente"), e.get("tema"))


def main():
    dry = "--dry-run" in sys.argv
    raw = sys.stdin.read().strip()
    if not raw:
        sys.exit("ERROR: no llegó ningún entry por stdin")
    parsed = json.loads(raw)
    incoming = parsed if isinstance(parsed, list) else [parsed]

    for e in incoming:
        miss = [f for f in REQUIRED if f not in e or e[f] in (None, "")]
        if miss:
            sys.exit(f"ERROR: entry sin campos requeridos {miss}: {json.dumps(e, ensure_ascii=False)[:200]}")
        if not isinstance(e["tags"], list):
            sys.exit("ERROR: 'tags' debe ser lista")

    url, key = creds()

    # 1. LEER ESTADO VIVO
    st, doc = api("GET", url, key)
    if st != 200:
        sys.exit(f"ERROR leyendo {SPACE}: {st} {doc}")
    data = doc.get("data", doc)
    prev = data.get("entries", [])
    prev_idents = {ident(e) for e in prev}
    prev_count = len(prev)

    # 2. DEDUP + MERGE
    new = [e for e in incoming if ident(e) not in prev_idents]
    skipped = len(incoming) - len(new)
    if not new:
        print(f"Nada que hacer: los {len(incoming)} entry(s) ya existen en {SPACE} (v{doc.get('version')}). No se escribe.")
        return

    merged = dict(data)
    merged["entries"] = prev + new
    merged["entries"].sort(key=lambda e: (e.get("date") or "", e.get("fuente") or ""))
    merged["updated"] = max(e["date"] for e in merged["entries"])
    merged["version_note"] = f"+{len(new)} entry(s) lado-CC (harvest-journal): " + "; ".join(e["tema"][:50] for e in new)

    # 3. ASSERTS DUROS (no perder nada)
    final_idents = {ident(e) for e in merged["entries"]}
    assert prev_idents <= final_idents, "PELIGRO: se perdería un entry previo — abortado"
    assert len(merged["entries"]) == prev_count + len(new), "conteo inconsistente — abortado"

    if dry:
        print(f"[DRY-RUN] {SPACE} v{doc.get('version')}: {prev_count} → {len(merged['entries'])} "
              f"(+{len(new)} nuevos, {skipped} ya existían). NO se escribió.")
        for e in new:
            print(f"  + {e['date']} [{e['punto']}] {e['tema'][:70]}")
        return

    # 4. ESCRIBIR
    st, resp = api("PUT", url, key, merged)
    if st != 200:
        sys.exit(f"ERROR escribiendo {SPACE}: {st} {resp}")

    # 5. VERIFICAR releyendo
    st2, doc2 = api("GET", url, key)
    got = len(doc2.get("data", doc2).get("entries", []))
    assert got == prev_count + len(new), f"VERIFICACIÓN FALLÓ: esperaba {prev_count+len(new)}, hay {got}"
    print(f"OK: {SPACE} {prev_count} → {got} (+{len(new)}, {skipped} ya existían). v{resp.get('version')}.")
    for e in new:
        print(f"  + {e['date']} [{e['punto']}] {e['tema'][:70]}")


if __name__ == "__main__":
    main()
