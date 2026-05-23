# Research Framework — Inicialización

Este fichero contiene las instrucciones para instalar el Research Framework en el proyecto actual.

## Cómo invocar

El usuario debe decirle a Claude algo como:
- `"ejecuta research/INIT.md"`
- `"inicializa el research framework"`
- `"instala el framework de research en este proyecto"`

Claude leerá este fichero y seguirá los pasos a continuación.

---

## Instrucciones de instalación

### Paso 1 — Verificar que el framework está presente

Comprueba que existe el directorio `research/` en la raíz del proyecto actual con los subdirectorios esperados (`config/`, `agents/`, `data/`, `wip/`, `state/`).

- Si no existe → informa al usuario: "El directorio `research/` no está presente. Clona el template desde GitHub: `git clone https://github.com/local_dgarciahz/claude-research-skills.git`"
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

### Paso 4 — Crear directorios de datos de usuario

Crea los siguientes directorios si no existen (son gitignoreados y no vienen en el repo):

```
research/data/in/
research/data/market/
research/data/projects/
```

### Paso 5 — Actualizar .gitignore

Busca el fichero `.gitignore` en la raíz del proyecto. Si no existe, créalo.

Añade las siguientes líneas si no están ya presentes:

```
research/data/
research/wip/
research/state/
```

### Paso 6 — Configurar NotebookLM (opcional)

Pregunta al usuario:

> "El módulo NotebookLM requiere el MCP server de NotebookLM configurado en `.mcp.json`. ¿Lo tienes ya configurado?"

- Si responde **sí** → continúa al Paso 7.
- Si responde **no** o **no sé** → informa:

> "Sin problema, puedes configurarlo más adelante. Cuando lo tengas, añade el servidor en `.mcp.json` en la raíz del proyecto, bajo la clave `mcpServers`, siguiendo el formato estándar de MCP servers de Claude Code. Sin él, el módulo NotebookLM se marcará automáticamente como `skipped` y el framework continuará con los demás módulos."

Continúa al Paso 7 independientemente de la respuesta.

### Paso 7 — Confirmar instalación

Muestra al usuario el siguiente mensaje:

```
Research Framework inicializado correctamente.

Se ha añadido a tu CLAUDE.md:
  @research/RESEARCH.md
  @research/skills/research--template-pull.md
  @research/skills/research--template-push.md

Directorios de datos creados (gitignored, solo locales):
  research/data/in/       → coloca aquí los documentos de propuesta a analizar
  research/data/market/   → coloca aquí ficheros .md de referencia competitiva
  research/data/projects/ → aquí se guardarán tus resultados de research

Próximos pasos:
  1. Reinicia Claude Code para que los @filepath carguen en el contexto.
  2. Añade ficheros .md de proyectos de referencia en research/data/market/
  3. Pide a Claude: "analiza este proyecto: [descripción]"

Comandos disponibles (tras reiniciar):
  "research pull"  → actualiza el framework core desde el repo de origen
  "research push"  → propone mejoras al framework via PR
```

---

## Notas

- Este fichero solo debe ejecutarse una vez por proyecto.
- Para desinstalar: elimina el bloque `<!-- RESEARCH:START/END -->` del CLAUDE.md y el directorio `research/`.
- Para añadir nuevos agentes de research: crea un fichero `.md` en `research/agents/` y regístralo en `research/config/config.yaml` bajo `workflow.research_agents`.
