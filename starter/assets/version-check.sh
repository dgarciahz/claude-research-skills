#!/bin/bash
# Version check de claude-starter. Hook: SessionStart.

LOCAL="starter/config/version"

local_hash=$(cat "$LOCAL" 2>/dev/null | tr -d '[:space:]')
if [ -z "$local_hash" ]; then
  exit 0
fi

remote_hash=$(curl -sf --max-time 5 --ssl-no-revoke \
  -H "Accept: application/vnd.github.raw+json" \
  "https://api.github.com/repos/dgarciahz/claude-starter/contents/starter/config/version?ref=main" \
  | tr -d '[:space:]')

if [ -z "$remote_hash" ]; then
  exit 0
fi

if [ "$local_hash" = "$remote_hash" ]; then
  printf '{"systemMessage": "✓ starter framework — up to date (%s)"}\n' "$local_hash"
else
  printf '{"systemMessage": "✗ starter framework DESACTUALIZADO (local: %s | upstream: %s) — ejecuta: /sys--template-pull"}\n' "$local_hash" "$remote_hash"
fi
