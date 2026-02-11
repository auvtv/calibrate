# Blueprint: Configuracion Claude Code en Tres Capas

> Documento de referencia para organizar instrucciones, memorias y skills
> de manera que escalen a multiples proyectos (gestion, IA/RAG, mobile, web).
> Basado en insights de 47 sesiones (Dic 2025 - Feb 2026).

---

## Arquitectura de Capas

```
~/.claude/
├── CLAUDE.md                          ← CAPA 1: Global (todos los proyectos)
├── relationship-contract.md           ← Ya existe
├── skills/
│   ├── agent-browser/SKILL.md         ← Ya existe
│   ├── refactor/SKILL.md              ← NUEVO: skill universal
│   ├── blast-radius/SKILL.md          ← NUEVO: skill universal
│   └── explore-arch/SKILL.md          ← NUEVO: skill universal
│
├── projects/<proyecto>/memory/
│   └── MEMORY.md                      ← CAPA 2b: Learnings por proyecto

<proyecto>/
├── .claude/
│   └── skills/
│       ├── deploy/SKILL.md            ← CAPA 2: Skills de proyecto
│       └── <otros>/SKILL.md
├── .serena/memories/
│   └── project-overview.md            ← CAPA 2c: Arquitectura (Serena)
```

**Regla simple:**
- Si aplica a *cualquier* proyecto → global
- Si aplica solo a *este* proyecto → proyecto
- Si es arquitectura/estructura de codigo → Serena memory
- Si es leccion aprendida / gotcha → Claude Code MEMORY.md del proyecto

---

## CAPA 1: Global CLAUDE.md

**Archivo:** `~/.claude/CLAUDE.md`

```markdown
## Relational Framework
Read and internalize: ~/.claude/relationship-contract.md
This defines how we work together. Review it at the start of every session.

## Serena Workflow

### Code Exploration (read as little as possible)
1. `get_symbols_overview` on the target file — see all top-level symbols
2. `find_symbol(name, depth=1)` — see methods/fields without reading bodies
3. `find_symbol(name, include_body=True)` — read only the specific symbol needed
4. `find_referencing_symbols` — find all callsites and dependents
Never read entire source files unless working with non-code files (HTML, YAML, config).

### Code Editing (symbolic over text-based)
- Always prefer `replace_symbol_body` over text-based find/replace
- Use `insert_after_symbol` / `insert_before_symbol` for new code
- Use `rename_symbol` for renames (handles all references automatically)
- Fall back to regex-based edits ONLY for small changes within a symbol body
- NEVER use `replace_all` on variable names, function names, or widget properties

### Before Any Multi-File Change
1. Run `find_referencing_symbols` on every symbol being modified
2. Review the returned callsites — this is the blast radius
3. If 3+ callsites exist, list them and confirm scope before proceeding
4. Use `think_about_task_adherence` before writing any edit

### Cross-Session Context
- Read Serena project memories at session start if relevant to the task
- Claude Code MEMORY.md carries lessons learned and gotchas
- Both systems complement: Serena = architecture, Claude MEMORY = learnings

### Meta-Tools (use them)
- `think_about_collected_information` — after any research sequence
- `think_about_task_adherence` — before any code edit
- `think_about_whether_you_are_done` — before declaring task complete

## General Principles

### Editing
- Understand code before modifying it — always read the symbol first
- Verify blast radius with `find_referencing_symbols` before changing signatures
- After edits, run the project's test suite and report pass/fail count

### Deployment
- Use `git push` + `git pull` on server for file transfer (never scp/rsync/base64)
- Before deploying: verify env vars, test build locally, confirm DB schema matches
- Debug order: env vars → DB connection/roles → build → reverse proxy/SSL → CORS

### Scope Discipline
- When making find-and-replace style changes, confirm whether the change applies
  to all occurrences or only specific contexts (e.g., "only in quiz text, not
  product definitions")
- For renames: always use `rename_symbol` — never manual text replacement
```

**Que NO va aqui:**
- Nada de Flutter, Riverpod, Dart, soundpool
- Nada de Next.js, React, Supabase
- Nada de puertos, Docker, Hostinger
- Nada de quiz, garrapatas, perfiles

---

## CAPA 2a: Proyecto CLAUDE.md

**Archivo:** `<proyecto>/.claude/CLAUDE.md` (no existe aun en GarrapAttack)

Ejemplo para GarrapAttack:

