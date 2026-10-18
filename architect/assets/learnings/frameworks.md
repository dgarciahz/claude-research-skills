# Learnings — Frameworks en Claude Code

Reglas y patrones aprendidos sobre diseño, estructura y mantenimiento de frameworks en Claude Code.

---

## 2026-05-02 — Cohesión vs. sencillez al agrupar artefactos
**Contexto**: decidir si poner cada skill en su propio repo o en un monorepo de skills de research
**Feedback**: el usuario pidió razonar en profundidad el balance antes de proponer, no ir directamente a la solución más "limpia" técnicamente
**Regla**: al evaluar si separar artefactos relacionados (skills, módulos, plugins) en repos independientes vs. monorepo, hacer preguntas clave antes de proponer: ¿lo recordaré en 6 meses?, ¿necesita versiones independientes?, ¿hay conflictos que justifiquen el aislamiento? Si la respuesta es no, favorecer el monorepo con granularidad a nivel de directorio. La descubribilidad y el bajo overhead cognitivo a largo plazo pesan más que la cohesión estricta cuando los artefactos son pequeños y relacionados.

## 2026-05-08 — Protocolo de comunicación estricta entre subagentes (JSON)
**Contexto**: definición de la interfaz de intercambio de información en arquitecturas multi-agente en Claude Code.
**Feedback**: se requiere evitar la deriva de formato y errores de parseo que ocurren al usar lenguaje natural o formatos laxos entre agentes.
**Regla**: todos los subagentes creados deben comunicarse mediante un contrato en formato JSON. Al recibir información, el subagente debe realizar una validación inmediata: si el esquema no es correcto, debe rechazar la entrada y solicitar la corrección. Antes de emitir una respuesta (salida), el subagente debe verificar que su output cumple con el esquema JSON de salida definido; si no es así, debe reescribirlo antes de finalizar la tarea. La integridad del contrato es la prioridad máxima en la cadena de mando.

## 2026-05-08 — Estandarización de la configuración de agentes (YAML)
**Contexto**: gestión y mantenimiento de las definiciones, roles y capacidades de los subagentes.
**Feedback**: se busca separar la lógica de ejecución (JSON) de la configuración y definición humana para mejorar la legibilidad y el mantenimiento.
**Regla**: toda la configuración de los subagentes (definición de roles, parámetros de sistema, límites de herramientas y metadatos) que se creen en Claude Code, debe realizarse exclusivamente a través de ficheros YAML. Este formato será la "fuente de verdad" para la edición humana y la documentación de la arquitectura, facilitando la visión global del sistema y el uso de comentarios explicativos.

## 2026-05-17 — Anatomía de un framework
**Contexto**: diseño del Research Framework como alternativa escalable a añadir skills individuales en `.claude/skills/`
**Feedback**: los scripts OS-centric (`install.ps1`/`install.sh`) se dessincronizan entre plataformas. Un skill de init en `.claude/skills/` rompe la cohesión cuando el framework es un bloque autocontenido.
**Regla**: un framework es una carpeta autocontenida con estructura fija: `agents/` (un `.md` por agente con frontmatter YAML), `config/` (workflow, settings, io-schema), directorios de datos separados para input estático y output acumulado (con nombre `YYYY.MM.DD-{nombre}.md`), y carpetas temporales gitignored para wip y estado. El init se implementa como `INIT.md` — instrucciones que Claude ejecuta sin código ni dependencias OS.

## 2026-05-17 — Skills vs Agentes: cuándo usar cada uno
**Contexto**: decisión arquitectónica sobre si los módulos de trabajo de un framework debían ser skills residentes o agentes aislados
**Feedback**: los skills "infectan" el contexto al vivir en la conversación. Lo que tiene IO definida, principio y fin claros, y no debe acumular contexto, es un agente.
**Regla**: usar skills para capacidades residentes que asisten durante toda la conversación (orquestadores, herramientas de sesión). Usar agentes (`Agent tool`) para tareas con input/output definido que deben correr aisladas sin contaminar el contexto principal. En cualquier framework, los módulos de trabajo son siempre agentes; el skill o `@filepath` es solo el punto de entrada del orquestador.

