# The Calibration Framework

**A systematic approach to configuring AI coding assistants across multiple projects**

## The Starting Point

Over 45 days, I ran a deliberate experiment: learn Flutter from scratch while simultaneously pushing Claude Code + Serena MCP through sustained, complex development work. The scope covered a Flutter mobile app, a Next.js web app, and self-hosted infrastructure — 47 working sessions, 320 hours of development, 49 commits.

The combination was intentional. Learning a new framework exposes every assumption an AI assistant makes, because you can't silently correct its mistakes when you're also learning the territory. Every friction point becomes visible.

I instrumented the process, tracking where time was lost and why. The patterns that emerged weren't about the code — they were about the assistant's behavior across sessions.

## The Pattern

The AI assistant kept re-learning the same lessons.

Deployment debugging followed the same sequence every time. Audio performance gotchas on iOS were discovered, fixed, and then forgotten by the next session. Text-based find-and-replace operations broke unrelated code because the assistant didn't verify impact scope first. Platform limitations (Flutter Web's canvas rendering blocking browser automation) were attempted, failed, and attempted again sessions later.

The assistant had powerful tools — Serena's semantic code navigation, SSH access to production servers, project memories that persisted across sessions — but no systematic framework for organizing what it knew, where it knew it, and when to apply it.

When I analyzed the friction data across all 47 sessions, a clear picture emerged:

* **40 "buggy code" friction events** — the assistant applying changes too broadly, not scoping edits before executing
* **35 "wrong approach" attempts** — the assistant not checking feasibility before committing to a path
* **16 deployment sessions** where the assistant re-debugged the same Docker/Postgres/Nginx issues
* **7-hour average sessions** that worked despite, not because of, how the assistant was configured

These weren't developer errors — they were system configuration gaps. The assistant was powerful but uncalibrated: it had no structured way to retain operational knowledge, distinguish project-specific conventions from universal principles, or apply lessons already learned.

## The Opportunity

Analyzing this data revealed something significant: the largest performance gains available weren't in the model itself, but in how it was configured and what knowledge it carried into each session.

The opportunity was a framework — a combination of **patterns** and **tools** — that would allow the assistant to:

* **Retain and apply operational knowledge** across sessions instead of rediscovering it
* **Separate concerns** the way software architecture does: universal principles vs. project-specific conventions vs. evolving project knowledge
* **Encode proven workflows** as reusable skills rather than manual sequences repeated from memory
* **Self-diagnose configuration gaps** before they manifest as wasted time

The insight came from a simple analogy: software projects have clear separation of concerns — global config vs. project-specific settings vs. runtime state. But AI assistant instructions were a flat soup — Flutter conventions mixed with universal editing principles, mixed with deployment IP addresses, mixed with debugging lessons from last Tuesday.

The second piece was Serena, an MCP (Model Context Protocol) server that provides semantic code understanding. Instead of reading entire files, Serena lets the AI navigate code symbolically: find a class, inspect its methods, trace references across the codebase, and make surgical edits to specific symbols. This fundamentally changes how an AI assistant should approach code modification — and that change needs to be encoded in the configuration, not rediscovered each session.

## The Three-Layer Architecture

The Calibration Framework organizes AI assistant configuration into three layers, each with a clear responsibility and scope.

```
┌──────────────────────────────────────────────────┐
│             LAYER 1: GLOBAL                      │
│         ~/.claude/CLAUDE.md                      │
│                                                  │
│  Universal principles that apply to ANY project  │
│  • Serena workflow (symbolic exploration/editing) │
│  • Scope verification before changes             │
│  • Meta-cognitive checkpoints                    │
│  • Deployment principles                         │
│  • Editing discipline                            │
├──────────────────────────────────────────────────┤
│             LAYER 2: PROJECT                     │
│         <project>/.claude/CLAUDE.md              │
│                                                  │
│  Conventions specific to THIS project            │
│  • Tech stack and framework conventions          │
│  • Deployment configuration                      │
│  • Testing instructions                          │
│  • Preferred workflows and skills                │
├──────────────────────────────────────────────────┤
│             LAYER 3: KNOWLEDGE                   │
│    Serena memories + Claude MEMORY.md            │
│                                                  │
│  Living knowledge that evolves with the project  │
│  • Architecture & structure (Serena memories)    │
│  • Lessons learned & gotchas (MEMORY.md)         │
│  • What went wrong and how it was fixed          │
└──────────────────────────────────────────────────┘
```

