# Skill: Template Push

Sincroniza los skills y assets del proyecto actual al repositorio template `claude-starter`, para que los próximos proyectos partan de la versión más reciente.

Este skill siempre opera sobre el repositorio actual — no hay modo remoto ni worktrees. Si necesitas propagar cambios al template, hazlos directamente en `claude-starter`.

## Trigger

Usar cuando el usuario invoque `/sys--template-push` o pida sincronizar / propagar cambios al template.

## Configuración

- **Repo remoto del template**: `https://github.com/dgarciahz/claude-starter`

## Agents incluidos en el template

Solo se sincronizan estos agents (lista explícita). El usuario puede tener agents propios en el proyecto que NO deben subirse al template:

_(ninguno por ahora)_

Si el usuario pide añadir o quitar un agent de esta lista, actualiza el SKILL.md antes de continuar.

## Skills incluidos en el template

Solo se sincronizan estos skills (lista explícita). El usuario puede tener skills propios en el proyecto que NO deben subirse al template:

- `gh--pull`
- `gh--push`
- `per--handoff`
- `per--history`
- `per--session-close`
- `per--learn`
- `sys--context-report`
- `sys--template-pull`
- `sys--template-push`

Si el usuario pide añadir o quitar un skill de esta lista, actualiza el SKILL.md antes de continuar.

## Instrucciones

Sigue estos pasos en orden:

### 1. Commit de cambios pendientes

Antes de sincronizar, asegúrate de que no hay cambios sin commitear en `.claude/skills/` o `starter/`. Ejecuta:

```bash
git status --short
```

Si hay cambios pendientes en `.claude/skills/` o `starter/`, haz commit automáticamente:

```bash
git add .claude/skills/ starter/
git commit -m "Prepara skills/assets para sincronización con template — <fecha>"
```

Si hay cambios en otros archivos fuera de estos directorios, infórmaselo al usuario pero no los incluyas en el commit — son responsabilidad suya.

### 2. Sincronizar starter/assets/config.yaml

Lee `.mcp.json` del proyecto actual y compáralo con `starter/assets/config.yaml#mcp_servers`.

**2.1 — MCP servers nuevos**: si hay servers en el proyecto que no están en el catálogo del config, pregunta al usuario:
> "Estos servers están en tu proyecto pero no en el config del template: [lista]. ¿Los añado?"

Para cada server aprobado, añade una entrada a `config.yaml#mcp_servers` con:
- Nombre del server
- Paquete npx
- Descripción de uso

**2.2 — Permisos nuevos**: compara `settings.local.json#permissions.allow` del proyecto con `config.yaml#permissions`. Si hay permisos en el proyecto que no están en el config, pregunta al usuario:
> "Estos permisos están en tu proyecto pero no en el config del template: [lista]. ¿Los añado?"

Añade los aprobados a `config.yaml#permissions`.

No copies `.mcp.json`, `settings.local.json`, ni `CLAUDE.md` — son propios de cada proyecto.

### 3. Actualizar starter/README.md

Comprueba si `starter/README.md` ya tiene cambios pendientes (el usuario lo modificó manualmente):

```bash
git diff --name-only HEAD -- starter/README.md
```

Si aparece en el diff → salta este paso.

Si no aparece:

1. Toma la lista de skills del template.
2. Lee `starter/README.md` y extrae las filas de la tabla de skills.
3. Para cada skill de la lista: lee la primera línea descriptiva de su `SKILL.md` (la que sigue al encabezado `#`). Compárala con la descripción en la tabla.
   - Skill nuevo (no tiene fila): añade una fila.
   - Skill con descripción distinta: actualiza la fila.
4. Para cada fila en la tabla cuyo skill ya no esté en la lista: elimina la fila.
5. Si hubo cambios: actualiza `starter/README.md` e informa al usuario qué filas se añadieron, eliminaron o modificaron.
6. Si no hubo cambios: informa "starter/README.md no requiere cambios."

### 4. Commit y push

```bash
git add .claude/ starter/
git commit -m "Sincroniza skills/assets — <fecha>"
git push
```

### 5. Actualizar starter/config/version

Tras el push, obtén el hash del commit recién subido y actualiza el fichero de versión:

```bash
HASH=$(git rev-parse HEAD)
echo $HASH > starter/config/version
git add starter/config/version
git commit -m "chore: actualiza versión del starter — $HASH"
git push
```

### 6. Confirmar

Informa al usuario de:
- Qué skills están en el template
- Si se añadieron MCP servers o permisos nuevos al config
- La URL del repo: `https://github.com/dgarciahz/claude-starter`

## Notas

- NUNCA copies `CLAUDE.md`, `.mcp.json`, ni `.claude/settings.local.json` al template — son propios de cada proyecto.
- Si el usuario quiere actualizar solo un skill concreto, acepta el nombre como argumento e informa de qué se sincronizaría.
- Tras el push, el template queda actualizado pero los proyectos ya creados desde él NO reciben los cambios automáticamente — eso es por diseño (usan `/sys--template-pull` para actualizar).
