# Skill: per--learn

Añade uno o varios aprendizajes a `learnings.md` en `CLAUDE_PERSONAL_DIR`.

## Trigger

Usar cuando el usuario invoque `/per--learn` o pida guardar un aprendizaje, corrección o patrón a recordar.

## Instrucciones

### 1. Leer CLAUDE_PERSONAL_DIR

Obtén la ruta desde la variable de entorno `CLAUDE_PERSONAL_DIR`. Si no está definida, informa y detente.

### 2. Determinar el aprendizaje

Si el usuario pasó texto como argumento al invocar el skill (ej. `/per--learn nunca usar X porque Y`), úsalo como punto de partida.

Si no hay argumento, pregunta al usuario qué aprendizaje quiere guardar.

### 3. Estructurar el aprendizaje

Para cada aprendizaje, obtén o infiere los tres campos del formato de `learnings.md`:

- **Contexto**: qué se estaba haciendo cuando surgió el aprendizaje
- **Feedback/Error**: qué salió mal o qué corrigió el usuario (o qué funcionó bien y debe repetirse)
- **Regla**: qué hacer (o no hacer) en el futuro — formulado como regla aplicable

Si el usuario proporcionó texto libre, infiere los tres campos tú mismo y muéstraselos para que los confirme o corrija antes de guardar.

Si falta información clave para algún campo, pregunta solo lo necesario — no hagas más de una ronda de preguntas.

### 4. Escribir en learnings.md

Lee `$CLAUDE_PERSONAL_DIR/learnings.md` y añade al final cada aprendizaje con este formato:

```markdown
## YYYY-MM-DD — [tema en 3-6 palabras]
**Contexto**: [qué se estaba haciendo]
**Feedback**: [qué salió mal o qué corrigió el usuario]
**Regla**: [qué hacer o no hacer en el futuro]
```

Usa la fecha actual. Si hay varios aprendizajes, añádelos todos en el mismo paso.

### 5. Confirmar

Informa al usuario de cuántas entradas se añadieron y muestra el texto final de cada una tal como quedó en el archivo.

## Notas

- NUNCA sobreescribas entradas existentes — solo añade al final.
- Si el usuario quiere corregir el texto antes de guardar, permítele hacerlo.
- Un aprendizaje puede ser positivo (patrón a repetir) o negativo (error a evitar) — el campo **Feedback** debe reflejarlo.
