#!/usr/bin/env bash
set -euo pipefail
ACTION="${1:-dry-run}"   # dry-run | apply

# Packet guardrails
SUPPORT="10.250.250.0/24"
BTA1="10.250.250.11"
BTA2="169.254.169.254"
GW="10.250.194.1"
AWS1="10.250.194.2"
AWS2="10.250.194.3"

echo "== Team 44 SAFE UFW helper @ $(date) =="
echo "[*] Mode: $ACTION"
echo "[*] This script ALWAYS allows supporting infra and BTA egress."
echo "[*] It does NOT set default deny unless you do it manually."

RULES=$(cat <<EOF
ufw allow in ssh
ufw allow out to $SUPPORT
ufw allow out to $BTA1 port 443 proto tcp
ufw allow out to $BTA2 port 80 proto tcp
# Explicitly do NOT block these off-limits; leaving note for humans:
# $GW, $AWS1, $AWS2
EOF
)

if [[ "$ACTION" == "dry-run" ]]; then
  echo "$RULES"
  echo
  echo "[!] Dry-run only. Review with your team lead before applying."
  exit 0
fi

if [[ "$ACTION" == "apply" ]]; then
  if ! command -v ufw >/dev/null 2>&1; then
    echo "[!] ufw not installed."
    exit 1
  fi
  echo "[*] Applying rules..."
  ufw allow in ssh || true
  ufw allow out to "$SUPPORT" || true
  ufw allow out to "$BTA1" port 443 proto tcp || true
  ufw allow out to "$BTA2" port 80 proto tcp || true
  ufw status verbose
  echo "[*] Done. Confirm services still score before tightening anything."
  exit 0
fi

echo "Usage: $0 dry-run|apply"
exit 1
