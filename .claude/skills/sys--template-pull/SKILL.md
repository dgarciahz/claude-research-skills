# Skill: Template Pull

Actualiza los skills y el directorio `<fw>/` del proyecto actual desde el repo del framework `<fw>`, sin tocar la configuración local (`.mcp.json`, `settings.local.json`, `CLAUDE.md`).

Uso: `/sys--template-pull <fw> [url]`. Ejemplo: `/sys--template-pull starter`.

## Trigger

Usar cuando el usuario invoque `/sys--template-pull <fw>` o pida actualizar/sincronizar skills desde un template.

## Convención de framework

Todo framework `<fw>` tiene la misma estructura (ver `sys--template-push`): `<fw>/config/manifest.yaml` (con `repo`, `skills`, `agents`), `<fw>/config/version`, `<fw>/assets/config.yaml`, `<fw>/README.md` e `<fw>/INIT.md`.

El manifest es la única fuente de verdad de qué skills y agents pertenecen al framework.

## Instrucciones

Sigue estos pasos en orden:

### 1. Resolver framework y URL del repo

El primer argumento es `<fw>`. Si falta, pídelo y detente.

La URL del repo se resuelve así:

1. Si existe `<fw>/config/manifest.yaml`, lee `repo`.
2. Si no existe, o no tiene `repo`, usa el segundo argumento `[url]`. Si tampoco se pasó, pídela al usuario y detente.
3. Si se resolvió por el argumento (primer pull), crea un manifest mínimo `<fw>/config/manifest.yaml` con solo `repo: <url>`. El paso 4 lo sobrescribe con el manifest completo del remoto.

### 2. Verificar o añadir el remote `template-<fw>`

```bash
git remote get-url template-<fw>
```

Si no existe pero hay un remote antiguo `template` con la misma URL, renómbralo: `git remote rename template template-<fw>`.

Si no existe ninguno, añádelo:
```bash
git remote add template-<fw> <repo>
```

### 3. Fetch del template

```bash
git fetch template-<fw>
```

### 4. Leer el manifest remoto y mostrar qué ha cambiado

Léelo del remote (no del working tree local, que puede estar desactualizado):

```bash
git show template-<fw>/main:<fw>/config/manifest.yaml
```

Si el `repo` del manifest remoto difiere de la URL usada, avisa al usuario antes de continuar.

Con las rutas de skills/agents que liste, muestra un diff acotado a esas rutas más `<fw>/` completo:

```bash
git diff HEAD template-<fw>/main -- .claude/skills/<skill1> ... .claude/agents/<agent1> ... <fw>/
```

Si no hay diferencias, informa y detente — el proyecto ya está al día.

### 5. Bajar skills, agents y el directorio del framework

Trae solo las rutas declaradas en el manifest, nunca `.claude/skills/` o `.claude/agents/` completas — así nunca se toca un skill/agent propio del proyecto que no esté en el manifest:

```bash
git checkout template-<fw>/main -- .claude/skills/<skill1> .claude/skills/<skill2> ...
git checkout template-<fw>/main -- .claude/agents/<agent1> ...
git checkout template-<fw>/main -- <fw>/
```

No descarga ni modifica `.mcp.json`, `settings.local.json` ni `CLAUDE.md`.

### 6. Comparar config del template con el proyecto

Si `<fw>/assets/config.yaml` no existe en el template, omite este paso.

Lee `<fw>/assets/config.yaml` recién descargado y compáralo con `.mcp.json` del proyecto (si existe).

Si hay servers en el config que **no están en el proyecto**, muéstralos:
> "El config de <fw> tiene estos servers que no tienes configurados: [lista]. ¿Quieres añadir alguno?"

Usa `AskUserQuestion` con multiSelect. Para los elegidos:
- Pide las credenciales necesarias (si aplica)
- Detecta la ruta de `npx` según el SO (Windows: `C:\Program Files\nodejs\npx.cmd`, Unix: `npx`)
- Actualiza `.mcp.json` y `enabledMcpjsonServers` en `.claude/settings.local.json`

Si no hay diff de MCP servers (o el usuario no quiere ninguno), continúa sin tocar la config MCP.

### 7. Commit de los cambios

Añade solo las rutas traídas en el paso 5. No uses `git add .claude/skills/` a secas:

```bash
git add .claude/skills/<skill1> ... .claude/agents/<agent1> ... <fw>/
git commit -m "Sincroniza skills/framework desde template <fw> — <fecha>"
```

Si se añadieron MCP servers en el paso 6:
```bash
git add .mcp.json .claude/settings.local.json
git commit -m "Añade MCP servers desde template <fw> — <fecha>"
```

### 8. Confirmar al usuario

Informa de:
- Qué skills/agents fueron actualizados
- Si se actualizó `<fw>/` (INIT.md, assets)
- Qué MCP servers se añadieron (si los hay)
- Recordatorio: "Puedes re-ejecutar `<fw>/INIT.md` para aplicar cambios del framework (idempotente)"
- Recordatorio: reiniciar Claude Code si se añadieron MCP servers nuevos

## Notas

- NUNCA sobreescribas `.mcp.json` completo si ya existe — solo añade los servers nuevos elegidos.
- NUNCA sobreescribas `.claude/settings.local.json` completo — haz merge de `enabledMcpjsonServers`.
- NUNCA toques `CLAUDE.md` — es propio del proyecto.
- El scope lo decide el manifest del template, no una carpeta completa. NUNCA hagas `git checkout template-<fw>/main -- .claude/skills/` a secas.
- Este skill es idempotente: ejecutarlo varias veces no causa daño.
