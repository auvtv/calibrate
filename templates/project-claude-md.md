# Project CLAUDE.md Template
# Copy to <your-project>/.claude/CLAUDE.md and customize

# <Project Name> — Project Conventions

## Stack
- **Language:** [TypeScript, Python, Dart, etc.]
- **Framework:** [Next.js, Flask, Flutter, etc.]
- **Database:** [PostgreSQL, MongoDB, SQLite, etc.]
- **Infrastructure:** [Docker, Vercel, VPS, etc.]

## Preferred Workflows
- Use `/refactor` for any multi-file code change
- Use `/blast-radius <symbol>` before changing widely-referenced symbols
- Use `/calibrate` periodically to verify workspace config
# Add project-specific skills below:
# - Use `/deploy` for production deployments
# - Use `/seed-db` for database seeding

## Conventions
# Add framework-specific conventions here. Examples:
# - After any Dart file change: run `flutter analyze`
# - Server components by default, `use client` only when needed
# - All API routes return { data, error } shape

## Architecture Decisions
# Document key design decisions that affect how code should be written.
# Examples:
# - Offline-first: load data locally, sync in background
# - Event-driven: all mutations emit events, listeners handle side effects

## Deployment
# Add deployment-specific configuration. Examples:
# - Server: 192.168.1.1, path: /opt/myapp/
# - Docker: docker-compose.prod.yml
# - CI/CD: GitHub Actions → deploy on push to main

## Testing
# - Describe how to run tests: `npm test`, `flutter test`, `pytest`
# - List any testing constraints or known limitations
# - Specify what to run after changes (linter, type check, test suite)
