#!/usr/bin/env bash
# ===============================================================
# 00_ccdc_jumpbox_setup.sh
#
# SECCDC / CCDC Jump Box Preparation Script (Blue Team)
#
# This script prepares a COMPETITION JUMP BOX.
# It is NOT a server hardening script.
#
# CCDC Context:
# - Jump boxes are OUT OF SCOPE for Red Team
# - Jump boxes are NOT scored
# - Jump boxes are used to:
#     * Access scored servers (SSH/RDP)
#     * Check service availability
#     * Read logs
#     * Restore content
#     * Write incident response reports
#
# Installing ONLY tools that:
# - Improve visibility
# - Improve recovery speed
# - Improve documentation quality
#
# NO offensive tools.
# NO data exfiltration.
# NO security agents.
# ===============================================================

set -Eeuo pipefail

# -------------------------------
# Output formatting (clean & calm)
# -------------------------------
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
ok()   { echo -e "${GREEN}[ OK ]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "${RED}[FAIL]${RESET} $*"; }

# -------------------------------
# Safety & environment checks
# -------------------------------
if [[ "${EUID}" -ne 0 ]]; then
  fail "Run this script with sudo."
  echo "Example: sudo $0"
  exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
  fail "This jump box is not Debian/Ubuntu (apt not found)."
  fail "CCDC typically uses Ubuntu jump boxes."
  exit 1
fi

info "SECCDC Jump Box preparation started."

# -------------------------------
# Tool selection (CCDC-driven)
# -------------------------------

# ---- Service availability & scoring ----
PKG_SCORING=(
  curl            # verify HTTP responses exactly like scoring engine
  iputils-ping    # quick host liveness
  netcat-openbsd  # port-level service checks (SSH, HTTP, RDP, etc.)
  nmap            # light service discovery on OWN hosts only
  dnsutils        # dig/nslookup for DNS scoring
)

# ---- System visibility & triage ----
PKG_VISIBILITY=(
  htop            # CPU/memory abuse & DoS symptoms
  lsof            # identify what is holding ports/files
  psmisc          # killall, pstree (used carefully)
)

# ---- Logs & incident response ----
PKG_IR=(
  lnav            # fast multi-log timeline analysis (huge CCDC advantage)
  jq              # parse JSON logs/output cleanly
)

# ---- Backup & restore (defacement recovery) ----
PKG_RECOVERY=(
  rsync           # fast restore of known-good content
  zip unzip
  tree            # detect unauthorized file additions
)

# ---- Operator productivity (chaos control) ----
PKG_OPS=(
  tmux            # multiple sessions during attacks
  vim nano
)

# ---- Base OS sanity ----
PKG_BASE=(
  ca-certificates
)

ALL_PKGS=(
  "${PKG_BASE[@]}"
  "${PKG_SCORING[@]}"
  "${PKG_VISIBILITY[@]}"
  "${PKG_IR[@]}"
  "${PKG_RECOVERY[@]}"
  "${PKG_OPS[@]}"
)

# -------------------------------
# Install phase
# -------------------------------
info "Updating package index..."
apt update -y >/dev/null

info "Installing CCDC-approved toolset:"
for pkg in "${ALL_PKGS[@]}"; do
  echo "   - $pkg"
done

DEBIAN_FRONTEND=noninteractive apt install -y "${ALL_PKGS[@]}" >/dev/null
ok "Tool installation complete."

# -------------------------------
# Workspace layout (CCDC-oriented)
# -------------------------------
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(eval echo "~${TARGET_USER}")"
WORKDIR="${TARGET_HOME}/ccdc"

info "Creating CCDC workspace at ${WORKDIR}"

mkdir -p "${WORKDIR}"/{
  notes,          # credentials (if allowed), observations, timelines
  outputs,        # service checks, command outputs
  ir_bundles,     # evidence collected for IR reports
  scripts,        # playbook scripts
  hosts,          # host/IP lists
  templates       # inject & IR templates
}

cat > "${WORKDIR}/README.txt" <<'EOF'
CCDC Jump Box Workspace
======================

This directory exists ONLY for competition operations.

notes/        -> observations, timestamps, findings
outputs/      -> service checks & command output
ir_bundles/   -> incident response evidence (KEEP INTERNAL)
hosts/        -> IP/hostname lists for scripts
scripts/      -> approved blue-team helper scripts
templates/    -> incident report & inject templates

IMPORTANT:
- Do NOT upload logs, artifacts, or malware outside the competition.
- Restore services FIRST, investigate SECOND.
- Documentation recovers points.
EOF

chown -R "${TARGET_USER}:${TARGET_USER}" "${WORKDIR}" 2>/dev/null || true
ok "Workspace ready."

# -------------------------------
# Verification (confidence check)
# -------------------------------
info "Verifying critical tools..."
REQUIRED=(curl nc nmap dig htop lnav jq rsync tmux)
missing=0

for tool in "${REQUIRED[@]}"; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    warn "Missing tool: ${tool}"
    missing=1
  fi
done

if [[ "${missing}" -eq 0 ]]; then
  ok "All required CCDC tools are available."
else
  warn "Some tools are missing — investigate before competition."
fi

# -------------------------------
# CCDC reminders (printed on run)
# -------------------------------
echo ""
info "CCDC Reminders:"
echo " - Jump boxes are NOT defended and NOT scored."
echo " - Do NOT harden or restrict the jump box."
echo " - Do NOT install tools that upload data externally."
echo " - Use tools for visibility, restoration, and documentation."

ok "SECCDC Jump Box setup complete."