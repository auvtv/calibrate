---
name: explore-arch
description: Map the architecture of a project or subsystem using Serena's symbolic tools. Use at the start of a new project or when entering an unfamiliar area of the codebase.
---

# Architecture Exploration (Serena-Powered)

Map the architecture of the current project or a specific subsystem.
If `$ARGUMENTS` specifies a directory or subsystem, scope the exploration there.

## Steps

1. **Check existing knowledge**
   - Read Serena project memories if they exist (list_memories → read_memory)
   - If a `project-overview` memory already exists, start from there and update rather than re-exploring

2. **Map structure**
   - `list_dir` recursive on the target directory (or project root)
   - Identify entry points: main, index, app, routes, schema, config files

3. **Discover key symbols**
   - `get_symbols_overview` on entry points and core files
   - `find_symbol` with depth=1 on main classes, services, controllers, models

4. **Trace dependencies**
   - `find_referencing_symbols` on core symbols to map how components connect
   - Identify the dependency direction (who depends on whom)

5. **Identify patterns**
   - State management approach (Redux, Riverpod, Context, custom)
   - Data flow (API → service → repository → model → UI)
   - Auth pattern (middleware, guards, session)
   - Cross-cutting concerns (logging, error handling, validation)

6. **Produce summary**

```
## Architecture: <project or subsystem>

### Stack
- [Language, framework, key libraries]

### Layer Diagram
- [Data layer] → [Service layer] → [UI layer]
- (or whatever pattern the project uses)

### Entry Points
- [file] — [responsibility]

### Core Symbols
- [Class/Module] — [what it does, key methods]

### Data Flow
- [How data moves through the system]

### Cross-Cutting Concerns
- Auth: [approach]
- Error handling: [approach]
- State management: [approach]
```

7. **Offer to persist**
   - Ask user if they want to save this as a Serena memory (`write_memory`)
   - Suggested memory name: `project-overview` or `<subsystem>-architecture`
