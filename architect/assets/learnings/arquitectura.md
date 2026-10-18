# Learnings — Arquitectura de sistemas con LLM

## 2026-07-03 — Langfuse: Cloud vs. self-hosted en proyectos pequeños
**Contexto**: Diseño de arquitectura para una app RAG conversacional v1 con tráfico bajo (lump sum, EC2 pequeña, Docker Compose).
**Feedback**: Self-hosted Langfuse requiere su propio servidor Node.js + PostgreSQL + ClickHouse + Redis — termina siendo más pesado que la app principal. David quiere la observabilidad pero no a ese coste operativo.
**Regla**: En proyectos v1 con tráfico bajo, usar **Langfuse Cloud tier gratuito** (~50k observaciones/mes, solo API key, cero infraestructura). Evaluar self-hosted solo si el tier gratuito se queda pequeño o hay restricciones de privacidad de datos. Si ni eso es viable, fallback: logging estructurado a PostgreSQL propio.

## 2026-07-04 — RAG: retry y model cascade en structured output
**Contexto**: Diseño de la ruta de degradación para la llamada LLM de clasificación (A/B/C + surfacing) en un sistema RAG con LiteLLM y modelo barato como primer proveedor de inferencia.
**Feedback**: Un fallo de JSON structured output es casi siempre un problema de capacidad del modelo para seguir formato, no un fallo de red. El patrón de escalar a un modelo superior en caso de fallo doble (model cascade / quality escalation fallback) es reconocido en producción. El modelo de fallback más limpio es el mismo que ya se usa para generar la respuesta RAG — evita introducir un tercer modelo en el stack.
**Regla**: Cuando falla el parsing de structured output en la llamada de clasificación LLM: (1) reintentar con el mismo modelo a temperatura 0; (2) si falla de nuevo, llamar al modelo de generación RAG (el "modelo de calidad" ya en el stack) como árbitro de clasificación — via `fallbacks` de LiteLLM o llamada explícita; (3) si aun así falla, asumir Tipo A como último recurso y loggear en Langfuse. Nunca propagar un 500 al usuario por un fallo interno de clasificación.

## 2026-07-04 — RAG: desacoplar inferencia de embeddings
**Contexto**: Diseño de arquitectura RAG; debate sobre independencia de proveedores — LiteLLM desacopla la inferencia pero los embeddings tienen su propia dependencia.
**Feedback**: Self-hosting embeddings open-source (ej. Ollama + nomic-embed-text) añade complejidad operativa que supera el valor de la independencia a volúmenes bajos. Cambiar el modelo de embedding requiere reindexar todo el corpus — es el lock-in más severo en RAG. LiteLLM no resuelve esto: desacopla inferencia, no embeddings.
**Regla**: En RAG, tratar inferencia y embeddings como capas independientes. Elegir un **proveedor de embeddings estable** (familia OpenAI `text-embedding-3-*`: `small` para volúmenes bajos y coste mínimo, `large` si se necesita mayor calidad de retrieval) con dependencia deliberada y controlada. El consumo de embeddings ocurre en dos momentos: al reindexar documentos Y en cada query del usuario (para embeber la pregunta) — pero el coste es negligible (~$0.02–0.13/M tokens según modelo). La inferencia se mantiene switchable via LiteLLM. Documentar el modelo en un campo `embedding_model_version` en la tabla de chunks para detectar incompatibilidades al cambiar de modelo.

## 2026-07-03 — LLM wrapping: LiteLLM como librería desde el día 0
**Contexto**: Misma app RAG. David quiere arrancar con Claude API pero poder cambiar a un proveedor más barato (ej. Zhipu GLM via Serverless Inference) en el futuro sin tocar código.
**Feedback**: La abstracción debe diseñarse desde el inicio, no como refactor posterior. David lo señaló explícitamente como requisito arquitectónico.
**Regla**: Usar **LiteLLM como librería Python** (no el proxy) desde el primer commit. Todas las llamadas LLM pasan por `litellm.completion()` con el modelo como string configurable (`settings.LLM_MODEL`). Cambiar de proveedor = cambiar una variable de entorno. Soporta Claude, OpenAI, Zhipu GLM, Ollama y ~100 más sin infraestructura adicional.

## 2026-08-05 — Evitar tuning profundo en herramientas de terceros
**Contexto**: Diseño de arquitectura LightRAG (Postgres+pgvector) para el proyecto OKF, reemplazando llmwiki.
**Feedback**: David señaló que no quiere un tuning profundo de los parámetros internos de LightRAG — cuanto más se desvía de los valores por defecto, más fricción y riesgo de rotura al hacer upgrade de versión de la herramienta.
**Regla**: Al configurar herramientas de terceros con muchos parámetros internos ajustables (RAG, compiladores, frameworks), mantenerse cerca de los valores por defecto salvo necesidad concreta y medida. Documentar explícitamente cualquier desviación de default y por qué, para poder revisarla en cada upgrade.

