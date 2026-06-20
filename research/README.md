# Research Framework

Un framework de investigación multi-agente para Claude Code que analiza proyectos desde múltiples ángulos y produce una recomendación accionable.

---

## Índice

1. [Contexto](#contexto)
2. [Quick Start](#quick-start)
3. [Install & Config](#install--config)
4. [Deep Dive](#deep-dive)
5. [Agents](#agents)
6. [Extending](#extending)

---

## Contexto

El Research Framework orquesta una secuencia de agentes de investigación, cada uno especializado en una fuente distinta de información. Antes del research, un agente de análisis caracteriza la propuesta recibida (fundamento técnico, diferenciales, casos de uso) y genera un resumen estructurado que orienta a los agentes posteriores. Al final, un agente de síntesis confronta los hallazgos y decide el próximo paso: pedir más información al usuario o proponer un experimento de validación.

El framework está diseñado para evaluar propuestas que llegan de terceros — puede recibir tanto una descripción breve como un documento extenso.

**Principios de diseño:**

- **Análisis previo** — antes de buscar, el framework caracteriza la propuesta: qué la fundamenta, qué dice ser diferente y para qué casos de uso. El research se orienta por estas hipótesis, no por la descripción cruda.
- **Aislamiento de contexto** — cada agente corre en su propio contexto y no "contamina" la conversación principal. Solo sus resultados (JSON estructurado) llegan al orquestador.
- **IO definida** — todos los agentes comparten el mismo contrato de entrada y salida (`config/io-schema.yaml`), lo que hace sus outputs comparables y la síntesis predecible.
- **Early exit** — si un agente devuelve confianza alta y recomienda parar, los agentes posteriores se omiten y se pasa directamente a síntesis.
- **Selección de módulos** — antes de ejecutar, el usuario puede elegir qué agentes correr y cuáles omitir.
- **Memoria acumulada** — los resultados finales se guardan en `data/projects/` con nombre `YYYY.MM.DD-{proyecto}.md` y se acumulan con el tiempo.

---

## Quick Start

Una vez instalado (ver [Install & Config](#install--config)), usa el framework así:

```
"Analiza este proyecto: [descripción del proyecto]"
"Investiga esta idea: [descripción]"
"Quiero hacer research sobre: [descripción]"
```

La descripción puede ser breve (unas líneas) o un documento completo. Si tienes un fichero, puedes indicar la ruta y el orquestador lo leerá. El framework primero caracterizará la propuesta (fundamento técnico, diferenciales, casos de uso) y te mostrará un resumen del análisis antes de lanzar los módulos de research. Al terminar, recibirás un informe con la decisión y los próximos pasos, guardado en `research/data/projects/`.

---

## Install & Config

### Opción A — Repo standalone

Clona el repositorio o usa **"Use this template"** en GitHub para crear tu propio repo:

```bash
git clone https://github.com/local_dgarciahz/claude-research-skills.git
```

Los resultados de research (`data/projects/`) son locales y gitignoreados. Los ficheros de referencia competitiva (`market/`) están versionados en el repo y se sincronizan con `research pull` / `research push`.

### Opción B — Integrar en proyecto existente (claude-starter)

Si ya tienes un proyecto creado desde `claude-starter` y quieres añadir research:

```bash
# Añadir el remote de research (una vez)
git remote add research https://github.com/local_dgarciahz/claude-research-skills.git

# Fetch y copiar SOLO el directorio research/
git fetch research
git checkout research/main -- research/
```

**Importante**: copiar solo `research/`. No copiar `.mcp.json` ni `.claude/settings.local.json` — esos ficheros son del proyecto destino. El paso siguiente (INIT.md) hace el merge de lo que research necesita en esos ficheros sin tocar la configuración existente.

### 2. Inicializar

Dile a Claude en ese proyecto:

```
"Ejecuta research/INIT.md"
```

Claude ejecutará los pasos de inicialización automáticamente:
- Añadir `@research/RESEARCH.md` al `CLAUDE.md` del proyecto (bloque `<!-- RESEARCH:START/END -->`)
- Añadir `research/wip/` y `research/state/` al `.gitignore`

### 3. Reiniciar Claude Code

Necesario para que el `@filepath` cargue en el contexto de sistema.

### 4. Añadir datos de referencia (opcional)

Coloca ficheros `.md` con descripciones de proyectos del mercado en `research/market/`. El agente `market-projects` los leerá para el análisis competitivo. Sin ellos, ese módulo informará que no hay datos y seguirá adelante.

### 5. Directorios de datos

El directorio `research/data/` es completamente gitignoreado. INIT.md lo crea con tres subdirectorios:

- `data/in/` — coloca aquí los documentos de propuesta a analizar
- `market/` — ficheros `.md` de referencia competitiva para el agente Market Projects (versionado en el repo)
- `data/projects/` — resultados generados automáticamente (informes de research)

### 6. Actualizar el framework (cuando haya nuevas versiones)

Pide a Claude: `"research pull"`. El framework actualiza solo el core (agents/, config/, skills/, RESEARCH.md) sin tocar tus datos ni resultados.

Para proponer mejoras al framework: `"research push"`. Se abre un PR en el repositorio de origen.

### 6. Configurar NotebookLM (opcional)

El agente `notebooklm` requiere el MCP server de NotebookLM configurado en `.mcp.json`. Si no está disponible, el módulo se marca automáticamente como `skipped` y el framework continúa.

**Instalar el MCP:**

```bash
pip install notebooklm-mcp
nlm login   # autenticación con tu cuenta Google
```

**Configurar en `.mcp.json`:**

```json
"notebooklm": {
  "command": "C:\\Users\\{usuario}\\AppData\\Roaming\\Python\\Python3XX\\Scripts\\notebooklm-mcp.exe",
  "env": {
    "SSL_CERT_FILE": "C:\\Users\\{usuario}\\AppData\\Roaming\\Python\\Python3XX\\site-packages\\certifi\\cacert.pem"
  }
}
```

> **Windows — fix SSL obligatorio:** Sin `SSL_CERT_FILE`, el proceso falla con `CERTIFICATE_VERIFY_FAILED`. La variable apunta al bundle de certificados de `certifi`, que se instala junto con el paquete. Sustituye `{usuario}` y `Python3XX` por los valores reales de tu máquina.

**Comportamiento del agente:**

Cada ejecución crea un cuaderno nuevo en NotebookLM con nombre `research_fw_{project_name}`, lanza una búsqueda web basada en el fundamento técnico y los diferenciales identificados en el análisis previo, importa las fuentes encontradas al cuaderno, y después interroga ese cuaderno con tres preguntas de viabilidad. El cuaderno queda disponible en NotebookLM para consulta posterior.

---

## Deep Dive

### Estructura de directorios

```
research/
├── RESEARCH.md          ← orquestador cargado via @filepath en CLAUDE.md
├── INIT.md              ← instalador one-shot (ejecutar una vez por proyecto)
├── README.md            ← esta guía
├── skills/              ← skill-like files cargados via @filepath
│   ├── research--template-pull.md   ← actualizar framework core desde upstream
│   └── research--template-push.md   ← proponer mejoras via PR
├── agents/              ← un .md por agente (llamados via Agent tool)
├── config/              ← configuración del framework
│   ├── config.yaml      ← pipeline de agentes, settings y repo de origen
│   ├── io-schema.yaml   ← contrato de entrada/salida de todos los agentes
│   └── version          ← hash del último push; los consumidores lo comparan al activar el framework
├── market/              ← ficheros .md de referencia competitiva (versionado en el repo)
├── data/
│   ├── in/              ← documentos de propuesta a analizar (gitignored, local)
│   └── projects/        ← tus resultados de research (gitignored, local)
├── wip/
│   └── {project_name}/  ← JSONs de resultados reales (solo agentes con status: completed, gitignored)
└── state/               ← traza completa de ejecución por proyecto (todos los agentes, gitignored)
```

---

### `RESEARCH.md` — El orquestador

Cargado en el contexto de sistema via `@research/RESEARCH.md` en `CLAUDE.md`. Contiene las instrucciones completas de orquestación: cuándo activar el framework, cómo recoger el input, cómo seleccionar módulos, cómo lanzar cada agente, la lógica de early exit y cómo presentar el resultado final.

No necesitas modificarlo salvo que quieras cambiar el comportamiento del orquestador.

---

### `config/config.yaml` — Configuración del framework

Un único fichero con tres secciones diferenciadas:

- **`workflow`**: pipeline de agentes (qué corre, en qué orden, condiciones de early exit, formato de output)
- **`settings`**: rutas internas y límites operativos
- **`source`**: URL del repo de origen (usado por `research--template-pull` y `research--template-push`)

Para añadir un nuevo agente: añade una entrada en `workflow.research_agents` con el `id`, `file` y `order` correspondiente.

---

### `config/io-schema.yaml` — Contrato de IO

Define el esquema de entrada y salida que todos los agentes deben respetar. Es la interfaz que hace posible que el orquestador y el agente de síntesis procesen outputs de distintos módulos de forma uniforme.

**Input al framework:**

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `project_name` | string | sí | Nombre corto del proyecto (sin espacios) |
| `description` | string | sí | Texto de la propuesta — puede ser breve o un documento extenso |
| `document_path` | string | no | Ruta a un fichero con la propuesta (alternativa o complemento a `description`) |

**Output del agente de análisis previo (`analysis_output`):**

| Campo | Tipo | Valores posibles | Descripción |
|---|---|---|---|
| `status` | string | `completed`, `insufficient_info` | Si la propuesta tiene sustancia suficiente para investigar |
| `proposal_summary` | string | — | Resumen estructurado de 400-600 palabras de la propuesta |
| `scientific_basis` | string | — | Fundamento científico/tecnológico subyacente |
| `differentiators` | array | — | Diferenciales afirmados con hipótesis verificables (`aspect`, `hypothesis`) |
| `use_cases` | array | — | Casos de uso con usuario objetivo (`use_case`, `target_user`) |
| `missing_elements` | array | — | Elementos ausentes en la propuesta (solo si `insufficient_info`) |

**Output de cada agente de research:**

| Campo | Tipo | Valores posibles | Descripción |
|---|---|---|---|
| `agent_id` | string | — | Identificador del agente |
| `status` | string | `completed`, `skipped`, `error` | Estado de la ejecución |
| `summary` | string | — | Resumen de hallazgos en 2-4 frases |
| `evidence` | array | — | Lista de evidencias con `source` y `finding` |
| `confidence` | string | `low`, `medium`, `high` | Confianza en los hallazgos |
| `recommendation` | string | `continue`, `stop` | Si `high`+`stop` → early exit |
| `findings` | object | — | Hallazgos detallados específicos del agente |

**Output del agente de síntesis:**

| Campo | Tipo | Valores posibles | Descripción |
|---|---|---|---|
| `decision` | string | `ask_more_info`, `propose_experiment` | Próximo paso recomendado |
| `rationale` | string | — | Razonamiento detrás de la decisión |
| `next_steps` | array | — | Preguntas (si `ask_more_info`) o pasos del experimento |
| `synthesis_notes` | string | — | Cómo encajan los hallazgos entre sí |

---

### `market/` — Datos de referencia competitiva

Ficheros `.md` que describen proyectos existentes en el mercado. Están versionados en el repo y se sincronizan con `research pull` / `research push`. El agente `market-projects` los lee y contrasta con el proyecto analizado. Formato libre; cuanto más estructurado, mejor el análisis.

### `data/projects/` — Resultados acumulados

Informes generados automáticamente por el agente de síntesis, con nombre `YYYY.MM.DD-{project_name}.md`. Se acumulan con el tiempo y forman una base de conocimiento de los proyectos analizados.

### `wip/` y `state/`

Directorios gitignored con responsabilidades distintas:

- **`wip/{project_name}/`** — contiene únicamente los JSONs de agentes que terminaron con `status: completed`. Si un agente fue omitido o falló, no escribe fichero. El árbol de `wip/` es fuente de verdad visual: si el JSON existe, tiene datos útiles.
- **`state/{project_name}.json`** — traza completa de la ejecución: todos los agentes con su estado real (`completed`, `skipped`, `error`, `pending`). Lo escribe y mantiene el orquestador, no los agentes. El orquestador lo lee al inicio de cada ejecución para mostrar el estado del run anterior y preguntar qué regenerar.

---

## Agents

Cada agente es un fichero `.md` en `research/agents/` con frontmatter YAML (modelo, herramientas disponibles) y un prompt de instrucciones. Todos escriben su output en `research/wip/{id}.json` siguiendo el esquema de `config/io-schema.yaml`.

Agentes disponibles actualmente:

| Agente | Fichero | Rol | Descripción |
|---|---|---|---|
| Analysis | `agents/analysis.md` | Pre-research | Caracteriza la propuesta: fundamento técnico, diferenciales e hipótesis, casos de uso |
| NotebookLM | `agents/notebooklm.md` | Research | Research conversacional en cuadernos de Google NotebookLM via MCP |
| Market Projects | `agents/market-projects.md` | Research | Analiza transcripciones de proyectos existentes para detectar si los casos de uso ya tienen solución |
| Semantic Scholar | `agents/semantic-scholar.md` | Research | Consulta Semantic Scholar para validar el fundamento científico/tecnológico contra literatura peer-reviewed |
| Synthesis | `agents/synthesis.md` | Síntesis | Sintetiza hallazgos de todos los módulos, produce valoración agregada y propone experimentos priorizados |

### Agente NotebookLM — cómo funciona

El agente crea un cuaderno nuevo en Google NotebookLM con nombre `research_fw_{project_name}`, construye una query de búsqueda web combinando el `scientific_basis` y los diferenciales más relevantes del análisis previo, y lanza esa búsqueda para poblar el cuaderno con fuentes reales (~10 documentos en modo `fast`).

Con el cuaderno poblado, realiza tres queries conversacionales sobre las fuentes importadas:
1. **Demanda real**: ¿hay evidencia de mercado para el fundamento técnico?
2. **Precedentes y competidores**: ¿hay proyectos similares? ¿qué se puede aprender de ellos?
3. **Criterios de validación**: ¿qué debería validarse primero antes de escalar?

El cuaderno queda disponible en tu cuenta de NotebookLM para consulta posterior — las fuentes importadas son accesibles directamente.

**Infraestructura:** Requiere el MCP server `notebooklm-mcp` configurado en `.mcp.json` (ver paso 6 de Install & Config). Sin él, el módulo se marca automáticamente como `skipped` y el framework continúa.

---

### Agente Market Projects — cómo funciona

El agente lee todos los ficheros `.md` disponibles en `research/market/` (hasta 20) y los contrasta con la propuesta analizada. Para cada proyecto de referencia evalúa tres dimensiones: si es competidor directo o indirecto, qué hace mejor o peor que la propuesta, y qué vacío deja que la propuesta podría cubrir.

El resultado es un mapa competitivo con competidores directos, competidores indirectos, brechas de mercado identificadas, y una síntesis de dónde hay espacio real para diferenciarse.

**Infraestructura:** Sin dependencias externas — solo lee ficheros locales. Si `market/` está vacío, escribe un resultado válido con `confidence: low` y continúa sin bloquear el pipeline. La calidad del análisis depende directamente de cuántos y cuán detallados sean los ficheros que el usuario haya colocado en `market/`.

---

### Agente Semantic Scholar — cómo funciona

El agente formula **4 queries** en inglés a partir del `scientific_basis` y los `differentiators` del análisis previo: una por el fundamento central, una por cada diferencial clave, y una por limitaciones conocidas del enfoque.

Para cada query, llama a la **API REST de Semantic Scholar** (`api.semanticscholar.org`) y recupera los 20 papers más relevantes semánticamente. De esos 20, selecciona 4-5 aplicando una estrategia de dos capas diseñada para evitar el sesgo temporal:

- **Papers fundacionales** (más de 2 años): se compara por `citas por año` (`citationCount / edad`), no por citas brutas. Esto evita que papers viejos muy citados eclipsen trabajo reciente equivalente. Se da prioridad especial a reviews y meta-análisis, que son el mejor proxy de consenso de la comunidad.
- **Papers recientes** (últimos 2 años): se acepta `influentialCitationCount > 0` o `citationCount ≥ 5` como umbral — suficiente señal de validación en un campo donde la antigüedad no ha tenido tiempo de acumularse.

El resultado (~15-20 papers en total) alimenta una síntesis en cuatro dimensiones: validación del fundamento, evidencia sobre los diferenciales, limitaciones conocidas, y nivel de madurez tecnológica (`early-research` / `emerging` / `validated` / `mature`).

**Infraestructura:** La API de Semantic Scholar es gratuita sin autenticación para uso básico (100 req/5 min). No requiere cuenta ni token. Devuelve JSON estructurado — sin scraping HTML.

---

## Extending

Para añadir un nuevo módulo de research al framework:

**1. Crea el fichero del agente**

Crea `research/agents/{nuevo-id}.md` con este esquema:

```markdown
---
description: Descripción del agente
model: claude-sonnet-4-6
tools:
  - [herramientas necesarias]
---

# Agente: {Nombre}

[Instrucciones del agente]

## Output que debes producir

Escribe `research/wip/{nuevo-id}.json` siguiendo `research/config/io-schema.yaml`.
```

**2. Regístralo en `config.yaml`**

Añade una entrada en `workflow.research_agents` de `research/config/config.yaml`:

```yaml
- id: nuevo-id
  file: agents/nuevo-id.md
  order: 4          # el siguiente en la secuencia
  description: Qué hace este agente
```

El orquestador lo incluirá automáticamente en la próxima ejecución.
