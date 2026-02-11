---
name: deploy-docker
description: "Deploy a web app via Docker Compose to a VPS. Handles build verification, git push, Docker rebuild, and post-deploy checks. Pass 'web', 'admin', or 'both' as argument."
---

# Deploy via Docker Compose

Target is specified via `$ARGUMENTS`: "web" (default), "admin", or "both".

**Before using:** Replace all `<PLACEHOLDERS>` with your actual values.

## Pre-Deploy Checks

1. **Verify no uncommitted changes**
   - `git status` — if dirty, ask user whether to commit first

2. **Run tests** (if applicable to changed files)
   - Flutter changes: `flutter test` + `flutter analyze` in `mobile/`
   - Web/API changes: verify TypeScript compiles (`npx tsc --noEmit` or build)
   - Admin changes: verify build

3. **Verify environment**
   - Check `.env` exists and has required vars (e.g., `DATABASE_URL`)
   - Reminder: `NEXT_PUBLIC_*` vars are baked at build time, not runtime

4. **Push to remote**
   - `git push origin main`

## Deploy Web App

Execute via SSH MCP:

```bash
cd <APP_PATH>
git pull
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

## Deploy Admin App

Execute via SSH MCP:

```bash
cd <APP_PATH>/admin
docker compose -f docker-compose.admin.yml down
docker compose -f docker-compose.admin.yml build --no-cache
docker compose -f docker-compose.admin.yml up -d
```

## Post-Deploy Verification

Execute via SSH MCP:

1. **Container health:**
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
   ```

2. **Web app (if deployed):**
   ```bash
   curl -s -o /dev/null -w "%{http_code}" https://<YOUR_DOMAIN>
   curl -s https://<YOUR_DOMAIN>/api/health | head -c 200
   ```

3. **Admin app (if deployed):**
   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://<SERVER_IP>:<ADMIN_PORT>
   ```

4. **Check logs for errors:**
   ```bash
   docker logs <WEB_CONTAINER> --tail 30 2>&1 | grep -i error
   ```

## Common Issues & Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Build fails on API routes | `DATABASE_URL` missing at build time | Add to `docker-compose.prod.yml` build args |
| `NEXT_PUBLIC_*` vars empty in client | Not set during `docker build` | Must be in build args, not just runtime env |
| 502 Bad Gateway | Container not on shared network | Check Docker network in compose |
| DB connection refused | Postgres container down | `docker ps` and restart Postgres container |
| CORS errors | Nginx missing headers | Check nginx site config |
| CSS/JS not loading | Stale build cache | Rebuild with `--no-cache` |

## Report

After deployment, present:
- Deploy target: web / admin / both
- Build: success / failed (with error)
- Container status: running / unhealthy
- HTTP checks: status codes
- Errors in logs: none / [list]
- **Verdict: DEPLOYED SUCCESSFULLY / NEEDS ATTENTION**
