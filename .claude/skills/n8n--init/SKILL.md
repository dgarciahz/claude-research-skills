# Skill: n8n--init

Instala los skills de n8n (czlonkowski/n8n-skills) en el proyecto actual descargándolos directamente desde su repositorio oficial.

## Trigger

Usar cuando el usuario invoque `/n8n--init`, o cuando `sys--template-init` lo llame como parte del proceso de inicialización.

## Configuración

- **Repo fuente**: `https://github.com/czlonkowski/n8n-skills`
- **Destino**: `.claude/skills/` del proyecto actual

## Skills incluidos

- `n8n--code-javascript`
- `n8n--code-python`
- `n8n--expression-syntax`
- `n8n--mcp-tools-expert`
- `n8n--node-configuration`
- `n8n--validation-expert`
- `n8n--workflow-patterns`

## Instrucciones

### 1. Comprobar si ya están instalados

Verifica si existe `.claude/skills/n8n--code-javascript/`. Si existe, pregunta al usuario:
> "Los skills de n8n ya están instalados. ¿Quieres sobreescribirlos con la versión más reciente del repositorio?"

Si responde no, detente.

### 2. Clonar el repositorio en un directorio temporal

```bash
git clone --depth=1 https://github.com/czlonkowski/n8n-skills /tmp/n8n-skills-install
```

### 3. Copiar los skills al proyecto

Para cada skill de la lista anterior, copia su directorio desde el repo clonado a `.claude/skills/`:

```bash
cp -r /tmp/n8n-skills-install/<skill-name> .claude/skills/
```

### 4. Limpiar el directorio temporal

```bash
rm -rf /tmp/n8n-skills-install
```

### 5. Confirmar

Informa al usuario de:
- Qué skills se instalaron
- Si alguno ya existía y fue sobreescrito
- Recordatorio: reiniciar Claude Code para que los skills nuevos sean detectados

## Notas

- Los skills de n8n son de terceros — no se sincronizan al template via `sys--template-update`.
- Para actualizar a la última versión, volver a ejecutar `/n8n--init` y confirmar la sobreescritura.
- En Windows, `/tmp/` en Git Bash equivale a `C:\Users\<usuario>\AppData\Local\Temp\`.
