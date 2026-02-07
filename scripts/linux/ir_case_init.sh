#!/usr/bin/env bash
set -euo pipefail

CASE_ID="${1:-}"
BASE="${2:-$HOME/ccdc/cases}"
TEMPLATE="${3:-../common/ir_report_template.md}"

if [[ -z "$CASE_ID" ]]; then
  echo "Usage: $0 <CASE-ID> [base_dir] [template]"
  exit 1
fi

DIR="$BASE/CASE-$CASE_ID"
mkdir -p "$DIR"/{evidence,logs}

cp "$TEMPLATE" "$DIR/IR_REPORT.md"

cat > "$DIR/timeline.md" <<EOF
# Timeline (CASE-$CASE_ID)
- $(date): Case created
EOF

cat > "$DIR/notes.md" <<EOF
# Notes (CASE-$CASE_ID)
Hosts:
Suspected timeframe:
Initial indicators:
Actions taken:
EOF

echo "[*] Created $DIR"
echo " - IR_REPORT.md (packet-aligned)"
echo " - timeline.md"
echo " - notes.md"
