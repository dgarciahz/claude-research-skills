#!/bin/bash
# Version check de claude-starter. Hook: SessionStart.

LOCAL="starter/config/version"

local_hash=$(cat "$LOCAL" 2>/dev/null | tr -d '[:space:]')
if [ -z "$local_hash" ]; then
  exit 0
fi

remote_hash=$(curl -sf --max-time 3 "https://raw.githubusercontent.com/dgarciahz/claude-starter/main/starter/config/version" | tr -d '[:space:]')

if [ -z "$remote_hash" ]; then
  exit 0
fi

if [ "$local_hash" != "$remote_hash" ]; then
  echo "Nueva versión de claude-starter disponible (local: ${local_hash:0:8} | upstream: ${remote_hash:0:8}). Ejecuta /sys--template-pull y re-ejecuta starter/INIT.md."
fi
