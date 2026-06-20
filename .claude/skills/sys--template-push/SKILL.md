# Skill: Template Push

Sincroniza los skills y assets del proyecto actual al repositorio template `claude-starter`, para que los próximos proyectos partan de la versión más reciente.

## Trigger

Usar cuando el usuario invoque `/sys--template-push` o pida sincronizar / propagar cambios al template.

## Configuración

- **Repo remoto del template**: `https://github.com/dgarciahz/claude-starter`
- **Remote name**: `template`

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

### 1. Commit de cambios pendientes en el proyecto actual

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

### 2. Detectar el modo de operación

Ejecuta:
```bash
git remote get-url origin
```

- Si la URL contiene `dgarciahz/claude-starter` → **modo directo**: estás en el template. Los pasos siguientes operan sobre el directorio actual.
- Si la URL es otra cosa → **modo remoto**: estás en un proyecto derivado. Necesitas un worktree temporal del template.

#### Modo remoto: preparar worktree del template

Verifica o añade el remote `template`:
```bash
git remote get-url template 2>/dev/null || git remote add template https://github.com/dgarciahz/claude-starter
git fetch template
```

Crea un worktree temporal en una carpeta fuera del proyecto (e.g. `/tmp/claude-starter-push` o `%TEMP%\claude-starter-push`):
```bash
git worktree add <ruta-temporal> template/main
```

Todos los pasos 3–5 en modo remoto copian archivos a `<ruta-temporal>` en lugar de al directorio actual.

### 3. Sincronizar skills

Copia **solo los skills de la lista anterior** desde `.claude/skills/` del proyecto actual al directorio de destino (actual en modo directo, `<ruta-temporal>` en modo remoto), sobreescribiendo los existentes.

No copies skills que no estén en la lista — pueden ser skills específicos del proyecto activo.

### 4. Sincronizar agents

Copia **solo los agents de la lista anterior** desde `.claude/agents/` al directorio de destino.

No copies agents que no estén en la lista.

### 5. Sincronizar starter/assets/config.yaml

Lee `.mcp.json` del proyecto actual y compáralo con `starter/assets/config.yaml#mcp_servers` del directorio de destino.

**5.1 — MCP servers nuevos**: si hay servers en el proyecto que no están en el catálogo del config, pregunta al usuario:
> "Estos servers están en tu proyecto pero no en el config del template: [lista]. ¿Los añado?"

Para cada server aprobado, añade una entrada a `config.yaml#mcp_servers` con:
- Nombre del server
- Paquete npx
- Descripción de uso

**5.2 — Permisos nuevos**: compara `settings.local.json#permissions.allow` del proyecto con `config.yaml#permissions` del destino. Si hay permisos en el proyecto que no están en el config, pregunta al usuario:
> "Estos permisos están en tu proyecto pero no en el config del template: [lista]. ¿Los añado?"

Añade los aprobados a `config.yaml#permissions`.

Si se realizaron cambios al config.yaml, cópialos al directorio de destino.

No copies `.mcp.json`, `settings.local.json`, ni `CLAUDE.md` — son propios de cada proyecto.

### 5b. Actualizar starter/README.md

Comprueba si `starter/README.md` ya tiene cambios pendientes (el usuario lo modificó manualmente):

```bash
git diff --name-only HEAD -- starter/README.md
```

Si aparece en el diff → salta este paso.

Si no aparece:

1. Toma la lista de skills sincronizados en el Paso 3.
2. Lee `starter/README.md` y extrae las filas de la tabla de skills.
3. Para cada skill de la lista: lee la primera línea descriptiva de su `SKILL.md` (la que sigue al encabezado `#`). Compárala con la descripción en la tabla.
   - Skill nuevo (no tiene fila): añade una fila.
   - Skill con descripción distinta: actualiza la fila.
4. Para cada fila en la tabla cuyo skill ya no esté en la lista: elimina la fila.
5. Si hubo cambios: actualiza `starter/README.md` e informa al usuario qué filas se añadieron, eliminaron o modificaron. El archivo se incluirá en el commit del Paso 6 porque `starter/` ya está en el `git add`.
6. Si no hubo cambios: informa "starter/README.md no requiere cambios."

### 6. Commit y push

**Modo directo** (en el template):
```bash
git add .claude/ starter/
git commit -m "Sincroniza skills/assets — <fecha>"
git push
```

**Modo remoto** (desde el worktree temporal):
```bash
cd <ruta-temporal>
git add .claude/ starter/
git commit -m "Sincroniza skills/assets desde [nombre del proyecto actual] — <fecha>"
git push
```

### 6b. Actualizar starter/config/version

Tras el push del Paso 6, obtén el hash del commit recién subido y actualiza el fichero de versión:

**Modo directo:**
```bash
HASH=$(git rev-parse HEAD)
echo $HASH > starter/config/version
git add starter/config/version
git commit -m "chore: actualiza versión del starter — $HASH"
git push
```

**Modo remoto** (desde el worktree temporal):
```bash
HASH=$(git rev-parse HEAD)
echo $HASH > starter/config/version
git add starter/config/version
git commit -m "chore: actualiza versión del starter — $HASH"
git push
git worktree remove <ruta-temporal>
```

### 7. Confirmar

Informa al usuario de:
- Qué skills fueron actualizados
- Si se añadieron MCP servers o permisos nuevos al config
- Si hubo skills nuevos que no existían en el template
- La URL del repo: `https://github.com/dgarciahz/claude-starter`

## Notas

- NUNCA copies `CLAUDE.md`, `.mcp.json`, ni `.claude/settings.local.json` al template — son propios de cada proyecto.
- Si el usuario quiere actualizar solo un skill concreto, acepta el nombre como argumento y copia únicamente ese directorio.
- Tras el push, el template queda actualizado pero los proyectos ya creados desde él NO reciben los cambios automáticamente — eso es por diseño.
