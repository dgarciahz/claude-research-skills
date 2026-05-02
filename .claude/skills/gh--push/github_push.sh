#!/bin/bash
# github_push.sh - Commit y push excluyendo .claude/skills/ y .claude/agents/
# Uso: bash .claude/skills/github-push/github_push.sh "mensaje" [rama] [remote]

set -e

MESSAGE="$1"
BRANCH="${2:-$(git branch --show-current)}"
REMOTE="${3:-origin}"

if [ -z "$MESSAGE" ]; then
  echo "ERROR: Se requiere un mensaje de commit." >&2
  exit 1
fi

echo "Iniciando push a $REMOTE/$BRANCH..."
echo "Mensaje: $MESSAGE"

git add -A
git reset HEAD -- .claude/skills/ .claude/agents/ 2>/dev/null || true

if git diff --cached --quiet; then
  echo "INFO: No hay cambios para commitear."
  exit 0
fi

git commit -m "$MESSAGE"
git push "$REMOTE" "$BRANCH"

echo "Push completado correctamente en $REMOTE/$BRANCH"
