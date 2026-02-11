#!/usr/bin/env bash
set -euo pipefail

# calibrate-init.sh — Bootstrap a new project for the Calibration Framework
#
# Run from inside a project directory:
#   calibrate-init.sh [--with-mcp serena,ssh,browser] [--no-mcp]
#
# What it does:
#   1. Verifies global prerequisites (Layer 1)
#   2. Creates project structure (.claude/, CLAUDE.md template)
#   3. Configures MCP servers (Serena is mandatory)
#   4. Prints next steps for /init-project skill
#
# Config file: ~/.calibrate.conf
#   Persistent defaults so you don't get asked the same questions every time.
#   Created automatically on first run, or create manually:
#     SERENA_PATH=/path/to/serena
#     CALIBRATE_REPO=/path/to/calibrate

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}→${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; }

# --- Load config file ---
CONF_FILE="$HOME/.calibrate.conf"
if [[ -f "$CONF_FILE" ]]; then
  # Source only known variables (safe loading)
  while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d ' ')
    value=$(echo "$value" | tr -d ' ' | sed 's/^"//' | sed 's/"$//')
    case "$key" in
      SERENA_PATH)   CONF_SERENA_PATH="$value" ;;
      CALIBRATE_REPO) export CALIBRATE_REPO="$value" ;;
      SSH_DEFAULT_KEY) CONF_SSH_DEFAULT_KEY="$value" ;;
    esac
  done < <(grep -v '^#' "$CONF_FILE" | grep -v '^$')
fi

# Save a value to config file (creates file if needed)
save_to_conf() {
  local key="$1" value="$2"
  if [[ -f "$CONF_FILE" ]] && grep -q "^$key=" "$CONF_FILE" 2>/dev/null; then
    # Update existing key
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|^$key=.*|$key=$value|" "$CONF_FILE"
    else
      sed -i "s|^$key=.*|$key=$value|" "$CONF_FILE"
    fi
  else
    # Append new key (create file if needed)
    echo "$key=$value" >> "$CONF_FILE"
  fi
}

# --- Locate calibrate repo ---
find_calibrate_repo() {
  if [[ -n "${CALIBRATE_REPO:-}" ]] && [[ -f "$CALIBRATE_REPO/catalog.json" ]]; then
    echo "$CALIBRATE_REPO"
    return
  fi

  local candidates=(
    "../calibrate"
    "$HOME/calibrate"
    "$HOME/projects/calibrate"
  )

  for dir in "${candidates[@]}"; do
    if [[ -f "$dir/catalog.json" ]]; then
      echo "$(cd "$dir" && pwd)"
      return
    fi
  done

  return 1
}

# --- Parse arguments ---
MCP_LIST=""
NO_MCP=false
SERENA_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-mcp)
      MCP_LIST="$2"
      shift 2
      ;;
    --no-mcp)
      NO_MCP=true
      shift
      ;;
    --serena-path)
      SERENA_PATH="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: calibrate-init.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --with-mcp LIST    Comma-separated MCP servers to configure (serena,ssh,browser,context7)"
      echo "  --no-mcp           Skip MCP configuration entirely"
      echo "  --serena-path DIR  Path to local Serena installation (overrides config file)"
      echo "  -h, --help         Show this help"
      echo ""
      echo "Config file: ~/.calibrate.conf"
      echo "  Persistent defaults (created on first run):"
      echo "    SERENA_PATH=/path/to/serena"
      echo "    CALIBRATE_REPO=/path/to/calibrate"
      echo "    SSH_DEFAULT_KEY=~/.ssh/my_key"
      echo ""
      echo "Run from inside your project directory."
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      exit 1
      ;;
  esac
done

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Calibration Framework — Project Init   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
info "Project: $PROJECT_NAME"
info "Directory: $PROJECT_DIR"
echo ""

# ============================================================
# STEP 1: Locate calibrate repo
# ============================================================
info "Locating calibrate repo..."

CALIBRATE_REPO=""
if CALIBRATE_REPO=$(find_calibrate_repo); then
  ok "Found calibrate repo at: $CALIBRATE_REPO"
else
  fail "Could not find calibrate repo."
  echo "  Set CALIBRATE_REPO env var or clone it to ../calibrate or ~/calibrate"
  exit 1
fi

