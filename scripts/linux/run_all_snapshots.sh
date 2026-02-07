#!/usr/bin/env bash
set -euo pipefail

CSV="${1:-../common/hosts_team44.csv}"
OUTDIR="${2:-$HOME/ccdc/logs/team44}"
SSH_USER="${SSH_USER:-alexisj}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3"

mkdir -p "$OUTDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "[*] Running snapshots -> $OUTDIR ($STAMP)"
echo "[*] Tip: update SSH_USER if needed. Do NOT touch seccdc* accounts. (packet) "

tail -n +2 "$CSV" | while IFS=, read -r host ip os_hint notes; do
  [[ -z "$ip" ]] && continue
  echo "== $host ($ip) =="

  # Try SSH; if it fails, log it and move on.
  if ssh $SSH_OPTS "$SSH_USER@$ip" "echo ok" >/dev/null 2>&1; then
    ssh $SSH_OPTS "$SSH_USER@$ip" 'bash -s' <<'REMOTE' >"$OUTDIR/${host}_${STAMP}.txt" 2>&1
set -e
echo "HOST: $(hostname)  DATE: $(date)"
echo
echo "## Network"
ip -br a || true
ip r || true
ss -tulpn | head -n 80 || true
echo
echo "## Services"
command -v systemctl >/dev/null 2>&1 && systemctl --failed --no-pager || true
echo
echo "## Users logged in"
who || true
echo
echo "## Recent auth"
for f in /var/log/auth.log /var/log/secure; do
  [[ -f "$f" ]] && { echo "--- tail $f"; tail -n 60 "$f"; }
done
REMOTE
    echo "  [+] Wrote $OUTDIR/${host}_${STAMP}.txt"
  else
    echo "  [-] SSH unavailable"
    echo "SSH unavailable for $host ($ip) at $STAMP" >"$OUTDIR/${host}_${STAMP}_NO_SSH.txt"
  fi
done
