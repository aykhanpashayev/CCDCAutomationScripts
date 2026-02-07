#!/usr/bin/env bash
set -euo pipefail

echo "== BTA Guard Check (Linux/BSD) @ $(date) =="
BIN="/usr/sbin/bta"
CFG="/etc/bta.enc"
STATUS="/usr/sbin/bta.status"

[[ -x "$BIN" ]] && echo "[+] Found $BIN" || echo "[-] Missing/Not executable: $BIN"

if command -v systemctl >/dev/null 2>&1; then
  systemctl status bta --no-pager 2>/dev/null | sed -n '1,12p' || echo "[-] Cannot read systemd bta service"
fi

for f in "$CFG" "$STATUS"; do
  if [[ -f "$f" ]]; then
    echo "[+] $f  mtime: $(stat -c %y "$f" 2>/dev/null || true)"
  else
    echo "[-] Missing: $f"
  fi
done

echo
echo "Packet reminder: DO NOT block BTA. Must allow outbound to 10.250.250.11:443 and 169.254.169.254:80."
