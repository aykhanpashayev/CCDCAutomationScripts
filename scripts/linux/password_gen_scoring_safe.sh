#!/usr/bin/env bash
set -euo pipefail
LEN="${1:-16}"

# Allowed specials (ASCII-safe): )(.,@|=:;/-!
ALNUM='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
SPEC=")(.,@|=:;/-!"

CHARS="${ALNUM}${SPEC}"

# generate
PASS="$(tr -dc "$CHARS" < /dev/urandom | head -c "$LEN")"
echo "$PASS"