```markdown
# GarrapAttack Project Conventions

## Stack
- Web: Next.js 14 (App Router), TypeScript, Tailwind, shadcn/ui
- Mobile: Flutter 3.38.9, Dart 3.10.8, Riverpod, Drift, Dio
- DB: PostgreSQL via Supabase (self-hosted), Drizzle ORM
- Admin: Separate Next.js app in admin/

## Preferred Workflows
- Use /deploy for all production deployments
- Use /refactor for any multi-file code change (global skill, Serena-powered)

## Flutter/Dart
- `withOpacity()` deprecated → use `withValues(alpha: x)`
- `mounted` → `context.mounted` for async gap checks
- Dart ^3.10.8 — no `?if` null-aware syntax (requires 3.12+)
- After any Dart file change, run `flutter analyze`
- Never `await` soundpool.play() — fire and forget
- soundpool for SFX, audio_session required on iOS for silent switch
- Max 4 concurrent sounds (beyond this, frame drops >20%)

## Web App
- Pages using `useSearchParams()` need `<Suspense>` wrapper
- Quiz page reads mode/category/section/count/profile from URL params
- Always pass `profile` as URL param from story page
- Check `res.ok` not just try/catch — fetch doesn't throw on 401/400
- Power-up/XP display commented out for demo phase (easy restore)

## State Management (Flutter)
- Use `submittingOptionId` pattern for immediate visual feedback
- Always guard async ops with `_submitting` + try/finally
- After mutations, invalidate the provider AND its dependents
- `copyWith` with `clearX` booleans for nullable fields

## Architecture Decisions
- Local-first quiz: load questions at start, verify locally, sync after
- Never call server per-answer during quiz play
- Offline: HMAC-SHA256 hash verification for cached questions
- Sync: push responses first, pull questions second

## Deployment (Hostinger VPS)
- Server: <SERVER_IP>, path: /opt/<APP_NAME>/
- Docker: docker-compose.prod.yml, container on port 3002
- Admin: admin/docker-compose.admin.yml, port 3003
- Nginx: /etc/nginx/conf.d/<APP_NAME>.conf
- DATABASE_URL needed at build time for API routes
- NEXT_PUBLIC_* vars baked into client JS by Next.js at build time

## Testing
- Flutter: `flutter test` + `flutter analyze`
- Do NOT attempt browser UI testing on Flutter Web (CanvasKit canvas blocks DOM)
- Use widget tests, API smoke tests, or IndexedDB validation instead
```

---

## CAPA 2b: Claude Code MEMORY.md (por proyecto)

**Archivo:** `~/.claude/projects/<proyecto>/memory/MEMORY.md`

**Proposito:** Lecciones aprendidas, gotchas, cosas que salieron mal y como se
resolvieron. Cosas que *no queres volver a debuggear*.

El MEMORY.md actual de GarrapAttack ya cumple bien este rol. Lo unico que
ajustaria es mover las convenciones de proyecto (stack, deployment config) al
CLAUDE.md de proyecto y dejar MEMORY.md solo para learnings:

```markdown
# GarrapAttack - Learnings

## Audio on iOS
- audioplayers causa jank en UI — soundpool es la solucion
- audio_session requerido para silent switch
- Max 4 sonidos concurrentes, fire-and-forget siempre
- ffmpeg: volume=2+ y normalize=0 para que no quede bajo

## Performance Debugging
- Cuando UI lagea, revisar timing de red primero (no audio)
- Stopwatch timestamps en metodos async para medir latencia real
- Debug mode en iOS fisico es mucho mas lento que release

## Cosas que mordieron
- replace_all en initialValue→value rompio DropdownMenuItem y PopupMenuItem
- Browser automation en Flutter Web imposible (CanvasKit canvas)
- 10s connect timeout en Dio causaba lag que parecia de audio
- fetch no tira excepcion en 401/400 — siempre checkear res.ok
- useSearchParams sin Suspense rompe Next.js production build
- {false && expr} con optional chaining falla en TS — comentar el bloque
```

---

## CAPA 2c: Serena Memories (por proyecto)

**Archivo:** `.serena/memories/project-overview.md` (ya existe)

**Proposito:** Arquitectura detallada, estructura de archivos, esquema de DB,
rutas de API, config de deploy. Es la "fuente de verdad" sobre como esta
construido el proyecto.

**Ya esta bien.** El `project-overview` actual tiene exactamente lo que
necesita. No requiere cambios.

---

## CAPA 3: Skills

### Skills Personales (universales)

**Ubicacion:** `~/.claude/skills/<nombre>/SKILL.md`

#### /refactor

```markdown
---
name: refactor
description: Serena-powered multi-file refactoring workflow. Use when modifying
  code that spans multiple files or touches symbols referenced elsewhere.
---

# Refactor Workflow

## Steps

1. **Map scope**
   - `get_symbols_overview` on all files that might be affected
   - `find_symbol` with depth=1 on classes/modules being changed
   - `find_referencing_symbols` on every symbol being modified
   - List all affected files and callsites

2. **Confirm with user**
   - Present: what changes, where, and what depends on it
   - Wait for approval before any edit

3. **Execute**
   - `replace_symbol_body` for modifications
   - `insert_after_symbol` / `insert_before_symbol` for additions
   - `rename_symbol` for renames
   - Regex only for small intra-symbol tweaks

4. **Verify**
   - `find_referencing_symbols` on changed symbols (confirm no broken refs)
   - Run the project's test suite
   - Run the project's static analysis (if applicable)

5. **Report**
   - List all files modified
   - Test results (pass/fail count)
   - Any remaining concerns
```

#### /blast-radius

