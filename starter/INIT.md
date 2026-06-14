# Starter Framework — Inicialización

Este fichero contiene las instrucciones para inicializar el Starter Framework en el proyecto actual. Es autocontenido: configura todo lo que el proyecto necesita sin depender de ningún skill cargado previamente. Puede ejecutarse múltiples veces — cada paso es idempotente.

## Cómo invocar

Dile a Claude algo como:
- `"ejecuta starter/INIT.md"`
- `"inicializa el proyecto"`
- `"inicializa el starter framework"`

Claude leerá este fichero y seguirá los pasos a continuación.

---

## Instrucciones de inicialización

### Paso 1 — Leer la configuración del framework

Lee `starter/assets/config.yaml`. Este fichero define la versión del framework, MCP servers disponibles, permisos recomendados, variables de entorno y output styles.

Anota el valor de `version` para usarlo en el bloque STARTER del CLAUDE.md.

### Paso 2 — Actualizar .gitignore

Detecta si estás en el template o en un proyecto derivado:

```bash
git remote get-url origin
```

- Si la URL contiene `dgarciahz/claude-starter` → **modo template**: el `.gitignore` ya está correcto. Solo asegúrate de que `.claude/settings.local.json` está presente; no toques las entradas de `CLAUDE.md` ni `.mcp.json`.
- Cualquier otra URL (o sin remote) → **modo derivado**: sigue los pasos a continuación.

**En modo derivado:**

Busca `.gitignore` en la raíz del proyecto. Si no existe, créalo.

1. **Elimina** las líneas `CLAUDE.md` y `.mcp.json` del `.gitignore` **si están presentes** — en proyectos derivados estos ficheros deben quedar trackeados en git.
2. **Añade** `.claude/settings.local.json` **solo si no está ya presente**.

### Paso 3 — Crear o actualizar CLAUDE.md

**Si CLAUDE.md no existe**: créalo con este skeleton (sustituye `{version}` por el valor del config):

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

<!-- Describe what this project does and its primary goals. -->

<!-- STARTER:START — claude-starter v{version} -->
<!-- Inicializado por starter/INIT.md. Para re-inicializar: "ejecuta starter/INIT.md" -->
<!-- STARTER:END -->
```

**Si CLAUDE.md ya existe**: respeta TODO el contenido fuera del bloque `<!-- STARTER:START -->...<!-- STARTER:END -->`. Reemplaza el bloque (o añádelo al final si no existe) con la versión actual. Si el bloque ya existe con la misma versión, reemplázalo igualmente — permite actualizar su contenido en futuras versiones:

```
<!-- STARTER:START — claude-starter v{version} -->
<!-- Inicializado por starter/INIT.md. Para re-inicializar: "ejecuta starter/INIT.md" -->
<!-- STARTER:END -->
```

### Paso 4 — Configurar .mcp.json

Lee la sección `mcp_servers` de `starter/assets/config.yaml`.

Lee `.mcp.json` en la raíz del proyecto (si no existe, tratar como `{ "mcpServers": {} }`).

Identifica qué servers del config **no están** en `.mcp.json`. Estos son los "servers nuevos".

Si hay servers nuevos, pregunta al usuario con `AskUserQuestion` (multiSelect: true) cuáles quiere configurar. Muestra nombre y descripción de cada uno.

Para los servers elegidos:
1. Detecta la ruta de `npx` según el SO:
   - Windows: comprueba si existe `C:\Program Files\nodejs\npx.cmd`. Si no, usa `where npx`.
   - macOS/Linux: usa `npx`.
2. Construye el bloque `mcpServers.<nombre>` con `command` (ruta npx) y `args: ["-y", "<package>"]`.
3. Merge en `.mcp.json` preservando los servers ya existentes.

Si no hay servers nuevos o el usuario no quiere ninguno, continúa sin tocar `.mcp.json`.

### Paso 5 — Configurar settings.local.json

Lee `.claude/settings.local.json` (si no existe, tratar como `{}`).

**5.1 — enabledMcpjsonServers**: añade los servers elegidos en el paso 4 al array `enabledMcpjsonServers`. Solo añade — no quites los existentes. Si la clave no existe, créala.

**5.2 — Permisos**: lee la sección `permissions` de `config.yaml`. Para cada permiso: si no está en `permissions.allow[]`, añádelo. Si la clave no existe, créala.

**5.3 — CLAUDE_PERSONAL_DIR**: comprueba si `env.CLAUDE_PERSONAL_DIR` ya tiene un valor no vacío en `.claude/settings.local.json`.
- Si ya tiene valor: no lo toques.
- Si no tiene valor o no existe: pregunta al usuario:
  > "¿Cuál es la ruta de tu directorio de personalización? (ej. `C:\Users\tu-usuario\claude-personal` o `~/claude-personal`)"
  
  Escribe la ruta en `env.CLAUDE_PERSONAL_DIR` de settings.local.json. Informa: "Reinicia Claude Code al terminar para que la variable quede disponible."

Escribe `.claude/settings.local.json` actualizado. Si el fichero ya existía, haz merge — no sobrescribas completo.

### Paso 6 — Configurar statusline

**6.1 — Copiar script**: copia `starter/assets/statusline-command.sh` a `~/.claude/statusline-command.sh`. Copia siempre (permite actualizar el script en futuros re-inits).

**6.2 — Actualizar `~/.claude/settings.json`**: lee el fichero (créalo como `{}` si no existe). Si ya contiene la clave `statusLine`, no la toques. Si no existe, añade:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```

