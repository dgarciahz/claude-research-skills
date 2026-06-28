# Skill: GitHub Push

Hace commit y push de los cambios actuales a GitHub. Genera el mensaje de commit en español si no se proporciona uno.

## Trigger

Usar cuando el usuario invoque `/gh--push` o pida hacer commit y push a GitHub. Acepta un mensaje de commit opcional como argumento.

## Instrucciones

### 1. Analizar el estado del repositorio

Ejecuta:
```bash
git --no-pager diff
```

- Si hay diff (cambios sin commitear): genera un mensaje descriptivo en español (máximo 72 caracteres, tiempo presente, sin punto final). Pasa al paso 2 con ese mensaje.
- Si no hay diff: no generes mensaje. Pasa al paso 2 igualmente sin argumento — el script detectará si hay commits pendientes de push y los pusheará.

### 2. Ejecutar el script

Con mensaje (cuando hay diff):
```bash
bash .claude/skills/gh--push/github_push.sh "MENSAJE"
```

Sin mensaje (cuando no hay diff):
```bash
bash .claude/skills/gh--push/github_push.sh
```

### 3. Mostrar el output del script al usuario.
