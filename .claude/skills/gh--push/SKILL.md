# Skill: GitHub Push

Hace commit y push de los cambios actuales a GitHub. Genera el mensaje de commit en español si no se proporciona uno.

## Trigger

Usar cuando el usuario invoque `/gh--push` o pida hacer commit y push a GitHub. Acepta un mensaje de commit opcional como argumento.

## Instrucciones

### 1. Generar mensaje de commit

Si el usuario no proporcionó un mensaje, ejecuta:
```bash
git --no-pager diff
```
Analiza el output y genera un mensaje descriptivo en español (máximo 72 caracteres, tiempo presente, sin punto final).

Si no hay diff, informa al usuario y termina.

### 2. Ejecutar el script

```bash
bash .claude/skills/github-push/github_push.sh "MENSAJE"
```

### 3. Mostrar el output del script al usuario.