## 2026-05-17 — README obligatorio en frameworks
**Contexto**: documentación del Research Framework como pieza duradera reutilizable en futuros frameworks
**Feedback**: acordado que todos los frameworks deben tener un README estándar que permita entender, instalar y extender sin leer el código
**Regla**: todo framework debe incluir `README.md` con estas secciones en orden: (1) Contexto, (2) Quick Start, (3) Install & Config, (4) Deep Dive (estructura + ficheros clave + tablas de IO/config), (5) módulos o agentes disponibles con placeholder para docs individuales, (6) Extending (cómo añadir un nuevo módulo en 2 pasos). Quick Start y Extending son las dos que aportan más valor operativo y deben incluirse siempre aunque el resto sea breve.

## 2026-05-23 — Research README como plantilla canónica
**Contexto**: al completar el README del Research Framework, el usuario estableció que debe servir de referencia para futuros frameworks
**Feedback**: todos los frameworks deben tener un README.md con estructura similar al del Research Framework, no solo tener algún README
**Regla**: al crear un nuevo framework, usar `research/README.md` como plantilla de referencia. La estructura es: Contexto → Quick Start → Install & Config → Deep Dive (estructura de dirs + ficheros clave + tablas de IO/config) → Agents/Módulos → Extending. Si el framework es más simple, las secciones pueden ser más breves pero todas deben estar presentes.

## 2026-05-23 — El push del framework gestiona la actualización del README
**Contexto**: tras añadir el agente de análisis y modificar io-schema, workflow y RESEARCH.md en el Research Framework, el README no se actualizó hasta que el usuario lo preguntó explícitamente
**Feedback**: el usuario tuvo que preguntar si el README estaba actualizado — debería haberse actualizado de forma proactiva junto con los cambios. La solución correcta no es recordar hacerlo manualmente, sino que el mecanismo de push lo haga sistemáticamente.
**Regla**: todo framework debe incluir en su skill de push un paso explícito que analice si los cambios del core afectan al README.md y, si es así, lo actualice antes de commitear. El push es el único punto de control que garantiza que README.md nunca quede desincronizado al propagar cambios.

## 2026-06-06 — Validación estricta de contratos IO en frameworks multi-agente
**Contexto**: diseño y modificación de frameworks multi-agente con contratos de paso de datos definidos en un schema compartido (como `io-schema.yaml`)
**Feedback**: los contratos de IO no tienen enforcement automático — un agente puede emitir campos incorrectos o recibir campos contaminados sin que el framework falle, generando desalineamientos silenciosos. Además, campos extra en el output de un agente que el siguiente no espera se descartan silenciosamente: información que se generó pero no llega a ningún sitio, y que puede haber influido en el razonamiento del agente emisor sin que el receptor lo sepa.
**Regla**: siempre que se cree o modifique un framework con contratos de paso de datos entre agentes, cada subagente debe validar estrictamente su input al inicio (campos esperados presentes, sin campos extra) y su output al final (campos requeridos completos, sin campos extra) antes de continuar o escribir resultados. Si hay desviación, el agente debe parar y reportar el error al orquestador — nunca continuar silenciosamente.

## 2026-06-07 — Frameworks: push/pull solo de sus propios archivos
**Contexto**: creando frameworks reutilizables (claude-starter, research framework) que se instalan en proyectos que pueden tener otros frameworks o utilidades adicionales.
**Feedback**: el push/pull de un framework arrastró archivos fuera de su scope (.claude/, CLAUDE.md), aplastando configuraciones del proyecto consumidor que no le pertenecían.
**Regla**: todo framework debe definir explícitamente en su push y pull solo los paths que le pertenecen. Nunca asumir que el directorio raíz o carpetas compartidas son exclusivos del framework — aunque en el proyecto de desarrollo convivan más utilidades.

