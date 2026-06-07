# Skill: Template Pull

Actualiza los skills y agents del proyecto actual desde el template `claude-starter`, sin tocar la configuración local (`.mcp.json`, `settings.local.json`).

## Trigger

Usar cuando el usuario invoque `/sys--template-pull` o pida actualizar/sincronizar skills desde el template.

## Configuración

- **Repo template**: `https://github.com/dgarciahz/claude-starter`
- **Remote name**: `template`

## Instrucciones

Sigue estos pasos en orden:

### 1. Verificar o añadir el remote `template`

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

### 3. Mostrar qué ha cambiado antes de aplicar

Muestra al usuario un diff resumido de lo que va a cambiar:

```bash
git diff HEAD template/main -- .claude/skills/ .claude/agents/ .claude/assets/
```

Si no hay diferencias, informa al usuario y detente — el proyecto ya está al día.

### 4. Bajar skills, agents y assets

```bash
git checkout template/main -- .claude/skills/
git checkout template/main -- .claude/agents/
git checkout template/main -- .claude/assets/
```

### 5. Comparar MCP servers del catálogo con el proyecto

Lee el archivo `.claude/skills/sys--template-push/MCP_SERVERS.md` recién descargado y compáralo con el `.mcp.json` del proyecto (si existe).

Si hay servers en el catálogo que **no están en el proyecto**, muéstralos al usuario:
> "El catálogo del template tiene estos servers que no tienes configurados: [lista]. ¿Quieres añadir alguno?"

Usa `AskUserQuestion` con multiSelect para que el usuario elija. Para los elegidos:
- Pide las credenciales necesarias
- Detecta la ruta de `npx` según el SO (Windows: `C:\Program Files\nodejs\npx.cmd`, Unix: `npx`)
- Actualiza `.mcp.json` y `enabledMcpjsonServers` en `.claude/settings.local.json`

Si no hay diff de MCP servers (o el usuario no quiere ninguno), continúa sin tocar la config MCP.

### 6. Commit de los cambios

```bash
git add .claude/skills/ .claude/agents/ .claude/assets/ .mcp.json
git commit -m "Sincroniza skills/agents/assets desde template claude-starter — <fecha>"
```

### 7. Confirmar al usuario

Informa de:
- Qué skills/agents fueron actualizados
- Si hay skills nuevos que no existían antes en el proyecto
- Qué MCP servers se añadieron (si los hay)
- Recordatorio: reiniciar Claude Code si se añadieron MCP servers nuevos

## Notas

- NUNCA sobreescribas `.mcp.json` completo si ya existe — solo añade los servers nuevos elegidos.
- NUNCA sobreescribas `.claude/settings.local.json` completo — haz merge de `enabledMcpjsonServers`.
- Este skill es idempotente: ejecutarlo varias veces no causa daño.