### Layer 1: Global — The Operating System

The global configuration defines how the AI works, regardless of project. It encodes workflow principles that emerged from hundreds of hours of real development:

**Symbolic over textual.** Always explore code through semantic tools (find the class, inspect its methods, trace its references) before reading entire files. Edit by replacing symbol bodies, not by text search-and-replace. This single principle eliminates an entire category of bugs — the "collateral damage" from broad text operations that break unrelated code.

**Blast radius before editing.** Before modifying any symbol that's referenced elsewhere, map every callsite first. This transforms scope decisions from guesswork ("I think this is only used here") into evidence ("there are 7 references across 4 files — here they are").

**Meta-cognitive checkpoints.** Force structured pauses at three moments: after gathering information (is this enough to proceed?), before making edits (am I still on track?), and before declaring done (did I actually complete everything?). These prevent the drift that causes "wrong approach" friction.

### Layer 2: Project — The Application Layer

Each project gets its own configuration with conventions that only make sense in context:

* A Flutter project needs rules about `withOpacity()` deprecation, Riverpod provider invalidation patterns, and soundpool concurrency limits
* A Python RAG system needs rules about embedding model selection, chunking strategies, and vector store configuration
* A Next.js management system needs rules about server components vs. client components, API route patterns, and Supabase RLS policies

Mixing these in a global config means the AI thinks about Flutter providers when you're building a RAG pipeline. Separating them means each project gets exactly the context it needs.

The project layer also declares preferred skills — specific workflows that the AI should reach for in this context (e.g., "use `/deploy` for all production deployments").

### Layer 3: Knowledge — The Memory System

The knowledge layer splits into two complementary systems:

**Serena memories** store architectural knowledge: project structure, database schemas, API routes, deployment configurations. This is the "how the project is built" knowledge that's stable and factual.

**Claude MEMORY.md** stores experiential knowledge: debugging lessons, platform gotchas, approaches that failed and why. This is the "what we learned the hard way" knowledge that prevents repeating mistakes.

The separation matters because architecture changes slowly (you reorganize a project structure maybe once a quarter) while lessons accumulate continuously (every debugging session might produce a new gotcha).

## The Skill System

Skills are reusable workflows that encode multi-step processes. The Calibration Framework uses skills at two levels:

### Personal Skills (universal)

| Skill | Purpose |
|-------|---------|
| `/refactor` | Map scope → confirm → edit symbolically → verify → test |
| `/blast-radius` | Analyze impact of changing a symbol (read-only, no edits) |
| `/explore-arch` | Map a project's architecture using semantic tools |
| `/calibrate` | Validate configuration and review recent work for improvements |
| `/init-project` | Bootstrap a new project: detect stack, customize CLAUDE.md, install skills |

These work on any project because they're defined in terms of Serena's semantic operations, not in terms of any specific framework or language.

### Project Skills (contextual)

| Skill | Project | Purpose |
|-------|---------|---------|
| `/deploy` | GarrapAttack | Specific deployment to Hostinger VPS via Docker |

A Python project might have `/train-model` or `/run-pipeline`. A management system might have `/seed-db` or `/run-migrations`. The skill structure is the same; the content is project-specific.

### The Decision Tree

```
Is this workflow universal across all my projects?
├── YES → Personal skill (~/.claude/skills/)
│         Examples: /refactor, /blast-radius, /explore-arch
│
└── NO → Project skill (<project>/.claude/skills/)
          Examples: /deploy, /seed-db, /train-model
```

## The /calibrate Meta-Skill

The framework includes a self-diagnostic skill that operates in two modes:

### Audit Mode (setup & validation)

Run `/calibrate` on any project to verify all three layers are properly configured:

