#!/bin/bash
# PreToolUse hook — intercepta operaciones destructivas en el Bash tool
# Exit 0: permitir | Exit 2: bloquear (Claude ve el mensaje y pide confirmación al usuario)

INPUT=$(cat)

# Extraer el comando del JSON de entrada (tool_input.command)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Fallback: grep directo sobre el JSON si python3 falla
if [ -z "$COMMAND" ]; then
    COMMAND=$(echo "$INPUT" | grep -oP '"command"\s*:\s*"\K[^"]+' | head -1)
fi

[ -z "$COMMAND" ] && exit 0

MATCHED=()

# rm (cualquier variante)
echo "$COMMAND" | grep -qE '(^|[;&|`( ])rm( |$)' && MATCHED+=("rm")

# git reset --hard
echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard' && MATCHED+=("git reset --hard")

# git push --force / -f
echo "$COMMAND" | grep -qE 'git\s+push\b.*(\s--force\b|\s-f\b)' && MATCHED+=("git push --force")

# truncate command
echo "$COMMAND" | grep -qE '(^|[;&|`( ])truncate( |$)' && MATCHED+=("truncate")

# Sobreescritura con > (no >> ni 2> ni &> ni 1>)
# Busca > precedido de espacio, ; | & ( o inicio — excluyendo 2>&>
echo "$COMMAND" | grep -qP '(?<![2&1>])>(?!>)' && MATCHED+=("sobreescritura con >")

if [ ${#MATCHED[@]} -gt 0 ]; then
    echo "OPERACION DESTRUCTIVA BLOQUEADA"
    echo "Patron: $(IFS=', '; echo "${MATCHED[*]}")"
    echo "Comando: $COMMAND"
    echo ""
    echo "Pide confirmacion explicita al usuario antes de reintentar."
    exit 2
fi

exit 0
