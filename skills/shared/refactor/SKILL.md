---
name: refactor
description: Serena-powered multi-file refactoring workflow. Use when modifying code that spans multiple files or touches symbols referenced elsewhere.
---

# Refactor Workflow (Serena-Powered)

Follow these steps strictly. Do not skip the scope mapping phase.

## 1. Map Scope
- `get_symbols_overview` on all files that might be affected
- `find_symbol` with depth=1 on classes/modules being changed
- `find_referencing_symbols` on every symbol being modified
- List all affected files and callsites with line numbers

## 2. Confirm With User
Present a summary before any edit:
- **Symbols changing:** [list with file:line]
- **References that need updating:** [list with file:line and snippet]
- **Risk level:** low (1-2 refs) / medium (3-10) / high (10+)
- **Proposed approach:** symbol replacement vs rename vs signature change

Wait for explicit approval before proceeding.

## 3. Execute
- `replace_symbol_body` for body modifications
- `insert_after_symbol` / `insert_before_symbol` for additions
- `rename_symbol` for renames (handles all refs automatically)
- Regex-based edits only for small intra-symbol tweaks
- Call `think_about_task_adherence` before each edit

## 4. Verify
- `find_referencing_symbols` on every changed symbol — confirm no broken refs
- Run the project's test suite (detect from project: flutter test, npm test, pytest, etc.)
- Run static analysis if available (flutter analyze, tsc --noEmit, etc.)

## 5. Report
- Files modified: [list]
- Test results: pass/fail count
- Static analysis: clean or issues found
- Remaining concerns (if any)
