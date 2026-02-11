# Claude Code Insights — Updated Recommendations (Serena-Aware)

> This document revises the suggestions from the original insights report
> (Feb 2026, 47 sessions) to account for the Serena MCP toolset, which is
> central to how we navigate, explore, and edit code in this project.

---

## 1. CLAUDE.md Additions (Revised)

### 1.1 Global vs Project CLAUDE.md (unchanged)

> When I reference 'global CLAUDE.md' or 'global level', always look at
> `~/.claude/CLAUDE.md`, NOT the project-level CLAUDE.md.

*Serena impact: none — this is a Claude Code convention issue.*

---

### 1.2 Code Editing Discipline (rewritten — was "never use replace_all")

**Original suggestion:** "Never use `replace_all` for widget property changes —
always target specific widgets to avoid collateral damage."

**Updated:**

```
## Code Editing

- Always prefer Serena's symbolic editing tools over text-based operations:
  - `replace_symbol_body` for modifying methods, functions, classes, or widgets
  - `insert_after_symbol` / `insert_before_symbol` for adding new code
  - `rename_symbol` for renaming across the codebase (handles all references)
- Fall back to regex/text-based edits ONLY for small intra-symbol changes
  (e.g., changing a single line inside a method body).
- NEVER use `replace_all` on widget property names or variable names —
  use `rename_symbol` or targeted `replace_symbol_body` instead.
- Before any edit, read the symbol body with `find_symbol(include_body=True)`
  to confirm you're changing exactly what you intend.
```

**Why the change:** The original "never use replace_all" is a symptom-level fix.
The root cause is using text-based editing when symbolic editing is available.
`replace_symbol_body` operates on a named symbol in a specific file — it
*cannot* cause collateral damage to unrelated widgets because it doesn't
pattern-match across files.

---

### 1.3 Scope Verification Before Changes (rewritten)

**Original suggestion:** "Confirm the exact scope of the change with the user
before proceeding. Especially for find-and-replace operations."

**Updated:**

```
## Change Scope Verification

Before modifying any symbol that is referenced elsewhere:
1. Run `find_referencing_symbols` on the target symbol
2. Review the returned callsites and code snippets
3. If references exist in 3+ locations, list them and confirm scope with user
4. After editing, re-run `find_referencing_symbols` to verify no broken refs

For renames: always use `rename_symbol` — it handles all references automatically.
For signature changes: manually check each reference from step 2 and update.
```

**Why the change:** The original is a conversational instruction ("ask the user").
With Serena, scope verification is a concrete tool workflow that produces
evidence. `find_referencing_symbols` shows every callsite with surrounding code,
so scope decisions are data-driven, not guesswork.

---

### 1.4 Provider Invalidation (rewritten)

**Original suggestion:** "After fixing a bug or implementing a feature that
touches providers/state management, always verify that related providers are
properly invalidated."

**Updated:**

```
## Provider Invalidation (Flutter/Riverpod)

After any mutation method change (create/update/delete):
1. Use `find_referencing_symbols` on the mutated repository/service method
2. Trace which providers call it (the referencing symbols will show provider bodies)
3. For each provider that calls the mutation, verify it invalidates:
   - Itself (if it holds cached state)
   - Any dependent providers that display the mutated data
4. Use `find_referencing_symbols` on the provider itself to find UI consumers
   that might show stale data

Common patterns in this project:
- `ref.invalidate(providerName)` after mutation
- `ref.invalidateSelf()` inside the provider
- Missing invalidation on `patientAppointmentsProvider` when `appointmentRepository`
  mutations run — this has bitten us before
```

**Why the change:** The original is a mental checklist. With Serena, this
becomes a traceable, repeatable workflow. `find_referencing_symbols` gives us
the actual dependency graph, not a guess about which providers might be affected.

---

### 1.5 Deployment (unchanged from original)

```
## Deployment
- Always use `git push` + `git pull` on server for file transfer
- Before deploying, verify: env vars set, Docker build succeeds locally,
  DB roles/schemas match
- Debug order: 1) env vars 2) DB connection/roles 3) Docker build
  4) nginx/SSL 5) CORS
```

*Serena impact: none — deployment is infrastructure, not code navigation.*

---

### 1.6 Testing (minor update)

**Original suggestion:** "Always run the full test suite after changes."

**Updated:**

```
## Testing
- Always run the full test suite after changes and report pass/fail count
- For Flutter: `flutter test` and `flutter analyze`
- For backend TypeScript: run existing test commands
- Do NOT attempt browser-based UI testing of Flutter web apps
  (CanvasKit canvas rendering blocks DOM automation)
- Use widget tests, API smoke tests, or IndexedDB-level validation instead
- After Serena symbolic edits (`replace_symbol_body`, `rename_symbol`),
  run tests to confirm — symbolic edits are reliable but the logic you
  write inside them still needs verification
```

