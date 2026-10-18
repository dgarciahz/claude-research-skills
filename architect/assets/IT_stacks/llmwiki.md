# Stack: llmwiki (llm-wiki-compiler)

Particularidades de configuración y límites del compilador de wikis `llmwiki` (paquete npm `llm-wiki-compiler`).

> Verificado leyendo `dist/index.js` del paquete instalado en **v0.11.0** (2026-08-03). Software joven, con cambios frecuentes — re-confirmar contra el código instalado (`npm ls -g llm-wiki-compiler` / `llmwiki --version`) antes de asumir que estos valores siguen igual si la versión ha cambiado.

---

## Límites de ingest — hardcoded, no configurables

- `MAX_SOURCE_CHARS = 100.000` — cualquier source ingerido (`llmwiki ingest`/`quickstart`) que supere 100K caracteres se trunca ahí, con warning y `truncated: true` + `originalChars` en el frontmatter guardado.
- `MIN_SOURCE_CHARS = 50` — solo warning si es más corto, no bloquea.
- No hay env var, flag CLI ni entrada de `.llmwiki/config.json`/`schema.json` que los sobreescriba. Para cambiarlos habría que parchear el paquete instalado.

## Coste de `compile` — por qué escala rápido

`compile` hace **1 llamada de extracción** sobre el source completo + **1 llamada de generación de página por cada concepto extraído**. Cada llamada de generación:
- Reenvía el contenido **íntegro** del source otra vez (no hay cache/reuso entre páginas del mismo source).
- Incluye además el contenido completo de hasta `RELATED_PAGE_CONTEXT_LIMIT = 5` páginas ya generadas antes (hardcoded, no configurable) — para evitar contradicciones entre páginas.

Un source de 21K caracteres que produce 8 conceptos ya son 9 llamadas, cada una reenviando el source completo + hasta 5 páginas previas enteras. El coste crece con nº de conceptos extraídos, no solo con el tamaño del fichero.

**Extracción de conceptos: fuerza bruta, sin RAG ni embeddings.** `extractConcepts` manda el source completo (hasta el tope de ingest) dentro del system prompt junto con el contenido crudo íntegro de `wiki/index.md` (texto plano, no vectorial) para que el modelo decida si un concepto ya existe — sin chunking, sin ventana, sin recuperación selectiva. Los embeddings (`.llmwiki/embeddings.json`) solo se calculan después de compilar y solo alimentan `llmwiki query`/`context` (búsqueda semántica sobre la wiki ya compilada) — desconectados del pipeline de `compile`.

**Escalado del coste con el tamaño de la wiki: lineal y confinado a extracción, no a generación.** A medida que se acumulan conceptos (C) entre sesiones de `compile`, `wiki/index.md` crece (una línea por concepto) y se reenvía completo en cada llamada de extracción — coste lineal en C, una vez por fuente procesada. Dentro de un mismo `compile`, todas las fuentes del batch ven el mismo índice (congelado desde antes de empezar el run: `generateIndex` solo se ejecuta al final, tras generar todas las páginas) — no hay crecimiento fuente-a-fuente dentro de una misma ejecución. Las llamadas de **generación** de página no escalan con el tamaño total de la wiki en absoluto: ni el contenido combinado por concepto ni las páginas relacionadas (tope fijo `RELATED_PAGE_CONTEXT_LIMIT=5`) dependen de cuántos conceptos tenga la wiki en total. Compilar el concepto #500 no es más caro que el #5, salvo el margen lineal y modesto del índice en la única llamada de extracción por fuente.

## Presupuesto de prompt — sí configurable

