# MCP Servers recomendados

Catálogo de referencia para `sys--init-template`. Cada entrada describe un servidor MCP, cómo arrancarlo y qué credenciales necesita.

## n8n-mcp
- **Paquete**: `n8n-mcp` (via npx)
- **Variables necesarias**: `N8N_API_URL`, `N8N_API_KEY`
- **Variables opcionales**: `LOG_LEVEL` (default: `error`), `DISABLE_CONSOLE_OUTPUT` (default: `true`)
- **Uso**: Gestión de workflows n8n via MCP

## playwright
- **Paquete**: `@playwright/mcp@latest` (via npx)
- **Variables necesarias**: ninguna
- **Uso**: Automatización de navegador (scraping, testing, capturas)

## context7
- **Paquete**: `@upstash/context7-mcp@latest` (via npx)
- **Variables necesarias**: ninguna
- **Uso**: Documentación actualizada de librerías en contexto de Claude
