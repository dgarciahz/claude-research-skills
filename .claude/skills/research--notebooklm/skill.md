# NotebookLM Research Assistant

Usa este skill para conectar Claude Code con tus cuadernos de Google NotebookLM como fuente de research. NotebookLM indexa tus documentos con Gemini y responde consultas con citas precisas — sin cargar documentación completa en el contexto.

## Inicio rápido

Cuando el usuario invoque `/research--notebooklm`, primero lista sus cuadernos disponibles con `list_notebooks` para que pueda elegir con cuál trabajar. Si ya mencionó el cuaderno, ve directo a la operación.

## Workflows principales

### Consulta RAG (uso más frecuente)
Para preguntas sobre el contenido de un cuaderno:
1. Usa `query_notebook` con el ID del cuaderno y la pregunta
2. Presenta la respuesta con sus citas
3. Si el usuario pide más detalle, usa `chat_notebook` para seguimiento

### Agregar fuentes
- URL o artículo: `add_source_url`
- YouTube: `add_source_youtube`
- Google Drive: `add_source_google_drive`
- Texto directo: `add_source_text`

### Generar contenido Studio
- Podcast/audio: `generate_audio_overview`
- Reporte escrito: `generate_report`
- Presentación: `generate_slides`
- Infografía: `generate_infographic`
- Flashcards: `generate_flashcards`
- Quiz: `generate_quiz`
- Mapa mental: `generate_mind_map`
- Tabla de datos: `generate_data_table`

### Gestión de cuadernos
- Listar: `list_notebooks`
- Crear: `create_notebook`
- Renombrar: `rename_notebook`
- Eliminar: `delete_notebook`

## Principios de uso

- Trata a NotebookLM como la **fuente de verdad** para el contenido de investigación del proyecto. Antes de generar contenido sobre un tema que puede estar en un cuaderno, consulta primero.
- Las respuestas de NotebookLM incluyen citas — úsalas para dar trazabilidad al usuario.
- Para documentación técnica extensa (SDKs, APIs, specs), siempre prefiere consultar el cuaderno en lugar de cargar el documento completo al contexto.
- Usa `nlm --ai` en terminal para ver la documentación completa de las 35 herramientas disponibles.
