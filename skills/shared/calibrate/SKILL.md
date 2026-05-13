---
name: calibrate
description: "Calibration Framework: validate workspace configuration, review recent work, and manage skill catalog. Modes: audit (default), review, full, catalog, publish, sync."
---

# Calibration Framework

## Mode Selection

Parse `$ARGUMENTS` to determine mode:
- (empty) or "audit" → **Audit mode**
- "review" → **Review mode**
- "full" → **Audit + Review**
- "catalog" → **Catalog mode** (suggest skills from catalog)
- "publish" → **Publish mode** (add project skill to catalog)
- "sync" → **Sync mode** (sync repo skills → global installation)

**Catalog repo location:** Look for the calibrate repo by checking these paths in order:
1. Check if `CALIBRATE_REPO` env var is set
2. Look for `../calibrate/catalog.json` relative to the current project
3. Look for `~/calibrate/catalog.json`
4. If not found, inform user and suggest cloning from GitHub

---

## MODE 1: Audit (default)

Validate that the three-layer configuration is properly set up for the current project.

### Layer 1: Global Configuration
Check `~/.claude/CLAUDE.md` for:
- [ ] Relational Framework reference exists
- [ ] Serena Workflow section exists (exploration, editing, meta-tools)
- [ ] General Principles section exists (editing, deployment, scope)
- [ ] Calibration Framework reference exists

Check `~/.claude/skills/` for personal skills:
- [ ] `/refactor` exists
- [ ] `/blast-radius` exists
- [ ] `/explore-arch` exists
- [ ] `/calibrate` exists (this skill)
- [ ] `/close-session` exists

### Layer 2: Project Configuration
Check for project-level CLAUDE.md (`.claude/CLAUDE.md` or `CLAUDE.md` in project root):
- [ ] File exists
- [ ] Contains stack/technology section
- [ ] Contains project-specific conventions
- [ ] Contains deployment configuration (if applicable)
- [ ] Contains testing instructions
- [ ] References preferred workflows/skills
- [ ] References `/close-session` for session hygiene (journal + handoff)

**Session hygiene check (warn + offer to patch):**
If the project CLAUDE.md exists but does not mention `/close-session` (case-insensitive grep), emit a ⚠️ warning and offer to insert a one-liner into the "Preferred Workflows" section:

```
- Use `/close-session` to close a session — writes a journal entry to `.journal/` and updates `.serena/memories/pending-work-actual.md`. Invoke at the end of substantive sessions before context cools.
```

Do not block CALIBRATED status on this — it's a soft recommendation. If the project has no `.journal/` directory yet, that's fine; the skill creates it on first run.

Check for project-level skills (`.claude/skills/`):
- [ ] Directory exists
- [ ] Contains at least a `/deploy` skill (if project has deployment)
- [ ] Any other project-specific skills present

Check Claude Code project MEMORY.md:
- [ ] File exists in `~/.claude/projects/<project>/memory/MEMORY.md`
- [ ] Contains learnings/gotchas (not architecture — that goes in Serena)
- [ ] No duplication with project CLAUDE.md (conventions should be in CLAUDE.md, not MEMORY)

### Layer 2.5: MCP Ecosystem Detection

Auto-detect locally available MCP servers and configure them if missing.

**serena** (symbolic code intelligence):

Serena can be installed two ways — detect both before concluding it's unavailable.

1. **Detect installation** (try in this order, stop at first hit):
   - **Local clone:** the directory holding the Serena repo is conventionally `programas/`, but variants exist (`2programas/`, `dev/programas/`, etc.). Walk up from the project root and at each ancestor check for any directory matching `*programas/serena/pyproject.toml`. Then fall back to home: try `~/2programas/serena`, `~/programas/serena`, `~/dev/programas/serena`. Stop at the first match that contains `pyproject.toml`.
   - **Global binary:** `which serena` or `uv run serena --version`
   - **uvx runner (recommended upstream install):** check if `uvx` is available (`which uvx`) AND `~/.serena/` exists (strong signal Serena has been run on this machine before). If `uvx` exists but `~/.serena/` doesn't, still treat as *available* — just never used yet.
