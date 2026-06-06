# Skill: per--init

Inicializa el sistema de personalización persistente para un proyecto nuevo: crea los archivos base si no existen y añade el bloque de carga al `CLAUDE.md` del proyecto.

## Trigger

Usar cuando el usuario invoque `/per--init`, o cuando `sys--template-init` lo llame como parte del proceso de inicialización.

## Instrucciones

Sigue estos pasos en orden:

### 1. Leer CLAUDE_PERSONAL_DIR

Obtén la ruta desde la variable de entorno `CLAUDE_PERSONAL_DIR`.

Si no está definida, pide la ruta al usuario:
> "¿Cuál es la ruta de tu directorio de personalización? (ej. `C:\Users\tu-usuario\claude-personal` o `~/claude-personal`)"

Con la ruta proporcionada:
1. Escríbela en el bloque `env` de `.claude/settings.local.json` (créalo si no existe):
   ```json
   { "env": { "CLAUDE_PERSONAL_DIR": "<ruta>" } }
   ```
   Si el archivo ya existe, añade solo la clave `CLAUDE_PERSONAL_DIR` sin tocar las demás claves.
2. Informa al usuario: "Reinicia Claude Code al terminar para que la variable quede disponible en el entorno."
3. Continúa usando la ruta proporcionada para el resto de los pasos de este skill.

### 2. Crear archivos base (solo si no existen)

Comprueba si existen estos archivos. **Nunca sobreescribas si ya existen.**

- `$CLAUDE_PERSONAL_DIR/soul.md`
- `$CLAUDE_PERSONAL_DIR/user.md`
- `$CLAUDE_PERSONAL_DIR/learnings.md`
- `$CLAUDE_PERSONAL_DIR/history/` (directorio)

Si alguno no existe, créalo con el contenido mínimo de plantilla:

**soul.md**: secciones Identidad, Principios éticos, Estilo de razonamiento — con texto placeholder.
**user.md**: secciones Idioma, Formato, Estilo de respuesta — con texto placeholder.
**learnings.md**: cabecera explicativa + vacío.
**history/**: directorio vacío.

### 3. Añadir bloque PERSONALIZATION al CLAUDE.md del proyecto

Lee el `CLAUDE.md` del directorio de trabajo actual.

Si ya contiene `<!-- PERSONALIZATION:START -->`, informa al usuario y no toques nada.

Si no existe el bloque, añade al final del archivo:

```
<!-- PERSONALIZATION:START — no eliminar este bloque -->
@<CLAUDE_PERSONAL_DIR>/soul.md
@<CLAUDE_PERSONAL_DIR>/user.md
@<CLAUDE_PERSONAL_DIR>/learnings.md
<!-- PERSONALIZATION:END -->
```

Sustituye `<CLAUDE_PERSONAL_DIR>` por la ruta real. En Windows usa backslashes (`\`).

### 4. Confirmar

Informa al usuario de:
- Qué archivos se crearon (o ya existían)
- Si el bloque se añadió al CLAUDE.md o ya estaba presente
- Recordatorio: reiniciar Claude Code para que los cambios en CLAUDE.md surtan efecto

## Notas

- NUNCA sobreescribas soul.md, user.md ni learnings.md si ya existen — contienen datos del usuario.
- El bloque PERSONALIZATION debe mantenerse intacto en futuras actualizaciones del CLAUDE.md.
- Si CLAUDE.md no existe en el proyecto, créalo con solo el bloque PERSONALIZATION.
