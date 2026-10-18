# IT Stacks — Índice de Ficheros

Catálogo de stack docs por plataforma/entorno. Actualizar al crear un nuevo fichero en `IT_stacks/`.

| Fichero | Plataformas / herramientas | Cuándo cargar |
|---------|---------------------------|---------------|
| [windows.md](windows.md) | Windows, Git Bash, SSL, schannel, line endings, paths, bash | Cuando la sesión implique setup o configuración en entorno Windows |
| [llmwiki.md](llmwiki.md) | llmwiki, llm-wiki-compiler, OKF wiki compiler | Cuando la sesión trate configuración, límites o coste de `llmwiki`/`llm-wiki-compiler` |
| [aws.md](aws.md) | AWS, Lambda, MemorySize, cuotas de cuenta, CloudFormation, S3, SSM | Cuando la sesión trate cuotas, límites de servicio, soporte AWS o comportamiento de CloudFormation/S3/SSM |
| [lightrag.md](lightrag.md) | LightRAG, RAG, grafo de conocimiento, pgvector, workspace, PGTableGraphStorage, Apache AGE, MCP server, embeddings | Cuando la sesión trate configuración, storage, despliegue o arquitectura de LightRAG |
| [docker.md](docker.md) | Docker, Compose, buildx, registries, pin de versiones, digests | Cuando la sesión trate construcción, despliegue o pin de versiones de imágenes Docker |
| [n8n.md](n8n.md) | n8n, workflows, MCP server de n8n, Chat Trigger, Webhook | Cuando la sesión trate creación o edición de workflows n8n o su uso vía MCP |

**Instrucción de carga automática**: cuando la sesión trate setup o configuración de alguna de las plataformas de la tabla, usa `Read` para cargar el stack file antes de responder por primera vez. Informa: "He cargado IT_stacks/<fichero>.md para esta sesión."

**Para añadir o actualizar entradas**: usa el skill `/arch--stack`. Gestiona deduplicación y evita contradicciones.
