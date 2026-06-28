#!/bin/bash
# github_push.sh - Commit y push excluyendo .claude/skills/ y .claude/agents/
# Uso:
#   bash .claude/skills/gh--push/github_push.sh "mensaje" [rama] [remote]
#   bash .claude/skills/gh--push/github_push.sh "" [rama] [remote]   # solo push

set -e

MESSAGE="$1"
BRANCH="${2:-$(git branch --show-current)}"
REMOTE="${3:-origin}"

echo "Iniciando proceso en $REMOTE/$BRANCH..."

git add -A
git reset HEAD -- .claude/skills/ .claude/agents/ 2>/dev/null || true

if git diff --cached --quiet; then
  echo "INFO: No hay cambios staged para commitear."
else
  if [ -z "$MESSAGE" ]; then
    echo "ERROR: Se requiere un mensaje de commit cuando hay cambios staged." >&2
    exit 1
  fi
  echo "Commiteando: $MESSAGE"
  git commit -m "$MESSAGE"
fi

if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  UNPUSHED=$(git rev-list --count @{u}..HEAD)
  if [ "$UNPUSHED" -gt 0 ]; then
    echo "Pusheando $UNPUSHED commit(s) a $REMOTE/$BRANCH..."
    git push "$REMOTE" "$BRANCH"
    echo "Push completado correctamente en $REMOTE/$BRANCH"
  else
    echo "INFO: No hay commits pendientes de push. Todo está al día."
  fi
else
  echo "Rama sin upstream. Pusheando con tracking a $REMOTE/$BRANCH..."
  git push -u "$REMOTE" "$BRANCH"
  echo "Push completado correctamente en $REMOTE/$BRANCH"
fi
