# Research Framework — MCP Servers requeridos

Catálogo de referencia usado por `research/INIT.md` para configurar los MCP servers necesarios. El formato sigue el mismo patrón de `.claude/assets/MCP_SERVERS.md` de `claude-starter`.

## notebooklm

- **Paquete**: `notebooklm-mcp` (via pip)
- **Variables necesarias**:
  - `SSL_CERT_FILE`: ruta al bundle de certificados de certifi (obligatorio en Windows)
- **Instalación previa**:
  ```bash
  pip install notebooklm-mcp
  nlm login   # autenticación con tu cuenta Google
  ```
- **Detección de rutas** (ejecutar en shell):
  - Ejecutable → Windows: `Get-Command notebooklm-mcp | Select-Object -ExpandProperty Source`
  - Ejecutable → Unix/Mac: `which notebooklm-mcp`
  - Certifi → cualquier SO: `python -c "import certifi; print(certifi.where())"`
- **Uso**: Research conversacional en Google NotebookLM — crea cuadernos, importa fuentes web y permite queries sobre ellas.
- **Nota**: Sin `SSL_CERT_FILE` en Windows falla con `CERTIFICATE_VERIFY_FAILED`. Requiere `nlm login` previo al primer uso.