# ============================================================
# STEP 2: Verify global prerequisites (Layer 1)
# ============================================================
echo ""
info "Checking global prerequisites (Layer 1)..."

GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [[ -f "$GLOBAL_CLAUDE_MD" ]]; then
  ok "Global CLAUDE.md exists"
else
  warn "Global CLAUDE.md not found at $GLOBAL_CLAUDE_MD"
  read -p "  Copy template from calibrate repo? [Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cp "$CALIBRATE_REPO/templates/global-claude-md.md" "$GLOBAL_CLAUDE_MD"
    ok "Copied global CLAUDE.md template"
  fi
fi

# Check personal skills
PERSONAL_SKILLS=("refactor" "blast-radius" "explore-arch" "calibrate" "init-project")
SKILLS_DIR="$HOME/.claude/skills"
MISSING_SKILLS=()

for skill in "${PERSONAL_SKILLS[@]}"; do
  if [[ -f "$SKILLS_DIR/$skill/SKILL.md" ]]; then
    ok "Skill /$skill installed"
  else
    MISSING_SKILLS+=("$skill")
  fi
done

if [[ ${#MISSING_SKILLS[@]} -gt 0 ]]; then
  warn "Missing personal skills: ${MISSING_SKILLS[*]}"
  read -p "  Install from calibrate repo? [Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    for skill in "${MISSING_SKILLS[@]}"; do
      mkdir -p "$SKILLS_DIR/$skill"
      if [[ -f "$CALIBRATE_REPO/skills/shared/$skill/SKILL.md" ]]; then
        cp "$CALIBRATE_REPO/skills/shared/$skill/SKILL.md" "$SKILLS_DIR/$skill/SKILL.md"
        ok "Installed /$skill"
      else
        warn "Skill $skill not found in calibrate repo (skills/shared/$skill/SKILL.md)"
      fi
    done
  fi
fi

# ============================================================
# STEP 3: Create project structure
# ============================================================
echo ""
info "Creating project structure..."

mkdir -p .claude/skills
ok "Created .claude/skills/"

if [[ ! -f "CLAUDE.md" ]]; then
  cp "$CALIBRATE_REPO/templates/project-claude-md.md" CLAUDE.md
  # Replace placeholder project name
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/# <Project Name>/# $PROJECT_NAME/" CLAUDE.md
  else
    sed -i "s/# <Project Name>/# $PROJECT_NAME/" CLAUDE.md
  fi
  ok "Created CLAUDE.md from template (needs customization)"
else
  warn "CLAUDE.md already exists — skipping"
fi

# Add .claude/settings.local.json to .gitignore if not already there
if [[ -f ".gitignore" ]]; then
  if ! grep -q "settings.local.json" .gitignore 2>/dev/null; then
    echo ".claude/settings.local.json" >> .gitignore
    ok "Added .claude/settings.local.json to .gitignore"
  fi
else
  echo ".claude/settings.local.json" > .gitignore
  ok "Created .gitignore with .claude/settings.local.json"
fi

# ============================================================
# STEP 4: Configure MCP servers
# ============================================================
echo ""

if $NO_MCP; then
  warn "Skipping MCP configuration (--no-mcp)"
else
  info "Configuring MCP servers..."

  # Build MCP list
  if [[ -z "$MCP_LIST" ]]; then
    echo "  Which MCP servers should be configured?"
    echo ""
    echo "  Available:"
    echo "    1) serena    — Semantic code navigation (recommended for all projects)"
    echo "    2) ssh       — SSH access for deployment"
    echo "    3) browser   — Browser automation"
    echo "    4) context7  — Library documentation lookup"
    echo ""
    echo "  Enter numbers separated by commas (e.g., 1,2):"
    read -p "  > " mcp_choices

    MCP_LIST=""
    IFS=',' read -ra choices <<< "$mcp_choices"
    for choice in "${choices[@]}"; do
      choice=$(echo "$choice" | tr -d ' ')
      case "$choice" in
        1) MCP_LIST="${MCP_LIST:+$MCP_LIST,}serena" ;;
        2) MCP_LIST="${MCP_LIST:+$MCP_LIST,}ssh" ;;
        3) MCP_LIST="${MCP_LIST:+$MCP_LIST,}browser" ;;
        4) MCP_LIST="${MCP_LIST:+$MCP_LIST,}context7" ;;
        *) warn "Unknown choice: $choice" ;;
      esac
    done
  fi

  # Always include serena (mandatory)
  if [[ ! "$MCP_LIST" == *"serena"* ]]; then
    MCP_LIST="serena${MCP_LIST:+,$MCP_LIST}"
    info "Added serena (mandatory)"
  fi

  IFS=',' read -ra mcps <<< "$MCP_LIST"
  for mcp in "${mcps[@]}"; do
    mcp=$(echo "$mcp" | tr -d ' ')
    case "$mcp" in
      serena)
        info "Configuring Serena MCP..."
        # Resolve Serena path: CLI flag > config file > ask
        serena_dir="${SERENA_PATH:-${CONF_SERENA_PATH:-}}"
        if [[ -z "$serena_dir" ]]; then
          echo "  Serena install path (e.g., ~/serena or /path/to/serena):"
          read -p "  > " serena_dir
          serena_dir="${serena_dir/#\~/$HOME}"
        fi

        if [[ -d "$serena_dir" ]]; then
          claude mcp add --transport stdio --scope project serena -- \
            uv run --directory "$serena_dir" serena start-mcp-server \
            --context ide-assistant --project "$PROJECT_DIR"
          ok "Serena configured (path: $serena_dir)"

          # Offer to remember for next time
          if [[ -z "${CONF_SERENA_PATH:-}" ]]; then
            read -p "  Save Serena path to ~/.calibrate.conf for future projects? [Y/n] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
              save_to_conf "SERENA_PATH" "$serena_dir"
              ok "Saved to ~/.calibrate.conf"
            fi
          fi
        else
          fail "Directory not found: $serena_dir"
          warn "You'll need to configure Serena manually:"
          echo "  claude mcp add --transport stdio --scope project serena -- \\"
          echo "    uv run --directory /path/to/serena serena start-mcp-server \\"
          echo "    --context ide-assistant --project $PROJECT_DIR"
        fi
        ;;

      ssh)
        info "Configuring SSH MCP..."
        echo "  SSH host (e.g., myserver.example.com):"
        read -p "  > " ssh_host
        echo "  SSH user [root]:"
        read -p "  > " ssh_user
        ssh_user="${ssh_user:-root}"
        default_key="${CONF_SSH_DEFAULT_KEY:-$HOME/.ssh/id_rsa}"
        echo "  SSH key path [$default_key]:"
        read -p "  > " ssh_key
        ssh_key="${ssh_key:-$default_key}"
        ssh_key="${ssh_key/#\~/$HOME}"

        local_name="ssh-${ssh_host%%.*}"
        claude mcp add --transport stdio --scope project "$local_name" -- \
          npx -y ssh-mcp -- \
          "--host=$ssh_host" "--user=$ssh_user" "--key=$ssh_key"
        ok "SSH MCP configured as $local_name"

        # Offer to save default key for future projects
        if [[ -z "${CONF_SSH_DEFAULT_KEY:-}" ]]; then
          read -p "  Save SSH key as default for future projects? [Y/n] " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            save_to_conf "SSH_DEFAULT_KEY" "$ssh_key"
            ok "Saved default SSH key to ~/.calibrate.conf"
          fi
        fi
        ;;

      browser)
        info "Configuring Browser MCP..."
        claude mcp add --transport stdio --scope user browser -- \
          npx -y @anthropic/agent-browser
        ok "Browser MCP configured (user scope — shared across projects)"
        ;;

      context7)
        info "Configuring Context7 MCP..."
        claude mcp add --transport stdio --scope project context7 -- \
          npx -y @anthropic/context7-mcp
        ok "Context7 configured"
        ;;

      *)
        warn "Unknown MCP server: $mcp — skipping"
        ;;
    esac
  done
fi

# ============================================================
# STEP 5: Summary
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Init Complete                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
ok "Project structure created"
ok "CLAUDE.md template in place"
[[ "$NO_MCP" == false ]] && ok "MCP servers configured"
ok "Personal skills verified"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Open Claude Code in this project"
echo "  2. Run ${YELLOW}/init-project${NC} to:"
echo "     - Auto-detect your stack and customize CLAUDE.md"
echo "     - Install relevant skills from the catalog"
echo "     - Map architecture with /explore-arch"
echo "     - Create initial Serena memories"
echo ""
echo "  Or manually edit CLAUDE.md and run ${YELLOW}/calibrate${NC} to verify setup."
echo ""