## 2026-06-08 — Contextualización temática con _index.md en Claude Code
**Contexto**: diseño de sistemas de contextualización temática en Claude Code con múltiples ficheros MD especializados
**Feedback**: patrón validado — usar `_index.md` como pivot referenciado en `CLAUDE.md` tiene coste de tokens mínimo y habilita carga selectiva de ficheros especializados
**Regla**: al crear un sistema de contextualización temática en Claude Code, referenciar solo un `_index.md` en `CLAUDE.md`; el índice se carga siempre (< 500 tokens), contiene la instrucción de auto-detección, y los ficheros especializados se cargan on-demand via `Read` — no añadirlos directamente a `@filepath`

## 2026-06-10 — Init idempotente en frameworks de Claude Code
**Contexto**: creación de mecanismos de inicialización (INIT.md o skills de init) para frameworks reutilizables en Claude Code
**Feedback**: un framework puede recibir actualizaciones que requieran re-ejecutar el init, pero partes del setup ya realizadas anteriormente no deben volver a aplicarse — un init no-idempotente las sobreescribe o duplica
**Regla**: todo mecanismo de inicialización de un framework debe ser idempotente: antes de aplicar cada paso, comprobar si ya está hecho y saltarlo si es así. Esto permite re-ejecutar el init tras actualizaciones parciales del framework sin efectos adversos sobre lo ya configurado.

## 2026-06-10 — Health check de MCP servers al arrancar frameworks
**Contexto**: diseño de frameworks en Claude Code que dependen de MCP servers para ejecutar subagentes o módulos
**Feedback**: un MCP server caído hace que los agentes que lo requieren fallen silenciosamente o se salten sin aviso — el usuario asume que el framework ejecutó todo correctamente cuando en realidad partes críticas no corrieron
**Regla**: todo framework que use MCP servers debe hacer un health check explícito antes del primer uso: verificar que cada MCP server necesario está activo y accesible. Si alguno no lo está, informar al usuario antes de lanzar cualquier agente, indicando qué módulos quedarán sin ejecutar. Nunca dejar que un MCP inactivo filtre silenciosamente un mal funcionamiento.

## 2026-06-20 — Nunca cambiar el remote de git sin confirmación explícita
**Contexto**: ejecutando un push de cambios de framework desde un proyecto consumidor. Claude Code modificó el remote de git del proyecto para apuntar al repositorio del framework y subió cambios, arrastrando archivos del proyecto que no pertenecían al framework.
**Feedback**: cambiar el remote sin confirmación del usuario es destructivo — puede subir contenido incorrecto al repositorio equivocado. Los frameworks ya tienen sus propios ficheros `*--template-push` y `*--template-pull` que definen exactamente qué subir y a dónde.
**Regla**: nunca modificar el remote de git de un proyecto (`git remote set-url`, `git remote add`, etc.) sin confirmación explícita del usuario. Al trabajar con frameworks, usar los ficheros `*--template-push` / `*--template-pull` del propio framework — ellos ya gestionan el scope y el destino. Si el remote actual no apunta al destino correcto para el framework, informar al usuario y pedir confirmación antes de cualquier cambio.

## 2026-06-20 — Version check automático al arrancar sesión en frameworks
**Contexto**: implementando notificación de actualizaciones disponibles en claude-starter y research framework para que proyectos consumidores sepan cuándo hay una versión nueva
**Feedback**: `@`-include en CLAUDE.md descartado — las instrucciones quedan en el system prompt de cada mensaje y Claude podría ejecutar el check en cada interacción. Instrucción directa en CLAUDE.md mismo problema. Check en el skill de pull no es automático — el usuario tiene que invocarlo.
**Regla**: todo framework que necesite notificar actualizaciones disponibles debe implementar estos cuatro componentes: (1) `config/version` — fichero de texto plano con el hash del último commit pusheado (vacío hasta el primer push); (2) `assets/version-check.sh` — script bash que lee la hash local, fetcha la hash remota vía `curl`, compara y avisa si difieren; usa un marker file en `~/.claude/` con TTL de 4h para no repetirse en la misma sesión, y sale en silencio ante cualquier error; (3) hook `UserPromptSubmit` en `.claude/settings.json` que ejecuta el script — configurado por `INIT.md` en un paso dedicado (Paso 5.4 o equivalente), con merge del JSON existente; (4) paso en el skill de push (Paso 6b o equivalente) que tras el commit+push principal obtiene el hash HEAD, lo escribe en `config/version` y lo commitea+pushea como commit separado.

