#!/usr/bin/env bash
set -euo pipefail
LEN="${1:-16}"

# Packet: passwords permitted alphanumeric and only these specials: )(’.,@|=:;/-!
# To avoid curly apostrophe issues, we include only ASCII specials from that set.
ALNUM='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
SPEC=')(. ,@|=:;/-!'   # space removed below
SPEC="${SPEC// /}"

CHARS="${ALNUM}${SPEC}"

# generate
PASS="$(tr -dc "$CHARS" < /dev/urandom | head -c "$LEN")"
echo "$PASS"