2. **Classify status** (use this exact vocabulary in the report, "not installed" is misleading):
   - `configured` — `.mcp.json` has a `serena` entry with correct `--project` AND (for local-clone setups) a `--directory` that exists on disk
   - `misconfigured` — entry exists but `--project` points elsewhere, OR `--directory` points to a path that no longer exists (binary moved/renamed — common after migrating across disks)
   - `available, not configured` — Serena is installed (any of the three methods above) but not in `.mcp.json`
   - `not available` — none of the three detection methods succeeded
3. **If `configured` or `misconfigured`:** verify both args and offer to fix any that are wrong:
   - `--project` matches the current project's absolute path
   - `--directory` (when present, i.e. local-clone setup) points to an existing directory on disk. If it doesn't exist, the Serena install was moved — replace it with the path detected in step 1.
4. **If `available, not configured`:** offer to create/update `.mcp.json`. Pick the command shape based on which detection hit:
   - **Local clone detected** → use `uv run --directory <serena-path>`:
       ```json
       {
         "mcpServers": {
           "serena": {
             "type": "stdio",
             "command": "uv",
             "args": ["run", "--directory", "<detected-serena-path>", "serena", "start-mcp-server", "--context", "ide-assistant", "--project", "<current-project-absolute-path>"],
             "env": {}
           }
         }
       }
       ```
   - **Only uvx detected** → use `uvx --from git+https://github.com/oraios/serena`:
       ```json
       {
         "mcpServers": {
           "serena": {
             "type": "stdio",
             "command": "uvx",
             "args": ["--from", "git+https://github.com/oraios/serena", "serena", "start-mcp-server", "--context", "ide-assistant", "--project", "<current-project-absolute-path>"],
             "env": {}
           }
         }
       }
       ```
5. After adding/fixing, remind the user to restart Claude Code for the MCP server to load.
6. **If `not available`:** skip silently (not all machines have it).

**convexo-coordinator** (multi-agent coordination):
1. Search for the convexo-coord build by checking these paths in order:
   - `../convexo-coord/build/index.js` relative to the current project
   - `~/convexo-coord/build/index.js`
   - Run `which convexo-coordinator` or `npm list -g convexo-coordinator`
2. If found:
   - [ ] Check `.mcp.json` includes a `convexo-coordinator` entry
   - [ ] Check project CLAUDE.md has a "Multi-Agent Coordination" section
   - If either is missing, **offer to add them automatically**:
     - Add to `.mcp.json`: `"convexo-coordinator": { "command": "node", "args": ["<detected-path>"] }`
     - Add to CLAUDE.md (before "Preferred Workflows" or at end if no such section):
       ```
       ## Multi-Agent Coordination (convexo-coord)

       "convexo-coord" / "convexo-coordinator" refers to the MCP tools already available in this
       session under the `mcp__convexo-coordinator__*` prefix. It is NOT a separate codebase —
       it is an MCP server configured in `.mcp.json`.

       **What it does**: Enables parallel sub-agent execution. Split a task into independent pieces,
       launch separate Claude instances in isolated git worktrees, and merge their work back.

       **When to use it**: When a plan has 2+ independent implementation phases that can run in parallel.

       **How to use it**: `/session-plan` skill for full orchestration, or manually via
       `register_instance` → `register_task` → `prepare_subagent_worktree` → `launch_subagent` →
       `merge_subagent_work`.

       Use `/bs` for brainstorm capture (also part of convexo-coordinator).
       ```
3. If not found: skip silently (not all machines have it)

**engram** (persistent cognitive memory):
1. Search for the Engram MCP server by checking these paths in order:
   - Walk up from the project directory checking `<ancestor>/engram/engram/mcp/index.js` at each level
   - `~/engram/engram/mcp/index.js`
   - Run `which engram-mcp` or `npm list -g engram-mcp`
2. If found:
   - [ ] Check `.mcp.json` includes an `engram` entry
   - If missing, **offer to add it automatically**:
     - Add to `.mcp.json`:
       ```json
       "engram": {
         "type": "stdio",
         "command": "node",
         "args": ["<detected-path>/mcp/index.js"],
         "env": {}
       }
       ```
   - After adding, inform the user they need to restart Claude Code for the MCP server to be available
3. If not found: skip silently (not all machines have it)

### Layer 3: Serena Configuration
**Prerequisite:** Only run these checks if Serena status in Layer 2.5 is `configured` (entry present, `--project` correct) AND the MCP session actually has `mcp__serena__*` tools available. Otherwise mark Layer 3 as ⏭️ (skipped) and note the reason: `not available`, `available but not configured`, or `configured but MCP not loaded yet — restart required`.

