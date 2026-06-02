# 2026-06-02 — Repaso de Engram → cierre de C1 (la ceguera de Engram)

## Contexto
Arrancó como un "repasá este proyecto" sobre Engram y derivó en algo mucho más grande:
analizar todo el corpus de Engram para sacar insights, y de ahí atacar el hallazgo #1
(la "ceguera de Engram": el sistema solo veía el chat, no el trabajo en Claude Code).

## Lo que pasó
El arco tuvo tres tramos. **(1) Higiene del repo engram:** estaba en estado corrupto por
sync (filemode noise, ramas `main(1)/main(2)` duplicadas, archivos `(1)` de conflicto). El
`main` local estaba 2 commits atrasado del trabajo real de abril (OAuth fixes + migración del
MCP público a nginx/engram.convexo.tech). Recuperado con un susto: un `merge --ff-only` falló
por el filemode noise pero el `set -e` no cortó y el script borró `main(2)`; el commit seguía
vivo como dangling y lo recuperé. Después: versioné `engram.conf`, arreglé el path del MCP
stdio en settings.json (apuntaba a `/Volumes/E001` desmontado — fantasma recurrente de toda
la sesión).

**(2) Análisis:** decidimos volcado-a-disco + CC sobre el connector para análisis exhaustivo.
Pull de un snapshot SQLite consistente del VPS → leí los 22 espacios + métricas de uso →
`INFORME-01`. Seis insights; C1 (ceguera) como el dominante.

**(3) Cierre de C1:** cuantifiqué la ceguera (68% del trabajo reciente invisible) y encontré
que el `registro-atencion.yaml` —pieza load-bearing del sistema de atención— nunca se había
guardado a disco y se perdió con E001: él mismo una baja de C1. Lo reconstruí desde el dump,
refiné 34 journals de close-session y los backfilleé al `convexo-activity-log`, y construí el
skill **`harvest-journal`** (el bridge lado-CC, R4 de proyecto-sistema-atencion) para que el
depósito sea automático de ahora en más.

## Decisiones
- **El registro va en `calibrate/sistema-atencion/`, no en `infra`.** El dump decía infra, pero
  Andrés frenó: infra es monitoreo de servidores. El reconciliador (R1/R4) es skill de Calibrate,
  así que el registro —su dato— vive con él.
- **Refinar los entries del backfill (no extracción mecánica).** El `por_que_importa` es la señal
  que lee el reconciliador; vale escribirlo con calidad.
- **Read-fresh-merge-write, nunca sobre snapshot viejo.** Load-bearing: el activity-log vivo tenía
  19 entries (no las 13 de mi dump) — 6 nuevas de sesiones paralelas de Andrés. Mergear sobre el
  dump las habría borrado.
- **`harvest-journal` = autoría agéntica + script determinístico (BAA).** Claude escribe el entry
  (tiene contexto); el script hace el read-merge-write seguro con dedup + asserts. La parte
  peligrosa nunca a mano.

## Deferred / Bloqueado
- **Registro v0→v1** — 4 puntos de juicio pendientes de autorización de Andrés (fantasmas
  garrapata/trini/shadowbot; canasta/lvtgrp/infra ¿punto o exclusión?; panel-instagram; kgis).
- **Borrar `analysis/raw/engram-snapshot-*.db`** — tiene tokens OAuth (system-oauth); ya cumplió
  su función con el backfill. Pendiente borrarlo.
- **Cron de renovación de certs Let's Encrypt** — garrapata vence 13-jun, engram 27-jul. Andrés
  abre otra sesión para validar (cree que ya está hecho).

## Patrones observados
- **La vigilancia de Andrés atrapó el riesgo exacto.** Su "ojo ojo ojo con no perder lo nuevo"
  apuntó justo al concurrent-write; el protocolo read-fresh se validó en vivo (otra sesión
  escribió en v21 mientras probaba el skill).
- **Default-correction, otra vez.** Andrés corrigió mi anclaje en el dump (registro→infra) con un
  argumento fuerte, no una preferencia. Tratar sus pushbacks como señal de framing mal.
- **El fantasma de E001 recorrió toda la sesión:** settings.json roto, .mcp.json del proyecto,
  el registro perdido, KGIS varado. Mismo disco, mismo síndrome que C1 a otra escala.

## Para próxima sesión
1. Validar el cron de certs (Andrés lo está chequeando en otra sesión).
2. Cuando Andrés autorice: subir el registro a v1 y commitear.
3. Borrar el snapshot con tokens de `analysis/raw/`.