---

### 1.7 Serena Workflow (NEW — not in original report)

```
## Serena MCP Workflow

### Exploring code (read as little as possible)
1. `get_symbols_overview` on the target file — see all top-level symbols
2. `find_symbol(name, depth=1)` — see methods/fields without reading bodies
3. `find_symbol(name, include_body=True)` — read only the specific symbol
4. `find_referencing_symbols` — find all callsites and dependents
Never read entire files unless working with non-code files (HTML, YAML, config).

### Editing code
1. Always `find_symbol(include_body=True)` before `replace_symbol_body`
2. Use `insert_after_symbol` / `insert_before_symbol` for new code
3. Use `rename_symbol` for renames (handles all references)
4. For small intra-symbol changes, use regex-based edits

### Cross-session context
- Serena memories (`project-overview`, `mobile-research-2025`) carry
  architectural knowledge between sessions — read them at session start
  if relevant to the task
- Claude Code's MEMORY.md carries learnings and gotchas
- Both systems complement each other: Serena = architecture, Claude = lessons

### Meta-tools (use them)
- `think_about_collected_information` — after a research sequence, before deciding
- `think_about_task_adherence` — before any edit, to prevent drift
- `think_about_whether_you_are_done` — before declaring completion
```

---

## 2. Features to Try (Revised)

### 2.1 Custom Skills

**Original:** `/deploy` skill for deployment checklist.

**Updated — add `/refactor` skill:**

