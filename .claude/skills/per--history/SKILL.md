# Skill: per--history

Lee el historial de sesiones y presenta un resumen ponderado según la antigüedad.

## Trigger

Usar cuando el usuario invoque `/per--history` o pida ver el historial de sesiones anteriores.

## Instrucciones

### 1. Leer CLAUDE_PERSONAL_DIR

Obtén la ruta desde la variable de entorno `CLAUDE_PERSONAL_DIR`. Si no está definida, informa y detente.

### 2. Listar archivos de historial

Lee todos los archivos de `$CLAUDE_PERSONAL_DIR/history/` ordenados por nombre (que equivale a orden cronológico por el formato `session-YYYY-MM-DD-NNN.md`).

Si no hay archivos, informa al usuario que el historial está vacío.

### 3. Aplicar ponderación por antigüedad

**Nivel 1 — Última sesión (máxima prioridad)**
- Lee el archivo completo
- Presenta: punto exacto donde se quedó, tareas pendientes con su contexto completo, decisiones relevantes tomadas

**Nivel 2 — Sesiones 2 a 4 (prioridad media)**
- Lee cada archivo
- Extrae: temas recurrentes, hilos conductores, tareas que aparecen en más de una sesión

**Nivel 3 — Sesiones 5 a 15 (prioridad base)**
- Lee cada archivo
- Extrae solo: conceptos clave, proyectos/áreas mencionados, contexto general
- No incluyas detalles — evita saturar el contexto de tokens

### 4. Presentar el resumen

Estructura la respuesta así:

```
## ¿Dónde lo dejamos? (última sesión — YYYY-MM-DD)
[resumen detallado de la última sesión]

## Hilos recientes (últimas 3 sesiones)
[temas recurrentes o en progreso]

## Contexto general (historial)
[conceptos clave del historial completo]
```

## Notas

- Si el usuario solo quiere la última sesión, lee solo el archivo más reciente.
- El objetivo del Nivel 3 es contexto, no detalle — prioriza brevedad para no consumir tokens innecesariamente.
