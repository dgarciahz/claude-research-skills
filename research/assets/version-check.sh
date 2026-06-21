#!/bin/bash
# Comprueba al inicio de sesión si hay una versión más nueva del research framework disponible.
# Ejecutado via hook SessionStart — dispara una sola vez al abrir la sesión.

local_hash=$(cat "research/config/version" 2>/dev/null | tr -d '[:space:]')
if [ -z "$local_hash" ]; then
  exit 0
fi

remote_hash=$(curl -sf --max-time 5 --ssl-no-revoke \
  -H "Accept: application/vnd.github.raw+json" \
  "https://api.github.com/repos/dgarciahz/claude-research-skills/contents/research/config/version" \
  | tr -d '[:space:]')
if [ -z "$remote_hash" ]; then
  printf '{"systemMessage": "research version-check: no se pudo contactar upstream. Verifica con: research pull"}\n'
  exit 0
fi

if [ "$local_hash" = "$remote_hash" ]; then
  printf '{"systemMessage": "✓ research framework — up to date (%s)"}\n' "$local_hash"
else
  printf '{"systemMessage": "✗ research framework DESACTUALIZADO (local: %s | upstream: %s) — ejecuta: research pull"}\n' "$local_hash" "$remote_hash"
fi
