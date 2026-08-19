#!/usr/bin/env bash
# Deploy clash-ext.yaml to the S-UI hub over SSH. Does not restart sing-box.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

load_config_value() {
  local key="$1"
  local cfg="$ROOT/.deploy/config"
  [[ -f "$cfg" ]] || return 0
  local line
  line="$(grep -E "^${key}=" "$cfg" | tail -n 1 || true)"
  [[ -n "$line" ]] || return 0
  local val="${line#*=}"
  val="${val%\"}"
  val="${val#\"}"
  val="${val%\'}"
  val="${val#\'}"
  printf '%s' "$val"
}

HOST="${SUI_HOST:-$(load_config_value SUI_HOST)}"
USER="${SUI_USER:-$(load_config_value SUI_USER)}"
KEY="${SUI_SSH_KEY:-$(load_config_value SUI_SSH_KEY)}"
if [[ -z "$KEY" && -f "$ROOT/.deploy/id_ed25519" ]]; then
  KEY="$ROOT/.deploy/id_ed25519"
fi

if [[ -z "$HOST" || -z "$USER" ]]; then
  echo "Set SUI_HOST and SUI_USER via env or .deploy/config. See scripts/deploy.env.example" >&2
  exit 1
fi

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)
if [[ -n "$KEY" ]]; then
  SSH_OPTS+=(-i "$KEY")
fi

scp "${SSH_OPTS[@]}" \
  "$ROOT/clash-ext.yaml" \
  "$ROOT/scripts/sync_subclash.py" \
  "${USER}@${HOST}:/tmp/"

ssh "${SSH_OPTS[@]}" "${USER}@${HOST}" \
  "sudo python3 /tmp/sync_subclash.py --file /tmp/clash-ext.yaml --verify"
