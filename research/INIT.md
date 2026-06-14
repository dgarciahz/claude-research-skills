# Research Framework — Inicialización

Este fichero contiene las instrucciones para instalar el Research Framework en el proyecto actual. Es autocontenido: configura todo lo que research necesita sin depender de `sys--template-init` ni de ninguna otra herramienta del proyecto base.

## Cómo invocar

El usuario debe decirle a Claude algo como:
- `"ejecuta research/INIT.md"`
- `"inicializa el research framework"`
- `"instala el framework de research en este proyecto"`

Claude leerá este fichero y seguirá los pasos a continuación.

## Flujo de integración recomendado

Si estás añadiendo research a un proyecto ya creado desde `claude-starter`, el flujo limpio es:

```bash
# 1. Añadir el remote de research (una vez)
git remote add research https://github.com/dgarciahz/claude-research-skills.git

# 2. Fetch y copiar SOLO el directorio research/
git fetch research
git checkout research/main -- research/

# 3. Inicializar (este fichero) — hace el merge en .mcp.json y settings.local.json
# Dile a Claude: "inicializa el research framework"
```

**Por qué solo `research/`**: `.mcp.json` y `settings.local.json` son propiedad del proyecto destino. INIT.md se encarga de hacer merge de los requisitos de research en esos ficheros sin sobrescribir lo que ya configuró `claude-starter`.

---

## Instrucciones de instalación

### Paso 1 — Verificar que el framework está presente

Comprueba que existe el directorio `research/` en la raíz del proyecto actual con los subdirectorios esperados (`config/`, `agents/`, `data/`, `wip/`, `state/`).

- Si no existe → informa al usuario: "El directorio `research/` no está presente. Clona el template desde GitHub: `git clone https://github.com/dgarciahz/claude-research-skills.git`"
- Si existe → continúa.

### Paso 2 — Verificar que no está ya inicializado

Busca el bloque `<!-- RESEARCH:START -->` en el fichero `CLAUDE.md` de la raíz del proyecto.

- Si ya existe → informa al usuario: "El Research Framework ya está inicializado en este proyecto (bloque RESEARCH encontrado en CLAUDE.md)." y detente.
- Si no existe → continúa.

### Paso 3 — Añadir @filepath al CLAUDE.md

Busca el fichero `CLAUDE.md` en la raíz del proyecto. Si no existe, créalo vacío.

Añade el siguiente bloque al **final** del fichero:

```
<!-- RESEARCH:START -->
@research/RESEARCH.md
@research/skills/research--template-pull.md
@research/skills/research--template-push.md
<!-- RESEARCH:END -->
```

### Paso 4 — Crear directorios de datos y temporales

Estos directorios son locales y gitignoreados — no se incluyen en el repo ni se sincronizan con `research pull`. Debes crearlos explícitamente usando la herramienta Write para escribir un fichero `.gitkeep` vacío en cada ruta (esto crea el directorio automáticamente si no existe):

- `research/data/in/.gitkeep` — documentos de propuesta a analizar
- `research/data/projects/.gitkeep` — informes de research generados automáticamente
- `research/wip/.gitkeep` — JSONs de resultados por agente (temporales de ejecución)
- `research/state/.gitkeep` — traza completa de ejecución por proyecto

`research/market/` no se crea aquí — viene versionado en el repo del framework (core) y se sincroniza con `research pull`.

Si algún directorio ya existe, omítelo.

Si prefieres usar bash:

```bash
mkdir -p research/data/in research/data/projects research/wip research/state
touch research/data/in/.gitkeep research/data/projects/.gitkeep research/wip/.gitkeep research/state/.gitkeep
```

### Paso 5 — Actualizar .gitignore

Busca el fichero `.gitignore` en la raíz del proyecto. Si no existe, créalo.

Añade las siguientes líneas si no están ya presentes:

```
research/data/
research/wip/
research/state/
```

### Paso 6 — Merge de configuración MCP (notebooklm)

Lee `research/assets/MCP_SERVERS.md` para entender los requisitos del server notebooklm.

**6.1 — Comprobar si ya está configurado**

