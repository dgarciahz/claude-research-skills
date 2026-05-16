# Skill: per--session-close

Genera un resumen de la sesión actual y lo guarda en el historial persistente.

## Trigger

Usar cuando el usuario invoque `/per--session-close` o pida cerrar/guardar la sesión.

## Instrucciones

### 1. Leer CLAUDE_PERSONAL_DIR

Obtén la ruta desde la variable de entorno `CLAUDE_PERSONAL_DIR`. Si no está definida, informa y detente.

### 2. Revisar pendientes de la sesión anterior

Lee el archivo de sesión más reciente en `$CLAUDE_PERSONAL_DIR/history/`. Para cada tarea pendiente que aparezca en él, evalúa explícitamente qué pasó esta sesión:

- **Completada** → inclúyela en "Tareas completadas", no en "Tareas pendientes"
- **Resuelta de otra forma** → no la arrastres; menciónala en "Decisiones tomadas" si el cambio de enfoque es relevante
- **Todavía activa** → inclúyela en "Tareas pendientes" con contexto actualizado
- **Descartada / ya no aplica** → no la incluyas

No copies tareas pendientes de sesiones anteriores sin pasar por este análisis. Si no hay sesión anterior, omite este paso.

### 3. Generar resumen de la sesión

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

### 4. Determinar nombre de archivo

Formato: `session-YYYY-MM-DD-NNN.md` donde NNN es un correlativo de 3 dígitos empezando en 001.

Comprueba cuántos archivos del día ya existen en `history/` para asignar el siguiente número.

### 5. Escribir el archivo

Guarda el resumen en `$CLAUDE_PERSONAL_DIR/history/session-YYYY-MM-DD-NNN.md`.

### 6. Mantener límite de 15 sesiones

Cuenta los archivos en `history/`. Si hay más de 15, elimina el más antiguo (el de fecha más temprana).

### 7. Confirmar

Informa al usuario de:
- Nombre del archivo guardado
- Cuántas sesiones hay ahora en el historial
- Si se eliminó alguna sesión antigua

## Notas

- No resumas demasiado las tareas pendientes — deben tener suficiente contexto para retomarse sin releer toda la sesión.
- Si el usuario quiere añadir algo al resumen antes de guardarlo, permítele revisar y editar.
