# Skill: research--run

Lanza el framework de research multi-agente sobre un proyecto: análisis previo, módulos de research en paralelo y síntesis.

Uso: `/research--run <project_name> [fichero]`. Ejemplo: `/research--run mi-idea propuesta.md`.

## Trigger

Usar cuando el usuario invoque `/research--run` o pida analizar, investigar o evaluar un proyecto concreto: "analiza este proyecto", "investiga esta idea", "quiero hacer research sobre…", "evalúa este proyecto".

No usar para preguntas puntuales de mercado ni búsquedas ad hoc: solo para un análisis estructurado de un proyecto concreto.

## Instrucciones

### 1. Localizar el framework

Comprueba que existe `research/RESEARCH.md`. Si no existe, informa de que el Research Framework no está instalado (`/core--template-pull research` + `research/INIT.md`) y detente.

### 2. Ejecutar el flujo

Lee `research/RESEARCH.md` con Read y sigue sus pasos (1 a 6) tal cual. Es la única fuente del procedimiento: este skill no lo duplica.

Mapeo de argumentos:
- `<project_name>` → `project_name` (Paso 1). Si falta, pídelo.
- `[fichero]` → `document_path` (Paso 1); se busca en `research/data/in/`.
- Sin fichero: usa como `description` el texto que dio el usuario; si no hay, pídelo.

## Off-limits

- No toques ficheros fuera de `research/wip/`, `research/state/` y `research/data/projects/`.
- No lances agentes antes del Paso 3 de `RESEARCH.md` (selección de módulos) ni sin haber completado el análisis previo.
- No escribas en `wip/` JSONs de módulos `skipped` o con error.
- No modifiques `research/RESEARCH.md`, `research/agents/` ni `research/config/` durante un run.
- No incluyas el contenido de `research/data/in/` en commits ni lo copies fuera de `research/`.
