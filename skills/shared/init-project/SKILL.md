---
name: init-project
description: "Bootstrap a new project for the Calibration Framework. Detects stack, customizes CLAUDE.md, installs catalog skills, and runs initial architecture exploration."
---

# Init Project

Intelligent project bootstrap for the Calibration Framework. Run this after
`calibrate-init.sh` has created the scaffolding, or standalone (it will create
missing structure inline).

## Prerequisites Check

1. Verify project structure exists:
   - `.claude/` directory
   - `.claude/skills/` directory
   - `CLAUDE.md` at project root (template or existing)
   If any are missing, create them. For CLAUDE.md, use the project template from
   the calibrate repo (`templates/project-claude-md.md`).

2. Verify MCP servers:
   - Run `/mcp` or check `.mcp.json` to confirm Serena is configured
   - If Serena is not available, warn the user and offer to configure it
   - Serena is mandatory — Layer 3 (architecture memories) depends on it

3. Locate the calibrate repo for catalog access:
   - Check `CALIBRATE_REPO` env var
   - Try `../calibrate/catalog.json`
   - Try `~/calibrate/catalog.json`
   - If not found, skip catalog steps but continue with the rest

## Step 1: Detect Project Stack

Scan the project root for framework indicators. Check these files in parallel:

| File | Indicates |
|------|-----------|
| `package.json` | Node.js — read `dependencies` for Next.js, React, Vue, Express, etc. |
| `pubspec.yaml` | Flutter / Dart |
| `requirements.txt` | Python |
| `pyproject.toml` | Python — read `[project]` for framework info |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `docker-compose*.yml` | Docker deployment |
| `Dockerfile` | Docker |
| `.github/workflows/` | GitHub Actions CI/CD |
| `vercel.json` | Vercel deployment |
| `fly.toml` | Fly.io deployment |
| `terraform/` or `*.tf` | Terraform infrastructure |

Present findings to the user:

```
Detected stack:
  - Language: TypeScript
  - Framework: Next.js 14 (App Router)
  - Database: PostgreSQL (via Prisma)
  - Deployment: Docker + Nginx
  - CI/CD: GitHub Actions

Is this correct? Anything to add or change?
```

Wait for user confirmation before proceeding.

## Step 2: Customize Project CLAUDE.md

Edit the project `CLAUDE.md` with detected and user-provided information:

### Fill `## Stack` section
Replace template placeholders with the detected technologies.

### Fill `## Preferred Workflows` section
Always include:
- `/refactor` for multi-file changes
- `/blast-radius` before changing widely-referenced symbols
- `/calibrate` for periodic config verification

Add stack-specific suggestions:
- If Docker detected: suggest a `/deploy` skill
- If database detected: suggest a `/seed-db` or `/migrate` skill
- If CI/CD detected: mention the pipeline

### Fill `## Conventions` section
Ask the user about key conventions. Provide framework-specific prompts:

**For Next.js:**
- "Server components by default, or client-first?"
- "API route response shape? (e.g., `{ data, error }`)"
- "State management approach? (React state, Zustand, Redux, etc.)"

**For Flutter:**
- "State management? (Riverpod, BLoC, Provider, etc.)"
- "Offline-first or online-first?"
- "Target platforms? (iOS, Android, Web)"

**For Python:**
- "Framework? (FastAPI, Flask, Django)"
- "Package manager? (pip, poetry, uv)"
- "Type checking? (mypy, pyright, none)"

**For any project:**
- "Any architectural decisions I should know about?"
- "Code style enforcement? (linter, formatter)"

### Fill `## Deployment` section
Ask: "How is this project deployed?"
- If Docker detected, pre-fill with docker-compose pattern
- If Vercel/Fly detected, note it
- If unknown, leave commented template for later

### Fill `## Testing` section
Detect test runner from config files:
- `package.json` scripts → jest, vitest, playwright
- `pubspec.yaml` → flutter test
- `pyproject.toml` → pytest
- `Cargo.toml` → cargo test

Ask: "How do you run tests? Anything I should know about the test setup?"

## Step 3: Suggest Catalog Skills

If the calibrate repo was located:

1. Read `catalog.json`
2. Match `stack_match` tags in each skill against the detected stack
3. Also check `tags` for general relevance
4. Present recommendations:

```
Recommended skills from catalog (not yet installed):
  - deploy-docker: Deploy via Docker Compose to VPS
    Match: detected docker-compose.yml
    Install? [Y/n]
```

For each accepted skill, copy the SKILL.md to `.claude/skills/<name>/SKILL.md`.

If a skill needs project-specific customization (e.g., deploy-docker has
placeholder values), flag it:

```
Note: deploy-docker has placeholders that need customization:
  - <SERVER_IP> → your server's IP
  - <APP_PATH> → deployment path on server
  Edit .claude/skills/deploy-docker/SKILL.md to fill these in.
```

## Step 4: Architecture Exploration

Run the `/explore-arch` workflow:
1. Use Serena's `list_dir` to map the project structure
2. Use `get_symbols_overview` on entry points
3. Use `find_symbol` on core classes/modules
4. Produce an architecture summary
5. Offer to save as a Serena memory (`write_memory` → `project-overview`)

This creates the Layer 3 foundation — the architectural knowledge that persists
across sessions.

## Step 5: Initialize MEMORY.md

Create the Claude Code project MEMORY.md:
- Determine the project memory path (shown in `/memory` output)
- Create `MEMORY.md` with a starter structure:

```markdown
# <Project Name> - Learnings

## Setup
- Initialized with Calibration Framework on <date>
- Stack: <detected stack summary>

## Gotchas
<!-- Add platform/framework gotchas as you discover them -->

## Debugging Lessons
<!-- Add non-obvious root causes and their fixes -->

## What Didn't Work
<!-- Approaches that were tried and failed, with reasons -->
```

## Step 6: Final Verification

Run `/calibrate audit` to verify all three layers:
- Layer 1: Global CLAUDE.md + personal skills
- Layer 2: Project CLAUDE.md + project skills
- Layer 3: Serena memories + MEMORY.md

Report the result. If anything is still missing, list specific action items.

## Output Summary

```
╔══════════════════════════════════════════╗
║   /init-project Complete                 ║
╚══════════════════════════════════════════╝

Project: <name>
Stack: <summary>

Layer 1 (Global):    ✓ Configured
Layer 2 (Project):   ✓ CLAUDE.md customized, N skills installed
Layer 3 (Knowledge): ✓ Serena memory created, MEMORY.md initialized

Installed skills:
  - /refactor (personal)
  - /blast-radius (personal)
  - /deploy-docker (project, from catalog)

Next:
  - Start working! The framework will track learnings automatically.
  - Run /calibrate review after major work sessions.
  - Add project-specific skills as workflows emerge.
```
