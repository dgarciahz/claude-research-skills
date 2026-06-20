#!/bin/bash
# Comprueba una vez por sesión si hay una versión más nueva de claude-starter disponible.
# Ejecutado via hook UserPromptSubmit — sale en silencio si ya se comprobó hace menos de 4 horas.

MARKER="$HOME/.claude/.starter-version-check"
LOCAL="starter/config/version"

if [ -f "$MARKER" ] && [ -n "$(find "$MARKER" -mmin -240 2>/dev/null)" ]; then
  exit 0
fi

local_hash=$(cat "$LOCAL" 2>/dev/null | tr -d '[:space:]')
if [ -z "$local_hash" ]; then
  exit 0
fi

remote_hash=$(curl -sf --max-time 3 "https://raw.githubusercontent.com/dgarciahz/claude-starter/main/starter/config/version" | tr -d '[:space:]')

touch "$MARKER"

if [ -z "$remote_hash" ]; then
  exit 0
fi

if [ "$local_hash" != "$remote_hash" ]; then
  echo "Nueva versión de claude-starter disponible (local: ${local_hash:0:8} | upstream: ${remote_hash:0:8}). Ejecuta /sys--template-pull y re-ejecuta starter/INIT.md."
fi
