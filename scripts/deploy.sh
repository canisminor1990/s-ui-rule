#!/usr/bin/env bash
# Deploy clash-ext.yaml to the S-UI hub over SSH. Does not restart sing-box.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${SUI_HOST:-13.196.71.52}"
USER="${SUI_USER:-ubuntu}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)
if [[ -n "${SUI_SSH_KEY:-}" ]]; then
  SSH_OPTS+=(-i "$SUI_SSH_KEY")
fi

scp "${SSH_OPTS[@]}" \
  "$ROOT/clash-ext.yaml" \
  "$ROOT/scripts/sync_subclash.py" \
  "${USER}@${HOST}:/tmp/"

ssh "${SSH_OPTS[@]}" "${USER}@${HOST}" \
  "sudo python3 /tmp/sync_subclash.py --file /tmp/clash-ext.yaml --verify"
