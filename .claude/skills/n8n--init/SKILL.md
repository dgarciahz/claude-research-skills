# Skill: n8n--init

Instala los skills de n8n (czlonkowski/n8n-skills) en el proyecto actual y configura el contexto de n8n para Claude Code: crea `n8n.md` en `CLAUDE_PERSONAL_DIR` y añade la referencia `@filepath` en `CLAUDE.md`.

## Trigger

Usar cuando el usuario invoque `/n8n--init`, o cuando `sys--template-init` lo llame como parte del proceso de inicialización.

## Configuración

- **Repo fuente**: `https://github.com/czlonkowski/n8n-skills`
- **Destino skills**: `.claude/skills/` del proyecto actual
- **Destino contexto**: `$CLAUDE_PERSONAL_DIR/n8n.md`

## Skills incluidos

- `n8n--code-javascript`
- `n8n--code-python`
- `n8n--expression-syntax`
- `n8n--mcp-tools-expert`
- `n8n--node-configuration`
- `n8n--validation-expert`
- `n8n--workflow-patterns`

---

## Instrucciones

### Fase 1 — Instalar skills de n8n

#### 1. Comprobar si ya están instalados

Verifica si existe `.claude/skills/n8n--code-javascript/`. Si existe, pregunta al usuario:
> "Los skills de n8n ya están instalados. ¿Quieres sobreescribirlos con la versión más reciente del repositorio?"

Si responde no, salta directamente a la Fase 2.

#### 2. Clonar el repositorio en un directorio temporal

```bash
git clone --depth=1 https://github.com/czlonkowski/n8n-skills /tmp/n8n-skills-install
```

#### 3. Copiar los skills al proyecto

Para cada skill de la lista anterior, copia su directorio desde el repo clonado a `.claude/skills/`:

```bash
cp -r /tmp/n8n-skills-install/<skill-name> .claude/skills/
```

#### 4. Limpiar el directorio temporal

```bash
rm -rf /tmp/n8n-skills-install
```

---

### Fase 2 — Configurar contexto n8n

#### 5. Leer CLAUDE_PERSONAL_DIR

Lee `CLAUDE_PERSONAL_DIR` del bloque `env` en `.claude/settings.local.json`.
Si no existe la variable, informa al usuario y detente.

#### 6. Crear `n8n.md` si no existe

Verifica si existe `$CLAUDE_PERSONAL_DIR/n8n.md`.
- Si existe: no sobreescribir, pasar al paso 7.
- Si no existe: crear el fichero con la plantilla de contenido agnóstico que figura al final de este skill (sección "Plantilla n8n.md").

#### 7. Verificar N8N_URL en settings.local.json

Comprueba si el bloque `env` de `.claude/settings.local.json` contiene la clave `N8N_URL`.
- Si no existe: preguntar al usuario la URL base de su instancia n8n (ej. `https://mi-instancia.duckdns.org`) y añadir `N8N_URL` y `N8N_API_URL` (URL + `/api/v1`) al bloque `env`.

#### 8. Añadir bloque N8N a CLAUDE.md si no existe

Lee el `CLAUDE.md` del directorio actual.
- Si ya contiene `<!-- N8N:START -->`: no modificar.
- Si no contiene el marcador: añadir al final del fichero:

```
<!-- N8N:START — no eliminar este bloque -->
@<CLAUDE_PERSONAL_DIR>/n8n.md
<!-- N8N:END -->
```

Sustituye `<CLAUDE_PERSONAL_DIR>` por la ruta real (en Windows, usa backslashes).

---

### 9. Confirmar

Informa al usuario de:
- Qué skills se instalaron (o si ya estaban al día)
- Si `n8n.md` se creó o ya existía
- Si `N8N_URL` se añadió a `settings.local.json` o ya estaba configurada
- Si el bloque `<!-- N8N:START/END -->` se añadió a `CLAUDE.md` o ya estaba presente
- Recordatorio: reiniciar Claude Code para que los cambios sean detectados

---

## Notas