## 2026-06-28 — Proponer hooks de verificación para operaciones destructivas en frameworks
**Contexto**: diseño de skills, pseudo-skills, subagentes o scripts dentro de un framework de Claude Code
**Feedback**: operaciones destructivas (borrado de ficheros, sobreescritura, git reset --hard, etc.) se cuelan en scripts sin que el usuario las haya revisado explícitamente — el daño ocurre antes de que haya oportunidad de interceptarlo
**Regla**: al diseñar cualquier componente de un framework que pueda ejecutar operaciones destructivas, evaluar proactivamente si procede añadir un hook de verificación (PreToolUse) como parte del diseño — no como añadido posterior. Señalar al usuario qué operaciones quedarían sin guardia si no se activa el hook.

## 2026-06-28 — Skill vs pseudo-skill: residente vs invocado
**Contexto**: decisión arquitectónica al crear capacidades en un framework de Claude Code
**Feedback**: skills creados como capacidades residentes cuando en realidad solo tienen sentido invocados conscientemente con contexto concreto — añaden tokens al contexto sin aportar valor de trigger
**Regla**: antes de crear un skill, evaluar si necesita detectar un trigger y activarse solo durante la sesión (→ skill residente en `.claude/skills/`) o si el usuario siempre lo invoca conscientemente con contexto concreto (→ pseudo-skill). Los pseudo-skills van en el subdirectorio `skills/` propio de cada framework: `starter/skills/` para el starter, `research/skills/` para el research framework, y el equivalente en cualquier otro. Un pseudo-skill encapsula conocimiento en un fichero disponible pero no "salta" — esa es su naturaleza, no una limitación.

## 2026-06-20 — Flujo unidireccional en template pull/push
**Contexto**: ejecutando `/core--template-pull <fw>` en `claude-research-skills` — tras el pull, había commits en `.claude/skills/` pendientes de push
**Feedback**: se propuso hacer `git push origin main` de esos commits "de vuelta" al template de origen (claude-starter), confundiendo la dirección del flujo
**Regla**: los commits que llegan a un proyecto vía template pull (`/core--template-pull <fw>`) no se pushean de vuelta al template de origen — el flujo es unidireccional (template → proyecto). Cada framework propaga sus cambios propios con `/core--template-push <fw>`, que solo empuja el scope definido por los `prefixes` de su manifest. Si no hay cambios propios en el core del framework, no hay nada que pushear.

## 2026-10-18 — Scope de un framework por prefixes en el manifest, no por listas
**Contexto**: migración de `architect/config/manifest.yaml` de listas `skills:`/`agents:` a `prefixes:`, como en starter, para que `core--template-push` y `core--template-pull` sepan qué pertenece al framework
**Feedback**: el usuario fijó el prefix `arch` (no `per`): el prefix identifica al framework, no un dominio de uso. Los skills `core--*` están versionados en el proyecto pero son de starter y se actualizan en otro hilo
**Regla**: el scope de un framework `<fw>` es `.claude/skills/<prefix>--*`, `.claude/agents/<prefix>--*` y el directorio `<fw>/`, declarado en `<fw>/config/manifest.yaml#prefixes`, sin listas de nombres. Un prefix pertenece a un único framework. Si el prefix elegido no coincide con los skills existentes, renombrar los skills y sus referencias en lugar de mantener excepciones. Un proyecto puede versionar skills de otro framework que usa (`core--*`) sin ser dueño de ellos: no tocarlos ni gitignorearlos desde aquí; se actualizan vía `/core--template-pull`.
