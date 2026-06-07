# Research Framework — Permisos requeridos

Lista de entradas para añadir a `settings.local.json → permissions.allow[]` durante la instalación via `research/INIT.md`. Solo incluye permisos específicos del framework que no están presentes en una instalación base de `claude-starter`.

## Permisos del agente notebooklm

```
mcp__notebooklm__research_start
mcp__notebooklm__research_status
mcp__notebooklm__research_import
mcp__notebooklm__notebook_query
mcp__notebooklm__notebook_query_start
mcp__notebooklm__notebook_query_status
mcp__notebooklm__refresh_auth
mcp__notebooklm__server_info
mcp__notebooklm__notebook_list
```

## Permisos del agente Semantic Scholar

```
WebFetch(domain:api.semanticscholar.org)
```

## Permisos de gestión de autenticación notebooklm

```
Bash(nlm login *)
```