- Los skills de n8n son de terceros — no se sincronizan al template via `sys--template-update`.
- Para actualizar a la última versión de los skills, volver a ejecutar `/n8n--init` y confirmar la sobreescritura.
- En Windows, `/tmp/` en Git Bash equivale a `C:\Users\<usuario>\AppData\Local\Temp\`.
- `n8n.md` es agnóstico de instancia — contiene preferencias y prácticas del usuario, no URLs.

---

## Plantilla n8n.md

Usar este contenido al crear `$CLAUDE_PERSONAL_DIR/n8n.md` desde cero:

```markdown
# n8n — Preferencias y prácticas del usuario

> Agnóstico de instancia. La URL de la instancia activa está en `settings.local.json` como `N8N_URL`.
> Locale: es-ES | Timezone: Europe/Madrid

## n8n Technical Constraints

- **Chat Trigger nodes** require an AI Agent/Chain node to properly return responses. A plain Code node connected to a Chat Trigger will not route responses back to the chat UI.
- **Webhook testing pattern**: Use a Webhook trigger with `responseMode: "lastNode"` + Code node for simple request/response testing via MCP.
- **`n8n_update_full_workflow`** requires the `name` parameter even when only updating nodes/connections.
- **`n8n_update_partial_workflow`** is preferred for targeted changes (add/remove/update nodes, activate/deactivate).

## Available Tools

### n8n MCP Server
Use MCP tools for all interactions with n8n:

| Operation | When to use |
|---|---|
| List workflows | Before creating, to check for duplicates; when the user asks what exists |
| Get workflow | Before updating or reviewing any workflow |
| Create workflow | When building a new workflow |
| Update workflow (partial) | When modifying specific nodes or connections |
| Update workflow (full) | When replacing the entire workflow structure |
| Execute/test workflow | To test after creating or updating |
| Get execution history | When debugging or auditing past runs |
| Validate workflow | Before deploying; catches errors, warnings, and suggestions |

### Claude Code Skills (Slash Commands)
Custom `/` commands for n8n tasks: code-javascript, code-python, expression-syntax, mcp-tools-expert, node-configuration, validation-expert, workflow-patterns. Prefer these over manual steps when applicable.

---

## Task Playbooks

### Creating a Workflow

1. Clarify requirements — ask the user if anything is ambiguous before starting
2. List existing workflows via MCP to check for duplicates or similar flows to reference
3. Design the workflow structure (trigger → steps → output) before building
4. Look up node schemas with `get_node` before configuring — use the latest `typeVersion`
5. Build nodes incrementally, naming each node descriptively (e.g., "Fetch User from DB", not "HTTP Request")
6. Validate the workflow with `n8n_validate_workflow` before activating
7. Test via execution; report results to the user

### Updating a Workflow

1. Fetch the current workflow via MCP before making any changes
2. Understand the existing logic fully before modifying
3. Use `n8n_update_partial_workflow` for targeted changes — preserve existing behavior unless explicitly asked to change it
4. Summarize what was changed and why after updating
5. Offer to test the updated workflow

### Reviewing / Auditing a Workflow

1. Fetch the workflow via MCP
2. Inspect for:
   - **Error handling**: Are failure paths handled? Is there an error workflow attached?
   - **Credentials**: No hardcoded secrets or API keys in node parameters
   - **Dead nodes**: Unconnected or disabled nodes left in the workflow
   - **Naming**: Workflow and node names are descriptive
   - **Complexity**: Can any logic be simplified or split into sub-workflows?
   - **Performance**: Any unnecessary polling, large payloads, or missing pagination?
3. Report findings with severity (critical / warning / suggestion)

---

## n8n Best Practices

- **Naming**: Use descriptive, action-oriented names — "Send Slack Notification" not "Slack"
- **Sticky notes**: Add sticky notes to explain complex logic or non-obvious decisions
- **Error workflows**: Attach an error workflow to all production-level flows
- **Credentials**: Always use the n8n credentials store; never hardcode secrets in parameters
- **Single responsibility**: Each workflow should do one thing well; use sub-workflows for reuse
- **Node notes**: Use the node description/note field when parameter logic isn't self-evident
- **Versioning**: When making significant changes, note what version/date was changed

---

## Important Reminders

- Always ask the user to confirm before **deleting** or **overwriting** a workflow
- When in doubt about a requirement, ask — don't assume
- After any create or update, offer to run a test execution to validate
```
