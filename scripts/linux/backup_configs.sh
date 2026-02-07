#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-$HOME/ccdc/backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
HOST="$(hostname)"
DEST="$OUT/${HOST}_${STAMP}"
mkdir -p "$DEST"

copy() { [[ -e "$1" ]] && cp -a "$1" "$DEST/" 2>/dev/null || true; }

copy /etc/ssh/sshd_config
copy /etc/sudoers
copy /etc/sudoers.d
copy /etc/passwd
copy /etc/group
copy /etc/shadow
copy /etc/hosts
copy /etc/resolv.conf
copy /etc/nginx
copy /etc/apache2
copy /etc/postfix
copy /etc/dovecot
copy /etc/mysql
copy /etc/postgresql
copy /etc/systemd/system
copy /etc/cron.d
copy /etc/crontab

tar -czf "${DEST}.tar.gz" -C "$OUT" "$(basename "$DEST")"
echo "[*] Backup -> ${DEST}.tar.gz"
