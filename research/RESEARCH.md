# Research Framework

Cuando el usuario pida analizar, investigar o evaluar un proyecto, activa este framework de research multi-agente.

## Cuándo activar

Activa el framework cuando el usuario diga cosas como:
- "analiza este proyecto"
- "investiga este proyecto"
- "quiero hacer research sobre esta idea"
- "evalúa este proyecto"

No actives el framework para preguntas puntuales de mercado o búsquedas ad hoc — solo cuando el usuario quiera un análisis estructurado de un proyecto concreto.

## Paso 1 — Recoger el input

Antes de lanzar ningún agente, asegúrate de tener:
- **project_name**: nombre corto del proyecto (sin espacios, usa guiones). Si no lo has recibido, pídelo.
- **description**: texto de la propuesta. Puede ser breve (problema + solución + público) o extenso (documento completo pegado). Si el usuario menciona un fichero, consulta el punto siguiente.
- **document_path** (opcional): si el usuario indica un nombre de fichero, búscalo en `research/data/in/`. Lee el fichero con la herramienta Read y úsalo como `description`. Confirma al usuario: "He leído el documento [nombre] desde research/data/in/. Procedo con el análisis."

> Los ficheros en `research/data/in/` son gitignoreados — el usuario puede colocar documentos de propuesta ahí sin riesgo de que se suban al repositorio.

## Paso 1b — Determinar directorio WIP y ejecutar análisis previo

Deriva `wip_dir = research/wip/{project_name}/`.

**Si `wip_dir` no existe o está vacío**: créalo y continúa normalmente.

**Si `wip_dir` ya contiene JSONs**: lee también `research/state/{project_name}.json` si existe para tener el estado completo del run anterior (completados, skipped, errores). Muestra al usuario un resumen:

> "Ya existe un análisis para `{project_name}`:
> ✓ analysis — completado
> ✓ notebooklm — completado
> ↷ market-projects — skipped (motivo)
> ↷ semantic-scholar — skipped (motivo)
>
> ¿Qué módulos quieres regenerar? Escribe los nombres separados por comas, o deja en blanco para reutilizarlos todos."

Espera la respuesta. Los módulos que el usuario quiera reutilizar (y tienen JSON en `wip_dir`): léelos directamente (no lances el agente) y aplica igualmente la lógica de early exit del Paso 4.

**Después**, lanza el agente `agents/analysis.md` via `Agent tool` (a menos que el usuario haya indicado reutilizar el analysis existente). En el prompt incluye:
- El contenido de `research/agents/analysis.md` como instrucciones base
- El input del usuario: `project_name`, `description`
- La ruta `wip_dir` donde debe escribir `analysis.json`

Lee `{wip_dir}/analysis.json` cuando el agente termine (o directamente si se reutiliza):
- Si `status == "insufficient_info"` → detén el framework y muestra al evaluador:

> **Propuesta insuficiente para analizar.**
> Elementos que faltan: [lista de `missing_elements`]

- Si `status == "completed"` → muestra al usuario un resumen del análisis en este formato:

> **Análisis previo:**
> - Fundamento: [scientific_basis]
> - Diferenciales a verificar: [lista de aspect de differentiators]
> - Casos de uso: [lista de use_case]

Después continúa al Paso 2.

## Paso 2 — Leer la configuración

Lee `research/config/config.yaml` para conocer el pipeline de agentes, el orden de ejecución y las condiciones de salida anticipada (`workflow`), así como las rutas y límites operativos (`settings`).
Lee `research/config/io-schema.yaml` para conocer el contrato IO que cada agente debe respetar.

## Paso 3 — Selección de módulos

Lista los módulos disponibles al usuario (en orden de ejecución según `config.yaml → workflow.research_agents`) y pregunta:

> "Tengo disponibles los siguientes módulos de research:
> 1. **NotebookLM** — consulta tus cuadernos de Google NotebookLM
> 2. **Market Projects** — analiza los proyectos de referencia en `data/market/`
> 3. **Semantic Scholar** — valida el fundamento científico contra literatura peer-reviewed
>
> ¿Quieres ejecutarlos todos, o prefieres omitir alguno?"

Espera la respuesta del usuario antes de continuar:
- Si dice "todos" o equivalente → ejecuta los tres en orden
- Si indica módulos a omitir → regístralos en `state/{project_name}.json` con `status: skipped`. No escribas ningún fichero en `wip/`.
- Si no responde nada concreto → ejecuta todos por defecto

## Paso 4 — Ejecutar agentes en orden

Para cada agente seleccionado (en orden ascendente por `order`):

1. Lanza el agente via `Agent tool`. En el prompt incluye:
   - El contenido del fichero del agente (`agents/{id}.md`) como instrucciones base
   - El input del usuario: `project_name`, `description`
   - El `proposal_summary` y los campos estructurados de `{wip_dir}/analysis.json` (fundamento técnico, diferenciales, casos de uso) — usa el `proposal_summary` como referencia de la propuesta en lugar del texto completo original si este era extenso
   - La ruta `wip_dir` donde debe escribir su output

2. Espera a que el agente termine:
   - Si completó con resultado: su JSON estará en `{wip_dir}/{id}.json`. Actualiza `research/state/{project_name}.json` con `status: completed` y el mensaje del agente.
   - Si skipped o error: el agente no habrá escrito ningún fichero. Actualiza `research/state/{project_name}.json` con `status: skipped` o `status: error` y el mensaje recibido.

3. Evalúa la condición de early exit (solo si el agente completó con resultado):
   - Si `confidence == "high"` Y `recommendation == "stop"` → no lances más agentes, ve directamente al Paso 5.
   - En cualquier otro caso → lanza el siguiente agente.

4. Informa brevemente al usuario tras cada agente: "Módulo [nombre] completado/omitido. [1 frase con el hallazgo principal o el motivo del skip]."

## Paso 5 — Síntesis

Lanza el agente de síntesis (`agents/synthesis.md`) via `Agent tool`. En el prompt incluye:
- El contenido de `agents/synthesis.md` como instrucciones base
- `project_name`, `description`
- La ruta `wip_dir` para que lea los JSONs disponibles
- La fecha actual en formato YYYY.MM.DD

El agente de síntesis escribirá:
- `{wip_dir}/synthesis.json`
- `research/data/projects/YYYY.MM.DD-{project_name}.md`

## Paso 6 — Presentar resultado

Lee el contenido de `research/data/projects/YYYY.MM.DD-{project_name}.md` y preséntalo al usuario de forma limpia. Destaca:
1. La decisión (`ask_more_info` o `propose_experiment`)
2. Los próximos pasos concretos

## Notas

- `research/wip/{project_name}/` — solo JSONs con resultados reales (`status: completed`). Gitignored.
- `research/state/{project_name}.json` — traza completa de ejecución: todos los agentes con su status y mensaje, incluyendo skipped y errores. Gitignored.
- Los resultados finales en `research/data/projects/` sí se persisten — son la memoria acumulada del framework.
- Para añadir nuevos módulos de research, crea un nuevo fichero en `research/agents/` y añade su entrada en `research/config/config.yaml` bajo `workflow.research_agents`.
