#!/usr/bin/env bash
# ===============================================================
# 10_ccdc_service_check.sh
#
# SECCDC / CCDC Service-Check Script (Blue Team)
#
# Purpose (CCDC-specific):
#   Quickly answer: "What services might be losing us points RIGHT NOW?"
#   - Reads a host list (IP/hostname + friendly label)
#   - Checks common scored ports with fast timeouts
#   - Optionally does quick HTTP/HTTPS HEAD checks (status code)
#   - Prints a tidy table to screen
#   - Saves a timestamped report into ~/ccdc/outputs/
#
# Notes:
#   - This is NOT a scanner for the whole network.
#   - Only check YOUR OWN hosts that White Team assigned.
#   - Keep it light: quick ports only.
#
# Input file format (hosts.txt):
#   <ip_or_host> <label>
# Example:
#   10.250.5X.10 frontier
#   10.250.5X.11 drifter
#
# Usage:
#   ./10_ccdc_service_check.sh ~/ccdc/hosts/hosts.txt
#
# Optional:
#   PORTS="22,80,443" ./10_ccdc_service_check.sh hosts.txt
#   TIMEOUT=2 ./10_ccdc_service_check.sh hosts.txt
# ===============================================================

# ---- Ensure Bash
if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "[FAIL] This script must be run with bash."
  echo "       Try: bash $0 <hosts.txt>"
  exit 1
fi

set -Eeuo pipefail

# -------------------------------
# Output formatting
# -------------------------------
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
ok()   { echo -e "${GREEN}[ OK ]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "${RED}[FAIL]${RESET} $*"; }

# -------------------------------
# Config (CCDC-minded defaults)
# -------------------------------
# Commonly scored / commonly present service ports in CCDC-style environments:
# SSH(22), HTTP(80), HTTPS(443), DNS(53), LDAP(389), SMB(445), RDP(3389),
# SMTP(25), Submission(587), POP3(110), IMAP(143), WinRM(5985/5986)
DEFAULT_PORTS="22,80,443,53,389,445,3389,25,587,110,143,5985,5986"

PORTS_CSV="${PORTS:-$DEFAULT_PORTS}"
TIMEOUT="${TIMEOUT:-1}"   # seconds for each port check (keep fast)
DO_HTTP_HEAD="${DO_HTTP_HEAD:-1}" # 1 = do quick HTTP(S) HEAD if port open

# -------------------------------
# Input validation
# -------------------------------
HOSTS_FILE="${1:-}"
if [[ -z "$HOSTS_FILE" ]]; then
  fail "Missing hosts file."
  echo "Usage: $0 /path/to/hosts.txt"
  exit 1
fi

if [[ ! -f "$HOSTS_FILE" ]]; then
  fail "Hosts file not found: $HOSTS_FILE"
  exit 1
fi

# -------------------------------
# Tool checks (friendly)
# -------------------------------
need_cmd() {
  local c="$1"
  if ! command -v "$c" >/dev/null 2>&1; then
    fail "Required command not found: $c"
    echo "Tip: On jump box, run your setup script first:"
    echo "     sudo bash 00_ccdc_jumpbox_setup.sh"
    exit 1
  fi
}

need_cmd nc
need_cmd printf
need_cmd date
if [[ "$DO_HTTP_HEAD" == "1" ]]; then
  need_cmd curl
fi

# -------------------------------
# Workspace output path
# -------------------------------
# Prefer ~/ccdc/outputs if it exists; otherwise use current directory.
USER_HOME="${HOME}"
OUT_DIR="${USER_HOME}/ccdc/outputs"
if [[ ! -d "$OUT_DIR" ]]; then
  warn "Output dir not found at $OUT_DIR — creating it."
  mkdir -p "$OUT_DIR"
fi

TS="$(date +%Y%m%d_%H%M%S)"
REPORT="${OUT_DIR}/service_check_${TS}.txt"

# -------------------------------
# Helpers
# -------------------------------
# Convert CSV ports to an array
IFS=',' read -r -a PORTS_ARR <<< "$PORTS_CSV"

# Check a TCP port quickly
check_port() {
  local host="$1"
  local port="$2"
  # nc returns 0 if open
  if nc -z -w "$TIMEOUT" "$host" "$port" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Quick HTTP status check (HEAD) to detect "up but broken"
http_status() {
  local url="$1"
  # Print HTTP code or "---" if not reachable quickly
  curl -sS -o /dev/null -m 2 -I -L -w "%{http_code}" "$url" 2>/dev/null || echo "---"
}

# Pretty port label for humans
port_name() {
  local p="$1"
  case "$p" in
    22) echo "SSH" ;;
    80) echo "HTTP" ;;
    443) echo "HTTPS" ;;
    53) echo "DNS" ;;
    389) echo "LDAP" ;;
    445) echo "SMB" ;;
    3389) echo "RDP" ;;
    25) echo "SMTP" ;;
    587) echo "SUBMIT" ;;
    110) echo "POP3" ;;
    143) echo "IMAP" ;;
    5985) echo "WINRM" ;;
    5986) echo "WINRMSSL" ;;
    *) echo "TCP" ;;
  esac
}

