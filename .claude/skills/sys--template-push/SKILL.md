# Skill: Template Push

Sincroniza los skills y agents del proyecto actual al repositorio template `claude-starter`, para que los próximos proyectos partan de la versión más reciente.

## Trigger

Usar cuando el usuario invoque `/sys--template-push` o pida sincronizar / propagar cambios al template.

## Configuración

- **Ruta local del template**: `C:\david\development\claude-templates\claude-starter`
- **Repo remoto**: `https://github.com/dgarciahz/claude-starter`

## Agents incluidos en el template

Solo se sincronizan estos agents (lista explícita). El usuario puede tener agents propios en el proyecto que NO deben subirse al template:

- `test-architect.md`

Si el usuario pide añadir o quitar un agent de esta lista, actualiza el SKILL.md antes de continuar.

## Skills incluidos en el template

Solo se sincronizan estos skills (lista explícita). El usuario puede tener skills propios en el proyecto que NO deben subirse al template:

- `gh--push`
- `n8n--init`
- `per--handoff`
- `per--history`
- `per--init`
- `per--session-close`
- `per--learn`
- `sys--context-report`
- `sys--template-init`
- `sys--template-pull`
- `sys--template-push`

Si el usuario pide añadir o quitar un skill de esta lista, actualiza el SKILL.md antes de continuar.

## Instrucciones

Sigue estos pasos en orden:

### 1. Commit de cambios pendientes en el proyecto actual

Antes de sincronizar, asegúrate de que no hay cambios sin commitear en el proyecto. Ejecuta:

```bash
git status --short
```

Si hay cambios pendientes (archivos modificados o nuevos en `.claude/skills/` o `.claude/agents/`), haz commit automáticamente:

```bash
git add .claude/
git commit -m "Prepara skills/agents para sincronización con template — <fecha>"
```

Si hay cambios en otros archivos fuera de `.claude/`, infórmaselo al usuario pero no los incluyas en el commit — son responsabilidad suya.

### 2. Verificar que el clone del template existe

Comprueba que existe `C:\david\development\claude-templates\claude-starter\.git`. Si no existe, informa al usuario y detente — hay que clonar el repo primero.

### 3. Sincronizar skills

Copia **solo los skills de la lista anterior** desde `.claude/skills/` del proyecto actual a `C:\david\development\claude-templates\claude-starter\.claude\skills\`, sobreescribiendo los archivos existentes.

No copies skills que no estén en la lista — pueden ser skills específicos del proyecto activo.

### 4. Sincronizar init scripts

Copia todo el contenido de `.claude/init/` del proyecto actual a `C:\david\development\claude-templates\claude-starter\.claude\init\`, sobreescribiendo los archivos existentes. Si el directorio destino no existe, créalo.

### 5. Sincronizar agents

Copia **solo los agents de la lista anterior** desde `.claude/agents/` del proyecto actual a `C:\david\development\claude-templates\claude-starter\.claude\agents\`, sobreescribiendo los archivos existentes.

No copies agents que no estén en la lista — pueden ser agents específicos del proyecto activo.

### 6. Actualizar MCP_SERVERS.md (catálogo del template)

Lee el `.mcp.json` del proyecto actual y compáralo con el catálogo `.claude/skills/sys--template-push/MCP_SERVERS.md`.

Si hay servers en el proyecto que **no están en el catálogo**, pregunta al usuario:
> "Estos servers están en tu proyecto pero no en el catálogo del template: [lista]. ¿Los añado?"

Para cada server que el usuario apruebe, añade una entrada al `MCP_SERVERS.md` con:
- Nombre del server
- Paquete npx
- Variables necesarias (sin valores reales — solo los nombres)
- Descripción de uso

Una vez actualizado el `MCP_SERVERS.md`, cópialo al template:
`C:\david\development\claude-templates\claude-starter\.claude\skills\sys--template-push\MCP_SERVERS.md`

No copies `.mcp.json` ni `settings.local.json` — contienen rutas absolutas y credenciales específicas de cada máquina.

### 7. Sincronizar CLAUDE.md (opcional)

Si el usuario indicó explícitamente que quiere actualizar también el `CLAUDE.md`, cópialo. Si no lo mencionó, pregunta antes de hacerlo — el CLAUDE.md suele tener contenido específico del proyecto activo.

### 8. Hacer commit y push en el template

Desde `C:\david\development\claude-templates\claude-starter`:
- `git add .`
- `git commit -m "Sincroniza skills/agents desde [nombre del proyecto actual] — [fecha]"`
- `git push`

### 9. Confirmar

Informa al usuario de:
- Qué archivos fueron actualizados
- Si hubo archivos nuevos (skills nuevos que no existían en el template)
- Si hubo archivos eliminados en el proyecto (y por tanto ausentes en la sincronización)
- La URL del repo: `https://github.com/dgarciahz/claude-starter`

## Notas

- NUNCA copies `.claude/settings.local.json` al template — contiene rutas absolutas y permisos específicos de cada proyecto.
- Si el usuario quiere actualizar solo un skill concreto en lugar de todos, acepta el nombre como argumento y copia únicamente ese directorio.
- Tras el push, el template queda actualizado pero los proyectos ya creados desde él NO reciben los cambios automáticamente — eso es por diseño.
