---
name: close-session
description: Cerrar sesión escribiendo un journal entry estructurado en `.journal/` del proyecto + actualizando el handoff vivo en `.serena/memories/pending-work-actual.md`. Use cuando el usuario diga "cerremos la sesión", "guardá el cierre", "armemos el journal del día", o al final de una sesión productiva antes de que el contexto se enfríe. Captura decisiones con razón, deferrals, bloqueos vivos y patrones de colaboración — NO re-narra commits (eso está en git log).
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# close-session

Generate a session journal entry that captures the *meta* of how we worked — not what we did (git log already has that).

## Cuándo usarse

El usuario invoca al final de una sesión de trabajo, típicamente con frases como:
- "cerremos la sesión"
- "guardá el cierre"
- "armemos el journal"
- "antes de cortar, dejá registro de hoy"

Si la sesión fue trivial (≤2 mensajes, sin commits, sin decisiones), avisarle al usuario y preguntar si igual quiere journal. Default: no escribir nada.

## Filosofía

**Journal ≠ memoria activa.** No es para que la próxima sesión arranque más rápido — para eso está `pending-work-actual.md`. El journal es para metacognición: leerlo en 3 meses y entender por qué tomamos ciertas decisiones, dónde nos trabamos, qué patrones se repitieron.

**Lo que importa preservar:**
- Decisiones con razón (no solo el outcome)
- Cosas pospuestas y por qué
- Bloqueos externos (terceros, esperas, info faltante)
- Feedback del usuario que modificó nuestro approach
- Patrones de colaboración observados (sucesos meta)

**Lo que NO va al journal:**
- Working tree status / archivos modificados (irrelevante después)
- "Cómo retomar: docker start, npm run dev" (eso está en CLAUDE.md/README)
- Re-narrativa de cada commit (eso está en `git log`)
- Cosas obvias del proyecto (la próxima sesión lee el código)

## Flujo

### 1. Determinar fecha y tema

- Fecha: `date +%Y-%m-%d` (o usar la del system reminder si está disponible).
- Tema: identificar el hilo dominante de la sesión leyendo la conversación. Si fue multi-tema, elegir el más sustantivo. Ejemplos:
  - `2026-05-13-cleanup-memorias-y-skill-cierre.md`
  - `2026-05-07-pr2-amplification.md`
  - `2026-05-10-skill-demo-screencast.md`
- Slug en kebab-case, máximo ~50 caracteres.

### 2. Recopilar material

Correr en paralelo:
- `git log --oneline <since>..HEAD` — donde `<since>` es la fecha del último journal entry o HEAD~10 si no hay journal previo.
- `git diff --stat <since>..HEAD` — para sentido de magnitud.
- Revisar la conversación buscando:
  - Decisiones explícitas ("decidimos X porque Y")
  - Deferrals ("luego", "después", "lo dejamos para", "postergamos")
  - Bloqueos ("esperamos respuesta de", "no podemos hasta que")
  - Feedback del usuario que cambió tu rumbo (corrección, redirect)
  - Pushbacks del usuario ("no me convence", "mejor así")

### 3. Pedir aclaración solo si es ambiguo

Máximo 1-2 preguntas, solo si genuinamente no podés inferir:
- "¿Esto fue decisión firme o tentativa que vamos a revisar?"
- "¿El bloqueo es por terceros o por scope tuyo?"

Si todo es claro del contexto, NO preguntar — escribir directo.

### 4. Escribir `.journal/YYYY-MM-DD-tema.md`

Usar `templates/journal-entry.md` como base. Estructura:

```markdown
# YYYY-MM-DD — Título humano (1 línea)

## Contexto
1-2 oraciones: de dónde venimos, qué disparó esta sesión.

## Lo que pasó
Prosa, no bullets de commits. Foco en el *arco*: cómo evolucionó el pensamiento, qué intentamos primero, qué redirigió.

## Decisiones
- **Decisión X.** Razón. (No solo el qué, también el por qué.)
- **Decisión Y.** Razón.

## Deferred / Bloqueado
- **Item Z** — diferido porque... (esperando respuesta de X / scope para otra sesión / etc.)

## Patrones observados (opcional)
Meta-observaciones sobre cómo se dio la sesión. Solo si emergió algo notable — no forzar.

## Para próxima sesión
1-3 bullets máximo. Lo que conviene retomar primero. SI hay más, va a `pending-work-actual.md`, no acá.
```

Largo objetivo: **30-80 líneas**. Si pasa de 100, recortar — probablemente entró info que pertenece a otro lado.

### 5. Actualizar `.serena/memories/pending-work-actual.md`

Este es el handoff vivo. Reglas:
- **Un solo archivo**, siempre llamado `pending-work-actual.md` (no por fecha). Overrides anterior.
- **Corto**: 1 pantalla, idealmente <40 líneas.
- Contiene solo:
  - Punto exacto de retoma (qué archivo, qué función, qué falta)
  - Bloqueos vivos (no históricos)
  - Decisiones pendientes que requieren input del usuario
- Si la sesión cerró sin trabajo en curso ("todo limpio, nada in-flight"), reflejarlo así explícitamente.

### 6. Detectar candidates a auto-memory

Si en la sesión emergió:
- Feedback recurrente del usuario sobre cómo trabajar
- Gotcha técnico que costó horas
- Decisión arquitectural cuyo *why* es importante

→ Surfacearlo al usuario al final, preguntando si lo guarda como auto-memory. NO escribir auto-memories sin confirmar.

### 7. Reportar al usuario

Output breve (3-5 líneas):
- Path del journal escrito
- Path del pending-work-actual actualizado
- Si hay candidates a auto-memory, listarlos para confirmación

## Argumentos opcionales

- `/close-session` → auto-detectar tema
- `/close-session "tema explícito"` → usar ese tema como título y slug
- `/close-session --dry-run` → mostrar qué se escribiría sin escribir nada (útil para validar el formato la primera vez)

## Ubicación

- Journals: `<project-root>/.journal/YYYY-MM-DD-tema.md`
- Handoff vivo: `<project-root>/.serena/memories/pending-work-actual.md`

Si `.journal/` no existe, crearla. Verificar que esté trackeada en git (no en `.gitignore`).

## Qué hacer si el usuario tiene `pending-work-*.md` viejos

Si al ejecutar la skill detectás múltiples `.serena/memories/pending-work-YYYY-MM-DD.md` (patrón legacy), NO los borrés silenciosamente. Mencionalo al usuario y ofrecé migrarlos a `.journal/` como parte del cierre. La decisión es de él.
