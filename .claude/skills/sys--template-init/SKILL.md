# Skill: Init Template

Inicializa un proyecto nuevo (o existente) desde el template `claude-starter`: baja skills, agents y asiste al usuario para configurar los MCP servers que necesite.

## Trigger

Usar cuando el usuario invoque `/sys--template-init` o pida inicializar/actualizar el proyecto desde el template.

## Configuración

- **Repo template**: `https://github.com/dgarciahz/claude-starter`
- **Remote name**: `template`
- **Catálogo MCP**: `.claude/skills/sys--template-update/MCP_SERVERS.md` (se descarga junto con los skills)

## Instrucciones

Sigue estos pasos en orden:

### 1. Verificar o añadir el remote `template`

Comprueba si el remote `template` ya existe:
```bash
git remote get-url template
```
Si no existe, añádelo:
```bash
git remote add template https://github.com/dgarciahz/claude-starter
```

### 2. Fetch del template

```bash
git fetch template
```

### 3. Bajar skills y agents

```bash
git checkout template/main -- .claude/skills/
git checkout template/main -- .claude/agents/
```

### 4. Leer el catálogo de MCP servers y calcular el diff

Lee el archivo `.claude/skills/sys--template-update/MCP_SERVERS.md` que acaba de descargarse.

Si ya existe un `.mcp.json` en el proyecto, compara los servers del catálogo con los ya configurados. Separa:
- **Servers nuevos**: están en el catálogo pero no en `.mcp.json` → candidatos a instalar
- **Servers existentes**: ya configurados → no tocar

### 5. Preguntar al usuario qué servers nuevos quiere configurar

Muestra solo los servers que no están aún en el proyecto. Pregunta cuáles quiere añadir usando `AskUserQuestion` con multiSelect.

Si es un proyecto completamente nuevo (sin `.mcp.json`), ofrece todos los del catálogo.

Para los servers elegidos que requieren credenciales (`N8N_API_URL`, `N8N_API_KEY`, etc.), solicítalas al usuario en este paso.

### 6. Detectar la ruta de npx según el SO

- **Windows**: comprueba si existe `C:\Program Files\nodejs\npx.cmd`. Si no, busca con `where npx`.
- **macOS / Linux**: usa simplemente `npx`.

### 7. Escribir `.mcp.json`

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

### 8. Actualizar `.claude/settings.local.json`

Añade los servers elegidos a `enabledMcpjsonServers`. Si el archivo no existe, créalo con esta estructura mínima:

```json
{
  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": ["server1", "server2"]
}
```

### 9. Ejecutar inits de bloque

Llama a cada skill de la siguiente lista en orden. Si alguno falla, informa al usuario pero continúa con el resto — un init fallido no debe bloquear los demás.

**Lista de inits de bloque:**
- `per--init` — inicializa el sistema de personalización persistente
- `n8n--init` — instala los skills de n8n desde czlonkowski/n8n-skills

Para invocar cada uno, indícale al usuario que el skill se ejecutará automáticamente, y procede a seguir sus instrucciones como si el usuario lo hubiera invocado directamente.

### 10. Commit de los cambios

```bash
git add .claude/ .mcp.json
git commit -m "Inicializa proyecto desde template claude-starter — <fecha>"
```

### 11. Confirmar al usuario

Informa de:
- Qué skills y agents se descargaron
- Qué MCP servers quedaron configurados
- Resultado de cada init de bloque (éxito / fallo)
- Recordatorio: reiniciar Claude Code para que los cambios surtan efecto

## Notas

- NUNCA sobreescribas `.claude/settings.local.json` completo si ya existe — haz merge de `enabledMcpjsonServers`.
- Si el usuario ya tiene servers en `.mcp.json`, respétalos y añade solo los nuevos.
- Para añadir un nuevo init de bloque al template, añádelo a la lista del paso 9 y actualiza con `/sys--template-update`.
