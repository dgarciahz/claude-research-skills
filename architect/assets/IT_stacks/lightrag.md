# Stack: LightRAG

Particularidades de configuración, storage y despliegue de LightRAG (framework RAG con grafo de conocimiento, HKUDS). Sustituye a `llmwiki` en el proyecto KM — ver `llmwiki.md` para el diagnóstico de por qué se descartó.

## Storage backends soportados

Cuatro tipos de storage, cada uno con varias implementaciones:
- **KV**: JsonKVStorage, RedisKVStorage, PGKVStorage, MongoKVStorage, OpenSearchKVStorage
- **Vector**: NanoVectorDBStorage, MilvusVectorDBStorage, PGVectorStorage, FaissVectorDBStorage, QdrantVectorDBStorage, MongoVectorDBStorage, OpenSearchVectorDBStorage
- **Graph**: NetworkXStorage, Neo4JStorage, PGTableGraphStorage, PGGraphStorage, MongoGraphStorage, MemgraphStorage, OpenSearchGraphStorage
- **Doc status**: JsonDocStatusStorage, RedisDocStatusStorage, PGDocStatusStorage, MongoDocStatusStorage, OpenSearchDocStatusStorage

## PostgreSQL como backend único

Postgres puede servir las 4 storages a la vez — env vars: `LIGHTRAG_KV_STORAGE=PGKVStorage`, `LIGHTRAG_VECTOR_STORAGE=PGVectorStorage`, `LIGHTRAG_GRAPH_STORAGE=PGTableGraphStorage`, `LIGHTRAG_DOC_STATUS_STORAGE=PGDocStatusStorage`, más `POSTGRES_USER`/`POSTGRES_PASSWORD`/`POSTGRES_DATABASE`.

