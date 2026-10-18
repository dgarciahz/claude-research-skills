# Skill: per--add-task

Añade una tarea al borrador de tareas de la sesión en curso, para que `per--session-close` la valide al cerrar en vez de reconstruirla.

## Trigger

Usar SOLO cuando el usuario invoque `/per--add-task`. No invocar por iniciativa propia.

## Instrucciones

### 1. Leer CLAUDE_PERSONAL_DIR

Obtén la ruta desde la variable de entorno `CLAUDE_PERSONAL_DIR`. Si no está definida, informa y detente.

### 2. Determinar la tarea

Si el usuario pasó texto como argumento (ej. `/per--add-task migrar X a Y antes de tocar Z`), úsalo como punto de partida.

Si no hay argumento, infiere la tarea de la conversación reciente y muéstrasela al usuario para que la confirme o corrija antes de guardar.

Redáctala con contexto suficiente para retomarla sin releer la sesión: qué falta, por qué, y dependencias o ficheros implicados si los hay.

### 3. Escribir en el borrador

Fichero: `$CLAUDE_PERSONAL_DIR/history/.session-tasks.md`. Si no existe, créalo con la cabecera `# Tareas declaradas durante la sesión`.

Añade al final, sin tocar las entradas existentes:

```markdown
- [YYYY-MM-DD] [descripción de la tarea con contexto]
```

Usa la fecha actual. La fecha permite a `per--session-close` detectar entradas huérfanas de sesiones que no se cerraron.

### 4. Confirmar

Muestra la entrada añadida tal como quedó y cuántas tareas hay ahora en el borrador.

## Notas

- NUNCA sobreescribas ni borres entradas existentes — solo añade al final. El borrador lo vacía `per--session-close`.
- Una invocación = una tarea. Si el usuario da varias, añade una línea por cada una.
