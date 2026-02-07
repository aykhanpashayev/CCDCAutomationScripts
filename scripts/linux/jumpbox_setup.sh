#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-$HOME/ccdc}"
echo "[*] Creating workspace at $BASE"
mkdir -p "$BASE"/{logs,backups,cases,tools}

echo "[*] Installing useful tools (best-effort)..."
if command -v sudo >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y \
    libreoffice-writer \
    curl jq net-tools dnsutils lsof \
    openssh-client rsync tar zip \
    || true
else
  echo "[!] sudo not available; skipping installs."
fi

echo "[*] Done."
