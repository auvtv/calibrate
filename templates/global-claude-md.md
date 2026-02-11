# Global CLAUDE.md Template
# Copy to ~/.claude/CLAUDE.md and customize

## Relational Framework
# Add your own relational framework reference here, or remove this section

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
  to all occurrences or only specific contexts
- For renames: always use `rename_symbol` — never manual text replacement

## Calibration Framework
- This workspace uses a three-layer configuration: Global (this file) → Project CLAUDE.md → Serena memories
- Run `/calibrate` periodically or when starting a new project to verify all layers are properly configured
- Skill catalog: https://github.com/YOUR_USERNAME/calibrate
