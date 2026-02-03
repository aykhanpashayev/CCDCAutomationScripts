#!/usr/bin/env bash
# ============================================================
# 00_jumpbox_setup.sh
# SECCDC / CCDC Jump Box Setup (Blue Team Safe)
#
# Purpose:
#   - Install essential defensive + ops tools on an EMPTY Linux jump box
#   - Create a clean workspace for notes, outputs, and IR bundles
#
# Safety:
#   - No offensive tools
#   - No data exfiltration
#   - Uses only official OS package repos (apt)
# ============================================================

set -Eeuo pipefail

# ----------------------------
# Pretty output helpers
# ----------------------------
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

log()  { echo -e "${GREEN}[+]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
err()  { echo -e "${RED}[-]${RESET} $*"; }

# ----------------------------
# Hard checks (friendly)
# ----------------------------
if [[ "${EUID}" -ne 0 ]]; then
  err "Please run as root. Example: sudo $0"
  exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
  err "This script requires 'apt' (Debian/Ubuntu). Your OS may be different."
  err "If you're on a different distro, we can make a yum/dnf version."
  exit 1
fi

log "Starting Jump Box setup..."

# ----------------------------
# Tool list (organized by purpose)
# ----------------------------
# Network + service checks:
PKG_NET=(
  curl wget
  iputils-ping
  netcat-openbsd
  nmap
  dnsutils
)

# System visibility:
PKG_SYS=(
  htop
  lsof
  psmisc
)

# Logs + parsing:
PKG_LOG=(
  lnav
  jq
)

# Backups + file ops:
PKG_FILE=(
  rsync
  zip unzip
  tree
)

# Productivity:
PKG_PROD=(
  tmux
  vim
  nano
)

# Basic certs + HTTPS sanity:
PKG_BASE=(
  ca-certificates
)

# Combine all packages:
ALL_PKGS=(
  "${PKG_BASE[@]}"
  "${PKG_NET[@]}"
  "${PKG_SYS[@]}"
  "${PKG_LOG[@]}"
  "${PKG_FILE[@]}"
  "${PKG_PROD[@]}"
)

# ----------------------------
# Update + Install
# ----------------------------
log "Updating package list (apt update)..."
apt update -y >/dev/null

log "Installing core tools (this may take a minute)..."
# Show a clean list of what's being installed
echo "    Packages:"
for p in "${ALL_PKGS[@]}"; do
  echo "      - $p"
done

# Install quietly but still show errors if any
DEBIAN_FRONTEND=noninteractive apt install -y "${ALL_PKGS[@]}" >/dev/null

log "Tool installation complete."

# ----------------------------
# Create workspace
# ----------------------------
# Use the calling user's home (not /root) so teammates find it easily
# If run with sudo, SUDO_USER is set; otherwise fallback.
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(eval echo "~${TARGET_USER}")"

WORKDIR="${TARGET_HOME}/ccdc"
log "Creating workspace in: ${WORKDIR}"

mkdir -p "${WORKDIR}"/{notes,outputs,ir_bundles,scripts,hosts,templates}

# Add a quick README inside the workspace
cat > "${WORKDIR}/README.txt" <<'EOF'
CCDC Workspace
==============

notes/       -> quick notes, credentials (ONLY if allowed), observations
outputs/     -> command outputs, service checks, quick snapshots
ir_bundles/  -> incident-response evidence bundles (keep internal!)
hosts/       -> host lists (IP + name)
scripts/     -> your helper scripts
templates/   -> incident report & inject templates

Reminder:
- Do NOT upload competition artifacts/logs outside the competition environment.
- Use tools to check, restore, document, and report.
EOF

chown -R "${TARGET_USER}:${TARGET_USER}" "${WORKDIR}" 2>/dev/null || true

log "Workspace ready."

# ----------------------------
# Quick verification (non-fancy)
# ----------------------------
log "Verifying key tools are available..."
NEEDED=(curl nc nmap dig htop lnav jq rsync tmux)
missing=0
for t in "${NEEDED[@]}"; do
  if ! command -v "${t}" >/dev/null 2>&1; then
    warn "Missing tool: ${t}"
    missing=1
  fi
done

if [[ "${missing}" -eq 0 ]]; then
  log "All key tools found ✅"
else
  warn "Some tools were missing. Check apt output or rerun install."
fi

# ----------------------------
# Friendly next steps
# ----------------------------
echo ""
log "Done. Next steps:"
echo "  1) Put your host list in: ${WORKDIR}/hosts/hosts.txt"
echo "     Format: <ip_or_host> <label>"
echo "     Example: 10.250.5X.10 frontier"
echo ""
echo "  2) Next script we will add: service check + scoreboard sanity"
echo ""
warn "Remember: do NOT install tools that record keystrokes/screens or upload samples externally."