The `/deploy` skill is still valid (Serena doesn't touch deployment). But the
report missed a natural candidate:

```
# .claude/skills/refactor/SKILL.md

## Serena-Powered Refactor Workflow
1. `get_symbols_overview` on all affected files
2. `find_symbol` with depth to understand class/method structure
3. `find_referencing_symbols` on every symbol being changed
4. Present the blast radius (files + callsites) and get user approval
5. Execute changes using `replace_symbol_body` / `rename_symbol`
6. Re-run `find_referencing_symbols` to verify no broken references
7. Run `flutter analyze` (Dart) or TypeScript compiler check
8. Run full test suite
9. Report results
```

### 2.2 Hooks (unchanged)

Auto-running `flutter analyze` after Dart file edits is complementary to Serena,
not replaced by it.

### 2.3 Task Agents (upgraded)

**Original:** "Use a task agent to explore all Riverpod providers and map their
dependency graph."

**Updated prompt:**

> Use a task agent with Serena's symbolic tools to map the Riverpod provider
> dependency graph. For each provider in `mobile/lib/providers/`:
> 1. `get_symbols_overview` to list all providers
> 2. `find_referencing_symbols` on each provider to find consumers
> 3. `find_symbol(include_body=True)` to see which other providers it watches
> 4. Build a dependency map: provider → watches → watched by
> 5. Flag any mutation that doesn't invalidate its dependents

**Why the change:** The original suggested grep for `ref.watch` patterns —
fragile and incomplete. Serena's `find_referencing_symbols` does *symbolic*
dependency tracing: it finds actual references, not string matches. This catches
indirect references, re-exports, and aliased providers that grep would miss.

---

## 3. Usage Patterns (Revised)

### 3.1 Deployment time sink (unchanged)

*Serena doesn't impact deployment debugging. The `/deploy` skill and checklist
suggestions from the original report remain valid.*

### 3.2 Buggy code and wrong approach (rewritten)

**Original:** "Ask Claude to propose its approach BEFORE implementing."

**Updated:**

The real fix isn't conversational ("propose your approach") — it's tool-based.
Before any multi-file change:

1. **Map the blast radius** with `find_referencing_symbols` on every symbol
   being modified. This produces a concrete list of files and callsites.
2. **Use `think_about_task_adherence`** before writing any edit — this is
   Serena's built-in "pause and check" that prevents drift.
3. **Edit symbolically** with `replace_symbol_body` instead of text-based
   operations — this eliminates the "collateral damage" category entirely.

The 40 "buggy code" friction events break down into:
- ~15 from `replace_all` collateral → **eliminated by symbolic editing**
- ~10 from missing reference updates → **eliminated by `find_referencing_symbols`**
- ~15 from logic errors → **unchanged, still need tests to catch these**

### 3.3 Multi-file implementation pattern (enhanced)

**Original:** "Plan → implement → test → commit."

**Updated — Serena-enhanced plan phase:**

```
1. PLAN (Serena exploration)
   - `get_symbols_overview` on affected files
   - `find_symbol` with depth to map class structures
   - `find_referencing_symbols` to trace cross-file dependencies
   - List all files and symbols that will change
   - Get user approval

2. IMPLEMENT (Serena editing)
   - `replace_symbol_body` for modifications
   - `insert_after_symbol` for new code
   - `rename_symbol` for renames
   - Regex edits only for small intra-symbol tweaks

3. VERIFY
   - `find_referencing_symbols` on changed symbols (no broken refs)
   - `flutter analyze` / TypeScript check
   - Full test suite

4. COMMIT
   - Only after step 3 is green
```

---

## 4. On the Horizon (Revised)

### 4.1 Parallel Agents for Deploy and Test (minor update)

The deploy agent doesn't use Serena. But the **test analysis agent** benefits:
when a test fails, instead of reading the whole test file and the whole
implementation file, use `find_symbol` to locate the exact failing method, read
only its body, and fix it with `replace_symbol_body`. Faster iteration loop.

### 4.2 Self-Healing Code via TDD (upgraded)

**Original prompt's fix loop:** "Analyze the failure, fix the code, re-run."

**Updated fix loop:**

```
When a test fails:
1. Parse the failure message for the failing test name and error location
2. `find_symbol` on the failing test to read its body (understand what's expected)
3. `find_symbol` on the implementation symbol under test (read only that method)
4. Fix with `replace_symbol_body` (surgical, no collateral damage)
5. Re-run tests
```

This is significantly faster than the file-level read→edit→rerun loop the
original report assumes, because each cycle reads and writes only the relevant
symbol bodies.

### 4.3 Cross-Platform Verification Pipeline (upgraded)

**Original item #6:** "For every mutation function, verify all related providers
are invalidated" (grep-based).

**Updated — symbolic verification:**

```
PROVIDER INVALIDATION AUDIT (Serena-powered):
1. `find_symbol` all methods containing 'create', 'update', 'delete'
   in mobile/lib/repositories/ and mobile/lib/services/
2. For each mutation method, run `find_referencing_symbols`
3. For each referencing provider, check if it calls ref.invalidate()
   on dependent providers after the mutation
4. Flag any mutation whose referencing providers don't invalidate dependents
```

This is **deterministic and complete** — unlike grep for `ref.invalidate` which
can't tell you whether the *right* providers are being invalidated.

---

## 5. What the Original Report Misses Entirely

### 5.1 Serena Memory System

The report credits Claude Code's `MEMORY.md` but ignores Serena's project
memories (`project-overview`, `mobile-research-2025`). These carry detailed
architectural context (full project structure, deployment config, API routes,
database schema) that persists across sessions independently of Claude Code's
memory. The two systems are complementary:

| System | Purpose | Scope |
|--------|---------|-------|
| Claude Code MEMORY.md | Lessons learned, gotchas, patterns | Cross-project learnings |
| Serena memories | Architecture, structure, config | Project-specific knowledge |

### 5.2 Token Efficiency

Sessions average 7 hours. Part of why they can run that long without context
window collapse is that Serena reads symbol bodies (~20-50 lines) instead of
whole files (~200-500 lines). Over a session with dozens of file explorations,
this is a 5-10x reduction in context consumption.

### 5.3 Think-Before-Act Meta-Tools

Serena's `think_about_task_adherence`, `think_about_collected_information`, and
`think_about_whether_you_are_done` are reflective checkpoints that prevent the
"wrong approach" friction the report flags (35 events). These force a structured
pause before edits, after research, and before declaring done. The report's
suggestion to "propose approach before implementing" is a weaker version of
what these tools already provide.

---

## Summary: What Changes With Serena

| Report Area | Original Approach | Serena-Aware Approach |
|-------------|-------------------|----------------------|
| Preventing collateral damage | "Don't use replace_all" | Use `replace_symbol_body` always |
| Scope verification | "Ask user before proceeding" | `find_referencing_symbols` → data-driven scope |
| Provider invalidation | Mental checklist | Symbolic dependency tracing |
| Refactoring workflow | Not mentioned | Formalized `/refactor` skill |
| Task agents for exploration | Grep-based text search | Symbolic dependency mapping |
| TDD fix loop | Read file → edit → rerun | Read symbol → `replace_symbol_body` → rerun |
| Cross-platform audit | Grep for patterns | Symbolic mutation → reference tracing |
| Context efficiency | Not mentioned | Symbol-level reads = 5-10x less context |
| Wrong approach prevention | "Propose plan first" | `think_about_task_adherence` meta-tool |
| Cross-session memory | MEMORY.md only | MEMORY.md + Serena project memories |
