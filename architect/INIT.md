# Architect Framework — Inicialización

Instrucciones para inicializar el Architect Framework en el proyecto actual. Idempotente: puede ejecutarse varias veces.

El framework se instala con `/core--template-pull architect`, que copia `architect/` y los skills `arch--learn` y `arch--stack` a `.claude/skills/`. INIT.md no instala nada: comprueba los skills y conecta el contenido a `CLAUDE.md`.

## Cómo invocar

- `"ejecuta architect/INIT.md"`
- `"inicializa el architect framework"`

---

## Instrucciones de inicialización

### Paso 1 — Verificar skills y contenido

Comprueba que existen `.claude/skills/arch--learn/SKILL.md` y `.claude/skills/arch--stack/SKILL.md`, y los ficheros `architect/assets/learnings/learnings.md`, `architect/assets/learnings/_index.md` y `architect/assets/IT_stacks/_index_stacks.md`.

Si falta alguno: informa de cuáles y de que hay que ejecutar `/core--template-pull architect`; detente. NUNCA los recrees vacíos.

### Paso 2 — Bloque ARCHITECT en CLAUDE.md (obligatorio)

Los ficheros de arquitectura se cargan desde `architect/assets/`. Sin este paso el framework no tiene efecto: no lo omitas.

Lee `CLAUDE.md` en la raíz (si no existe, créalo con la cabecera `# CLAUDE.md`).

Si existe `<!-- ARCHITECT:START -->`, reemplaza el bloque completo hasta `<!-- ARCHITECT:END -->`. Si no existe, añádelo al final:

```
<!-- ARCHITECT:START — no eliminar este bloque -->
@architect/assets/learnings/learnings.md
@architect/assets/learnings/_index.md
@architect/assets/IT_stacks/_index_stacks.md
<!-- ARCHITECT:END -->
```

### Paso 3 — Quitar referencias antiguas de PERSONALIZATION

Si `CLAUDE.md` tiene un bloque `<!-- PERSONALIZATION:START -->` con líneas `@.../learnings.md`, `@.../learnings/_index.md` o `@.../IT_stacks/_index_stacks.md` (apuntando a `CLAUDE_PERSONAL_DIR`), elimina solo esas líneas. No toques `soul.md` ni `user.md`.

### Paso 4 — Registrar hook de versión en settings.json

Lee `.claude/settings.json` (si no existe, tratarlo como `{}`). Comprueba si ya existe una entrada en `hooks.SessionStart[].hooks[]` con `"command": "bash architect/assets/version-check.sh"`.

- **Sí existe** → omitir.
- **No existe** → añadir al array `hooks.SessionStart[]` la siguiente entrada, preservando todas las entradas existentes:

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "bash architect/assets/version-check.sh"
    }
  ]
}
```

Escribir `.claude/settings.json` resultante.

### Paso 5 — Confirmar al usuario

Informa de: skills verificados, bloque ARCHITECT añadido/actualizado, líneas eliminadas de PERSONALIZATION, hook de versión (añadido | ya existía), y que hay que reiniciar Claude Code para cargar los imports.

---

## Notas

- Re-ejecutar aplica cambios del template sin perder contenido.
- Para desinstalar: elimina el bloque ARCHITECT de `CLAUDE.md`, el directorio `architect/` y los skills `arch--learn` y `arch--stack`.
