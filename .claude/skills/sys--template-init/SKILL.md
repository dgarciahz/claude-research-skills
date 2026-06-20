# Skill: Init Template

Inicializa un proyecto nuevo creado desde el template `claude-starter`: configura MCP servers, statusline e inits de personalización.

## Trigger

Usar cuando el usuario invoque `/sys--template-init` o pida inicializar el proyecto.

## Configuración

- **Catálogo MCP**: `.claude/assets/MCP_SERVERS.md`

## Prerequisito

El proyecto debe haberse creado desde el template:
```bash
gh repo create mi-proyecto --template dgarciahz/claude-starter --private --clone
```
Esto ya trae skills, agents e init. Este skill solo inicializa — no descarga nada. Para actualizaciones posteriores del template, usar `/sys--template-pull`.

## Instrucciones

Sigue estos pasos en orden:

### 1. Leer el catálogo de MCP servers y calcular el diff

Lee `.claude/assets/MCP_SERVERS.md`.

Si ya existe un `.mcp.json` en el proyecto, compara los servers del catálogo con los ya configurados. Separa:
- **Servers nuevos**: están en el catálogo pero no en `.mcp.json` → candidatos a instalar
- **Servers existentes**: ya configurados → no tocar

### 2. Preguntar al usuario qué servers nuevos quiere configurar

Muestra solo los servers que no están aún en el proyecto. Pregunta cuáles quiere añadir usando `AskUserQuestion` con multiSelect.

Si es un proyecto completamente nuevo (sin `.mcp.json`), ofrece todos los del catálogo.

Para los servers elegidos que requieren credenciales (`N8N_API_URL`, `N8N_API_KEY`, etc.), solicítalas al usuario en este paso.

### 3. Detectar la ruta de npx según el SO

- **Windows**: comprueba si existe `C:\Program Files\nodejs\npx.cmd`. Si no, busca con `where npx`.
- **macOS / Linux**: usa simplemente `npx`.

### 4. Escribir `.mcp.json`

Construye el archivo `.mcp.json` en la raíz del proyecto con los servers elegidos. Ejemplo de estructura:

```json
{
  "mcpServers": {
    "nombre-server": {
      "command": "<ruta npx>",
      "args": ["-y", "<paquete>"],
      "env": {
        "VAR": "valor"
      }
    }
  }
}
```

Si ya existe un `.mcp.json`, combina los servers nuevos con los existentes (no sobreescribas los que ya estén configurados).

### 5. Actualizar `.claude/settings.local.json`

Añade los servers elegidos a `enabledMcpjsonServers`. Si el archivo no existe, créalo con esta estructura mínima:

```json
{
  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": ["server1", "server2"]
}
```

### 6. Configurar el statusline

Copia el script al directorio global de Claude Code:

```bash
cp .claude/assets/statusline-command.sh ~/.claude/statusline-command.sh
```

Lee `~/.claude/settings.json` (créalo si no existe). Si ya contiene el bloque `statusLine`, no toques nada.

Si no existe, añade:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```

> Este paso modifica `~/.claude/settings.json` — configuración global del usuario, no del proyecto.

### 7. Instalar output styles

Copia los output styles de `.claude/assets/` al directorio global. Los output styles son los `.md` que tienen frontmatter con `name:` en `.claude/assets/`.

```bash
mkdir -p ~/.claude/output-styles/
cp .claude/assets/caveman.md ~/.claude/output-styles/caveman.md
```

Después pregunta al usuario con `AskUserQuestion` qué output style quiere activar para este proyecto. Muestra los estilos disponibles leyendo el frontmatter `name:` de los `.md` de `.claude/assets/`. Incluye siempre la opción "Ninguno".

Para el estilo elegido (si no es "Ninguno"), escribe `outputStyle` en `.claude/settings.local.json`:

```json
{
  "outputStyle": "<nombre del estilo>"
}
```

Si el archivo ya existe, añade/actualiza solo esa clave — no sobreescribas el resto.

### 8. Ejecutar inits de bloque

Llama a cada skill de la siguiente lista en orden. Si alguno falla, informa al usuario pero continúa con el resto — un init fallido no debe bloquear los demás.

**Lista de inits de bloque:**
- `per--init` — inicializa el sistema de personalización persistente

Para invocar cada uno, indícale al usuario que el skill se ejecutará automáticamente, y procede a seguir sus instrucciones como si el usuario lo hubiera invocado directamente.

### 9. Commit de los cambios

```bash
git add .claude/ .mcp.json
git commit -m "Inicializa proyecto desde template claude-starter — <fecha>"
```

### 10. Confirmar al usuario

Informa de:
- Qué MCP servers quedaron configurados
- Si el statusline se configuró o ya estaba presente
- Resultado de cada init de bloque (éxito / fallo)
- Recordatorio: reiniciar Claude Code para que los cambios surtan efecto

## Notas

- NUNCA sobreescribas `.claude/settings.local.json` completo si ya existe — haz merge de `enabledMcpjsonServers`.
- Si el usuario ya tiene servers en `.mcp.json`, respétalos y añade solo los nuevos.
- Para añadir un nuevo init de bloque al template, añádelo a la lista del paso 8 y actualiza con `/sys--template-push`.
