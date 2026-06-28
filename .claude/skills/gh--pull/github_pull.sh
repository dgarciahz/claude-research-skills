#!/bin/bash
# github_pull.sh - Pull desde remote hacia la rama local
# Uso:
#   bash .claude/skills/gh--pull/github_pull.sh [rama] [remote]

set -e

BRANCH="${1:-$(git branch --show-current)}"
REMOTE="${2:-origin}"

echo "Sincronizando $REMOTE/$BRANCH..."

if ! git ls-remote --exit-code "$REMOTE" >/dev/null 2>&1; then
  echo "ERROR: No se puede alcanzar el remote '$REMOTE'." >&2
  exit 1
fi

if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  echo "AVISO: La rama '$BRANCH' no tiene upstream configurado en '$REMOTE'."
  echo "Para configurarlo: git branch --set-upstream-to=$REMOTE/$BRANCH $BRANCH"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "AVISO: Hay cambios locales sin commitear. El pull puede generar conflictos."
fi

BEFORE=$(git rev-parse HEAD)

git pull "$REMOTE" "$BRANCH"

AFTER=$(git rev-parse HEAD)

if [ "$BEFORE" = "$AFTER" ]; then
  echo "INFO: Ya estás al día con $REMOTE/$BRANCH."
else
  echo ""
  echo "Commits recibidos:"
  git --no-pager log --oneline "$BEFORE..$AFTER"
fi
