# Skill: per--session-close

Genera un resumen de la sesión actual y lo guarda en el historial persistente.

## Trigger

Usar cuando el usuario invoque `/per--session-close` o pida cerrar/guardar la sesión.

## Instrucciones

### 1. Leer CLAUDE_PERSONAL_DIR

Obtén la ruta desde la variable de entorno `CLAUDE_PERSONAL_DIR`. Si no está definida, informa y detente.

### 2. Generar resumen de la sesión

Genera un resumen estructurado de la sesión actual con estas secciones:

```markdown
# Sesión — YYYY-MM-DD

## Contexto
[Proyecto y objetivo principal de la sesión]

## Tareas completadas
- [lista de lo que se hizo]

## Tareas pendientes
- [lista de lo que quedó sin terminar, con suficiente contexto para retomarlo]

## Decisiones tomadas
- [decisiones de diseño, arquitectura o configuración relevantes]

## Aprendizajes / Feedback
- [correcciones del usuario, patrones a recordar]
```

### 3. Determinar nombre de archivo

Formato: `session-YYYY-MM-DD-NNN.md` donde NNN es un correlativo de 3 dígitos empezando en 001.

Comprueba cuántos archivos del día ya existen en `history/` para asignar el siguiente número.

### 4. Escribir el archivo

Guarda el resumen en `$CLAUDE_PERSONAL_DIR/history/session-YYYY-MM-DD-NNN.md`.

### 5. Mantener límite de 15 sesiones

Cuenta los archivos en `history/`. Si hay más de 15, elimina el más antiguo (el de fecha más temprana).

### 6. Confirmar

Informa al usuario de:
- Nombre del archivo guardado
- Cuántas sesiones hay ahora en el historial
- Si se eliminó alguna sesión antigua

## Notas

- No resumas demasiado las tareas pendientes — deben tener suficiente contexto para retomarse sin releer toda la sesión.
- Si el usuario quiere añadir algo al resumen antes de guardarlo, permítele revisar y editar.