```markdown
---
name: blast-radius
description: Analyze the impact of changing a symbol before making any edits.
  Use to understand what will break before you touch it.
---

# Blast Radius Analysis

Given a symbol name and file:

1. `find_symbol` to locate the exact symbol and read its signature
2. `find_referencing_symbols` to find ALL references across the codebase
3. For each reference, classify as:
   - **Direct call** — will break if signature changes
   - **Type reference** — will break if type/interface changes
   - **Import only** — will break if symbol is renamed/moved
4. Present a summary:
   - Total references: N across M files
   - Callsites that need updating: [list]
   - Risk level: low (1-2 refs) / medium (3-10) / high (10+)
5. Do NOT make any changes — only report
```

#### /explore-arch

```markdown
---
name: explore-arch
description: Map the architecture of a project or subsystem using Serena's
  symbolic tools. Use at the start of a new project or when entering an
  unfamiliar part of the codebase.
---

# Architecture Exploration

## Steps

1. **Structure**: `list_dir` recursive on the target directory
2. **Key files**: `get_symbols_overview` on entry points
   (main, index, app, routes, schema files)
3. **Core symbols**: `find_symbol` with depth=1 on main classes/modules
4. **Dependencies**: `find_referencing_symbols` on core symbols to map
   how components connect
5. **Produce summary**:
   - Layer diagram (data → service → UI, or equivalent)
   - Key entry points and their responsibilities
   - Cross-cutting concerns (auth, logging, error handling)
   - State management pattern (if applicable)

Read Serena project memories first if they exist — they may already have this.
If no memory exists, offer to create one with `write_memory`.
```

### Skills de Proyecto (especificos a GarrapAttack)

**Ubicacion:** `<proyecto>/.claude/skills/<nombre>/SKILL.md`

#### /deploy

```markdown
---
name: deploy
description: Deploy app to VPS via Docker. Handles build, push, Docker,
  and verification.
---

# Deploy App

## Pre-deploy Checks
1. Run `flutter analyze` on mobile/ (if mobile changes)
2. Run test suite for changed components
3. Verify `.env` has all required vars (DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY)
4. Git commit and push to main

## Deploy Web App
```bash
# On server via SSH MCP:
cd /opt/<APP_NAME> && git pull
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
docker logs <APP_NAME>-web --tail 20
```

## Deploy Admin App
```bash
cd /opt/<APP_NAME>/admin
docker compose -f docker-compose.admin.yml down
docker compose -f docker-compose.admin.yml build --no-cache
docker compose -f docker-compose.admin.yml up -d
```

## Post-deploy Verification
1. Check container health: `docker ps`
2. Test web: `curl -s https://<YOUR_DOMAIN> | head -5`
3. Test API: `curl -s https://<YOUR_DOMAIN>/api/questions/random?count=1`
4. Check logs for errors: `docker logs <APP_NAME>-web --tail 50`

## Common Issues
- Build fails → check DATABASE_URL is in build args (needed at build time)
- NEXT_PUBLIC_* empty → must be in .env AND as build args (baked at build)
- 502 Bad Gateway → container not on `<PROJECT>-net` network
- DB connection refused → check <PROJECT>-postgres is running
- CORS errors → check nginx config has proper headers
```

---

## Diagrama de Decision: Donde va cada cosa?

```
¿Aplica a TODOS mis proyectos?
├── SI → ¿Es un workflow/skill?
│   ├── SI → ~/.claude/skills/<nombre>/SKILL.md
│   └── NO → ~/.claude/CLAUDE.md
│
└── NO → ¿Es de ESTE proyecto?
    ├── SI → ¿Es arquitectura/estructura del codigo?
    │   ├── SI → Serena memory (project-overview)
    │   └── NO → ¿Es una leccion aprendida / gotcha?
    │       ├── SI → Claude MEMORY.md del proyecto
    │       └── NO → .claude/CLAUDE.md del proyecto
    │           (convenciones, stack, config, preferred workflows)
    │
    └── ¿Es un workflow especifico del proyecto?
        └── SI → .claude/skills/<nombre>/SKILL.md del proyecto
```

---

## Plan de Implementacion

### Paso 1: Actualizar Global CLAUDE.md
- Agregar secciones de Serena Workflow y General Principles
- Mantener referencia a relationship-contract.md

### Paso 2: Crear Proyecto CLAUDE.md
- `.claude/CLAUDE.md` en la raiz de GarrapAttack (no existe aun)
- Mover convenciones de Flutter, web, deploy del MEMORY.md actual

### Paso 3: Limpiar MEMORY.md del proyecto
- Dejar solo learnings y gotchas
- Remover info de arquitectura (ya esta en Serena memory)
- Remover convenciones (van al CLAUDE.md de proyecto)

### Paso 4: Crear Skills Personales
- `~/.claude/skills/refactor/SKILL.md`
- `~/.claude/skills/blast-radius/SKILL.md`
- `~/.claude/skills/explore-arch/SKILL.md`

### Paso 5: Crear Skills de Proyecto
- `.claude/skills/deploy/SKILL.md` en GarrapAttack

### Orden sugerido: 1 → 4 → 2 → 5 → 3
(Global primero, luego proyecto, limpiar MEMORY al final para no perder nada)
