#!/bin/bash
# Comprueba al inicio de sesión si hay una versión más nueva del architect framework disponible.
# Ejecutado via hook SessionStart — dispara una sola vez al abrir la sesión.

local_hash=$(cat "architect/config/version" 2>/dev/null | tr -d '[:space:]')
if [ -z "$local_hash" ]; then
  exit 0
fi

remote_hash=$(curl -sf --max-time 5 --ssl-no-revoke \
  -H "Accept: application/vnd.github.raw+json" \
  "https://api.github.com/repos/dgarciahz/claude-architect/contents/architect/config/version?ref=main" \
  | tr -d '[:space:]')
if [ -z "$remote_hash" ]; then
  printf '{"systemMessage": "architect version-check: no se pudo contactar upstream. Verifica con: /core--template-pull architect"}\n'
  exit 0
fi

if [ "$local_hash" = "$remote_hash" ]; then
  printf '{"systemMessage": "✓ architect framework — up to date (%s)"}\n' "$local_hash"
else
  printf '{"systemMessage": "✗ architect framework DESACTUALIZADO (local: %s | upstream: %s) — ejecuta: /core--template-pull architect"}\n' "$local_hash" "$remote_hash"
fi
