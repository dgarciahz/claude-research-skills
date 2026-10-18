# Skill: Template Push

Propaga al repo de un framework (`<fw>`) los skills, agents y ficheros del directorio `<fw>/` del proyecto actual, para que los próximos proyectos partan de la versión más reciente.

Uso: `/sys--template-push <fw> [skill]`. Ejemplo: `/sys--template-push starter`.

## Trigger

Usar cuando el usuario invoque `/sys--template-push <fw>` o pida sincronizar / propagar cambios a un template.

## Convención de framework

Todo framework `<fw>` tiene la misma estructura dentro del proyecto:

```
<fw>/
  config/manifest.yaml   # repo, skills, agents
  config/version         # hash del último push
  assets/config.yaml     # catálogo de MCP servers y permisos
  README.md              # tabla de skills del framework
  INIT.md
```

`<fw>/config/manifest.yaml` es la única fuente de verdad del scope y la leen también `sys--template-pull` y este skill:

```yaml
repo: https://github.com/<owner>/<repo>
skills:
  - <skill1>
agents: []
```

Un skill o agent pertenece a un único framework. Si el usuario pide añadir o quitar uno, edita el manifest antes de continuar — no añadas listas en prosa aquí.

Los ficheros en `<fw>/skills/` son pseudo-skills del framework: no están en `.claude/skills/` y no necesitan lista explícita; viajan con `<fw>/`.

## Instrucciones

Sigue estos pasos en orden:

### 1. Resolver el framework

El primer argumento es `<fw>`. Si falta, pídelo y detente.

Comprueba que existe `<fw>/config/manifest.yaml`. Si no existe, informa de que `<fw>` no cumple la convención y detente. Léelo: de él salen `repo`, `skills` y `agents`.

Si el usuario pasó un segundo argumento (nombre de un skill), limita los pasos 4 y 5 a ese skill más `<fw>/` y dilo antes de continuar.

### 2. Commit de cambios pendientes

```bash
git status --short
```

Si hay cambios pendientes en las rutas del manifest o en `<fw>/`, haz commit automáticamente añadiendo solo esas rutas:

```bash
git add .claude/skills/<skill1> .claude/skills/<skill2> ... .claude/agents/<agent1> ... <fw>/
git commit -m "Prepara skills/assets para sincronización con template <fw> — <fecha>"
```

No uses `git add .claude/` a secas — se llevaría cualquier skill/agent/config ajeno al framework. Si hay cambios fuera de esas rutas, informa al usuario pero no los incluyas.

### 3. Sincronizar `<fw>/assets/config.yaml`

Si `<fw>/assets/config.yaml` no existe (framework sin MCP ni permisos propios, ej. `architect`), omite este paso.

Lee `.mcp.json` del proyecto y compáralo con `<fw>/assets/config.yaml#mcp_servers`.

**3.1 — MCP servers nuevos**: si hay servers en el proyecto que no están en el catálogo, pregunta:
> "Estos servers están en tu proyecto pero no en el config de <fw>: [lista]. ¿Los añado?"

Para cada uno aprobado, añade a `config.yaml#mcp_servers`: nombre, paquete npx y descripción de uso.

**3.2 — Permisos nuevos**: compara `settings.local.json#permissions.allow` con `config.yaml#permissions`. Si hay permisos que no están en el config, pregunta:
> "Estos permisos están en tu proyecto pero no en el config de <fw>: [lista]. ¿Los añado?"

Añade los aprobados a `config.yaml#permissions`.

No copies `.mcp.json`, `settings.local.json` ni `CLAUDE.md` — son propios de cada proyecto.

### 4. Actualizar `<fw>/README.md`

Si `<fw>/README.md` ya tiene cambios pendientes (`git diff --name-only HEAD -- <fw>/README.md`), salta este paso.

Si no:

1. Toma la lista de skills del manifest.
2. Extrae las filas de la tabla de skills de `<fw>/README.md`.
3. Para cada skill: lee la primera línea descriptiva de su `SKILL.md` (la que sigue al encabezado `#`) y compárala con la tabla.
   - Skill sin fila: añade una.
   - Descripción distinta: actualiza la fila.
4. Elimina las filas cuyo skill ya no esté en el manifest.
5. Informa de las filas añadidas, eliminadas o modificadas, o "<fw>/README.md no requiere cambios."

### 5. Commit y push al repo del framework

El destino es `repo` del manifest. Compara con el origin del proyecto:

```bash
git remote get-url origin
```

**5a. Origin == `repo`** (el proyecto es el propio repo del framework):

```bash
git add .claude/skills/<skill1> ... .claude/agents/<agent1> ... <fw>/
git commit -m "Sincroniza skills/assets — <fecha>"
git push
```

**5b. Origin != `repo`** (proyecto derivado). No empujes la historia del proyecto; publica solo las rutas del framework sobre la historia del repo del framework mediante un worktree temporal:

```bash
git remote get-url template-<fw> || git remote add template-<fw> <repo>
git fetch template-<fw>
git worktree add --detach <tmp> template-<fw>/main
```

Si el repo remoto está vacío (no existe `template-<fw>/main`), crea el worktree huérfano: `git worktree add --orphan -b sync-<fw> <tmp>`.

En `<tmp>`: para cada ruta del manifest y `<fw>/`, borra la ruta destino y copia la del proyecto (así se propagan también los ficheros eliminados). Después:

```bash
git -C <tmp> add -A
git -C <tmp> commit -m "Sincroniza skills/assets — <fecha>"
git -C <tmp> push template-<fw> HEAD:main
```

Si el push es rechazado por no ser fast-forward, informa y detente; no fuerces. Al terminar (también si falla), elimina el worktree: `git worktree remove --force <tmp>`.

En ambos casos no uses `git add .claude/` a secas.

### 6. Actualizar `<fw>/config/version`

Tras el push, escribe el hash del commit subido (`git rev-parse HEAD` en 5a, `git -C <tmp> rev-parse HEAD` en 5b) en `<fw>/config/version`, haz commit en el proyecto y haz push:

```bash
echo $HASH > <fw>/config/version
git add <fw>/config/version
git commit -m "chore: actualiza versión de <fw> — $HASH"
git push
```

En 5b, repite el commit de `version` en el worktree antes de eliminarlo para que el remoto también lo tenga, y haz push allí; en el proyecto el `git push` solo aplica si su origin lo tiene configurado.

### 7. Confirmar

Informa de:
- Qué skills están en el template `<fw>`
- Si se añadieron MCP servers o permisos nuevos al config
- La URL del repo (`repo` del manifest)

## Notas

- NUNCA copies `CLAUDE.md`, `.mcp.json` ni `.claude/settings.local.json` al template — son propios de cada proyecto.
- El manifest es la única fuente de verdad del scope. NUNCA uses `git add .claude/` a secas — siempre añade las rutas del manifest una a una.
- Tras el push, los proyectos ya creados desde el template NO reciben los cambios automáticamente — eso es por diseño (usan `/sys--template-pull <fw>`).
