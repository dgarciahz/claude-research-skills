# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project manages n8n workflows through Claude Code via the n8n-mcp MCP server. Three primary operations: **Create**, **Update**, and **Review/Audit** workflows.

## n8n Instance

- **URL**: https://silocompany-n8n.duckdns.org/home/workflows
- **API**: https://silocompany-n8n.duckdns.org/api/v1
- **User locale**: es-ES, timezone: Europe/Madrid

## Environment Notes

- Windows 10, Git Bash shell
- Node.js v24.13.0 is at `C:\Program Files\nodejs\` but is **NOT in the bash PATH**. The `.mcp.json` must use the full path `C:\Program Files\nodejs\npx.cmd` as the command — not just `npx`.
- n8n skills (7) are installed in `~/.claude/skills/` from czlonkowski/n8n-skills

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
