# research--notebooklm

Módulo reutilizable para conectar Claude Code con Google NotebookLM vía MCP (Model Context Protocol). Permite usar cuadernos de NotebookLM como fuente de research con contexto infinito sin gastar tokens.

## Cómo funciona

NotebookLM indexa tus documentos con Gemini usando RAG. Cuando Claude consulta un cuaderno, recibe solo los fragmentos relevantes con citas (~1,500–3,000 tokens) en lugar del documento completo, lo que lo hace ideal para documentación técnica extensa (SDKs, specs, papers).

## Instalación

### Requisitos
- Python con `pip`, `pipx`, o `uv` instalado
- Google Chrome
- Claude Code

### Primera vez en una máquina nueva

```powershell
# Windows — instala en el directorio actual
.\skills\research--notebooklm\install.ps1

# macOS / Linux
chmod +x skills/research--notebooklm/install.sh && ./skills/research--notebooklm/install.sh
```

### Instalar en otro proyecto

```powershell
# Windows
.\skills\research--notebooklm\install.ps1 -TargetProject "C:\ruta\a\mi-proyecto"

# macOS / Linux
./skills/research--notebooklm/install.sh /ruta/a/mi-proyecto
```

El script:
1. Instala `notebooklm-mcp-cli` si no está presente
2. Copia el skill `/research--notebooklm` al proyecto destino
3. Inyecta un snippet en el `CLAUDE.md` del proyecto destino (si existe)
4. Configura el MCP server en `.claude/settings.json` del proyecto destino

### Autenticación (una vez por máquina)

```bash
nlm login
```

Abre Chrome, ingresas con tu cuenta Google, las cookies persisten 2–4 semanas y se auto-refrescan.

## Uso en Claude Code

Una vez instalado en tu proyecto, escribe en cualquier sesión de Claude Code:

```
/research--notebooklm
```

Ejemplos:
- `/research--notebooklm listar mis cuadernos`
- `/research--notebooklm consultar el cuaderno "Stripe API" sobre webhooks`
- `/research--notebooklm agregar esta URL como fuente: https://...`
- `/research--notebooklm generar un reporte del cuaderno "Proyecto X"`

## Herramientas disponibles (35 en total)

Para ver la documentación completa de todas las herramientas:

```bash
nlm --ai
```

Categorías principales:
- **Notebooks**: listar, crear, renombrar, eliminar
- **Fuentes**: URLs, texto, PDFs, YouTube, Google Drive
- **Consultas RAG**: query con citas, chat de seguimiento
- **Studio**: podcasts, reportes, slides, infografías, flashcards, quizzes, tablas, mapas mentales

## Actualizar el módulo

```bash
# Actualizar el binario
uv tool upgrade notebooklm-mcp-cli   # o pip install --upgrade notebooklm-mcp-cli

# Actualizar skill en tu proyecto (re-ejecutar el install script)
.\skills\research--notebooklm\install.ps1 -TargetProject "C:\ruta\a\mi-proyecto"
```

## Estructura del módulo

```
skills/research--notebooklm/
  skill.md          ← skill /research--notebooklm (fuente de verdad)
  install.ps1       ← instalador Windows
  install.sh        ← instalador macOS/Linux
  claude-snippet.md ← fragmento que el instalador inyecta en el CLAUDE.md del proyecto destino
  README.md         ← esta documentación
```

## Notas importantes

- El MCP server usa las APIs internas de Google NotebookLM (no oficiales). Puede romperse si Google cambia su UI.
- Se recomienda revisar actualizaciones del paquete si algo deja de funcionar.
- Las credenciales se guardan localmente en `~/.notebooklm-mcp-cli/`.
