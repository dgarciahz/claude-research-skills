# Learnings — Seguridad (secretos, credenciales, .env, git)

## 2026-09-24 — No subir ficheros con claves a repos
**Contexto**: configurando `.env` de BMAD_test5 con claves de OpenAI/Anthropic para el contenedor Docker.
**Feedback**: el usuario preguntó si es seguro poner API keys en `.env`; se verificó que estaba en `.gitignore` y sin trackear, pero pidió dejar la regla explícita para el futuro.
**Regla**: ficheros con claves/secretos NUNCA se suben a un repo público; en repo privado solo se suben con confirmación FUERTE y explícita del usuario (no vale un "ok" genérico a un `git add`/`commit` amplio) — verificar siempre `.gitignore` antes de cualquier `git add`/`commit` que pueda incluirlos.
