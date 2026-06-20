#!/bin/bash
# Comprueba al inicio de sesión si hay una versión más nueva del research framework disponible.
# Ejecutado via hook SessionStart — dispara una sola vez al abrir la sesión.

local_hash=$(cat "research/config/version" 2>/dev/null | tr -d '[:space:]')
if [ -z "$local_hash" ]; then
  exit 0
fi

remote_hash=$(curl -sf --max-time 3 "https://raw.githubusercontent.com/dgarciahz/claude-research-skills/main/research/config/version" 2>/dev/null | tr -d '[:space:]')
if [ -z "$remote_hash" ]; then
  exit 0
fi

if [ "$local_hash" != "$remote_hash" ]; then
  printf '{"systemMessage": "Nueva versión del framework de research disponible (local: %s | upstream: %s). Ejecuta research pull para actualizar."}' "${local_hash:0:8}" "${remote_hash:0:8}"
fi