Para el grafo, usar **`PGTableGraphStorage`** (tablas planas, recomendada por el proyecto para despliegues nuevos), no `PGGraphStorage` (Apache AGE). AGE tiene bugs documentados: fallo intermitente en fusión de entidades ([#2122](https://github.com/HKUDS/LightRAG/issues/2122)) y una migración de versión que causó 17h de downtime por un query ineficiente con producto cartesiano entre tablas de vértices, cerrado como "no planeado" ([#2255](https://github.com/HKUDS/LightRAG/issues/2255)). `PGTableGraphStorage` no depende de la extensión AGE.

## Workspace — aislamiento y sus límites

`workspace` particiona lógicamente los datos (KV+vector+grafo) dentro del mismo backend — es el mecanismo para separar "temas"/corpus distintos. Se fija **al arrancar el proceso y es inmutable**: no hay parámetro en la API para elegir o cambiar workspace en tiempo de ejecución, ni forma de que un mismo proceso sirva varios workspaces a demanda. Confirmado en dos issues abiertos sin resolver por los mantenedores ([#2133](https://github.com/HKUDS/LightRAG/issues/2133), [#2527](https://github.com/HKUDS/LightRAG/issues/2527)).

Consecuencia práctica: **1 tema = 1 proceso LightRAG, siempre**. Compartir Postgres entre procesos es válido para ahorrar overhead operativo (parcheo/backup/monitorización de una sola instancia en vez de N), pero no cambia el hecho de que cada tema necesita su propio proceso corriendo.

## Sin migración oficial entre workspaces/instancias/backends

No existe herramienta oficial de export/import de corpus (chunks, entidades, relaciones, vectores) entre workspaces, instancias o backends de storage distintos — un issue pidiendo esto está cerrado como "not planned" ([#2011](https://github.com/HKUDS/LightRAG/issues/2011)). Para promocionar un tema de un Postgres compartido a uno dedicado: reingestar desde las fuentes `.md` originales, o hacer un dump/restore a nivel Postgres filtrado por el prefijo/columna de workspace (a validar contra el schema real de cada storage cuando se implemente — no dar por hecho que el filtro es limpio sin comprobarlo).

## Embeddings — lock-in de modelo

No hay herramienta de re-embedding. Cambiar de modelo de embedding obliga a borrar las tablas vectoriales (la dimensión queda fija en el schema al crearlas por primera vez) y reindexar todo el corpus desde las fuentes. El modelo de embedding se elige una vez, de forma deliberada, antes de indexar nada — ver también `learnings/arquitectura.md` (2026-07-04, "RAG: desacoplar inferencia de embeddings").

## LLM binding — proveedor pluggable nativo

LightRAG trae su propio binding pluggable por env var, sin necesitar una capa extra tipo LiteLLM: `LLM_BINDING` (`openai`, `azure_openai`, `aws_bedrock`, `ollama`, etc.), con roles separados — `LLM_MODEL`, `EXTRACT_LLM_MODEL`, `KEYWORD_LLM_MODEL`. Embeddings aparte: `EMBEDDING_BINDING`, `EMBEDDING_MODEL`, `EMBEDDING_DIM`. La documentación oficial recomienda explícitamente un modelo **non-thinking** para el rol de extracción.

## API server y OpenAPI

El servidor API corre sobre FastAPI y expone OpenAPI **3.x** nativamente — Swagger UI en `/docs`, ReDoc en `/redoc`. No genera Swagger 2.0; requeriría conversión adicional si algún consumidor externo lo exigiera.

## MCP server — decisión tomada

Existen varios wrappers MCP de terceros (`daniel-lightrag-mcp`, `lightragmcp`, `lightrag-mcp`, `mcp-lightrag`) que hacen de puente a la REST API — ninguno mantenido por HKUDS (el equipo del proyecto). Decisión: construir un MCP server propio y delgado sobre la REST API nativa de LightRAG, no adoptar uno de terceros — control total sobre el tool surface y evita el check de seguridad de dependencia externa para algo pensado como pieza core de infra propia.

## Despliegue multi-tema — arquitectura decidida

N procesos Docker LightRAG, uno por workspace (obligatorio, ver arriba). Dos niveles:
- **Temas no clave**: comparten un único Postgres (workspace por tema, coste de infra de BBDD amortizado entre todos).
- **Temas relevantes**: Postgres dedicado — sin depender de scale-to-zero, el tráfico ya lo justifica.

**Criterio de asignación (nace dedicado vs promoción con evidencia)**: importancia del tema + uso previsto **continuo** (no esporádico) → dedicado desde el día 1. Tema exploratorio o de uso bajo/esporádico → pool compartido. Si un tema del pool compartido pasa a tener uso continuo con el tiempo, esa es la señal de promoción a instancia dedicada. Criterio cualitativo, no un umbral numérico — juicio caso a caso, no automatizado.

**Infra: Docker en una sola EC2, no Kubernetes/EKS — decisión tomada.** Postgres compartido autogestionado en Docker, no Aurora: el argumento no es fuga de datos (Aurora habla Postgres estándar, `pg_dump`/`pg_restore` funcionan igual — solo el nivel físico/snapshots es propietario), sino portabilidad — mismo container en EC2, portátil o hardware propio, sin divergencia de setup ni extensiones (dev/prod parity).

EKS descartado para este despliegue: el control plane tiene coste fijo (~$73/mes) independiente del uso, y como Postgres nunca escala a cero, siempre queda mínimo 1 nodo worker vivo — el único ahorro real de KEDA+bin-packing sería de *tamaño* de instancia, no de *cantidad*, y no compensa el suelo fijo.

Con Docker+EC2 se pierde el scale-to-zero por-container que daría KEDA — asumido: Postgres + los N containers LightRAG se dejan corriendo siempre, sin watcher de idle-timeout (LightRAG es ligero, no mantiene estado en memoria, todo vive en Postgres). La EC2 sí se puede parar entera cuando no se usa (`aws ec2 stop-instances`, coste de cómputo $0, datos persisten en el volumen EBS) — útil para entornos de prueba.

Alcance de acceso: empezar con API key única (consumidor = Claude Code/agentes propios); si se convierte en infra compartida para terceros, diseñar usuarios con permisos CRUD por workspace — ahí es donde entraría OAuth (no antes, ver discusión de sesión).

## Concurrencia de ingesta — parámetros reales (verificado contra `env.example` del repo)

- `MAX_ASYNC_LLM` (default **4**): concurrencia de llamadas al LLM de extracción de entidades/relaciones. Es el cuello de botella real de la velocidad de ingesta — verificado empíricamente en despliegue propio: 3 documentos (104 chunks) tardaron ~11 min de punta a punta con este valor por defecto, con la CPU de una `t3.medium` en pico 39%/media 15% durante toda la ventana. **La ingesta es I/O-bound contra el proveedor LLM, no CPU-bound en la EC2** — dimensionar por rate-limit de la cuenta del proveedor (RPM/TPM), no por tamaño de instancia.
- `EMBEDDING_FUNC_MAX_ASYNC` (default **8**): concurrencia de llamadas de embedding.
- `MAX_PARALLEL_INSERT` (default 3, recomendado = `MAX_ASYNC_LLM`/3): nº de documentos procesados en paralelo.
- `EMBEDDING_BATCH_NUM` (nominalmente 32, aunque el propio `env.example` se contradice en un punto y dice 10 — no verificado cuál es el valor realmente aplicado en el contenedor desplegado): chunks agrupados por request de embedding.

Subir estos valores no tiene coste adicional en tokens facturados (mismo trabajo, menos tiempo de reloj) — el límite real a vigilar es el TPM de la cuenta del proveedor LLM, normalmente antes que el RPM (una llamada de extracción típica ronda ~3.500 tokens, mucho más que el tamaño medio que suele asumir el ratio RPM/TPM de las cuentas OpenAI).

## Rate-limit (429) durante ingesta — atomicidad real por fase, verificado contra código (v1.5.6, mismo commit `b33c6b0` de la sección anterior)

Al subir la concurrencia de ingesta (arriba) crece la probabilidad de 429 del
proveedor LLM. La ingesta tiene dos fases con comportamiento distinto ante
esto — importa para saber si subir el dial puede dejar un documento con
inserción incompleta y silenciosa en el grafo.

**Fase 1 — extracción de entidades/relaciones (LLM): atómica, sin riesgo.**
`extract_entities` (`operate.py:4077`) usa `asyncio.wait(tasks,
return_when=asyncio.FIRST_EXCEPTION)`: si cualquier chunk agota sus 3
reintentos con backoff (`openai_complete_if_cache`, tenacity,
`stop_after_attempt(3)`, `wait_exponential(min=4, max=10)`, cubre
`RateLimitError`) y sigue fallando, cancela todos los chunks pendientes y
relanza — la función nunca devuelve un resultado parcial
(`operate.py:4113`: solo se materializa si no hubo excepción). Esa excepción
sube hasta `pipeline.py:5250`, donde `merge_nodes_and_edges` **nunca llega a
ejecutarse**. Documento marcado `FAILED`, grafo intacto, cero residuo. Es la
fase que satura primero al subir concurrencia (más llamadas LLM en
paralelo).

**Fase 2 — merge en el grafo (LLM de resumen + embeddings): no atómica, pero
autorreparable.** `merge_nodes_and_edges` procesa entidades/relaciones una
por una (`_merge_nodes_then_upsert`/`_merge_edges_then_upsert`, con
`wait_tasks_with_drain`, no fail-fast global). Cada una puede disparar
`_handle_entity_relation_summary` (LLM, si hay descripciones a fusionar) y
`entity_vdb.upsert(...)` (embedding vía `openai_embed`, mismo patrón de
retry: tenacity, `stop_after_attempt(3)`, `wait_exponential(min=4, max=60)`,
cubre `RateLimitError`). Si una entidad falla tras agotar sus reintentos,
las entidades anteriores del mismo documento ya mergeadas quedan escritas en
el grafo — aquí sí hay, en teoría, residuo parcial real.

Pero LightRAG ya lo cubre por diseño, sin intervención externa necesaria:
- El documento se marca `FAILED` igual (nunca `PROCESSED` falso — el propio
  código cita el issue #3400: *"writing PROCESSED first opens a crash window
  where the status is durable but the graph/vector/chunk data is not —
  status is the commit record"*).
- El snapshot de chunks que se guarda en el `FAILED`
  (`get_failed_chunk_snapshot()`, `pipeline.py:4693`) es la lista
  **completa** de chunk_ids del documento, no solo los que fallaron. Al
  reintentar, `_purge_stale_extraction_if_resuming` →
  `_purge_doc_chunks_and_kg` purga todos esos chunks y su contribución al
  grafo antes de re-procesar — incluidas las entidades que sí se habían
  mergeado con éxito. Cero residuo huérfano tras el reintento, cero
  double-insert.

El reintento se dispara vía el endpoint **nativo** `POST /documents/scan` de
LightRAG (hace un "exclusive `FAILED`→`PENDING` reset" como parte de su
operación normal, confirmado en su propio código). **No confundir** con el
`POST /candidates/scan` propio del `dedup-service` (detección de candidatos a fusión,
cosa completamente distinta) — mismo nombre de verbo, endpoints distintos,
fácil de confundir en un mensaje al usuario.

**Ventana real, acotada, que sí existe**: entre que un documento queda
`FAILED` en fase de merge (con residuo parcial) y que alguien invoca `POST
/documents/scan` nativo, ese residuo es visible en el grafo con normalidad
— el documento no está borrado, solo `FAILED`, sus chunks siguen en
`lightrag_doc_chunks`. Se autorrepara solo al reintentar; si nadie reintenta
nunca, se queda así indefinidamente sin que nada lo señale como anómalo más
allá del propio `status=FAILED`/`error_msg` del documento.

**Implicación para el borrado coherente propio** (sección 5, arriba): borrar
un documento en estado `FAILED` a mitad de merge no es un remedio seguro sin
probarlo — `DELETE /documents/{doc_id}` de este proyecto delega en
`adelete_by_doc_id`, que enumera vía `lightrag_full_entities`/
`lightrag_full_relations`, tablas que `merge_nodes_and_edges` puebla
progresivamente. En un `FAILED` a mitad de merge esas tablas pueden estar
parcialmente pobladas o vacías según el punto exacto del fallo — mismo
patrón de riesgo que el bug ya documentado arriba (purge nativo que enumera
poco o nada y reporta éxito sobre un borrado incompleto). No se ha
ejercitado nunca borrar un doc `FAILED` end-to-end. El remedio correcto es
dejar que `/documents/scan` nativo reintente — no borrar.

## Modelo de coste de una query (no de ingesta)

Una query (`/query`, modo hybrid/local/global) es mucho más barata que ingerir el mismo documento: 1 llamada de embedding para la pregunta + retrieval en Postgres (gratis, es lectura de BBDD) + **1 sola llamada LLM** que sintetiza la respuesta final sobre el contexto ya recuperado. No repite nada parecido a la fase de extracción de la ingesta — el coste por query escala con el tamaño del contexto recuperado (`top_k`/presupuesto de tokens), no con el tamaño del grafo.

## Protección de documentos duplicados — dos capas distintas, no una

Hay **dos mecanismos de dedup independientes** en la ruta `/documents/upload`, en momentos distintos del ciclo de vida de la petición. Confundirlos lleva a conclusiones incorrectas (nos pasó: la entrada original de este fichero solo documentaba la capa 1 y daba por hecho, sin probarlo en vivo, que subir el mismo contenido con nombre de fichero distinto duplicaba — **falso**, corregido el 2026-08-20 tras probarlo).

**Capa 1 — por nombre de fichero, en el momento de subir.** Confirmado contra código (`get_existing_doc_by_file_path_candidates`, `document_routes.py`, docstring literal *"Find an existing document by canonical basename"* — compara solo `doc_status.get_doc_by_file_basename`, cero referencias a hash en todo el fichero). Si el nombre de fichero ya existe con `Status: processed`, devuelve **`HTTP 409 Conflict`** inmediato (*"Document storage already contains '&lt;nombre&gt;' (Status: processed). Delete the existing record before re-uploading."*) — la petición ni se encola.

**Capa 2 — por contenido, en el momento de parsear (después de aceptar la subida).** Confirmado **en vivo, por comportamiento observado en logs** (2026-08-20), no localizado en código todavía — pendiente si se necesita el mecanismo exacto (probable hash del texto parseado, a diferencia de `compute_mdhash_id(full_text, ...)` de `lightrag.py`, que pertenece a una ruta de inserción distinta — chunks custom vía SDK/Python, no la API REST). Subir el mismo contenido exacto con un **nombre de fichero distinto** pasa la capa 1 sin problema (202/200, aceptado), pero el pipeline lo descarta silenciosamente al parsear, sin extraer nada ni tocar el grafo — log real: `"Duplicate content skipped after parsing: &lt;nombre&gt;; archived to /app/data/inputs/default/__parsed__/&lt;nombre&gt;"`. No hay error HTTP, no hay aviso al cliente del upload — solo aparece en `history_messages` de `/documents/pipeline_status`.

**Tabla de comportamiento real, verificada en vivo:**

| Nombre de fichero | Contenido | Resultado |
|---|---|---|
| Igual | Igual | `409 Conflict` en el upload (capa 1) |
| Distinto | Igual | Upload aceptado, pero descartado en silencio al parsear (capa 2) — **no duplica** |
| Igual | Distinto | `409 Conflict` en el upload (capa 1) — bloqueado aunque el contenido no tenga nada que ver |
| Distinto | Distinto (aunque sea una edición mínima) | Se procesa normalmente, extrae entidades nuevas |

Para forzar reprocesamiento real en pruebas: no basta con cambiar el nombre de fichero, hace falta cambiar también el contenido (aunque sea una edición menor — confirmado que un cambio de unas pocas palabras ya basta para pasar la capa 2).

## Logs del contenedor — extraerlos sin depender del túnel

`docker compose logs -t` vía `aws ssm send-command` (canal independiente del port-forward interactivo) da timestamps reales de cada etapa del pipeline (extracción, merge, upsert) — útil para medir rendimiento real sin depender de polling por API. Ver `IT_stacks/aws.md` sobre el límite de 24.000 caracteres de `get-command-invocation`.

## Mecánica interna de ingesta, dedup y búsqueda

**Verificado contra**: código fuente de la rama `main` de `HKUDS/LightRAG` en 2026-08-19 (instancia desplegada corre la imagen `1.5.6`). El comportamiento interno de extracción/dedup no está documentado públicamente — solo se puede confirmar leyendo el código. Re-verificar estos 5 puntos si se actualiza la versión desplegada.

### 1. Ingesta y almacenamiento — 3 tablas/colecciones vectoriales distintas

Un documento se divide en chunks. Cada chunk se procesa **de forma aislada** por el LLM (sin ver qué se extrajo de otros chunks, ni del mismo documento ni de otros), según el prompt de extracción oficial, que pide dos tipos de salida:
- **Entidades**: `entity_name` (Título Case), `entity_type` (Person/Organization/Location/Event/Concept/Method/Content/Data/Artifact/NaturalObject/Other), `entity_description` (resumen generado por el LLM).
- **Relaciones**: `source_entity`, `target_entity`, `relationship_keywords`, `relationship_description`. No dirigidas por defecto (A→B y B→A son la misma arista).

Todo esto se guarda en **3 storages vectoriales distintos**, cada uno con contenido propio:

| Storage | Qué guarda | Qué se embebe |
|---|---|---|
| `chunks_vdb` | Texto crudo de cada chunk | El propio texto del chunk |
| `entities_vdb` | Una fila por entidad (nodo del grafo) | `entity_name + entity_description` |
| `relationships_vdb` | Una fila por relación (arista del grafo) | `keywords + entidad_origen + entidad_destino + relationship_description` |

Además, el grafo en sí (nodos + aristas con sus atributos) vive en tabla de grafo aparte (`PGTableGraphStorage` en nuestro despliegue). Cada entidad y relación guarda un `source_id` — puntero al chunk de origen, no el texto — para poder citar la fuente original bajo demanda.

### 2. Dedup nativo — solo por nombre exacto, no por significado

Al extraer una entidad, LightRAG comprueba si ya existe un nodo con ese `entity_name` **normalizado y exacto** (`_merge_nodes_then_upsert`) — búsqueda por clave, no por parecido semántico. El prompt pide al LLM "ensure consistent naming across the entire extraction process", pero **no hay mecanismo que lo garantice** — cada chunk se procesa sin ver los nombres ya usados antes, ni siquiera dentro del mismo documento.

Consecuencia: **sub-conexión** (misma entidad real, nombrada distinto por flexión/abreviatura/idioma/orden de palabras entre chunks o documentos → nodos separados que nunca se fusionan solos) y **falsa fusión** (dos entidades reales distintas con nombre genérico coincidente → se fusionan igual, mezclando descripciones). Relevante sobre todo para `global`/`hybrid` (punto 3), que dependen de que el grafo esté bien conectado.

**Matiz importante**: `entity_name` no es necesariamente una palabra literal del texto fuente — es una etiqueta generada por el LLM (Título Case, según su propio criterio de redacción), no un substring extraído mecánicamente. Esto significa que **controlar el nombre vía pre-proceso del documento fuente (lematizar, normalizar el `.md` antes de ingerir) no sirve**: el LLM puede redactar el nombre de forma distinta cada vez independientemente de cómo esté escrito el texto de entrada — no hay garantía de que un input normalizado produzca una salida normalizada. El control tiene que aplicarse **después** de la extracción, sobre el `entity_name` ya generado, no antes sobre el texto fuente.

### 3. Búsqueda — 5 modos, cada uno toca storages distintos

| Modo | Consulta primero | Qué aporta el grafo | Cuándo |
|---|---|---|---|
| `naive` | `chunks_vdb` | Nada — no toca el grafo | RAG plano, equivale a no tener LightRAG |
| `local` | `entities_vdb` (entidades semánticamente cercanas a la pregunta) | Sus aristas directas (1 salto), vía **traversal directo del grafo** (no vuelve a buscar en `relationships_vdb`) | Preguntas sobre un concepto/entidad concreto |
| `global` | `relationships_vdb` | Cadenas de relación más amplias. **No hace community detection ni multi-hop** — decisión de diseño explícita (se diferencian de Microsoft GraphRAG a propósito), más modesto de lo que suena | Preguntas temáticas/transversales |
| `hybrid` | `local` + `global` | Fusión de ambos | Caso general, el más usado |
| `mix` | `local` + `global` + `naive` | Todo junto | Máxima cobertura, más caro |

En todos los modos, el texto real del chunk se recupera por `source_id` (lookup directo), nunca por nueva búsqueda vectorial sobre `chunks_vdb`.

### 4. Fusión manual de entidades — API pública ya existente, con una laguna real

`POST /graph/entities/merge` (`amerge_entities`/`_merge_entities_impl`): fusiona descripciones (concatenación, no resumen LLM), redirige y deduplica relaciones, re-embebe entidad destino y relaciones afectadas, actualiza correctamente `entity_chunks`/`relation_chunks` (los índices que sí usan búsqueda/retrieval), **borra físicamente** las entidades origen (si ese nombre reaparece en una ingesta futura, crea un nodo huérfano nuevo — no hay memoria de la fusión pasada dentro de LightRAG). Manejo de fallos serio (`VectorStorageConsistencyError` + herramienta de recuperación `lightrag-rebuild-vdb`). Es la pieza que permitiría un dedup externo sin tocar código interno.

**Laguna real, verificada contra código (`v1.5.6`, ver punto 5): el merge nunca actualiza `full_entities`/`full_relations`** — tabla que solo usa el borrado de documentos (no la búsqueda) para enumerar candidatos. Consecuencia: la fusión en sí no rompe nada de retrieval, pero deja una entidad fusionada "invisible" para el mecanismo de borrado del documento que la respaldaba — ver punto 5.

### 5. Borrado de documentos — coherencia nativa, con una excepción real: entidades fusionadas manualmente

`adelete_by_doc_id`: si una entidad/relación tenía anclaje en varios documentos y se borra uno, la **reconstruye** usando extracción LLM ya cacheada de los documentos restantes — no la deja huérfana ni la borra sin más, para el caso normal (fuentes múltiples surgidas de ingesta, sin merge manual de por medio).

**Excepción real, verificada en producción y contra código fuente (`v1.5.6`, commit `b33c6b0`, 2026-08-21) — reproducida dos veces idéntica**: si la entidad viene de un `POST /graph/entities/merge` (punto 4), el borrado del documento puede **excluirla de su propia lista de candidatos a revisar** y aun así reportar éxito completo. Causa raíz exacta: el purge no mira `source_id` del grafo — enumera candidatos vía `lightrag_full_entities`/`lightrag_full_relations` (`lightrag.py:4997-5010`), tabla que solo se puebla **en la ingesta**, indexada por `doc_id`, con los nombres que ese documento extrajo originalmente. Como el merge nunca actualiza esa tabla, el `full_entities` del documento sigue apuntando al nombre **pre-fusión** (ya borrado del grafo por el propio merge); el purge lo busca, no lo encuentra, lo trata como "ya resuelto" (`lightrag.py:5038-5041`) y sigue — la entidad fusionada real, que sí tenía una fuente legítima de ese documento, nunca entra en la lista, nunca se evalúa. No afecta a entidades con fuentes de varios documentos que nunca pasaron por merge manual — solo a las fusionadas.

**Bug independiente, mismo hallazgo**: el borrado puntual (`DELETE /graph/entity/delete`, `adelete_by_entity`) sí limpia el nodo del grafo, pero **no limpia `lightrag_entity_chunks`/`lightrag_relation_chunks`** — el wrapper `LightRAG.adelete_by_entity` (`lightrag.py:6174`) no reenvía esos storages a la función interna que sabe limpiarlos (código muerto en ese camino).

Sin issue previo en `HKUDS/LightRAG` que coincida (confirmado con búsqueda real). El issue #3400 (cerrado 2026-07-17) introdujo el mecanismo `full_entities`/`entity_chunks` precisamente para evitar huérfanos de purge, pero nunca extendió esa contabilidad al endpoint de merge manual — probable candidato a seguir sin arreglar en próximas versiones salvo que se reporte. **Mitigación aplicada**: `km/assets/AWS-lightrag-ec2/bootstrap/dedup-service/` — limpieza defensiva tras cada borrado (comprobar que las entidades que el footprint marcaba `exclusive` de verdad desaparecieron, purgarlas vía API si no). **Re-verificar este punto en cualquier actualización de versión de LightRAG** — si `amerge_entities` empieza a mantener `full_entities`/`full_relations`, la mitigación deja de ser necesaria.
