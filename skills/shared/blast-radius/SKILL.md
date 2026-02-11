---
name: blast-radius
description: Analyze the impact of changing a symbol before making any edits. Use to understand what will break before you touch it. Pass the symbol name as argument.
---

# Blast Radius Analysis

Analyze the impact of modifying a symbol **without making any changes**.

The user will provide a symbol name (and optionally a file path) via `$ARGUMENTS`.

## Steps

1. **Locate the symbol**
   - `find_symbol` to locate the exact symbol, read its signature and body
   - If ambiguous, list candidates and ask user to clarify

2. **Map all references**
   - `find_referencing_symbols` across the entire codebase
   - For each reference, capture: file, line, surrounding code snippet

3. **Classify each reference**
   - **Direct call** — will break if signature changes
   - **Type reference** — will break if type/interface/return changes
   - **Import only** — will break if symbol is renamed or moved
   - **Indirect** — accessed via variable, reflection, or dynamic dispatch

4. **Produce report**

```
## Blast Radius: <symbol name>
**Location:** <file>:<line>
**Signature:** <current signature>

### Summary
- Total references: N across M files
- Direct calls: X
- Type references: Y
- Import-only: Z

### Risk Level: low | medium | high
- low: 1-2 references, all in same module
- medium: 3-10 references, contained within one layer
- high: 10+ references, or spans multiple layers (UI + service + data)

### Reference Details
| # | File | Line | Type | Snippet |
|---|------|------|------|---------|
| 1 | ... | ... | call | ... |

### Recommendations
- [Safe to change in place / Needs coordinated update / Consider deprecation pattern]
```

5. **Do NOT make any changes** — this is analysis only