Este paso modifica la configuración global del usuario (`~/.claude/`), no del proyecto.

### Paso 7 — Instalar output styles

Lee la sección `output_styles` de `config.yaml`.

Para cada output style: copia `starter/assets/{file}` a `~/.claude/output-styles/{file}`. Copia siempre (permite actualizar en futuros re-inits). Crea el directorio `~/.claude/output-styles/` si no existe.

Después: comprueba si `outputStyle` ya está definido en `.claude/settings.local.json`.
- Si ya está definido: informa cuál está activo. No preguntes.
- Si no está definido: pregunta con `AskUserQuestion` qué output style quiere activar. Muestra los estilos del config más la opción "Ninguno". Para el estilo elegido (si no es "Ninguno"), escribe `"outputStyle": "<nombre>"` en `.claude/settings.local.json`.

### Paso 8 — Configurar personalización

Lee `CLAUDE_PERSONAL_DIR` desde `env.CLAUDE_PERSONAL_DIR` en `.claude/settings.local.json` (el valor configurado en el paso 5.3 o el preexistente).

**8.1 — Crear estructura de directorios**: crea cada fichero/directorio siguiente **solo si no existe aún**. NUNCA sobreescribas si ya existen — contienen datos del usuario.

- `$CLAUDE_PERSONAL_DIR/soul.md`:

```markdown
# Soul

## Identidad

<!-- Describe quién eres como asistente: tu rol, tu propósito, tu perspectiva. -->

## Principios éticos

<!-- Lista tus principios clave. -->

## Estilo de razonamiento

<!-- Cómo abordas los problemas. -->
```

- `$CLAUDE_PERSONAL_DIR/user.md`:

```markdown
# User

## Idioma

<!-- Idioma principal. Ej: Español -->

## Formato

<!-- Preferencias de formato. Ej: Sin emojis, respuestas concisas. -->

## Estilo de respuesta

<!-- Tono y estilo preferido. -->
```

- `$CLAUDE_PERSONAL_DIR/learnings.md`:

```markdown
# Learnings

Observaciones y aprendizajes acumulados sobre preferencias y patrones del usuario.
```

- `$CLAUDE_PERSONAL_DIR/learnings/_index.md`:

```markdown
# Learnings — Índice de Ficheros Temáticos

Catálogo de ficheros de aprendizaje por temática. Actualizar al crear un nuevo fichero en `learnings/`.

| Fichero | Temas | Cuándo cargar |
|---------|-------|---------------|
| (vacío — añadir entradas con /per--learn) | | |

**Instrucción de carga automática**: Cuando detectes que la sesión trata alguno de los temas de la tabla, usa la herramienta `Read` para cargar ese fichero antes de responder por primera vez. Informa al usuario: "He cargado learnings/<fichero>.md para esta sesión."
```

Para crear los directorios `learnings/` y `history/` si no existen, escribe un fichero `.gitkeep` vacío dentro de cada uno (esto crea el directorio automáticamente).

**8.2 — Bloque PERSONALIZATION en CLAUDE.md**: lee el `CLAUDE.md` del directorio de trabajo actual. Comprueba si ya contiene `<!-- PERSONALIZATION:START -->`.
- Si existe: reemplaza el bloque completo (desde `<!-- PERSONALIZATION:START -->` hasta `<!-- PERSONALIZATION:END -->`).
- Si no existe: añádelo al final del fichero.

Contenido del bloque (sustituye `<CLAUDE_PERSONAL_DIR>` por la ruta real; en Windows usa backslashes `\`):

```
<!-- PERSONALIZATION:START — no eliminar este bloque -->
@<CLAUDE_PERSONAL_DIR>/soul.md
@<CLAUDE_PERSONAL_DIR>/user.md
@<CLAUDE_PERSONAL_DIR>/learnings.md
@<CLAUDE_PERSONAL_DIR>/learnings/_index.md
<!-- PERSONALIZATION:END -->
```

### Paso 9 — Commit

**Modo derivado**: `CLAUDE.md` y `.mcp.json` ya están des-gitignoreados por el paso 2, así que pueden añadirse normalmente.

```bash
git add .mcp.json CLAUDE.md .gitignore .claude/settings.local.json
git commit -m "Inicializa proyecto desde starter framework — <fecha>"
```

**Modo template**: `CLAUDE.md` y `.mcp.json` siguen gitignoreados — no los incluyas en `git add`. Solo commitea `.gitignore` y `.claude/settings.local.json` si cambiaron.

Si algún fichero no existe (ej. `.mcp.json` si no se configuró ningún MCP server), omítelo del `git add`.

### Paso 10 — Confirmar al usuario

Informa de:
- MCP servers configurados (o "ninguno")
- Statusline: configurado / ya existía
- Output style activo
- CLAUDE_PERSONAL_DIR: ruta configurada
- Qué ficheros de personalización se crearon vs ya existían
- Recordatorio: reiniciar Claude Code para que los cambios surtan efecto

---

## Notas

- Re-ejecutar INIT.md aplica cambios del template sin perder configuración existente.
- NUNCA sobreescribe soul.md, user.md, learnings.md ni learnings/_index.md si ya existen.
- Para desinstalar: elimina los bloques `STARTER` y `PERSONALIZATION` de CLAUDE.md, borra `.claude/` y `.mcp.json`.
