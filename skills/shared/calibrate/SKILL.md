---
name: calibrate
description: "Calibration Framework: validate workspace configuration, review recent work, and manage skill catalog. Modes: audit (default), review, full, catalog, publish."
---

# Calibration Framework

## Mode Selection

Parse `$ARGUMENTS` to determine mode:
- (empty) or "audit" → **Audit mode**
- "review" → **Review mode**
- "full" → **Audit + Review**
- "catalog" → **Catalog mode** (suggest skills from catalog)
- "publish" → **Publish mode** (add project skill to catalog)

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

### Layer 2: Project Configuration
Check for project-level CLAUDE.md (`.claude/CLAUDE.md` or `CLAUDE.md` in project root):
- [ ] File exists
- [ ] Contains stack/technology section
- [ ] Contains project-specific conventions
- [ ] Contains deployment configuration (if applicable)
- [ ] Contains testing instructions
- [ ] References preferred workflows/skills

Check for project-level skills (`.claude/skills/`):
- [ ] Directory exists
- [ ] Contains at least a `/deploy` skill (if project has deployment)
- [ ] Any other project-specific skills present

Check Claude Code project MEMORY.md:
- [ ] File exists in `~/.claude/projects/<project>/memory/MEMORY.md`
- [ ] Contains learnings/gotchas (not architecture — that goes in Serena)
- [ ] No duplication with project CLAUDE.md (conventions should be in CLAUDE.md, not MEMORY)

### Layer 3: Serena Configuration
Check Serena memories:
- [ ] `list_memories` returns results
- [ ] A `project-overview` or equivalent architectural memory exists
- [ ] Memory content is up-to-date (check last modified if possible)

### Audit Output

```
# Calibration Audit: <project name>
Date: <date>

## Status: CALIBRATED | NEEDS ATTENTION | NOT CONFIGURED

### Layer 1: Global ✅ | ⚠️ | ❌
- [status for each check]

### Layer 2: Project ✅ | ⚠️ | ❌
- [status for each check]

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