* **Layer 1 check:** Does the global CLAUDE.md have Serena workflow, editing principles, and meta-tool references?
* **Layer 2 check:** Does the project have its own CLAUDE.md with stack conventions, deployment config, and preferred skills?
* **Layer 3 check:** Do Serena memories exist with architecture documentation? Does MEMORY.md contain learnings (not duplicated conventions)?

Missing pieces are flagged with specific action items.

### Review Mode (continuous improvement)

Run `/calibrate review` after a significant work session to detect:

* **Uncaptured learnings:** Was a non-obvious bug root cause found that isn't in MEMORY.md yet?
* **Convention violations:** Were text-based edits used when symbolic editing was available? Were tests skipped after changes?
* **Workflow candidates:** Was the same sequence of actions performed manually more than once? That's a skill waiting to be formalized.
* **Stale documentation:** Has the project structure changed since the Serena memory was last updated?

### Full Mode

Run `/calibrate full` for both audit and review in a single pass — ideal for periodic maintenance or end-of-sprint reviews.

## Results: What Changes

Based on the friction analysis from 47 sessions, the Calibration Framework targets specific, measurable improvements:

| Friction Category | Count | Root Cause | Framework Solution |
|---|---|---|---|
| Collateral code damage | ~15 | Text-based `replace_all` | Symbolic editing via `replace_symbol_body` (Layer 1 principle) |
| Missing reference updates | ~10 | No impact analysis before edits | `find_referencing_symbols` as mandatory pre-edit step (Layer 1) |
| Repeated deployment debugging | 16 sessions | No deployment runbook | `/deploy` project skill + deployment config in Layer 2 |
| Wrong approach chosen | ~35 | No feasibility check | Meta-cognitive checkpoints + `/blast-radius` skill |
| Re-learning platform gotchas | Multiple | Lessons not persisted | MEMORY.md in Layer 3 |
| Context window bloat | Ongoing | Reading entire files | Symbolic exploration hierarchy in Layer 1 |

The framework doesn't eliminate logic errors (those still need tests) or novel platform issues (those still need debugging). What it eliminates is the preventable friction — the mistakes that come from not applying what was already known.

## Implementation Checklist

### For a new project

1. Run `calibrate-init.sh` from your project directory — creates structure, copies templates, configures MCP servers (Serena + any others you need)
2. Open Claude Code and run `/init-project` — detects your stack, customizes CLAUDE.md, installs relevant skills from the catalog, maps architecture with Serena
3. Start working. The framework tracks learnings automatically.
4. Run `/calibrate review` after each major work session

### For an existing project

1. Run `/calibrate full` — audit the current state and review recent sessions
2. Separate learnings from conventions in existing MEMORY.md
3. Move conventions to project CLAUDE.md, keep gotchas in MEMORY.md
4. Formalize any repeated manual workflows as skills
5. Update Serena memories if architecture has changed

## Key Takeaway

The tools are already here. AI assistants can navigate code semantically, persist memories across sessions, execute multi-step workflows, and access production infrastructure. What's missing isn't capability — it's methodology.

Every developer using an AI coding assistant is, whether they realize it or not, engaged in a new form of collaborative engineering. There are decisions about what knowledge the human holds vs. what the assistant carries, about when to delegate vs. when to direct, about how to encode working patterns so they compound over time instead of resetting. These are engineering decisions — but we don't yet treat them that way.

Software development went through this before. We moved from ad-hoc scripting to version control, from manual deployments to CI/CD, from tribal knowledge to documentation-as-code. Each transition took an implicit practice and made it explicit, systematic, and repeatable. The human-AI working relationship is at that same inflection point.

The Calibration Framework is a concrete proposal for what that methodology looks like: a layered architecture for separating concerns, a skill system for encoding workflows, and a self-diagnostic loop for continuous improvement. It emerged from 320 hours of real development across mobile apps, web apps, and production infrastructure — not as theory, but as a practical answer to a practical question: how do you engineer a human-AI collaboration that gets better over time?

The answer, it turns out, is the same one software engineering has always given: make the implicit explicit, and design the system intentionally.

Andrés & Claude
---

*Built with Claude Code + Serena MCP, February 2026. 47 sessions. 320 hours. 49 commits. One framework to calibrate the way we work with AI.*
