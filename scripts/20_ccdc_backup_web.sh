#!/usr/bin/env bash
# ===============================================================
# 20_ccdc_backup_web.sh
#
# SECCDC / CCDC Web Backup Script (Blue Team)
#
# Purpose (CCDC-specific):
#   Create a FAST, LOCAL, "known-good" backup of a web service so you
#   can restore from defacement or accidental breakage in seconds.
#
# Why this matters in CCDC:
#   - Web defacements are common ("stickers", changed HTML/JS/images).
#   - Points are lost when content/behavior deviates from expected.
#   - The fastest winning move is: evidence -> restore -> stabilize.
#
# What this script backs up:
#   1) Web root content (default: /var/www/html)
#   2) Web server config (Apache /etc/apache2 OR Nginx /etc/nginx)
#   3) A small "snapshot" file with metadata for IR (optional evidence)
#
# What this script does NOT do:
#   - No hardening
#   - No firewall changes
#   - No uploading off-network
#
# Output:
#   Saves backups under: /root/ccdc_backups/web/
#   Example files:
#     webroot_<host>_<label>_<timestamp>.tar.gz
#     apache2_<host>_<label>_<timestamp>.tar.gz
#     nginx_<host>_<label>_<timestamp>.tar.gz
#     snapshot_<host>_<label>_<timestamp>.txt
#
# Usage:
#   sudo bash 20_ccdc_backup_web.sh
#
# Optional variables:
#   WEBROOT=/var/www/html
#   LABEL=baseline
#   OUTDIR=/root/ccdc_backups/web
#
# Example:
#   sudo LABEL=day1 WEBROOT=/var/www/html bash 20_ccdc_backup_web.sh
# ===============================================================

# ---- Ensure Bash
if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "[FAIL] This script must be run with bash."
  echo "       Try: sudo bash $0"
  exit 1
fi

set -Eeuo pipefail

# -------------------------------
# Output formatting
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
# Safety checks
# -------------------------------
if [[ "${EUID}" -ne 0 ]]; then
  fail "Run with sudo/root."
  echo "Example: sudo bash $0"
  exit 1
fi

need_cmd() {
  local c="$1"
  if ! command -v "$c" >/dev/null 2>&1; then
    fail "Missing required command: $c"
    echo "Install it (Debian/Ubuntu): sudo apt install -y $c"
    exit 1
  fi
}

need_cmd tar
need_cmd date
need_cmd hostname
need_cmd find
need_cmd du
need_cmd ls
need_cmd stat

# -------------------------------
# Config (CCDC-friendly defaults)
# -------------------------------
WEBROOT="${WEBROOT:-/var/www/html}"
LABEL="${LABEL:-day1}"                  # e.g., day1, baseline, pre-hardening
OUTDIR="${OUTDIR:-/root/ccdc_backups/web}"
TS="$(date +%Y%m%d_%H%M%S)"
HOST_SHORT="$(hostname -s 2>/dev/null || hostname)"
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown-ip")"

# Sanitize label (avoid spaces/slashes)
SAFE_LABEL="$(echo "$LABEL" | tr ' /' '__' | tr -cd '[:alnum:]_-')"

# -------------------------------
# Validate webroot
# -------------------------------
if [[ ! -d "$WEBROOT" ]]; then
  fail "WEBROOT directory not found: $WEBROOT"
  echo "Set WEBROOT explicitly, e.g.:"
  echo "  sudo WEBROOT=/srv/www bash $0"
  exit 1
fi

# -------------------------------
# Prepare output dir
# -------------------------------
mkdir -p "$OUTDIR"
chmod 700 "$OUTDIR" || true

info "CCDC Web Backup (local)"
info "Host:     ${HOST_SHORT} (${HOST_IP})"
info "Label:    ${SAFE_LABEL}"
info "Webroot:  ${WEBROOT}"
info "Outdir:   ${OUTDIR}"
echo ""

# -------------------------------
# Snapshot metadata (helps IR + sanity)
# -------------------------------
SNAPSHOT="${OUTDIR}/snapshot_${HOST_SHORT}_${SAFE_LABEL}_${TS}.txt"

{
  echo "CCDC Web Backup Snapshot"
  echo "Timestamp:  $(date)"
  echo "Host:       ${HOST_SHORT}"
  echo "Host IP:    ${HOST_IP}"
  echo "Webroot:    ${WEBROOT}"
  echo "Label:      ${SAFE_LABEL}"
  echo "----------------------------------------"
  echo ""
  echo "[Webroot Size]"
  du -sh "$WEBROOT" 2>/dev/null || true
  echo ""
  echo "[Most Recently Modified Files (Top 30)]"
  # Useful later to compare "what changed"
  (cd "$WEBROOT" && find . -type f -printf "%TY-%Tm-%Td %TH:%TM:%TS %p\n" 2>/dev/null | sort -r | head -n 30) || true
  echo ""
  echo "[Web Server Detection]"
  if [[ -d /etc/apache2 ]]; then
    echo "Apache config found: /etc/apache2"
  fi
  if [[ -d /etc/nginx ]]; then
    echo "Nginx config found: /etc/nginx"
  fi
} > "$SNAPSHOT"

ok "Snapshot created: $(basename "$SNAPSHOT")"

# -------------------------------
# Backup webroot
# -------------------------------
WEBROOT_TARBALL="${OUTDIR}/webroot_${HOST_SHORT}_${SAFE_LABEL}_${TS}.tar.gz"

info "Backing up webroot..."
# -C / is used so extraction can restore paths cleanly
tar -czf "$WEBROOT_TARBALL" "$WEBROOT"
ok "Webroot backup: $(basename "$WEBROOT_TARBALL")"

# -------------------------------
# Backup web server config (Apache/Nginx if present)
# -------------------------------
# We back up configs separately so you can restore config without touching content
if [[ -d /etc/apache2 ]]; then
  APACHE_TARBALL="${OUTDIR}/apache2_${HOST_SHORT}_${SAFE_LABEL}_${TS}.tar.gz"
  info "Backing up Apache config..."
  tar -czf "$APACHE_TARBALL" /etc/apache2
  ok "Apache backup:  $(basename "$APACHE_TARBALL")"
else
  warn "Apache config not found (/etc/apache2) — skipping."
fi

if [[ -d /etc/nginx ]]; then
  NGINX_TARBALL="${OUTDIR}/nginx_${HOST_SHORT}_${SAFE_LABEL}_${TS}.tar.gz"
  info "Backing up Nginx config..."
  tar -czf "$NGINX_TARBALL" /etc/nginx
  ok "Nginx backup:   $(basename "$NGINX_TARBALL")"
else
  warn "Nginx config not found (/etc/nginx) — skipping."
fi

# -------------------------------
# Friendly output summary
# -------------------------------
echo ""
ok "Backup complete. Files created:"
ls -lh "$OUTDIR" | tail -n +1

echo ""
info "CCDC Reminder:"
echo " - Store backups locally on the server (fast restore, no policy issues)."
echo " - If defaced: capture evidence -> restore -> stabilize -> investigate."
echo ""
info "Next script (we'll do next):"
echo " - 30_ccdc_restore_web.sh"
echo "   Restores webroot from one of these tarballs safely and quickly."