- `LLMWIKI_PROMPT_BUDGET_CHARS` (env var), default `200.000` — presupuesto de caracteres combinados por llamada de generación de página (`resolvePromptBudgetChars`).
- Como el default (200K) es mayor que el tope de ingest (100K), un source de 100K se manda **íntegro sin truncar** en cada llamada de generación — no hay protección automática solo por estar en el límite de ingest.
- Bajar este valor (ej. 20.000-30.000) es la palanca real para controlar el coste por llamada en sources grandes: fuerza a truncar el contenido combinado (marcador `[…truncated for prompt budget…]`), a costa de que el modelo trabaje con menos contexto de la fuente.
- **Alcance real del presupuesto** (`buildBudgetedCombinedContent`): por concepto, suma el contenido **íntegro** de *todas* las fuentes donde ese concepto apareció (sin tope de número de fuentes) y, si el total supera el budget, reparte el presupuesto a partes iguales entre esas fuentes y trunca cada una desde el principio (`slice(0, perSource)`) — **corte de prefijo ciego, no una ventana centrada en dónde se discute el concepto**. Si el pasaje relevante está hacia el final del fichero, bajar el budget puede eliminarlo sin que quede ningún indicio.
- **No cubre las páginas relacionadas**: las hasta `RELATED_PAGE_CONTEXT_LIMIT=5` páginas de otros conceptos ya generados (`loadRelatedPages`) se envían completas y **sin pasar por este presupuesto**. Tampoco se eligen por relevancia — es `readdir()` del directorio de conceptos, filtrado y recortado a los primeros 5 en el orden que devuelva el filesystem (típicamente alfabético), no un ranking semántico.

## Estado del proyecto — `.llmwiki/state.json`

- `compile` decide qué reprocesar comparando el hash de cada source contra `.llmwiki/state.json` (`classifyFile`). Si el fichero no tiene entrada ahí, se trata como `"new"` **aunque ya exista una página compilada para él en disco** (ej. tras un crash que interrumpió el guardado del estado).
- No existe flag CLI para compilar un fichero suelto (`compile`/`refresh` siempre escanean todo `sources/`). Para controlar qué se compila en cada pasada sin mover ficheros de `sources/`: escribir a mano una entrada en `state.json` con el hash real (`concepts: []`) para los sources que se quieren dejar en pausa, y dejar sin entrada solo el que se quiere procesar. Reversible borrando la entrada.

## Providers

- Se resuelve solo por env var `LLMWIKI_PROVIDER` (`getProviderName`, `dist/index.js:1734`) — no hay campo de provider en `config.json`/`schema.json` ni en `state.json`. Sin la env var, cae a `DEFAULT_PROVIDER = "anthropic"`.
- **`anthropic`** (default): cliente HTTP directo (`@anthropic-ai/sdk`, `client.messages.create`), requiere `ANTHROPIC_API_KEY`. Billing por token vía API, aparte de cualquier plan de Claude Code. **No implementa prompt caching** (`cache_control`) en ningún método (`complete`/`stream`/`toolCall`) — el resend íntegro de source/páginas relacionadas en cada llamada no se beneficia de cache aunque el contenido se repita entre llamadas.
- **`claude-agent`**: no usa la API HTTP en absoluto — spawnea un **subproceso real del binario de Claude Code** vía `@anthropic-ai/claude-agent-sdk` (`query()`), comunicándose por stdin/stdout con mensajes JSON-lines (mismo mecanismo que usar `claude` desde terminal). No requiere `ANTHROPIC_API_KEY`; consume la sesión/plan de Claude Code (sus rate limits de 5h/semanales), no billing de API aparte.
- `MAX_TURNS = 4` en el provider `claude-agent` (`claude-agent.ts`) es un **techo de seguridad del bucle agente de esa sesión spawneada**, no el nº real de llamadas — con `tools: []`/`allowedTools: []` (como lo usa llmwiki) el caso normal resuelve en 1 turno; turnos extra solo si hay refusal-retry, respuesta cortada u otro evento anómalo dentro de esa invocación.
- Ninguno de los dos providers reduce el volumen de tokens reenviado por llamada (ver "Presupuesto de prompt") — la elección de provider decide **de qué cuota sale el gasto** (plan de Claude Code vs billing de API), no cuánto se gasta.
