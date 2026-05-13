# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

The Calibration Framework is a **documentation-and-templates project** — not a software application. There is no build system, no runtime, no dependencies, and no test suite. The "product" is markdown files (skills, templates, docs) and a JSON catalog.

## Repository Structure

- `skills/` — Reusable workflow definitions organized by category (`shared/`, `web/`, `mobile/`, `ai/`, `devops/`). Each skill is a `SKILL.md` with YAML frontmatter.
- `templates/` — Starter templates for global and project-level CLAUDE.md files.
- `docs/` — Design documents and analysis (some in Spanish).
- `catalog.json` — Registry of all available skills with metadata, tags, and stack matching info.

## Skill File Format

Every skill lives at `skills/<category>/<skill-name>/SKILL.md` and follows this structure:

```yaml
---
name: skill-name
description: "Brief description of what the skill does"
---

# Skill Title

## Steps
1. ...
```

## Catalog Schema

When adding or modifying skills, keep `catalog.json` in sync. Each skill entry requires:
- `name` — Skill identifier (matches directory name)
- `path` — Relative path to `SKILL.md`
- `description` — What the skill does
- `requires` — Array of dependencies (e.g., `["serena"]`, `["ssh-mcp"]`)
- `tags` — Array for discoverability
- `stack_match` — (project-specific skills only) Technologies that trigger auto-suggestion

## Skill Categorization

Shared skills (work on any project, framework-agnostic) go in `skills/shared/`. Project-specific skills go in their stack category (`web/`, `mobile/`, `ai/`, `devops/`). Project-specific skills should use placeholders instead of hardcoded values (IPs, paths, URLs).

## Three-Layer Architecture (Core Concept)

This framework organizes AI assistant config into three layers — understand this before editing any content:

1. **Global** (`~/.claude/CLAUDE.md`) — Universal principles: Serena workflow, editing discipline, meta-cognitive checkpoints. Template: `templates/global-claude-md.md`
2. **Project** (`<project>/.claude/CLAUDE.md`) — Stack conventions, deployment config, testing, preferred skills. Template: `templates/project-claude-md.md`
3. **Knowledge** (Serena memories + Claude MEMORY.md) — Architecture in Serena, experiential learnings in MEMORY.md. These don't overlap.

When writing or editing templates and docs, respect these boundaries — conventions belong in Layer 2, not MEMORY.md; universal principles belong in Layer 1, not project configs.

## Editing Guidelines

- All content is markdown. Maintain consistent heading hierarchy and formatting.
- Skills reference Serena MCP tools (`get_symbols_overview`, `find_referencing_symbols`, `replace_symbol_body`, etc.) — these are real tool names, not placeholders.
- The `/calibrate` skill (in `skills/shared/calibrate/SKILL.md`) is the meta-skill that validates the entire framework. Changes to the three-layer architecture must be reflected there.

## Preferred Workflows

- Use `/calibrate sync` after editing any `skills/shared/*/SKILL.md` to push the change into `~/.claude/skills/`
- Use `/close-session` at the end of substantive sessions (skill/catalog/template changes that need rationale captured) — writes a journal to `.journal/` and updates `.serena/memories/pending-work-actual.md`. Skip for one-line typo fixes.
