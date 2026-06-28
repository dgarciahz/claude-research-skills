# Skill: Template Pull

Actualiza los skills y el framework starter del proyecto actual desde el template `claude-starter`, sin tocar la configuración local (`.mcp.json`, `settings.local.json`, `CLAUDE.md`).

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
git fetch template
```

### 2. Fetch del template

```bash
git fetch template
```

### 3. Mostrar qué ha cambiado antes de aplicar

Muestra al usuario un diff resumido de lo que va a cambiar:

```bash
git diff HEAD template/main -- .claude/skills/ .claude/agents/ starter/
```

Si no hay diferencias, informa al usuario y detente — el proyecto ya está al día.

### 4. Bajar skills, agents y el framework starter

```bash
git checkout template/main -- .claude/skills/
git checkout template/main -- .claude/agents/
git checkout template/main -- starter/
```

Esto descarga:
- Los skills actualizados
- El directorio `starter/` completo: INIT.md actualizado, README.md y assets (config.yaml, caveman.md, statusline-command.sh)

No descarga ni modifica `.mcp.json`, `settings.local.json`, ni `CLAUDE.md`.

### 5. Comparar config del template con el proyecto

Lee `starter/assets/config.yaml` recién descargado y compáralo con `.mcp.json` del proyecto (si existe).

Si hay servers en el config que **no están en el proyecto**, muéstralos al usuario:
> "El config del template tiene estos servers que no tienes configurados: [lista]. ¿Quieres añadir alguno?"

Usa `AskUserQuestion` con multiSelect para que el usuario elija. Para los elegidos:
- Pide las credenciales necesarias (si aplica)
- Detecta la ruta de `npx` según el SO (Windows: `C:\Program Files\nodejs\npx.cmd`, Unix: `npx`)
- Actualiza `.mcp.json` y `enabledMcpjsonServers` en `.claude/settings.local.json`

Si no hay diff de MCP servers (o el usuario no quiere ninguno), continúa sin tocar la config MCP.

### 6. Commit de los cambios

```bash
git add .claude/skills/ .claude/agents/ starter/
git commit -m "Sincroniza skills/framework desde template claude-starter — <fecha>"
```

Si se añadieron MCP servers en el paso 5:
```bash
git add .mcp.json .claude/settings.local.json
git commit -m "Añade MCP servers desde template — <fecha>"
```

### 7. Confirmar al usuario

Informa de:
- Qué skills/agents fueron actualizados
- Si se actualizó `starter/` (INIT.md, assets)
- Qué MCP servers se añadieron (si los hay)
- Recordatorio: "Puedes re-ejecutar `starter/INIT.md` para aplicar cambios del framework (idempotente)"
- Recordatorio: reiniciar Claude Code si se añadieron MCP servers nuevos

## Notas

- NUNCA sobreescribas `.mcp.json` completo si ya existe — solo añade los servers nuevos elegidos.
- NUNCA sobreescribas `.claude/settings.local.json` completo — haz merge de `enabledMcpjsonServers`.
- NUNCA toques `CLAUDE.md` — es propio del proyecto.
- Este skill es idempotente: ejecutarlo varias veces no causa daño.