Check Serena memories:
- [ ] `list_memories` returns results for the current project
- [ ] A `project-overview` or equivalent architectural memory exists
- [ ] Memory content is up-to-date (check last modified if possible)
- If no memories exist (new project), **offer to run `/explore-arch`** to bootstrap them

### Audit Output

```
# Calibration Audit: <project name>
Date: <date>

## Status: CALIBRATED | NEEDS ATTENTION | NOT CONFIGURED

### Layer 1: Global ✅ | ⚠️ | ❌
- [status for each check]

### Layer 2: Project ✅ | ⚠️ | ❌
- [status for each check]

### Layer 2.5: MCP Ecosystem ✅ | ⚠️ | ⏭️ (skipped if not found)
- serena: [configured | added | misconfigured → fixed | available, not configured | not available]
- convexo-coordinator: [configured | added | not installed]

### Layer 3: Serena ✅ | ⚠️ | ❌
- [status for each check]

### Action Items
1. [specific action to fix each gap]
```

If gaps are found, offer to fix them interactively (create missing files,
add missing sections). For missing project CLAUDE.md, offer to generate one
from the template at `<calibrate-repo>/templates/project-claude-md.md`.

---

## MODE 2: Review

Analyze the current conversation and recent project state to detect opportunities
for improving the configuration.

### Step 1: Scan for Uncaptured Learnings
Review the conversation history for:
- **Debugging sessions** where the root cause was non-obvious → should be in MEMORY.md
- **Workarounds** applied for platform/framework limitations → should be in MEMORY.md
- **"Aha" moments** where an approach was wrong and corrected → should be in MEMORY.md

For each finding, check if it's already captured in MEMORY.md. If not, suggest adding it.

### Step 2: Detect Convention Violations
Look for patterns in the conversation where:
- **Text-based edits were used** when symbolic editing was available → reinforce in Global CLAUDE.md
- **Entire files were read** when symbol-level exploration would suffice → reinforce Serena workflow
- **Scope wasn't verified** before a multi-file change → suggest blast-radius step
- **Tests weren't run** after changes → reinforce in project CLAUDE.md

### Step 3: Identify Repeated Manual Workflows
Look for sequences of actions that were performed manually more than once:
- Same deployment steps repeated → should be a `/deploy` skill or update existing one
- Same exploration pattern for a subsystem → should be a project skill
- Same setup steps at session start → should be in project CLAUDE.md

### Step 4: Check Architecture Freshness
- Compare Serena `project-overview` memory against current project structure
- Flag if new directories, key files, or patterns exist that aren't documented
- Offer to update the memory

### Review Output

```
# Calibration Review: <project name>
Date: <date>
Sessions analyzed: current conversation

## Uncaptured Learnings
1. [learning] → suggest adding to MEMORY.md
2. ...

## Convention Adherence
- Symbolic editing: [used consistently | bypassed N times]
- Blast radius checks: [done before changes | skipped]
- Test suite: [run after changes | not run]

## Workflow Opportunities
1. [repeated pattern] → suggest creating /skill-name
2. ...

## Stale Documentation
- [file/memory] → [what needs updating]

## Recommended Actions
1. [prioritized action list]
```

---

## MODE 3: Full (Audit + Review)

Run both modes sequentially. Present a unified report.

```
# Full Calibration: <project name>
Date: <date>

## Part 1: Configuration Audit
[audit output]

## Part 2: Interaction Review
[review output]

## Combined Action Items (prioritized)
1. [most impactful action first]
2. ...
```

---

## MODE 4: Catalog

Check the catalog repo for skills that match the current project's stack
and suggest relevant ones that aren't installed yet.

### Steps

1. **Locate catalog repo** (see path resolution above)
2. **Read `catalog.json`** to get all available skills
3. **Detect project stack** from project CLAUDE.md (Stack section) or by
   scanning for framework indicators:
   - `package.json` → Node/Next.js/React
   - `pubspec.yaml` → Flutter/Dart
   - `requirements.txt` / `pyproject.toml` → Python
   - `Cargo.toml` → Rust
   - `docker-compose*.yml` → Docker
   - `Dockerfile` → Docker