# -------------------------------
# Header
# -------------------------------
info "CCDC Service Check"
info "Hosts file:  $HOSTS_FILE"
info "Ports:       $PORTS_CSV"
info "Timeout:     ${TIMEOUT}s per port"
info "HTTP HEAD:   $([[ "$DO_HTTP_HEAD" == "1" ]] && echo "enabled" || echo "disabled")"
info "Saving to:   $REPORT"
echo ""

{
  echo "CCDC Service Check Report"
  echo "Timestamp: $(date)"
  echo "Hosts file: $HOSTS_FILE"
  echo "Ports: $PORTS_CSV"
  echo "Timeout: ${TIMEOUT}s"
  echo "HTTP HEAD: $DO_HTTP_HEAD"
  echo "------------------------------------------------------------"
} > "$REPORT"

# -------------------------------
# Table layout
# -------------------------------
# We'll print one line per host with compact results:
# label | host | open_ports_count/total | open list | http codes
printf "%-14s %-18s %-9s %-38s %-12s\n" "LABEL" "HOST" "OPEN/TOT" "OPEN PORTS" "HTTP(S)"
printf "%-14s %-18s %-9s %-38s %-12s\n" "-----" "----" "--------" "---------" "------"

{
  printf "%-14s %-18s %-9s %-38s %-12s\n" "LABEL" "HOST" "OPEN/TOT" "OPEN PORTS" "HTTP(S)"
  printf "%-14s %-18s %-9s %-38s %-12s\n" "-----" "----" "--------" "---------" "------"
} >> "$REPORT"

# -------------------------------
# Main loop
# -------------------------------
total_hosts=0
total_open=0
total_ports=${#PORTS_ARR[@]}

# Read hosts file safely:
# - ignore blank lines
# - ignore comments starting with #
while IFS= read -r line; do
  # Trim whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^# ]] && continue

  host="$(awk '{print $1}' <<< "$line")"
  label="$(awk '{print $2}' <<< "$line")"

  if [[ -z "${host:-}" || -z "${label:-}" ]]; then
    warn "Skipping invalid line (need: <host> <label>): $line"
    continue
  fi

  ((total_hosts+=1))

  open_list=()
  open_count=0

  # Check ports
  for p in "${PORTS_ARR[@]}"; do
    if check_port "$host" "$p"; then
      ((open_count+=1))
      ((total_open+=1))
      open_list+=("$(port_name "$p"):$p")
    fi
  done

  # Compact string for table
  open_str="none"
  if [[ "${#open_list[@]}" -gt 0 ]]; then
    open_str="$(IFS=','; echo "${open_list[*]}")"
  fi

  # Optional HTTP(S) HEAD (only if ports open)
  http_codes="---/---"
  if [[ "$DO_HTTP_HEAD" == "1" ]]; then
    http_code="---"
    https_code="---"
    # If port 80 open, check http
    if check_port "$host" "80"; then
      http_code="$(http_status "http://${host}/")"
    fi
    # If port 443 open, check https
    if check_port "$host" "443"; then
      https_code="$(http_status "https://${host}/")"
    fi
    http_codes="${http_code}/${https_code}"
  fi

  # Print to screen
  printf "%-14s %-18s %2d/%-6d %-38s %-12s\n" \
    "$label" "$host" "$open_count" "$total_ports" "$open_str" "$http_codes"

  # Save to report
  printf "%-14s %-18s %2d/%-6d %-38s %-12s\n" \
    "$label" "$host" "$open_count" "$total_ports" "$open_str" "$http_codes" >> "$REPORT"

done < "$HOSTS_FILE"

echo ""
ok "Checked ${total_hosts} host(s). Report saved to:"
echo "    $REPORT"

# -------------------------------
# Friendly interpretation tips
# -------------------------------
echo ""
info "How to read this quickly (CCDC mindset):"
echo " - OPEN/TOT low (e.g., 0/13)  -> host might be down or blocked"
echo " - HTTP(S) 200/200            -> web likely functional"
echo " - HTTP(S) 403/404/500        -> service is up but may be losing points"
echo " - SSH open but you can't login-> investigate server, don't panic-change creds"

echo ""
info "Next script we'll build:"
echo " - 20_ccdc_backup_web.sh  (one-command web backup + restore points)"
