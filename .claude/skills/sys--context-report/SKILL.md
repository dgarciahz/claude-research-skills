# Skill: Context Report

Regenera la página `project-tools.html` del proyecto con información actualizada de MCP Servers y Skills.

## Trigger

Usar cuando el usuario invoque `/sys--context-report` o pida actualizar/regenerar la página de herramientas del proyecto.

## Instrucciones

Sigue estos pasos en orden:

### 1. Recopilar datos

#### MCP Servers
- Lee el archivo `.mcp.json` del directorio de trabajo actual para obtener los servidores configurados.
- Para cada servidor, extrae: nombre, command, args, y variables de entorno relevantes (sin exponer API keys completas).
- Obtén la lista de tools de cada servidor desde tu contexto de sistema (las definiciones de tools MCP cargadas en tu prompt). Incluye el conteo de tokens de cada tool.

#### Skills
- Lee skills de **dos directorios**, en este orden:
  1. `~/.claude/skills/` — nivel **usuario** (global)
  2. `.claude/skills/` relativo al directorio de trabajo actual — nivel **proyecto**
- En ambos directorios, ignora entradas que empiecen por `_` (como `_categories.json`) — no son skills.
- Para cada skill, lee su `SKILL.md` o `README.md` para extraer una descripción breve (1-2 frases).
- Lista los archivos `.md` de cada skill.
- Obtén los tokens de cada skill desde tu contexto de sistema.
- Registra el **origen** de cada skill (`usuario` o `proyecto`) para mostrarlo en el HTML.
- Si el mismo nombre de skill existe en ambos niveles, muéstralos como entradas separadas indicando su origen.

#### Categorías
- Busca `_categories.json` primero en `.claude/skills/` del proyecto; si no existe, usa `~/.claude/skills/_categories.json` como fallback.
- Clasifica cada skill según su prefijo (la parte antes de `--` en el nombre de la carpeta).
- Si un skill no tiene prefijo reconocido, agrúpalo bajo "other" con nombre "Otros" y descripción "Skills sin categoría asignada".

### 2. Generar el HTML

Genera el archivo `project-tools.html` en el directorio de trabajo actual con estas características:

#### Estructura general
- Tema oscuro (fondo #0f1117, estilo GitHub dark)
- Título: nombre del directorio de trabajo actual + " — Claude Code"
- Subtítulo: "MCP Servers y Skills asociados a este proyecto"
- Dos secciones colapsables: "MCP Servers" y "Skills"

#### Sección MCP Servers
- Header con: icono 🔌, título, descripción breve, badge con cantidad, total de tokens, chevron
- Barra de ordenación con botones: "Tokens", "Fecha creación", "Incorporación al proyecto"
  - Cada clic alterna ascendente ↑ / descendente ↓
  - Botón activo resaltado en azul
- Cada servidor como card colapsable con:
  - Nombre, cantidad de tools, tokens totales del servidor
  - Descripción breve
  - Al expandir: lista de tools con tokens individuales + bloque de configuración

#### Sección Skills
- Header con: icono 🧠, título, descripción breve, badge con cantidad, total de tokens, chevron
- Barra de ordenación con los mismos criterios que MCP Servers (Tokens, Fecha creación, Incorporación al proyecto) — aplica a nivel de categoría
- Nivel intermedio por categoría:
  - Cada categoría es una card colapsable con: prefijo, nombre de categoría, descripción, cantidad de skills, tokens totales de la categoría
  - Al expandir la categoría: lista de skills individuales como sub-cards colapsables
- Cada skill individual con:
  - Nombre, badge de origen (`usuario` en azul / `proyecto` en verde), cantidad de archivos, tokens
  - Descripción breve
  - Al expandir: lista de archivos .md del skill

#### Tokens
- Mostrar tokens entre paréntesis en color púrpura (#d2a8ff) a la derecha en TODOS los niveles:
  - Sección (total MCP / total Skills)
  - Servidor o categoría (subtotal)
  - Tool o skill individual
- Usar formato español con punto como separador de miles (ej: 6.595)

#### Data attributes para ordenación
- Cada item-card de servidor: `data-tokens`, `data-created`, `data-added`
- Cada item-card de categoría: `data-tokens`, `data-created`, `data-added`
- Para fechas, usar formato ISO (YYYY-MM-DD). Si no se conoce la fecha exacta, usar una fecha aproximada razonable.

### 3. Confirmar

Informa al usuario de:
- Cuántos MCP servers se encontraron y sus tools totales
- Cuántas categorías de skills y cuántos skills en total
- Total de tokens consumidos por MCP servers + skills
- Ruta del archivo generado

## Notas

- NO expongas API keys completas en el HTML — muestra solo los primeros/últimos caracteres o reemplaza con `***`.
- Los tokens se obtienen del contexto de sistema de Claude, no de archivos externos.
- Si un skill no tiene README.md ni SKILL.md legible, usa el nombre de la carpeta como descripción.