## 2026-08-05 — Señal de alerta: piezas de "conocimiento consultable" sin retrieval real
**Contexto**: Descarte de `llm-wiki-compiler` (llmwiki) como motor de conocimiento consultable de OKF, sustituido por LightRAG — ver `IT_stacks/lightrag.md`.
**Feedback**: El motivo real del descarte no fue un límite puntual (cuota agotada) sino un defecto de diseño: llmwiki no usa RAG ni embeddings — en cada llamada reenvía el source completo más el índice/páginas relacionadas completas, así que el coste escala con el nº de conceptos y el tamaño de cada fuente, no con lo que realmente hace falta para responder.
**Regla**: Al evaluar una pieza de infra que promete "conocimiento consultable" (wiki compiler, motor de búsqueda semántica, etc.), verificar explícitamente si el mecanismo interno hace retrieval real (embeddings + selección de contexto relevante) o si en el fondo reenvía contexto completo/creciente en cada llamada. Esto último no es descarte automático — puede bastar para volúmenes pequeños — pero es la señal concreta que debe abrir una reflexión más profunda sobre si la pieza escala al caso de uso real, antes de comprometerse a ella.

## 2026-08-07 — Validar la coherencia del propio diseño de punta a punta antes de defender una pieza aislada
**Contexto**: Diseño del template CloudFormation para el primer despliegue LightRAG en EC2 (`km/assets/AWS-lightrag-ec2/`). Se justificó una Elastic IP como "necesaria para tener un endpoint estable" sin notar que el propio Security Group, ya diseñado sin ningún ingress (acceso solo vía SSM Session Manager), hacía esa IP inalcanzable para cualquiera — el usuario lo detectó preguntando, no yo.
**Regla**: Tras diseñar varios recursos relacionados entre sí, releer el conjunto para comprobar que cada justificación individual sigue siendo cierta con las demás piezas ya puestas — no defender una pieza mirándola aislada de las decisiones tomadas alrededor.

## 2026-08-07 — Verificar cifras de pricing/billing cloud contra fuente actual, nunca contra memoria
**Contexto**: Misma sesión de diseño LightRAG-EC2. Se afirmó que la IP pública efímera de EC2 es gratis (a diferencia de la Elastic IP). Ese dato cambió en AWS en febrero de 2024 — ahora toda IPv4 pública factura por igual, esté fija o no (ver `IT_stacks/aws.md`).
**Regla**: En cualquier pregunta de coste de un servicio cloud, verificar contra la página de pricing o una fuente reciente antes de dar una cifra — el conocimiento propio puede estar desactualizado sin que lo parezca, sobre todo en cosas que cambian de política de precios sin avisar mucho.

## 2026-08-21 — Watermark de progreso: no avanzarlo sobre registros saltados, solo sobre procesados

**Contexto**: servicio de dedup reforzado de LightRAG (`km/assets/AWS-lightrag-ec2/bootstrap/dedup-service/`) — `/scan` usa un watermark (`last_watermark`) para saber qué entidades del vector store son "nuevas" desde el último escaneo.

**Feedback**: el `advisor` detectó, antes de escribir código, que el watermark avanzaba para *toda* entidad nueva vista, incluso las que se saltaban por no tener aún su nodo de grafo resuelto (`entity_type is None` — ventana real durante ingesta en ráfaga, fila del vector store escrita antes que la del grafo). Esa entidad quedaba por debajo de la marca de agua sin haber sido evaluada nunca: se perdía para siempre, sin error visible.

**Regla**: en cualquier pipeline con un marcador de progreso tipo watermark/cursor/offset que decide qué unidades de trabajo son "nuevas", el marcador solo debe avanzar hasta el punto donde todas las unidades anteriores fueron **procesadas** (evaluadas de verdad), nunca hasta donde simplemente se **iteró** — si una unidad se salta por una condición temporal (dependencia aún no resuelta, dato aún no consistente), el marcador debe congelarse justo antes de ella para que el siguiente ciclo la reintente, en vez de avanzar igual y perderla en silencio. Es una clase general de bug de pipelines asíncronos, no específica de LightRAG — vigilar el mismo patrón en cualquier `cursor`/`offset`/`last_seen` que coexista con escritura concurrente de las fuentes que consulta.

## 2026-08-07 — Marco conceptual antes de pedir una decisión, y aislar explícitamente lo que excede el scope del proyecto
**Contexto**: Misma sesión. La pregunta "¿los consumidores son máquinas que controlas o clientes arbitrarios?" (para decidir el modelo de acceso a LightRAG) se lanzó de golpe cuando el usuario tenía conocimiento parcial del terreno (VPN, TLS, modelos de acceso) — tuvo que repetirse dos veces con marcos cada vez más concretos hasta que pudo decidir con criterio. Al final el usuario señaló, sin que se le preguntara, que la decisión de red/seguridad excedía este proyecto y era territorio de otro departamento (sistemas/CISO).
**Regla**: Cuando una pregunta de decisión toca un dominio que el usuario no domina aún, anteponer el marco conceptual (qué es cada opción, qué trade-offs concretos tiene) antes de pedir que elija. Y cuando una decisión técnica destapa una implicación de gobierno/seguridad más amplia que el proyecto en curso, señalarlo y ofrecer explícitamente dejarla fuera de scope, en vez de resolverla de facto eligiendo una opción por el usuario.