4. **Match skills** by comparing `stack_match` tags in catalog against detected stack
5. **Check what's already installed** in `.claude/skills/`
6. **Present recommendations:**

```
# Skill Catalog: <project name>
Date: <date>

## Detected Stack
- [list of detected technologies]

## Recommended Skills (not yet installed)
| Skill | Category | Description | Match Reason |
|-------|----------|-------------|--------------|
| deploy-docker | web | Deploy via Docker Compose | Detected docker-compose.yml |

## Already Installed
| Skill | Source |
|-------|--------|
| deploy | project |
| refactor | personal |

## Install?
[For each recommended skill, offer to copy it to .claude/skills/]
```

If the user confirms, copy the SKILL.md from the catalog repo to the project's
`.claude/skills/<skill-name>/SKILL.md`.

---

## MODE 5: Publish

Add a project-level skill to the catalog repo for reuse in other projects.

### Steps

1. **Locate catalog repo** (see path resolution above)
2. **List project skills** from `.claude/skills/`
3. **Ask user** which skill to publish and which category (shared, web, mobile, ai, devops)
4. **Copy the skill** to `<catalog-repo>/skills/<category>/<skill-name>/SKILL.md`
5. **Generalize the skill** if needed:
   - Replace project-specific paths, IPs, or URLs with placeholders
   - Replace project-specific commands with generic patterns
   - Add `stack_match` tags for discoverability
   - Ask user to review the generalized version
6. **Update `catalog.json`** — add the new skill entry to the appropriate category
7. **Report:**

```
# Published: <skill-name>
Category: <category>
Path: skills/<category>/<skill-name>/SKILL.md
Tags: [list]

The skill is now in your local catalog. To share it:
  cd <catalog-repo> && git add . && git commit -m "feat: add <skill-name> skill" && git push
```

---

## MODE 6: Sync

Synchronize skills from the calibrate repo to the global installation at `~/.claude/skills/`.
This is the inverse of Publish: it pushes updated skill definitions from the source-of-truth (repo)
to where Claude Code actually loads them from (global skills directory).

### Steps

1. **Locate catalog repo** (see path resolution above)
2. **Scan the repo** for all skills: find every `SKILL.md` under `skills/` in the catalog repo
3. **Scan global installation** at `~/.claude/skills/` — list every installed skill
4. **Compare each installed skill** against the repo version:
   - Read both files and diff them
   - Classify as: `up-to-date`, `outdated` (repo is newer/different), or `local-only` (not in repo)
5. **Scan for uninstalled shared skills** — skills in `skills/shared/` in the repo that don't exist
   in `~/.claude/skills/`. These are candidates for installation.
6. **Present the sync report:**

```
# Skill Sync Report
Date: <date>
Repo: <calibrate-repo-path>
Target: ~/.claude/skills/

## Status
| Skill | Installed | Repo | Status |
|-------|-----------|------|--------|
| calibrate | ✅ | ✅ | outdated — repo has changes |
| refactor | ✅ | ✅ | up-to-date |
| blast-radius | ✅ | ✅ | up-to-date |
| explore-arch | ✅ | ✅ | up-to-date |
| new-skill | ❌ | ✅ (shared) | available — not installed |
| custom-local | ✅ | ❌ | local-only (won't touch) |

## Actions Available
1. Update N outdated skills
2. Install N new shared skills
```

7. **Ask the user** which actions to take:
   - "Update all outdated" → copy each changed `SKILL.md` from repo to `~/.claude/skills/<name>/`
   - "Install new shared skills" → copy from `skills/shared/<name>/SKILL.md` to `~/.claude/skills/<name>/SKILL.md`
   - "Show diff for <skill>" → display the diff for a specific skill before deciding
   - "Skip" → do nothing

8. **After syncing**, remind the user:
   - New/updated skills take effect in new Claude Code sessions
   - The sync itself (`/calibrate sync`) should also be kept up-to-date — if the `calibrate` skill was
     among the updated files, the current session is still running the old version

### Notes
- **Never delete local-only skills** — they may be user-created skills not meant for the catalog
- **Never modify the repo** — sync is one-way: repo → global installation
- Stack-specific skills (`web/`, `mobile/`, `ai/`, `devops/`) are NOT auto-installed globally —
  they should be installed per-project via `/calibrate catalog`. Only `shared/` skills are candidates
  for global installation