Lee `.mcp.json` del proyecto raíz (si no existe, tratar como `{}`). Comprueba si existe la clave `mcpServers.notebooklm`:

- **Sí existe** → saltar al paso 6.4 (solo merge de permisos).
- **No existe** → preguntar al usuario: *"El agente NotebookLM requiere el MCP server `notebooklm-mcp` configurado en `.mcp.json`. ¿Quieres configurarlo ahora?"*
  - **No** → informar: *"Sin problema. El módulo notebooklm se marcará automáticamente como `skipped` y el framework continuará con los demás módulos. Puedes configurarlo más adelante ejecutando `research/INIT.md` de nuevo."* Saltar al Paso 7.
  - **Sí** → continuar al paso 6.2.

**6.2 — Detectar rutas automáticamente**

Ejecuta los siguientes comandos para detectar las rutas del sistema:

- **Ejecutable notebooklm-mcp**:
  - Windows: `Get-Command notebooklm-mcp -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source`
  - Unix/Mac: `which notebooklm-mcp`
  - Si no se encuentra: pedir al usuario la ruta completa del ejecutable.

- **Ruta certifi** (certificados SSL):
  - `python -c "import certifi; print(certifi.where())"`
  - Si falla: pedir al usuario la ruta del archivo `.pem`.

**6.3 — Añadir notebooklm a `.mcp.json`**

Merge del bloque notebooklm en `.mcp.json`, preservando todos los servers existentes (playwright, context7, n8n-mcp, etc.):

```json
"notebooklm": {
  "command": "<ruta_ejecutable_detectada>",
  "env": {
    "SSL_CERT_FILE": "<ruta_certifi_detectada>"
  }
}
```

Escribir el `.mcp.json` resultante.

**6.4 — Merge de permisos en `settings.local.json`**

Lee `research/assets/permissions.md` para obtener la lista de permisos.

Lee `.claude/settings.local.json` (si no existe, tratar como `{}`).

Para cada entrada de `research/assets/permissions.md`:
- Si ya está en `permissions.allow[]` → omitir.
- Si no está → añadirla al array.

Si el usuario eligió configurar notebooklm (paso 6.1 respondió Sí):
- Añadir `"notebooklm"` a `enabledMcpjsonServers[]` si no está ya.

Escribir `.claude/settings.local.json` actualizado.

**6.5 — Confirmar**

Si se configuró notebooklm: informar al usuario que ejecute `nlm login` antes del primer uso para autenticarse con su cuenta Google.

### Paso 7 — Confirmar instalación

Muestra al usuario un resumen adaptado a lo que se ejecutó:

```
Research Framework inicializado correctamente.

CLAUDE.md — añadido:
  @research/RESEARCH.md
  @research/skills/research--template-pull.md
  @research/skills/research--template-push.md

Directorios creados (gitignored, solo locales):
  research/data/in/       → documentos de propuesta a analizar
  research/data/projects/ → resultados de research
  research/wip/           → JSONs temporales por agente
  research/state/         → traza de ejecución

  research/market/        → referencia competitiva (versionado en el repo)

.mcp.json — notebooklm: [configurado | ya existía | saltado]
settings.local.json — permisos notebooklm: [añadidos | ya existían | saltados]

Próximos pasos:
  1. [Solo si notebooklm se configuró ahora] Ejecuta `nlm login` para autenticarte.
  2. Reinicia Claude Code para que los @filepath carguen en el contexto.
  3. Añade ficheros .md de proyectos de referencia en research/market/
  4. Pide a Claude: "analiza este proyecto: [descripción]"

Comandos disponibles (tras reiniciar):
  "research pull"  → actualiza el framework core desde el repo de origen
  "research push"  → propone mejoras al framework via PR
```

---

## Notas

- Este fichero solo debe ejecutarse una vez por proyecto.
- Para desinstalar: elimina el bloque `<!-- RESEARCH:START/END -->` del CLAUDE.md y el directorio `research/`.
- Para añadir nuevos agentes de research: crea un fichero `.md` en `research/agents/` y regístralo en `research/config/config.yaml` bajo `workflow.research_agents`.
