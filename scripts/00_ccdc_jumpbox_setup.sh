#!/usr/bin/env bash
# ===============================================================
# 00_ccdc_jumpbox_setup.sh
#
# SECCDC / CCDC Jump Box Preparation Script (Blue Team)
#
# Purpose:
#   Prepare an EMPTY Linux jump box to be a CCDC "workstation":
#     - service checks (scoring visibility)
#     - log viewing (IR + triage)
#     - backup/restore helpers (web defacement recovery)
#     - multitasking + clean workspace
#
# CCDC Context:
#   - Jump boxes are NOT scored and typically OUT OF SCOPE for Red Team.
#   - Do NOT "harden" the jump box or block traffic on it.
#
# Safety:
#   - No offensive tooling
#   - No external uploads/exfil
#   - Installs only from OS package repos (apt)
# ===============================================================

# ---- Ensure Bash (prevents "notes, command not found" type issues if run with sh)
if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "[FAIL] This script must be run with bash."
  echo "       Try: sudo bash $0"
  exit 1
fi

set -Eeuo pipefail

# -------------------------------
# Output formatting (clean)
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
# Hard checks
# -------------------------------
if [[ "${EUID}" -ne 0 ]]; then
  fail "Run with sudo."
  echo "Example: sudo bash $0"
  exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
  fail "apt not found (not Debian/Ubuntu)."
  fail "Tell me the distro and I'll provide a dnf/yum version."
  exit 1
fi

info "SECCDC Jump Box preparation started."

# -------------------------------
# Tool selection (CCDC-driven)
# -------------------------------

# Service availability & scoring
PKG_SCORING=(
  curl            # verify HTTP responses like scoring checks
  wget            # quick downloads from internal resources if needed
  iputils-ping    # basic host liveness
  netcat-openbsd  # port checks (SSH/HTTP/RDP/etc.)
  nmap            # light port verification on OWN hosts
  dnsutils        # dig/nslookup for DNS checks
)

# System triage / visibility
PKG_VISIBILITY=(
  htop            # CPU/memory triage
  lsof            # what process owns a port/file
  psmisc          # pstree/killall (use carefully)
)

# Logs + IR
PKG_IR=(
  lnav            # fast multi-log viewing
  jq              # parse JSON outputs/logs cleanly
)

# Backup & restore helpers
PKG_RECOVERY=(
  rsync
  zip unzip
  tree
)

# Operator productivity
PKG_OPS=(
  tmux
  vim
  nano
)

# Base OS sanity
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
info "Updating package index (apt update)..."
apt update -y >/dev/null

info "Installing CCDC-approved tools:"
for pkg in "${ALL_PKGS[@]}"; do
  echo "   - $pkg"
done

DEBIAN_FRONTEND=noninteractive apt install -y "${ALL_PKGS[@]}" >/dev/null
ok "Tool installation complete."

# -------------------------------
# Workspace layout (NO brace expansion; avoids 'notes, command not found')
# -------------------------------
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(eval echo "~${TARGET_USER}")"
WORKDIR="${TARGET_HOME}/ccdc"

info "Creating CCDC workspace at: ${WORKDIR}"

mkdir -p "${WORKDIR}/notes"       # observations, timestamps, findings
mkdir -p "${WORKDIR}/outputs"     # service checks & command outputs
mkdir -p "${WORKDIR}/ir_bundles"  # evidence bundles for IR reports (keep internal)
mkdir -p "${WORKDIR}/scripts"     # playbook scripts
mkdir -p "${WORKDIR}/hosts"       # IP/hostname lists
mkdir -p "${WORKDIR}/templates"   # IR + inject templates

cat > "${WORKDIR}/README.txt" <<'EOF'
CCDC Jump Box Workspace
======================

notes/        -> observations, timestamps, findings
outputs/      -> service checks & command output
ir_bundles/   -> incident response evidence (KEEP INTERNAL)
hosts/        -> IP/hostname lists for scripts
scripts/      -> approved blue-team helper scripts
templates/    -> incident report & inject templates

IMPORTANT:
- Do NOT upload logs, artifacts, or malware outside the competition.
- Restore services FIRST, investigate SECOND.
- Documentation can recover points.
EOF

chown -R "${TARGET_USER}:${TARGET_USER}" "${WORKDIR}" 2>/dev/null || true
ok "Workspace ready."

# -------------------------------
# Verification (confidence check)
# -------------------------------
info "Verifying critical tools..."
REQUIRED=(curl wget nc nmap dig htop lnav jq rsync tmux)
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
  warn "Some tools appear missing. Re-run install or check apt errors."
fi

# -------------------------------
# Friendly next steps
# -------------------------------
echo ""
info "Next steps for the team:"
echo "  1) Put your host list here:"
echo "       ${WORKDIR}/hosts/hosts.txt"
echo "     Format:"
echo "       <ip_or_host> <label>"
echo "     Example:"
echo "       10.250.5X.10 frontier"
echo ""
echo "  2) Next script (we'll build next):"
echo "       10_ccdc_service_check.sh"
echo "     - reads hosts.txt"
echo "     - checks common scored ports"
echo "     - saves a clean report to outputs/"
echo ""
warn "Reminder: Jump box is a WORKSTATION. Don't harden it or block traffic."
ok "SECCDC Jump Box setup complete."